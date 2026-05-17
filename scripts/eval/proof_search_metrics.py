#!/usr/bin/env python3
"""Compute proof-search diagnostics from a ProofWala run directory.

The metrics here are intentionally useful even when theorem pass rates are all
zero.  They distinguish parser failures, no-goal/environment failures, invalid
generations, shallow/dead proof trees, and search timing.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import statistics
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any


NODE_RE = re.compile(r"^\s*(?P<node>\"[^\"]+\"|[A-Za-z0-9_]+)\s+\[")
EDGE_RE = re.compile(r"^\s*(?P<src>\"[^\"]+\"|[A-Za-z0-9_]+)\s*->\s*(?P<dst>\"[^\"]+\"|[A-Za-z0-9_]+)")
THEOREM_NAME_RE = re.compile(r"\btheorem\s+([A-Za-z0-9_'.]+)")


def load_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def write_json(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2, sort_keys=True, ensure_ascii=False)
        handle.write("\n")


def mean(values: list[float]) -> float | None:
    return statistics.fmean(values) if values else None


def rate(numerator: int, denominator: int) -> float | None:
    return numerator / denominator if denominator else None


def find_latest(root: Path, pattern: str) -> Path | None:
    if not root.exists():
        return None
    paths = sorted(root.rglob(pattern), key=lambda path: path.stat().st_mtime)
    return paths[-1] if paths else None


def flatten_results(results_json: Path) -> list[dict[str, Any]]:
    payload = load_json(results_json)
    rows: list[dict[str, Any]] = []
    for proof_file, theorem_map in (payload.get("theorem_map") or {}).items():
        if not isinstance(theorem_map, dict):
            continue
        for theorem, result in theorem_map.items():
            if not isinstance(result, dict):
                continue
            row = dict(result)
            row["proof_file"] = row.get("proof_file") or proof_file
            row["lemma_name"] = row.get("lemma_name") or theorem
            rows.append(row)
    return rows


def proof_result_metrics(results_json: Path | None) -> dict[str, Any]:
    if results_json is None:
        return {
            "results_json": None,
            "theorem_count": 0,
            "error": "proof_results.json not found",
        }

    rows = flatten_results(results_json)
    proved = sum(1 for row in rows if row.get("proof_found") is True)
    proved_by_attempt_1 = 0
    proved_by_attempt_5 = 0
    proved_with_unknown_attempt = 0
    for row in rows:
        if row.get("proof_found") is not True:
            continue
        attempt_idx = (row.get("additional_info") or {}).get("attempt_idx")
        if isinstance(attempt_idx, int):
            if attempt_idx < 1:
                proved_by_attempt_1 += 1
            if attempt_idx < 5:
                proved_by_attempt_5 += 1
        else:
            proved_with_unknown_attempt += 1
    timeouts = sum(1 for row in rows if row.get("is_timeout") is True)
    exhausted = sum(1 for row in rows if row.get("is_inference_exhausted") is True)
    proof_times = [
        float(row["proof_time_in_secs"])
        for row in rows
        if isinstance(row.get("proof_time_in_secs"), (int, float))
    ]
    inference_counts = [
        int(row["inferences_taken"])
        for row in rows
        if isinstance(row.get("inferences_taken"), int) and int(row["inferences_taken"]) >= 0
    ]
    longest_paths = [
        int(row["longest_success_path"])
        for row in rows
        if isinstance(row.get("longest_success_path"), int) and int(row["longest_success_path"]) >= 0
    ]
    theorem_rows = [
        {
            "proof_file": row.get("proof_file"),
            "lemma_name": row.get("lemma_name"),
            "proof_found": row.get("proof_found"),
            "proof_time_in_secs": row.get("proof_time_in_secs"),
            "inferences_taken": row.get("inferences_taken"),
            "is_timeout": row.get("is_timeout"),
            "is_inference_exhausted": row.get("is_inference_exhausted"),
            "longest_success_path": row.get("longest_success_path"),
            "attempt_idx": (row.get("additional_info") or {}).get("attempt_idx"),
            "num_of_backtracks": row.get("num_of_backtracks"),
            "possible_failed_paths": row.get("possible_failed_paths"),
        }
        for row in rows
    ]
    return {
        "results_json": str(results_json),
        "theorem_count": len(rows),
        "proved_count": proved,
        "search_pass_rate": rate(proved, len(rows)),
        "proved_by_attempt_1_count": proved_by_attempt_1,
        "pass_at_1": rate(proved_by_attempt_1, len(rows)),
        "proved_by_attempt_5_count": proved_by_attempt_5,
        "pass_at_5_observed": rate(proved_by_attempt_5, len(rows)),
        "proved_with_unknown_attempt_count": proved_with_unknown_attempt,
        "timeout_count": timeouts,
        "timeout_rate": rate(timeouts, len(rows)),
        "inference_exhausted_count": exhausted,
        "inference_exhausted_rate": rate(exhausted, len(rows)),
        "mean_proof_time_in_secs": mean(proof_times),
        "mean_inferences_taken": mean([float(item) for item in inference_counts]),
        "mean_longest_success_path": mean([float(item) for item in longest_paths]),
        "theorems": theorem_rows,
    }


def load_generation_debug(path: Path | None) -> list[dict[str, Any]]:
    if path is None or not path.exists():
        return []
    records = []
    with path.open("r", encoding="utf-8", errors="replace") as handle:
        for line_number, line in enumerate(handle, start=1):
            line = line.strip()
            if not line:
                continue
            try:
                records.append(json.loads(line))
            except json.JSONDecodeError as exc:
                records.append(
                    {
                        "_decode_error": f"{type(exc).__name__}: {exc}",
                        "_line_number": line_number,
                    }
                )
    return records


def short_error(text: Any, limit: int = 140) -> str:
    value = "none" if text is None else str(text)
    value = " ".join(value.split())
    return value[:limit]


def theorem_name_from_problem(problem: str) -> str | None:
    match = THEOREM_NAME_RE.search(problem)
    return match.group(1) if match else None


def generation_metrics(debug_jsonl: Path | None) -> dict[str, Any]:
    records = load_generation_debug(debug_jsonl)
    if not records:
        return {
            "generation_debug_jsonl": str(debug_jsonl) if debug_jsonl else None,
            "prompt_state_count": 0,
            "error": "generation debug JSONL not found or empty",
        }

    output_count = 0
    model_called_output_count = 0
    accepted_count = 0
    model_called_accepted_count = 0
    parsed_tactic_count = 0
    model_called_parsed_tactic_count = 0
    parse_error_count = 0
    model_called_count = 0
    no_start_goals_count = 0
    zero_accepted_states = 0
    model_called_zero_accepted_states = 0
    zero_parsed_states = 0
    model_called_zero_parsed_states = 0
    generation_times: list[float] = []
    accepted_per_state: list[float] = []
    parsed_per_state: list[float] = []
    output_per_state: list[float] = []
    parse_errors: Counter[str] = Counter()
    reason_counts: Counter[str] = Counter()
    tactic_counts: Counter[str] = Counter()
    theorem_state_counts: Counter[str] = Counter()

    for record in records:
        if "_decode_error" in record:
            parse_errors[record["_decode_error"]] += 1
            continue

        problem = str(record.get("problem") or "")
        theorem_name = theorem_name_from_problem(problem)
        if theorem_name:
            theorem_state_counts[theorem_name] += 1

        outputs = record.get("outputs") or []
        state_output_count = len(outputs)
        state_accepted_count = 0
        state_parsed_count = 0
        if state_output_count > 0:
            output_per_state.append(float(state_output_count))
        if isinstance(record.get("generation_time_seconds"), (int, float)):
            generation_times.append(float(record["generation_time_seconds"]))

        record_reason = None
        is_no_start_goal_record = False
        for output in outputs:
            if output.get("reason") == "no_start_goals_model_not_called":
                is_no_start_goal_record = True
        for output in outputs:
            output_count += 1
            if not is_no_start_goal_record:
                model_called_output_count += 1
            reason = output.get("reason")
            if reason:
                reason_counts[str(reason)] += 1
                record_reason = str(reason)
            if output.get("accepted_as_action") is True:
                accepted_count += 1
                state_accepted_count += 1
                if not is_no_start_goal_record:
                    model_called_accepted_count += 1
            parsed_tactics = output.get("parsed_tactics") or []
            if parsed_tactics:
                parsed_tactic_count += len(parsed_tactics)
                state_parsed_count += len(parsed_tactics)
                if not is_no_start_goal_record:
                    model_called_parsed_tactic_count += len(parsed_tactics)
                for tactic in parsed_tactics:
                    tactic_counts[" ".join(str(tactic).split())[:120]] += 1
            if output.get("parse_error"):
                parse_error_count += 1
                parse_errors[short_error(output.get("parse_error"))] += 1

        if record_reason == "no_start_goals_model_not_called":
            no_start_goals_count += 1
        else:
            model_called_count += 1

        if state_accepted_count == 0:
            zero_accepted_states += 1
            if not is_no_start_goal_record:
                model_called_zero_accepted_states += 1
        if state_parsed_count == 0:
            zero_parsed_states += 1
            if not is_no_start_goal_record:
                model_called_zero_parsed_states += 1
        accepted_per_state.append(float(state_accepted_count))
        parsed_per_state.append(float(state_parsed_count))

    prompt_state_count = len(records)
    model_output_states = max(prompt_state_count - no_start_goals_count, 0)
    return {
        "generation_debug_jsonl": str(debug_jsonl) if debug_jsonl else None,
        "prompt_state_count": prompt_state_count,
        "model_called_state_count": model_called_count,
        "no_start_goals_count": no_start_goals_count,
        "no_start_goals_rate": rate(no_start_goals_count, prompt_state_count),
        "output_count": output_count,
        "model_called_output_count": model_called_output_count,
        "accepted_action_count": accepted_count,
        "accepted_action_rate": rate(accepted_count, output_count),
        "accepted_action_count_after_model_call": model_called_accepted_count,
        "accepted_action_rate_after_model_call": rate(
            model_called_accepted_count,
            model_called_output_count,
        ),
        "parsed_tactic_count": parsed_tactic_count,
        "parsed_tactic_rate": rate(parsed_tactic_count, output_count),
        "parsed_tactic_count_after_model_call": model_called_parsed_tactic_count,
        "parsed_tactic_rate_after_model_call": rate(
            model_called_parsed_tactic_count,
            model_called_output_count,
        ),
        "parse_error_count": parse_error_count,
        "parse_error_rate": rate(parse_error_count, output_count),
        "states_with_zero_accepted_actions": zero_accepted_states,
        "states_with_zero_accepted_actions_rate": rate(zero_accepted_states, prompt_state_count),
        "states_with_zero_accepted_actions_after_model_call": model_called_zero_accepted_states,
        "states_with_zero_parsed_tactics": zero_parsed_states,
        "states_with_zero_parsed_tactics_rate": rate(zero_parsed_states, prompt_state_count),
        "states_with_zero_parsed_tactics_after_model_call": model_called_zero_parsed_states,
        "states_with_zero_parsed_tactics_after_model_call_rate": rate(
            model_called_zero_parsed_states,
            model_output_states,
        ),
        "states_with_zero_accepted_actions_after_model_call_rate": rate(
            model_called_zero_accepted_states,
            model_output_states,
        ),
        "mean_generation_time_in_secs": mean(generation_times),
        "mean_outputs_per_state": mean(output_per_state),
        "mean_accepted_actions_per_state": mean(accepted_per_state),
        "mean_parsed_tactics_per_state": mean(parsed_per_state),
        "top_parse_errors": parse_errors.most_common(10),
        "generation_reason_counts": dict(reason_counts),
        "top_generated_tactics": tactic_counts.most_common(20),
        "theorem_state_counts": dict(theorem_state_counts),
    }


def parse_dot_tree(path: Path) -> dict[str, Any]:
    nodes: set[str] = set()
    edge_count = 0
    outgoing: Counter[str] = Counter()
    labels = []
    text = path.read_text(encoding="utf-8", errors="replace")
    for line in text.splitlines():
        node_match = NODE_RE.match(line)
        if node_match:
            nodes.add(node_match.group("node").strip('"'))
            if "label=" in line:
                labels.append(short_error(line))
            continue
        edge_match = EDGE_RE.match(line)
        if edge_match:
            src = edge_match.group("src").strip('"')
            dst = edge_match.group("dst").strip('"')
            nodes.add(src)
            nodes.add(dst)
            edge_count += 1
            outgoing[src] += 1

    branching_values = list(outgoing.values())
    return {
        "path": str(path),
        "node_count": len(nodes),
        "edge_count": edge_count,
        "branching_node_count": len(outgoing),
        "average_branching_factor": mean([float(item) for item in branching_values]),
        "max_branching_factor": max(branching_values) if branching_values else 0,
        "single_node_tree": len(nodes) <= 1,
        "sample_labels": labels[:3],
    }


def proof_tree_metrics(run_root: Path) -> dict[str, Any]:
    tree_root_candidates = list(run_root.rglob("proof_trees"))
    tree_files: list[Path] = []
    for tree_root in tree_root_candidates:
        for path in tree_root.rglob("*"):
            if path.is_file() and path.suffix != ".svg":
                tree_files.append(path)
    tree_files = sorted(set(tree_files))
    trees = [parse_dot_tree(path) for path in tree_files]
    node_counts = [float(item["node_count"]) for item in trees]
    edge_counts = [float(item["edge_count"]) for item in trees]
    branching = [
        float(item["average_branching_factor"])
        for item in trees
        if item["average_branching_factor"] is not None
    ]
    single_node_count = sum(1 for item in trees if item["single_node_tree"])
    return {
        "proof_tree_file_count": len(trees),
        "mean_node_count": mean(node_counts),
        "mean_edge_count": mean(edge_counts),
        "mean_average_branching_factor": mean(branching),
        "single_node_tree_count": single_node_count,
        "single_node_tree_rate": rate(single_node_count, len(trees)),
        "trees": trees[:50],
    }


def write_markdown(path: Path, payload: dict[str, Any]) -> None:
    result = payload["proof_results"]
    generation = payload["generation"]
    trees = payload["proof_trees"]
    lines = [
        "# Proof Search Metrics",
        "",
        f"- run_root: `{payload['run_root']}`",
        f"- proof_results: `{result.get('results_json')}`",
        f"- generation_debug: `{generation.get('generation_debug_jsonl')}`",
        "",
        "## Theorem Outcomes",
        "",
        f"- theorems: `{result.get('theorem_count')}`",
        f"- proved: `{result.get('proved_count')}`",
        f"- search_pass_rate: `{result.get('search_pass_rate')}`",
        f"- pass_at_1: `{result.get('pass_at_1')}`",
        f"- pass_at_5_observed: `{result.get('pass_at_5_observed')}`",
        f"- timeout_rate: `{result.get('timeout_rate')}`",
        f"- mean_proof_time_in_secs: `{result.get('mean_proof_time_in_secs')}`",
        "",
        "## Generated Action Quality",
        "",
        f"- prompt_states: `{generation.get('prompt_state_count')}`",
        f"- model_called_states: `{generation.get('model_called_state_count')}`",
        f"- no_start_goals_rate: `{generation.get('no_start_goals_rate')}`",
        f"- accepted_action_rate: `{generation.get('accepted_action_rate')}`",
        f"- accepted_action_rate_after_model_call: `{generation.get('accepted_action_rate_after_model_call')}`",
        f"- parsed_tactic_rate: `{generation.get('parsed_tactic_rate')}`",
        f"- parsed_tactic_rate_after_model_call: `{generation.get('parsed_tactic_rate_after_model_call')}`",
        f"- parse_error_rate: `{generation.get('parse_error_rate')}`",
        f"- zero_accepted_after_model_call_rate: `{generation.get('states_with_zero_accepted_actions_after_model_call_rate')}`",
        f"- mean_accepted_actions_per_state: `{generation.get('mean_accepted_actions_per_state')}`",
        "",
        "## Proof Trees",
        "",
        f"- proof_tree_files: `{trees.get('proof_tree_file_count')}`",
        f"- mean_node_count: `{trees.get('mean_node_count')}`",
        f"- mean_edge_count: `{trees.get('mean_edge_count')}`",
        f"- mean_average_branching_factor: `{trees.get('mean_average_branching_factor')}`",
        f"- single_node_tree_rate: `{trees.get('single_node_tree_rate')}`",
    ]
    if generation.get("top_parse_errors"):
        lines.extend(["", "## Top Parse Errors", ""])
        for error, count in generation["top_parse_errors"]:
            lines.append(f"- `{count}`: {error}")
    if generation.get("top_generated_tactics"):
        lines.extend(["", "## Top Generated Tactics", ""])
        for tactic, count in generation["top_generated_tactics"][:10]:
            lines.append(f"- `{count}`: `{tactic}`")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--run-root", required=True)
    parser.add_argument("--results-json", default=None)
    parser.add_argument("--generation-debug-jsonl", default=None)
    parser.add_argument("--output", default=None)
    args = parser.parse_args()

    run_root = Path(args.run_root).resolve()
    results_json = Path(args.results_json).resolve() if args.results_json else find_latest(run_root, "proof_results.json")
    debug_jsonl = (
        Path(args.generation_debug_jsonl).resolve()
        if args.generation_debug_jsonl
        else find_latest(run_root, "generation_debug.jsonl")
    )
    output = Path(args.output).resolve() if args.output else run_root / "proof_search_metrics.json"

    payload = {
        "run_root": str(run_root),
        "proof_results": proof_result_metrics(results_json),
        "generation": generation_metrics(debug_jsonl),
        "proof_trees": proof_tree_metrics(run_root),
    }
    write_json(output, payload)
    write_markdown(output.with_suffix(".md"), payload)
    print(f"wrote {output}")
    print(f"wrote {output.with_suffix('.md')}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
