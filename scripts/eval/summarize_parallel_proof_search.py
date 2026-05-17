#!/usr/bin/env python3
"""Summarize parallel E1/E3/E4 proof-search calibration runs."""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path
from typing import Any


EXPERIMENTS = ("E1", "E3", "E4")


def load_json(path: Path) -> dict[str, Any] | None:
    if not path.is_file():
        return None
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def pick(metrics: dict[str, Any] | None, *keys: str) -> Any:
    value: Any = metrics
    for key in keys:
        if not isinstance(value, dict):
            return None
        value = value.get(key)
    return value


def row_for(group_root: Path, experiment: str) -> dict[str, Any]:
    run_root = group_root / experiment
    metrics_path = run_root / "proof_search_metrics.json"
    metrics = load_json(metrics_path)
    return {
        "experiment": experiment,
        "run_root": str(run_root),
        "metrics_json": str(metrics_path) if metrics_path.is_file() else "",
        "theorem_count": pick(metrics, "proof_results", "theorem_count"),
        "proved_count": pick(metrics, "proof_results", "proved_count"),
        "search_pass_rate": pick(metrics, "proof_results", "search_pass_rate"),
        "pass_at_1": pick(metrics, "proof_results", "pass_at_1"),
        "pass_at_5_observed": pick(metrics, "proof_results", "pass_at_5_observed"),
        "timeout_rate": pick(metrics, "proof_results", "timeout_rate"),
        "mean_proof_time_in_secs": pick(metrics, "proof_results", "mean_proof_time_in_secs"),
        "prompt_state_count": pick(metrics, "generation", "prompt_state_count"),
        "model_called_state_count": pick(metrics, "generation", "model_called_state_count"),
        "accepted_action_rate_after_model_call": pick(
            metrics,
            "generation",
            "accepted_action_rate_after_model_call",
        ),
        "parsed_tactic_rate_after_model_call": pick(
            metrics,
            "generation",
            "parsed_tactic_rate_after_model_call",
        ),
        "zero_accepted_after_model_call_rate": pick(
            metrics,
            "generation",
            "states_with_zero_accepted_actions_after_model_call_rate",
        ),
        "mean_node_count": pick(metrics, "proof_trees", "mean_node_count"),
        "mean_average_branching_factor": pick(
            metrics,
            "proof_trees",
            "mean_average_branching_factor",
        ),
    }


def write_csv(path: Path, rows: list[dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)


def write_markdown(path: Path, rows: list[dict[str, Any]]) -> None:
    headers = [
        "experiment",
        "theorem_count",
        "proved_count",
        "search_pass_rate",
        "pass_at_1",
        "pass_at_5_observed",
        "timeout_rate",
        "mean_proof_time_in_secs",
        "accepted_action_rate_after_model_call",
        "parsed_tactic_rate_after_model_call",
        "zero_accepted_after_model_call_rate",
    ]
    lines = [
        "# Parallel Proof-Search Calibration Summary",
        "",
        f"- group_root: `{path.parent}`",
        "",
        "| " + " | ".join(headers) + " |",
        "| " + " | ".join("---" for _ in headers) + " |",
    ]
    for row in rows:
        lines.append("| " + " | ".join(str(row.get(header, "")) for header in headers) + " |")
    lines.extend(["", "## Run Roots", ""])
    for row in rows:
        lines.append(f"- {row['experiment']}: `{row['run_root']}`")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--group-root", required=True)
    parser.add_argument("--output-prefix", default=None)
    args = parser.parse_args()

    group_root = Path(args.group_root).resolve()
    output_prefix = Path(args.output_prefix).resolve() if args.output_prefix else group_root / "parallel_summary"
    rows = [row_for(group_root, experiment) for experiment in EXPERIMENTS]
    write_csv(output_prefix.with_suffix(".csv"), rows)
    write_markdown(output_prefix.with_suffix(".md"), rows)
    print(f"wrote {output_prefix.with_suffix('.csv')}")
    print(f"wrote {output_prefix.with_suffix('.md')}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
