#!/usr/bin/env python3
"""Freeze pilot dataset splits for E1, E3, and E4.

The downloaded ProofWalaDataset already has train/eval/test directories. For
the pilot we freeze:

- a small fixed Lean eval subset shared by E1/E3/E4
- a small fixed Lean test subset shared by E1/E3/E4
- source-level training pools for E1, E3 smoke, E3 final, and E4

Training pools are recorded by dataset split and counts instead of materializing
hundreds of thousands of JSONL references. The final token-matched E3 mixture
and E4 pseudo-Lean augmentation should be materialized by follow-up data scripts
using the seeds and source pools recorded here.
"""

from __future__ import annotations

import argparse
import json
import pathlib
import random
from dataclasses import dataclass
from datetime import date
from typing import Iterable


DEFAULT_DATASET_ROOT = "data/proofwala_dataset/ProofWalaDataset"
DEFAULT_OUTPUT_DIR = "data/frozen_splits"
DEFAULT_SEED = 20260504
DEFAULT_EVAL_SIZE = 1000
DEFAULT_TEST_SIZE = 1000


@dataclass(frozen=True)
class SplitInfo:
    family: str
    split: str
    path: pathlib.Path
    proof_steps: int
    files: list[str]


def load_json(path: pathlib.Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def split_dir(dataset_root: pathlib.Path, family: str, split: str) -> pathlib.Path:
    return dataset_root / family / split


def local_data_files(directory: pathlib.Path) -> list[pathlib.Path]:
    return sorted(directory.glob("local_data_*.json"))


def read_split_info(dataset_root: pathlib.Path, family: str, split: str) -> SplitInfo:
    directory = split_dir(dataset_root, family, split)
    meta_path = directory / "local.meta.json"
    if not meta_path.exists():
        raise FileNotFoundError(meta_path)
    metadata = load_json(meta_path)
    files = [
        str(path.relative_to(dataset_root))
        for path in local_data_files(directory)
    ]
    return SplitInfo(
        family=family,
        split=split,
        path=directory,
        proof_steps=int(metadata["total_proof_step_cnt"]),
        files=files,
    )


def iter_examples(dataset_root: pathlib.Path, family: str, split: str) -> Iterable[dict]:
    directory = split_dir(dataset_root, family, split)
    for data_file in local_data_files(directory):
        payload = load_json(data_file)
        training_data = payload["training_data"]
        relative_file = str(data_file.relative_to(dataset_root))
        for index, record in enumerate(training_data):
            yield {
                "source_file": relative_file,
                "record_index": index,
                "proof_id": record.get("proof_id"),
                "theorem_name": record.get("theorem_name"),
                "file_path": record.get("file_path"),
            }


def iter_unique_proofs(dataset_root: pathlib.Path, family: str, split: str) -> Iterable[dict]:
    seen: set[str] = set()
    for example in iter_examples(dataset_root, family, split):
        proof_id = example.get("proof_id")
        if proof_id in seen:
            continue
        seen.add(proof_id)
        yield example


def sample_unique_proofs(
    dataset_root: pathlib.Path,
    family: str,
    split: str,
    sample_size: int,
    seed: int,
) -> list[dict]:
    examples = list(iter_unique_proofs(dataset_root, family, split))
    sample_size = min(sample_size, len(examples))
    rng = random.Random(seed)
    sampled = rng.sample(examples, sample_size)
    return sorted(sampled, key=lambda item: (item["source_file"], item["record_index"]))


def write_jsonl(path: pathlib.Path, rows: Iterable[dict]) -> int:
    path.parent.mkdir(parents=True, exist_ok=True)
    count = 0
    with path.open("w", encoding="utf-8") as handle:
        for row in rows:
            handle.write(json.dumps(row, sort_keys=True) + "\n")
            count += 1
    return count


def yaml_quote(value: str) -> str:
    escaped = value.replace("\\", "\\\\").replace('"', '\\"')
    return f'"{escaped}"'


def write_split_manifest(
    path: pathlib.Path,
    dataset_root: pathlib.Path,
    seed: int,
    eval_size: int,
    test_size: int,
    infos: dict[tuple[str, str], SplitInfo],
    eval_refs_path: pathlib.Path,
    test_refs_path: pathlib.Path,
) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    rel_dataset_root = str(dataset_root)
    eval_rel = str(eval_refs_path)
    test_rel = str(test_refs_path)
    lines = [
        "version: 1",
        f"created_on: {date.today().isoformat()}",
        "dataset:",
        "  name: ProofWalaDataset",
        "  repo: amitayusht/ProofWalaDataset",
        "  url: https://huggingface.co/datasets/amitayusht/ProofWalaDataset",
        "  revision: 754fe36f8875178afbd9651f5c26a75d51171b3d",
        f"  root: {yaml_quote(rel_dataset_root)}",
        "randomization:",
        f"  seed: {seed}",
        "  sampler: python_random_sample_without_replacement",
        "shared_evaluation:",
        "  validation:",
        "    source: lean/eval",
        f"    refs: {yaml_quote(eval_rel)}",
        f"    count: {eval_size}",
        "    unit: unique_proof_id",
        "    purpose: validation_and_calibration_only",
        "  final_test:",
        "    source: lean/test",
        f"    refs: {yaml_quote(test_rel)}",
        f"    count: {test_size}",
        "    unit: unique_proof_id",
        "    purpose: final_reported_metrics",
        "experiments:",
        "  E1:",
        "    name: Lean-only baseline",
        "    train:",
        "      source: lean/train",
        f"      proof_steps: {infos[('lean', 'train')].proof_steps}",
        "      selection: all",
        f"    eval_refs: {yaml_quote(eval_rel)}",
        f"    test_refs: {yaml_quote(test_rel)}",
        "  E3_smoke:",
        "    name: Real multilingual smoke test",
        "    train:",
        "      source: multilingual/train",
        f"      proof_steps: {infos[('multilingual', 'train')].proof_steps}",
        "      selection: all",
        f"    eval_refs: {yaml_quote(eval_rel)}",
        f"    test_refs: {yaml_quote(test_rel)}",
        "  E3_final:",
        "    name: Real multilingual final",
        "    train:",
        "      sources:",
        "        - source: lean/train",
        f"          proof_steps: {infos[('lean', 'train')].proof_steps}",
        "        - source: coq/train",
        f"          proof_steps: {infos[('coq', 'train')].proof_steps}",
        "      selection: token_matched_lean_plus_coq_mixture",
        "      target_budget: match_E1_effective_training_tokens",
        "      materialization_status: pending_token_budget_script",
        f"    eval_refs: {yaml_quote(eval_rel)}",
        f"    test_refs: {yaml_quote(test_rel)}",
        "  E4:",
        "    name: Pseudo-multilingual control",
        "    train:",
        "      sources:",
        "        - source: lean/train",
        f"          proof_steps: {infos[('lean', 'train')].proof_steps}",
        "        - source: pseudo_lean/train",
        "          proof_steps: pending_generation",
        "      selection: token_matched_lean_plus_pseudo_lean_mixture",
        "      target_budget: match_E1_and_E3_final_effective_training_tokens",
        "      materialization_status: pending_pseudo_generation_script",
        f"    eval_refs: {yaml_quote(eval_rel)}",
        f"    test_refs: {yaml_quote(test_rel)}",
        "source_split_counts:",
    ]

    for (family, split), info in sorted(infos.items()):
        lines.extend(
            [
                f"  {family}_{split}:",
                f"    source: {family}/{split}",
                f"    proof_steps: {info.proof_steps}",
                f"    local_data_files: {len(info.files)}",
            ]
        )

    lines.extend(
        [
            "discipline:",
            "  - E1, E3, and E4 must use the same validation and test refs.",
            "  - Do not report final results on lean/eval; use lean/test only.",
            "  - E3_final and E4 must be token-budget matched before full training.",
            "  - If a reduced training subset is used, record it in this manifest before training.",
        ]
    )

    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dataset-root", default=DEFAULT_DATASET_ROOT)
    parser.add_argument("--output-dir", default=DEFAULT_OUTPUT_DIR)
    parser.add_argument("--seed", type=int, default=DEFAULT_SEED)
    parser.add_argument("--eval-size", type=int, default=DEFAULT_EVAL_SIZE)
    parser.add_argument("--test-size", type=int, default=DEFAULT_TEST_SIZE)
    args = parser.parse_args()

    dataset_root = pathlib.Path(args.dataset_root)
    output_dir = pathlib.Path(args.output_dir)
    eval_refs = sample_unique_proofs(
        dataset_root,
        "lean",
        "eval",
        args.eval_size,
        args.seed,
    )
    test_refs = sample_unique_proofs(
        dataset_root,
        "lean",
        "test",
        args.test_size,
        args.seed + 1,
    )

    eval_refs_path = output_dir / f"lean_eval_{len(eval_refs)}_proofs.jsonl"
    test_refs_path = output_dir / f"lean_test_{len(test_refs)}_proofs.jsonl"
    manifest_path = output_dir / "split_manifest.yaml"

    required_infos = {}
    for family, split in [
        ("lean", "train"),
        ("lean", "eval"),
        ("lean", "test"),
        ("coq", "train"),
        ("multilingual", "train"),
    ]:
        required_infos[(family, split)] = read_split_info(dataset_root, family, split)

    eval_ids = {row["proof_id"] for row in eval_refs}
    test_ids = {row["proof_id"] for row in test_refs}
    overlap = eval_ids & test_ids
    if overlap:
        raise RuntimeError(f"lean eval/test sampled proof_id overlap: {sorted(overlap)[:5]}")

    eval_count = write_jsonl(eval_refs_path, eval_refs)
    test_count = write_jsonl(test_refs_path, test_refs)
    write_split_manifest(
        manifest_path,
        dataset_root,
        args.seed,
        eval_count,
        test_count,
        required_infos,
        eval_refs_path,
        test_refs_path,
    )

    print(f"wrote {eval_refs_path} ({eval_count} refs)")
    print(f"wrote {test_refs_path} ({test_count} refs)")
    print(f"wrote {manifest_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
