#!/usr/bin/env python3
"""Materialize small ProofWala-compatible smoke datasets.

Inputs are the downloaded ProofWalaDataset and the frozen Lean eval refs. Outputs
are small ignored runtime datasets under data/smoke/ plus a tracked smoke
manifest under data/manifests/.
"""

from __future__ import annotations

import argparse
import copy
import json
import pathlib
import random
import re
from datetime import date
from typing import Iterable


DEFAULT_DATASET_ROOT = "data/proofwala_dataset/ProofWalaDataset"
DEFAULT_FROZEN_SPLITS = "data/frozen_splits"
DEFAULT_OUTPUT_ROOT = "data/smoke"
DEFAULT_MANIFEST = "data/manifests/smoke_manifest.yaml"
DEFAULT_E4_AUDIT = "data/pseudo_multilingual/e4_audit.md"
DEFAULT_SEED = 20260504


def load_json(path: pathlib.Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def write_json(path: pathlib.Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, ensure_ascii=False)
        handle.write("\n")


def local_data_files(dataset_root: pathlib.Path, source: str) -> list[pathlib.Path]:
    return sorted((dataset_root / source).glob("local_data_*.json"))


def iter_records(dataset_root: pathlib.Path, source: str) -> Iterable[dict]:
    for data_file in local_data_files(dataset_root, source):
        for record in load_json(data_file)["training_data"]:
            yield record


def reservoir_sample(
    dataset_root: pathlib.Path,
    source: str,
    count: int,
    seed: int,
) -> list[dict]:
    rng = random.Random(seed)
    sample: list[dict] = []
    for index, record in enumerate(iter_records(dataset_root, source)):
        if index < count:
            sample.append(copy.deepcopy(record))
            continue
        replacement = rng.randint(0, index)
        if replacement < count:
            sample[replacement] = copy.deepcopy(record)
    if len(sample) < count:
        raise ValueError(f"requested {count} records from {source}, found {len(sample)}")
    return sample


def records_from_refs(dataset_root: pathlib.Path, refs_path: pathlib.Path, count: int) -> list[dict]:
    cache: dict[str, list[dict]] = {}
    records: list[dict] = []
    with refs_path.open("r", encoding="utf-8") as handle:
        for line in handle:
            if len(records) >= count:
                break
            ref = json.loads(line)
            source_file = ref["source_file"]
            if source_file not in cache:
                cache[source_file] = load_json(dataset_root / source_file)["training_data"]
            records.append(copy.deepcopy(cache[source_file][ref["record_index"]]))
    if len(records) < count:
        raise ValueError(f"requested {count} refs from {refs_path}, found {len(records)}")
    return records


IDENTIFIER_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_']*$")


def reformat_text(text: str | None) -> str | None:
    if text is None:
        return None
    original = text
    lines = text.splitlines()
    if len(lines) > 1:
        text = lines[0] + "\n" + "\n".join(f"  {line}" for line in lines[1:])

    replacements = [
        (" : ", "  :  "),
        (" = ", "  =  "),
        (" <+ ", "  <+  "),
        (" :: ", "  ::  "),
        (" + ", "  +  "),
        (" - ", "  -  "),
        (" * ", "  *  "),
        (" / ", "  /  "),
        (" ↦ ", "  ↦  "),
        (" → ", "  →  "),
        (" ∧ ", "  ∧  "),
        (" ∨ ", "  ∨  "),
    ]
    for old, new in replacements:
        if old in text:
            text = text.replace(old, new, 1)
            break

    if text != original:
        return text

    # Last-resort formatting-only change for compact strings such as "case cons"
    # or "True": insert a line break/space without introducing new semantic tokens.
    first_space = text.find(" ")
    if first_space != -1:
        return text[:first_space] + "\n  " + text[first_space + 1:]
    return text + "\n"


def collect_local_identifier_map(record: dict) -> dict[str, str]:
    names: list[str] = []
    blocked = {
        "_",
        "case",
        "Type",
        "Prop",
        "Sort",
        "Nat",
        "Int",
        "Set",
        "True",
        "False",
    }
    for goal_group in ["start_goals", "end_goals", "simplified_goals"]:
        for goal in record.get(goal_group) or []:
            for hypothesis in goal.get("hypotheses") or []:
                separator = " : " if " : " in hypothesis else " := " if " := " in hypothesis else None
                if separator is None:
                    continue
                binder_text = hypothesis.split(separator, 1)[0].strip()
                for raw_name in binder_text.split():
                    name = raw_name.strip("(){}[],")
                    if name in blocked or not IDENTIFIER_RE.match(name):
                        continue
                    if name not in names:
                        names.append(name)
    return {name: f"pseudo_{idx}" for idx, name in enumerate(names[:24])}


def apply_identifier_map(text: str | None, rename_map: dict[str, str]) -> str | None:
    if text is None or not rename_map:
        return text
    result = text
    for old_name, new_name in sorted(rename_map.items(), key=lambda item: len(item[0]), reverse=True):
        result = re.sub(
            rf"(?<![A-Za-z0-9_']){re.escape(old_name)}(?![A-Za-z0-9_'])",
            new_name,
            result,
        )
    return result


def make_pseudo_record(record: dict, variant_index: int) -> dict:
    pseudo = copy.deepcopy(record)
    source_proof_id = str(record.get("proof_id") or f"missing-proof-id-{variant_index}")
    rename_map = collect_local_identifier_map(record)
    pseudo["proof_id"] = f"{source_proof_id}-pseudo-local-rename-v1"
    if pseudo.get("theorem_name"):
        pseudo["theorem_name"] = f"{pseudo['theorem_name']}__pseudo_format_v1"
    pseudo["addition_state_info"] = dict(pseudo.get("addition_state_info") or {})
    pseudo["addition_state_info"]["pseudo_variant"] = "local_rename_v1"
    pseudo["addition_state_info"]["source_proof_id"] = source_proof_id
    pseudo["addition_state_info"]["rename_map"] = rename_map

    for goal_group in ["start_goals", "end_goals", "simplified_goals"]:
        for goal in pseudo.get(goal_group) or []:
            goal["hypotheses"] = [
                reformat_text(apply_identifier_map(hypothesis, rename_map))
                for hypothesis in goal.get("hypotheses") or []
            ]
            goal["goal"] = reformat_text(apply_identifier_map(goal.get("goal"), rename_map))

    pseudo["proof_steps"] = [
        apply_identifier_map(step, rename_map) or step
        for step in pseudo.get("proof_steps") or []
    ]
    return pseudo


def write_training_dir(output_dir: pathlib.Path, records: list[dict], buffer_size: int = 10000) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    data_file = output_dir / f"local_data_{len(records):010d}.json"
    lemma_file = output_dir / "local_lemma_0000000000.json"
    meta_file = output_dir / "local.meta.json"
    write_json(data_file, {"training_data": records})
    write_json(lemma_file, {"training_data": []})
    write_json(
        meta_file,
        {
            "training_data_buffer_size": buffer_size,
            "last_training_data": len(records),
            "last_proof_id": records[-1].get("proof_id") if records else None,
            "external_theorems_used_cnt": 0,
            "local_theorems_used_cnt": 0,
            "total_data_count": len(records),
            "data_filename_prefix": "local_data_",
            "data_filename_suffix": ".json",
            "lemma_ref_filename_prefix": "local_lemma_",
            "lemma_ref_filename_suffix": ".json",
            "num_theorems": len({record.get("proof_id") for record in records}),
        },
    )


def goal_excerpt(record: dict) -> str:
    goals = record.get("start_goals") or []
    if not goals:
        return "(no start goal)"
    goal = goals[0]
    hyps = goal.get("hypotheses") or []
    hyp = hyps[0] if hyps else "(no hypotheses)"
    text = goal.get("goal") or "(no goal text)"
    return f"hyp: {hyp}\ngoal: {text[:240]}"


def write_e4_audit(path: pathlib.Path, originals: list[dict], pseudos: list[dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        "# E4 Pseudo-Multilingual Smoke Audit",
        "",
        f"Generated on: {date.today().isoformat()}",
        "",
        "Transformation: `local_rename_v1`",
        "",
        "- Proof-step targets are updated with the same local identifier rename map.",
        "- Pseudo records get a new `proof_id` suffix.",
        "- Local identifiers parsed from hypotheses are renamed consistently to `pseudo_0`, `pseudo_1`, ...",
        "- The same local rename map is applied to hypotheses, goals, and proof steps.",
        "- Minor spacing/indentation changes are applied after renaming.",
        "- `addition_state_info` records the source proof id.",
        "",
        "Manual inspection sample: first 50 pseudo records.",
        "",
    ]
    for idx, (original, pseudo) in enumerate(zip(originals[:50], pseudos[:50]), start=1):
        lines.extend(
            [
                f"## Example {idx}",
                "",
                f"- source proof id: `{original.get('proof_id')}`",
                f"- pseudo proof id: `{pseudo.get('proof_id')}`",
                f"- rename map: `{pseudo.get('addition_state_info', {}).get('rename_map', {})}`",
                f"- original proof step: `{(original.get('proof_steps') or [''])[0]}`",
                f"- pseudo proof step: `{(pseudo.get('proof_steps') or [''])[0]}`",
                "",
                "Original:",
                "",
                "```text",
                goal_excerpt(original),
                "```",
                "",
                "Pseudo:",
                "",
                "```text",
                goal_excerpt(pseudo),
                "```",
                "",
            ]
        )
    path.write_text("\n".join(lines), encoding="utf-8")


def write_manifest(path: pathlib.Path, rows: list[tuple[str, str, int]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        "version: 1",
        f"created_on: {date.today().isoformat()}",
        "purpose: Day 3 training smoke tests for E1, E3, and E4",
        "datasets:",
    ]
    for name, dataset_path, count in rows:
        lines.extend(
            [
                f"  {name}:",
                f"    path: {dataset_path}",
                f"    local_meta: {dataset_path}/local.meta.json",
                f"    count: {count}",
            ]
        )
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dataset-root", default=DEFAULT_DATASET_ROOT)
    parser.add_argument("--frozen-splits", default=DEFAULT_FROZEN_SPLITS)
    parser.add_argument("--output-root", default=DEFAULT_OUTPUT_ROOT)
    parser.add_argument("--manifest", default=DEFAULT_MANIFEST)
    parser.add_argument("--e4-audit", default=DEFAULT_E4_AUDIT)
    parser.add_argument("--train-size", type=int, default=512)
    parser.add_argument("--eval-size", type=int, default=128)
    parser.add_argument("--seed", type=int, default=DEFAULT_SEED)
    args = parser.parse_args()

    dataset_root = pathlib.Path(args.dataset_root)
    frozen_splits = pathlib.Path(args.frozen_splits)
    output_root = pathlib.Path(args.output_root)

    e1_train = reservoir_sample(dataset_root, "lean/train", args.train_size, args.seed)
    e3_train = reservoir_sample(dataset_root, "multilingual/train", args.train_size, args.seed + 1)
    e4_original = reservoir_sample(dataset_root, "lean/train", args.train_size // 2, args.seed + 2)
    e4_pseudo = [
        make_pseudo_record(record, idx)
        for idx, record in enumerate(e4_original)
    ]
    e4_train = e4_original + e4_pseudo
    eval_records = records_from_refs(
        dataset_root,
        frozen_splits / "lean_eval_1000_proofs.jsonl",
        args.eval_size,
    )

    outputs = [
        ("e1_train", output_root / "e1_train", e1_train),
        ("e3_train", output_root / "e3_train", e3_train),
        ("e4_train", output_root / "e4_train", e4_train),
        ("lean_eval_fixed", output_root / "lean_eval_fixed", eval_records),
    ]
    for _, output_dir, records in outputs:
        write_training_dir(output_dir, records, buffer_size=max(1000, len(records)))

    write_e4_audit(pathlib.Path(args.e4_audit), e4_original, e4_pseudo)
    write_manifest(
        pathlib.Path(args.manifest),
        [(name, str(path), len(records)) for name, path, records in outputs],
    )

    for name, output_dir, records in outputs:
        print(f"wrote {name}: {output_dir} ({len(records)} records)")
    print(f"wrote {args.manifest}")
    print(f"wrote {args.e4_audit}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
