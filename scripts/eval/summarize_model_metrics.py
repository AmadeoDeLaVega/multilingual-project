#!/usr/bin/env python3
"""Create compact E1/E3/E4 metric tables from diagnostic JSON files."""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path
from typing import Any


DEFAULT_EXPERIMENTS = ("E1", "E3", "E4")


def load_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def find_first_existing(paths: list[Path]) -> Path | None:
    for path in paths:
        if path.exists():
            return path
    return None


def find_latest(root: Path, pattern: str) -> Path | None:
    if not root.exists():
        return None
    paths = sorted(root.rglob(pattern), key=lambda path: path.stat().st_mtime)
    return paths[-1] if paths else None


def nested(payload: dict[str, Any], *keys: str) -> Any:
    value: Any = payload
    for key in keys:
        if not isinstance(value, dict):
            return None
        value = value.get(key)
    return value


def fmt(value: Any) -> str:
    if value is None:
        return ""
    if isinstance(value, float):
        return f"{value:.4f}"
    return str(value)


def diagnostic_candidates(run_root: Path, experiment: str) -> list[Path]:
    lower = experiment.lower()
    return [
        run_root / "diagnostics" / f"{lower}_model_diagnostics.json",
        run_root / "diagnostics" / f"{lower}_diagnostics.json",
        run_root / "diagnostics" / f"{lower}_checkpoint20000.json",
        run_root / "diagnostics" / f"{lower}_checkpoint5000.json",
        run_root / "diagnostics" / f"{lower}_final_diagnostics.json",
        run_root / "diagnostics" / "e1_diagnostics.json",
    ]


def collect_row(
    project_root: Path,
    experiment: str,
    proof_metric_overrides: dict[str, Path],
) -> dict[str, Any]:
    run_root = project_root / "runs" / experiment
    diagnostic_path = find_first_existing(diagnostic_candidates(run_root, experiment))
    if diagnostic_path is None:
        diagnostic_path = find_latest(run_root / "diagnostics", "*.json")
    proof_metrics_path = proof_metric_overrides.get(experiment)
    if proof_metrics_path is None:
        proof_metrics_path = find_latest(run_root / "proof_search", "proof_search_metrics.json")

    diagnostic_payload = load_json(diagnostic_path) if diagnostic_path else {}
    proof_payload = load_json(proof_metrics_path) if proof_metrics_path else {}
    next_step = diagnostic_payload.get("next_step_prediction") or {}
    proof_results = proof_payload.get("proof_results") or {}
    generation = proof_payload.get("generation") or {}
    trees = proof_payload.get("proof_trees") or {}

    return {
        "experiment": experiment,
        "diagnostic_json": str(diagnostic_path) if diagnostic_path else "",
        "proof_metrics_json": str(proof_metrics_path) if proof_metrics_path else "",
        "next_step_examples": next_step.get("examples"),
        "strict_exact_match": next_step.get("strict_exact_match"),
        "normalized_exact_match": next_step.get("normalized_exact_match"),
        "next_step_parseable_rate": next_step.get("parseable_rate"),
        "mean_eval_loss": next_step.get("mean_eval_loss"),
        "theorem_count": proof_results.get("theorem_count"),
        "proved_count": proof_results.get("proved_count"),
        "search_pass_rate": proof_results.get("search_pass_rate"),
        "timeout_rate": proof_results.get("timeout_rate"),
        "mean_proof_time_in_secs": proof_results.get("mean_proof_time_in_secs"),
        "prompt_state_count": generation.get("prompt_state_count"),
        "model_called_state_count": generation.get("model_called_state_count"),
        "accepted_action_rate": generation.get("accepted_action_rate"),
        "accepted_action_rate_after_model_call": generation.get("accepted_action_rate_after_model_call"),
        "parsed_tactic_rate": generation.get("parsed_tactic_rate"),
        "parsed_tactic_rate_after_model_call": generation.get("parsed_tactic_rate_after_model_call"),
        "parse_error_rate": generation.get("parse_error_rate"),
        "no_start_goals_rate": generation.get("no_start_goals_rate"),
        "zero_accepted_after_model_call_rate": generation.get(
            "states_with_zero_accepted_actions_after_model_call_rate"
        ),
        "zero_parsed_after_model_call_rate": generation.get(
            "states_with_zero_parsed_tactics_after_model_call_rate"
        ),
        "mean_accepted_actions_per_state": generation.get("mean_accepted_actions_per_state"),
        "proof_tree_file_count": trees.get("proof_tree_file_count"),
        "mean_node_count": trees.get("mean_node_count"),
        "mean_edge_count": trees.get("mean_edge_count"),
        "mean_average_branching_factor": trees.get("mean_average_branching_factor"),
        "single_node_tree_rate": trees.get("single_node_tree_rate"),
    }


