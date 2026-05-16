#!/usr/bin/env python3
"""Materialize the E4 Lean plus pseudo-Lean training dataset.

The output is ProofWala-compatible local_data/local.meta format. By default the
script streams the whole Lean train split and adds one conservative pseudo-Lean
variant for each record whose local identifiers can be safely renamed.
"""

from __future__ import annotations

import argparse
import copy
import json
import pathlib
import sys
from datetime import date
from typing import Iterable

SCRIPT_DIR = pathlib.Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from materialize_smoke_datasets import (  # noqa: E402
    DEFAULT_DATASET_ROOT,
    PSEUDO_TRANSFORM_VERSION,
    load_json,
    local_data_files,
    make_pseudo_record,
    pseudo_record_changed,
    write_e4_audit,
    write_json,
)

DEFAULT_OUTPUT_DIR = "data/pseudo_multilingual/e4_train"
DEFAULT_AUDIT = "data/pseudo_multilingual/e4_audit.md"
DEFAULT_CHUNK_SIZE = 10000
DEFAULT_AUDIT_SIZE = 50


def iter_lean_train_records(dataset_root: pathlib.Path) -> Iterable[dict]:
    for data_file in local_data_files(dataset_root, "lean/train"):
        for record in load_json(data_file)["training_data"]:
            yield record


def remove_existing_local_files(output_dir: pathlib.Path) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    for pattern in ("local_data_*.json", "local_lemma_*.json", "local.meta.json"):
        for path in output_dir.glob(pattern):
            path.unlink()


def write_chunk(output_dir: pathlib.Path, chunk_index: int, records: list[dict]) -> pathlib.Path:
    path = output_dir / f"local_data_{chunk_index:010d}.json"
    write_json(path, {"training_data": records})
    return path


def write_meta(
    output_dir: pathlib.Path,
    records_written: int,
    last_proof_id: str | None,
    unique_proof_ids: int,
) -> None:
    write_json(output_dir / "local_lemma_0000000000.json", {"training_data": []})
    write_json(
        output_dir / "local.meta.json",
        {
            "training_data_buffer_size": DEFAULT_CHUNK_SIZE,
            "last_training_data": records_written,
            "last_proof_id": last_proof_id,
            "external_theorems_used_cnt": 0,
            "local_theorems_used_cnt": 0,
            "total_data_count": records_written,
            "data_filename_prefix": "local_data_",
            "data_filename_suffix": ".json",
            "lemma_ref_filename_prefix": "local_lemma_",
            "lemma_ref_filename_suffix": ".json",
            "num_theorems": unique_proof_ids,
        },
    )


def write_summary(
    output_dir: pathlib.Path,
    source_records: int,
    pseudo_records: int,
    skipped_empty_or_unchanged: int,
    records_written: int,
    audit_path: pathlib.Path,
) -> None:
    lines = [
        "# E4 Pseudo Dataset Summary",
        "",
        f"- created_on: {date.today().isoformat()}",
        f"- transform: `{PSEUDO_TRANSFORM_VERSION}`",
        f"- output_dir: `{output_dir}`",
        f"- source_lean_records: `{source_records}`",
        f"- pseudo_records_added: `{pseudo_records}`",
        f"- skipped_empty_or_unchanged: `{skipped_empty_or_unchanged}`",
        f"- total_records_written: `{records_written}`",
        f"- audit: `{audit_path}`",
    ]
    (output_dir / "e4_pseudo_summary.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def materialize(
    dataset_root: pathlib.Path,
    output_dir: pathlib.Path,
    audit_path: pathlib.Path,
    max_source_records: int | None,
    max_pseudo_records: int | None,
    chunk_size: int,
    audit_size: int,
    keep_unchanged_pseudos: bool,
) -> None:
    remove_existing_local_files(output_dir)

    chunk: list[dict] = []
    chunk_index = 0
    source_records = 0
    pseudo_records = 0
    skipped_empty_or_unchanged = 0
    records_written = 0
    last_proof_id: str | None = None
    proof_ids: set[str] = set()
    audit_originals: list[dict] = []
    audit_pseudos: list[dict] = []

    def append_record(record: dict) -> None:
        nonlocal chunk, chunk_index, records_written, last_proof_id
        chunk.append(record)
        records_written += 1
        last_proof_id = record.get("proof_id")
        if last_proof_id is not None:
            proof_ids.add(str(last_proof_id))
        if len(chunk) >= chunk_size:
            write_chunk(output_dir, chunk_index, chunk)
            chunk = []
            chunk_index += 1

    for idx, record in enumerate(iter_lean_train_records(dataset_root)):
        if max_source_records is not None and source_records >= max_source_records:
            break
        original = copy.deepcopy(record)
        source_records += 1
        append_record(original)

        if max_pseudo_records is not None and pseudo_records >= max_pseudo_records:
            continue

        pseudo = make_pseudo_record(record, idx)
        rename_map = pseudo.get("addition_state_info", {}).get("rename_map", {})
        if not keep_unchanged_pseudos and (not rename_map or not pseudo_record_changed(record, pseudo)):
            skipped_empty_or_unchanged += 1
            continue

        pseudo_records += 1
        append_record(pseudo)
        if len(audit_pseudos) < audit_size:
            audit_originals.append(copy.deepcopy(record))
            audit_pseudos.append(copy.deepcopy(pseudo))

    if chunk:
        write_chunk(output_dir, chunk_index, chunk)

    write_meta(output_dir, records_written, last_proof_id, len(proof_ids))
    write_e4_audit(audit_path, audit_originals, audit_pseudos)
    write_summary(
        output_dir,
        source_records,
        pseudo_records,
        skipped_empty_or_unchanged,
        records_written,
        audit_path,
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dataset-root", default=DEFAULT_DATASET_ROOT)
    parser.add_argument("--output-dir", default=DEFAULT_OUTPUT_DIR)
    parser.add_argument("--audit", default=DEFAULT_AUDIT)
    parser.add_argument("--max-source-records", type=int)
    parser.add_argument("--max-pseudo-records", type=int)
    parser.add_argument("--chunk-size", type=int, default=DEFAULT_CHUNK_SIZE)
    parser.add_argument("--audit-size", type=int, default=DEFAULT_AUDIT_SIZE)
    parser.add_argument(
        "--keep-unchanged-pseudos",
        action="store_true",
        help="Keep pseudo records even when the safe rename map is empty or unchanged.",
    )
    args = parser.parse_args()

    materialize(
        dataset_root=pathlib.Path(args.dataset_root),
        output_dir=pathlib.Path(args.output_dir),
        audit_path=pathlib.Path(args.audit),
        max_source_records=args.max_source_records,
        max_pseudo_records=args.max_pseudo_records,
        chunk_size=args.chunk_size,
        audit_size=args.audit_size,
        keep_unchanged_pseudos=args.keep_unchanged_pseudos,
    )
    print(f"wrote {args.output_dir}")
    print(f"wrote {args.audit}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
