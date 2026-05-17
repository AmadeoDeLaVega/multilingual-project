#!/usr/bin/env python3
"""Freeze deterministic Lean theorem subsets for ProofWala proof search."""

from __future__ import annotations

import argparse
import json
import random
from collections import OrderedDict
from pathlib import Path
from typing import Any

import yaml


def load_jsonl(path: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    with path.open("r", encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if line:
                rows.append(json.loads(line))
    return rows


def write_jsonl(path: Path, rows: list[dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as handle:
        for row in rows:
            handle.write(json.dumps(row, ensure_ascii=False, sort_keys=True) + "\n")


def normalize_benchmark_path(path: str) -> list[str]:
    keys = [path]
    for prefix in (".lake/packages/mathlib/", ".lake/packages/std/"):
        if path.startswith(prefix):
            keys.append(path[len(prefix) :])
    return keys


def load_benchmark_lookup(path: Path) -> dict[tuple[str, str], tuple[str, str]]:
    benchmark = yaml.safe_load(path.read_text(encoding="utf-8"))
    lookup: dict[tuple[str, str], tuple[str, str]] = {}
    for dataset in benchmark.get("datasets", []):
        project = dataset["project"]
        for file_cfg in dataset.get("files", []):
            file_path = file_cfg["path"]
            theorems = file_cfg["theorems"]
            if not isinstance(theorems, list):
                continue
            for theorem in theorems:
                for key_path in normalize_benchmark_path(file_path):
                    lookup[(key_path, theorem)] = (project, file_path)
    return lookup


def select_rows(rows: list[dict[str, Any]], count: int, seed: int) -> list[dict[str, Any]]:
    if count <= 0:
        raise ValueError("--count must be positive")
    if count > len(rows):
        raise ValueError(f"--count {count} exceeds available rows {len(rows)}")
    rng = random.Random(seed)
    indices = rng.sample(range(len(rows)), count)
    return [dict(rows[index]) for index in indices]


def build_benchmark(
    selected: list[dict[str, Any]],
    source_lookup: dict[tuple[str, str], tuple[str, str]],
    name: str,
    project_override: str | None,
    timeout_per_theorem: int,
) -> dict[str, Any]:
    grouped: OrderedDict[tuple[str, str], list[str]] = OrderedDict()
    for row in selected:
        file_path = row["file_path"]
        theorem = row["theorem_name"]
        source = source_lookup.get((file_path, theorem))
        if source is None:
            raise KeyError(f"Could not find theorem in source benchmark: {file_path} :: {theorem}")
        project, benchmark_path = source
        project = project_override or project
        grouped.setdefault((project, benchmark_path), []).append(theorem)

    projects: OrderedDict[str, list[dict[str, Any]]] = OrderedDict()
    for (project, benchmark_path), theorems in grouped.items():
        projects.setdefault(project, []).append({"path": benchmark_path, "theorems": theorems})

    return {
        "name": name,
        "num_files": sum(len(files) for files in projects.values()),
        "language": "LEAN4",
        "few_shot_data_path_for_retrieval": None,
        "few_shot_metadata_filename_for_retrieval": None,
        "dfs_data_path_for_retrieval": None,
        "dfs_metadata_filename_for_retrieval": "local.meta.json",
        "theorem_cnt": len(selected),
        "timeout_per_theorem_in_secs": timeout_per_theorem,
        "datasets": [
            {"project": project, "files": files}
            for project, files in projects.items()
        ],
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input-refs", default="data/frozen_splits/lean_test_991_proofs.jsonl")
    parser.add_argument(
        "--source-benchmark",
        default="proof-wala/src/proof_wala/main/config/benchmark/leandojo_test.yaml",
    )
    parser.add_argument("--count", type=int, default=250)
    parser.add_argument("--seed", type=int, default=20260516)
    parser.add_argument("--name", default="leandojo-test-250")
    parser.add_argument("--timeout-per-theorem", type=int, default=720)
    parser.add_argument(
        "--project-override",
        default="<root>/../itp-interface/src/data/test/Mathlib",
        help="Project path to write into the benchmark YAML. Use '' to preserve the source benchmark path.",
    )
    parser.add_argument("--output-refs", required=True)
    parser.add_argument("--output-benchmark", required=True)
    parser.add_argument("--output-manifest", default=None)
    args = parser.parse_args()

    input_refs = Path(args.input_refs)
    source_benchmark = Path(args.source_benchmark)
    output_refs = Path(args.output_refs)
    output_benchmark = Path(args.output_benchmark)
    output_manifest = Path(args.output_manifest) if args.output_manifest else None
    project_override = args.project_override if args.project_override else None

    rows = load_jsonl(input_refs)
    selected = select_rows(rows, args.count, args.seed)
    lookup = load_benchmark_lookup(source_benchmark)
    benchmark = build_benchmark(
        selected,
        lookup,
        name=args.name,
        project_override=project_override,
        timeout_per_theorem=args.timeout_per_theorem,
    )

    write_jsonl(output_refs, selected)
    output_benchmark.parent.mkdir(parents=True, exist_ok=True)
    output_benchmark.write_text(
        yaml.safe_dump(benchmark, sort_keys=False, allow_unicode=True),
        encoding="utf-8",
    )

    if output_manifest is not None:
        manifest = {
            "version": 1,
            "source_refs": str(input_refs),
            "source_benchmark": str(source_benchmark),
            "output_refs": str(output_refs),
            "output_benchmark": str(output_benchmark),
            "name": args.name,
            "count": args.count,
            "seed": args.seed,
            "selection": "python_random_sample_without_replacement_in_sample_order",
            "project_override": project_override,
            "timeout_per_theorem_in_secs": args.timeout_per_theorem,
        }
        output_manifest.parent.mkdir(parents=True, exist_ok=True)
        output_manifest.write_text(
            yaml.safe_dump(manifest, sort_keys=False, allow_unicode=True),
            encoding="utf-8",
        )

    print(f"wrote {output_refs}")
    print(f"wrote {output_benchmark}")
    if output_manifest is not None:
        print(f"wrote {output_manifest}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