def parse_key_path_overrides(items: list[str]) -> dict[str, Path]:
    overrides = {}
    for item in items:
        if "=" not in item:
            raise SystemExit(f"Expected EXPERIMENT=PATH, got: {item}")
        key, value = item.split("=", 1)
        key = key.strip()
        if not key:
            raise SystemExit(f"Missing experiment label in override: {item}")
        overrides[key] = Path(value).expanduser().resolve()
    return overrides


def write_csv(path: Path, rows: list[dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fieldnames = list(rows[0].keys()) if rows else []
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def markdown_table(headers: list[str], rows: list[list[Any]]) -> list[str]:
    lines = [
        "| " + " | ".join(headers) + " |",
        "| " + " | ".join("---" for _ in headers) + " |",
    ]
    for row in rows:
        lines.append("| " + " | ".join(fmt(value) for value in row) + " |")
    return lines


def write_markdown(path: Path, rows: list[dict[str, Any]]) -> None:
    lines = [
        "# Model Metrics Summary",
        "",
        "## Next-Step Diagnostics",
        "",
    ]
    lines.extend(
        markdown_table(
            [
                "Exp",
                "Examples",
                "Strict EM",
                "Norm EM",
                "Parseable",
                "Mean Loss",
            ],
            [
                [
                    row["experiment"],
                    row["next_step_examples"],
                    row["strict_exact_match"],
                    row["normalized_exact_match"],
                    row["next_step_parseable_rate"],
                    row["mean_eval_loss"],
                ]
                for row in rows
            ],
        )
    )
    lines.extend(["", "## Proof-Search Outcomes", ""])
    lines.extend(
        markdown_table(
            [
                "Exp",
                "Theorems",
                "Proved",
                "Pass Rate",
                "Timeout Rate",
                "Mean Time",
            ],
            [
                [
                    row["experiment"],
                    row["theorem_count"],
                    row["proved_count"],
                    row["search_pass_rate"],
                    row["timeout_rate"],
                    row["mean_proof_time_in_secs"],
                ]
                for row in rows
            ],
        )
    )
    lines.extend(["", "## Generated-Tactic Quality", ""])
    lines.extend(
        markdown_table(
            [
                "Exp",
                "States",
                "Model Called",
                "Accepted",
                "Accepted After Model",
                "Parsed",
                "Parsed After Model",
                "Parse Errors",
                "No Start Goals",
                "Zero Accepted After Model",
                "Zero Parsed After Model",
            ],
            [
                [
                    row["experiment"],
                    row["prompt_state_count"],
                    row["model_called_state_count"],
                    row["accepted_action_rate"],
                    row["accepted_action_rate_after_model_call"],
                    row["parsed_tactic_rate"],
                    row["parsed_tactic_rate_after_model_call"],
                    row["parse_error_rate"],
                    row["no_start_goals_rate"],
                    row["zero_accepted_after_model_call_rate"],
                    row["zero_parsed_after_model_call_rate"],
                ]
                for row in rows
            ],
        )
    )
    lines.extend(["", "## Search Shape", ""])
    lines.extend(
        markdown_table(
            [
                "Exp",
                "Trees",
                "Mean Nodes",
                "Mean Edges",
                "Mean Branching",
                "Single-Node Trees",
            ],
            [
                [
                    row["experiment"],
                    row["proof_tree_file_count"],
                    row["mean_node_count"],
                    row["mean_edge_count"],
                    row["mean_average_branching_factor"],
                    row["single_node_tree_rate"],
                ]
                for row in rows
            ],
        )
    )
    lines.extend(["", "## Source Files", ""])
    for row in rows:
        lines.append(f"- {row['experiment']} diagnostics: `{row['diagnostic_json']}`")
        lines.append(f"- {row['experiment']} proof metrics: `{row['proof_metrics_json']}`")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project-root", default=".")
    parser.add_argument("--experiments", nargs="+", default=list(DEFAULT_EXPERIMENTS))
    parser.add_argument(
        "--proof-metrics",
        action="append",
        default=[],
        metavar="EXPERIMENT=PATH",
        help="Explicit proof_search_metrics.json path for an experiment; may be repeated.",
    )
    parser.add_argument("--output-dir", default="runs/metrics")
    args = parser.parse_args()

    project_root = Path(args.project_root).resolve()
    output_dir = Path(args.output_dir)
    if not output_dir.is_absolute():
        output_dir = project_root / output_dir

    proof_metric_overrides = parse_key_path_overrides(args.proof_metrics)
    rows = [
        collect_row(project_root, experiment, proof_metric_overrides)
        for experiment in args.experiments
    ]
    write_csv(output_dir / "model_metrics_summary.csv", rows)
    write_markdown(output_dir / "model_metrics_summary.md", rows)
    print(f"wrote {output_dir / 'model_metrics_summary.csv'}")
    print(f"wrote {output_dir / 'model_metrics_summary.md'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
