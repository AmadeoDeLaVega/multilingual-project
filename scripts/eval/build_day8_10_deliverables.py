#!/usr/bin/env python3
"""Build Day 8-10 proof-search diagnostics and analysis deliverables.

The script is intentionally self-contained and uses only the Python standard
library so it can run on the local checkout without the Nexus conda env.
"""

from __future__ import annotations

import csv
import json
import math
import re
import statistics
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "runs" / "analysis" / "day8_10"
TABLES = OUT / "tables"
FIGURES = OUT / "figures"

EXPERIMENTS = ("E1", "E3", "E4")
BENCHMARKS = {
    "CoreEval 250": [ROOT / "runs" / "proof_search_core_eval" / "6848604"],
    "miniF2F": [
        ROOT / "runs" / "proof_search_minif2f_easy10" / "6849079",
        ROOT / "runs" / "proof_search_minif2f_remaining_9h20" / "6850148",
    ],
}

NODE_RE = re.compile(r"^\s*(?P<node>\"[^\"]+\"|[A-Za-z0-9_]+)\s+\[")
EDGE_RE = re.compile(r"^\s*(?P<src>\"[^\"]+\"|[A-Za-z0-9_]+)\s*->\s*(?P<dst>\"[^\"]+\"|[A-Za-z0-9_]+)")
THEOREM_RE = re.compile(r"\btheorem\s+([A-Za-z0-9_'.]+)")


def safe_div(num: float, den: float) -> float | None:
    return num / den if den else None


def mean(values: list[float]) -> float | None:
    return statistics.fmean(values) if values else None


def fmt(value: Any, digits: int = 3) -> str:
    if value is None:
        return ""
    if isinstance(value, float):
        if math.isnan(value):
            return ""
        return f"{value:.{digits}f}"
    return str(value)


def load_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def write_json(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2, ensure_ascii=False, sort_keys=True)
        handle.write("\n")


def theorem_name(raw: Any, fallback: Any = None) -> str:
    value = raw if raw not in (None, "") else fallback
    if isinstance(value, str):
        stripped = value.strip()
        if stripped.startswith("{"):
            try:
                parsed = json.loads(stripped)
                if isinstance(parsed, dict) and parsed.get("name"):
                    return str(parsed["name"])
            except json.JSONDecodeError:
                pass
        match = THEOREM_RE.search(stripped)
        if match:
            return match.group(1)
        return " ".join(stripped.split())
    return str(value)


def collect_steps(row: dict[str, Any]) -> str:
    steps: list[str] = []
    for item in row.get("proof_steps") or []:
        if isinstance(item, dict):
            for step in item.get("proof_steps") or []:
                if step and step != "done" and step != "end":
                    steps.append(" ".join(str(step).split()))
        elif item:
            steps.append(" ".join(str(item).split()))
    return " ; ".join(steps)


def flatten_results(results_json: Path, benchmark: str, experiment: str) -> list[dict[str, Any]]:
    payload = load_json(results_json)
    rows: list[dict[str, Any]] = []
    for proof_file, theorem_map in (payload.get("theorem_map") or {}).items():
        for raw_key, result in theorem_map.items():
            if not isinstance(result, dict):
                continue
            attempt_idx = (result.get("additional_info") or {}).get("attempt_idx")
            name = theorem_name(raw_key, result.get("lemma_name"))
            rows.append(
                {
                    "benchmark": benchmark,
                    "experiment": experiment,
                    "theorem_name": name,
                    "proof_found": bool(result.get("proof_found")),
                    "is_timeout": bool(result.get("is_timeout")),
                    "is_inference_exhausted": bool(result.get("is_inference_exhausted")),
                    "proof_time_in_secs": result.get("proof_time_in_secs"),
                    "inferences_taken": result.get("inferences_taken"),
                    "possible_failed_paths": result.get("possible_failed_paths"),
                    "num_of_backtracks": result.get("num_of_backtracks"),
                    "longest_success_path": result.get("longest_success_path"),
                    "attempt_idx": attempt_idx,
                    "proof_steps": collect_steps(result),
                    "proof_file": proof_file,
                    "results_json": str(results_json.relative_to(ROOT)),
                }
            )
    return rows


def result_path(run_root: Path, experiment: str) -> Path | None:
    paths = sorted((run_root / experiment).glob("proof_dumps/*/*/proof_results.json"))
    return paths[-1] if paths else None


def generation_path(run_root: Path, experiment: str) -> Path | None:
    path = run_root / experiment / "generation_debug.jsonl"
    return path if path.is_file() else None


def load_generation_records(path: Path | None) -> list[dict[str, Any]]:
    if path is None or not path.is_file():
        return []
    records: list[dict[str, Any]] = []
    with path.open("r", encoding="utf-8", errors="replace") as handle:
        for line in handle:
            line = line.strip()
            if not line:
                continue
            try:
                records.append(json.loads(line))
            except json.JSONDecodeError:
                continue
    return records


def generation_summary(paths: list[Path | None]) -> dict[str, Any]:
    records: list[dict[str, Any]] = []
    for path in paths:
        records.extend(load_generation_records(path))
    output_count = 0
    model_called_output_count = 0
    accepted_count = 0
    model_called_accepted_count = 0
    parsed_tactic_count = 0
    parse_error_count = 0
    model_called_state_count = 0
    no_start_goal_count = 0
    zero_accepted_model_called = 0
    zero_parsed_model_called = 0
    generation_times: list[float] = []
    accepted_per_model_called_state: list[float] = []
    parsed_per_model_called_state: list[float] = []
    output_per_model_called_state: list[float] = []
    top_tactics: Counter[str] = Counter()
    reason_counts: Counter[str] = Counter()

    for record in records:
        outputs = record.get("outputs") or []
        no_start = any(output.get("reason") == "no_start_goals_model_not_called" for output in outputs)
        if no_start:
            no_start_goal_count += 1
        else:
            model_called_state_count += 1
        if isinstance(record.get("generation_time_seconds"), (int, float)):
            generation_times.append(float(record["generation_time_seconds"]))

        state_accepted = 0
        state_parsed = 0
        state_outputs = len(outputs)
        for output in outputs:
            output_count += 1
            if not no_start:
                model_called_output_count += 1
            if output.get("accepted_as_action") is True:
                accepted_count += 1
                state_accepted += 1
                if not no_start:
                    model_called_accepted_count += 1
            parsed_tactics = output.get("parsed_tactics") or []
            parsed_tactic_count += len(parsed_tactics)
            state_parsed += len(parsed_tactics)
            for tactic in parsed_tactics:
                top_tactics[" ".join(str(tactic).split())[:120]] += 1
            if output.get("parse_error"):
                parse_error_count += 1
            if output.get("reason"):
                reason_counts[str(output["reason"])] += 1
        if not no_start:
            output_per_model_called_state.append(float(state_outputs))
            accepted_per_model_called_state.append(float(state_accepted))
            parsed_per_model_called_state.append(float(state_parsed))
            if state_accepted == 0:
                zero_accepted_model_called += 1
            if state_parsed == 0:
                zero_parsed_model_called += 1

    return {
        "prompt_state_count": len(records),
        "model_called_state_count": model_called_state_count,
        "no_start_goal_count": no_start_goal_count,
        "output_count": output_count,
        "model_called_output_count": model_called_output_count,
        "accepted_action_count": accepted_count,
        "parsed_tactic_count": parsed_tactic_count,
        "parse_error_count": parse_error_count,
        "accepted_action_rate_after_model_call": safe_div(model_called_accepted_count, model_called_output_count),
        "parsed_tactic_rate": safe_div(parsed_tactic_count, output_count),
        "parse_error_rate": safe_div(parse_error_count, output_count),
        "valid_tactics_per_model_called_state": mean(accepted_per_model_called_state),
        "parsed_tactics_per_model_called_state": mean(parsed_per_model_called_state),
        "outputs_per_model_called_state": mean(output_per_model_called_state),
        "early_dead_end_rate": safe_div(zero_accepted_model_called, model_called_state_count),
        "zero_parsed_state_rate": safe_div(zero_parsed_model_called, model_called_state_count),
        "mean_generation_time_in_secs": mean(generation_times),
        "top_tactics": top_tactics.most_common(10),
        "generation_reason_counts": dict(reason_counts),
    }


def parse_tree_file(path: Path) -> dict[str, Any]:
    nodes: set[str] = set()
    outgoing: Counter[str] = Counter()
    edge_count = 0
    text = path.read_text(encoding="utf-8", errors="replace")
    for line in text.splitlines():
        node_match = NODE_RE.match(line)
        if node_match:
            nodes.add(node_match.group("node").strip('"'))
            continue
        edge_match = EDGE_RE.match(line)
        if edge_match:
            src = edge_match.group("src").strip('"')
            dst = edge_match.group("dst").strip('"')
            nodes.add(src)
            nodes.add(dst)
            outgoing[src] += 1
            edge_count += 1
    branches = [float(value) for value in outgoing.values()]
    return {
        "tree_path": str(path.relative_to(ROOT)),
        "tree_theorem": path.parent.name,
        "node_count": len(nodes),
        "edge_count": edge_count,
        "branching_node_count": len(outgoing),
        "average_branching_factor": mean(branches),
        "max_branching_factor": max(branches) if branches else 0,
        "single_node_tree": len(nodes) <= 1,
    }


def tree_summary(run_roots: list[Path], experiment: str) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    tree_files = [
        path
        for run_root in run_roots
        for path in (run_root / experiment).glob("proof_dumps/**/proof_trees/**/*")
        if path.is_file() and path.suffix != ".svg"
    ]
    trees = [parse_tree_file(path) for path in sorted(tree_files)]
    node_counts = [float(tree["node_count"]) for tree in trees]
    edge_counts = [float(tree["edge_count"]) for tree in trees]
    branch_factors = [
        float(tree["average_branching_factor"])
        for tree in trees
        if tree["average_branching_factor"] is not None
    ]
    single = sum(1 for tree in trees if tree["single_node_tree"])
    return (
        {
            "proof_tree_file_count": len(trees),
            "mean_node_count": mean(node_counts),
            "mean_edge_count": mean(edge_counts),
            "mean_average_branching_factor": mean(branch_factors),
            "single_node_tree_rate": safe_div(single, len(trees)),
        },
        trees,
    )


def summarize_outcomes(rows: list[dict[str, Any]], attempted_names: set[str] | None = None) -> dict[str, dict[str, Any]]:
    by_exp: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for row in rows:
        if attempted_names is None or row["theorem_name"] in attempted_names:
            by_exp[row["experiment"]].append(row)

    summary: dict[str, dict[str, Any]] = {}
    for exp in EXPERIMENTS:
        exp_rows = by_exp.get(exp, [])
        proved = [row for row in exp_rows if row["proof_found"]]
        attempt_1 = [
            row
            for row in proved
            if isinstance(row.get("attempt_idx"), int) and int(row["attempt_idx"]) < 1
        ]
        attempt_5 = [
            row
            for row in proved
            if isinstance(row.get("attempt_idx"), int) and int(row["attempt_idx"]) < 5
        ]
        proof_times = [
            float(row["proof_time_in_secs"])
            for row in exp_rows
            if isinstance(row.get("proof_time_in_secs"), (int, float))
        ]
        summary[exp] = {
            "attempted": len(exp_rows),
            "proved": len(proved),
            "pass_rate": safe_div(len(proved), len(exp_rows)),
            "pass_at_1": safe_div(len(attempt_1), len(exp_rows)),
            "pass_at_5_observed": safe_div(len(attempt_5), len(exp_rows)),
            "timeouts": sum(1 for row in exp_rows if row["is_timeout"]),
            "timeout_rate": safe_div(sum(1 for row in exp_rows if row["is_timeout"]), len(exp_rows)),
            "mean_proof_time_in_secs": mean(proof_times),
            "total_proof_time_in_secs": sum(proof_times),
        }
    return summary


def write_csv(path: Path, rows: list[dict[str, Any]], fieldnames: list[str] | None = None) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if not rows:
        path.write_text("", encoding="utf-8")
        return
    headers = fieldnames or list(rows[0].keys())
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=headers, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)


def markdown_table(headers: list[str], rows: list[list[Any]]) -> str:
    lines = [
        "| " + " | ".join(headers) + " |",
        "| " + " | ".join("---" for _ in headers) + " |",
    ]
    for row in rows:
        lines.append("| " + " | ".join(fmt(value) for value in row) + " |")
    return "\n".join(lines)


def write_summary_table_md(path: Path, title: str, summary: dict[str, dict[str, Any]]) -> None:
    rows = []
    for exp in EXPERIMENTS:
        item = summary[exp]
        rows.append(
            [
                exp,
                item["attempted"],
                item["proved"],
                item["pass_rate"],
                item["pass_at_1"],
                item["pass_at_5_observed"],
                item["timeouts"],
                item["mean_proof_time_in_secs"],
            ]
        )
    text = "\n".join(
        [
            f"# {title}",
            "",
            markdown_table(
                [
                    "experiment",
                    "attempted",
                    "proved",
                    "pass_rate",
                    "pass_at_1",
                    "pass_at_5_observed",
                    "timeouts",
                    "mean_time_s",
                ],
                rows,
            ),
            "",
        ]
    )
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def diagnostics_table_markdown(title: str, rows: list[dict[str, Any]]) -> str:
    table_rows = []
    for row in rows:
        table_rows.append(
            [
                row["experiment"],
                row["theorems_attempted"],
                row["theorems_proved"],
                row["pass_rate"],
                row["valid_tactics_per_model_called_state"],
                row["accepted_action_rate_after_model_call"],
                row["early_dead_end_rate"],
                row["mean_node_count"],
                row["mean_average_branching_factor"],
                row["mean_proof_time_in_secs"],
            ]
        )
    return "\n".join(
        [
            f"# {title}",
            "",
            markdown_table(
                [
                    "experiment",
                    "attempted",
                    "proved",
                    "pass_rate",
                    "valid_tactics/state",
                    "accepted_action_rate",
                    "early_dead_end_rate",
                    "mean_tree_nodes",
                    "mean_branching",
                    "mean_time_s",
                ],
                table_rows,
            ),
            "",
        ]
    )


def benchmark_slug(benchmark: str) -> str:
    if benchmark.startswith("CoreEval"):
        return "core_eval"
    if benchmark == "miniF2F":
        return "minif2f"
    return re.sub(r"[^a-z0-9]+", "_", benchmark.lower()).strip("_")


def svg_bar_chart(
    path: Path,
    title: str,
    series: list[tuple[str, dict[str, float]]],
    ylabel: str,
    max_value: float | None = None,
) -> None:
    width = 860
    height = 430
    margin_left = 70
    margin_bottom = 80
    margin_top = 52
    plot_w = width - margin_left - 40
    plot_h = height - margin_top - margin_bottom
    labels = list(EXPERIMENTS)
    colors = ["#2f6fdd", "#d36b2d", "#288a52", "#7b4cc2"]
    max_data = max((value for _, data in series for value in data.values()), default=1.0)
    ymax = max_value if max_value is not None else max(1.0, max_data * 1.15)
    group_w = plot_w / len(labels)
    bar_w = min(42, group_w / (len(series) + 1.3))

    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
        '<rect width="100%" height="100%" fill="white"/>',
        f'<text x="{width/2}" y="28" text-anchor="middle" font-family="Arial" font-size="18" font-weight="700">{title}</text>',
        f'<text x="18" y="{margin_top + plot_h/2}" transform="rotate(-90 18 {margin_top + plot_h/2})" text-anchor="middle" font-family="Arial" font-size="13">{ylabel}</text>',
        f'<line x1="{margin_left}" y1="{margin_top}" x2="{margin_left}" y2="{margin_top+plot_h}" stroke="#333"/>',
        f'<line x1="{margin_left}" y1="{margin_top+plot_h}" x2="{margin_left+plot_w}" y2="{margin_top+plot_h}" stroke="#333"/>',
    ]
    for tick in range(6):
        value = ymax * tick / 5
        y = margin_top + plot_h - (value / ymax * plot_h)
        parts.append(f'<line x1="{margin_left-4}" y1="{y:.1f}" x2="{margin_left+plot_w}" y2="{y:.1f}" stroke="#e4e4e4"/>')
        parts.append(f'<text x="{margin_left-8}" y="{y+4:.1f}" text-anchor="end" font-family="Arial" font-size="11">{value:.2f}</text>')
    for idx, label in enumerate(labels):
        base_x = margin_left + idx * group_w + group_w / 2
        parts.append(f'<text x="{base_x:.1f}" y="{height-45}" text-anchor="middle" font-family="Arial" font-size="13">{label}</text>')
        for s_idx, (_, data) in enumerate(series):
            value = data.get(label, 0.0)
            bar_h = 0 if ymax == 0 else value / ymax * plot_h
            x = base_x - (len(series) * bar_w) / 2 + s_idx * bar_w
            y = margin_top + plot_h - bar_h
            parts.append(f'<rect x="{x:.1f}" y="{y:.1f}" width="{bar_w-4:.1f}" height="{bar_h:.1f}" fill="{colors[s_idx % len(colors)]}"/>')
            parts.append(f'<text x="{x+(bar_w-4)/2:.1f}" y="{y-5:.1f}" text-anchor="middle" font-family="Arial" font-size="10">{value:.2f}</text>')
    legend_x = margin_left
    legend_y = height - 24
    for s_idx, (name, _) in enumerate(series):
        x = legend_x + s_idx * 180
        parts.append(f'<rect x="{x}" y="{legend_y-11}" width="13" height="13" fill="{colors[s_idx % len(colors)]}"/>')
        parts.append(f'<text x="{x+18}" y="{legend_y}" font-family="Arial" font-size="12">{name}</text>')
    parts.append("</svg>")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(parts), encoding="utf-8")


def main() -> int:
    TABLES.mkdir(parents=True, exist_ok=True)
    FIGURES.mkdir(parents=True, exist_ok=True)

    all_rows: list[dict[str, Any]] = []
    diagnostics_rows: list[dict[str, Any]] = []
    tree_rows: list[dict[str, Any]] = []
    benchmark_summaries: dict[str, dict[str, dict[str, Any]]] = {}
    intersection_summaries: dict[str, dict[str, dict[str, Any]]] = {}

    for benchmark, run_roots in BENCHMARKS.items():
        benchmark_rows: list[dict[str, Any]] = []
        attempted_sets: list[set[str]] = []
        for exp in EXPERIMENTS:
            rows: list[dict[str, Any]] = []
            generation_paths: list[Path | None] = []
            for run_root in run_roots:
                results = result_path(run_root, exp)
                if results is None:
                    continue
                rows.extend(flatten_results(results, benchmark, exp))
                generation_paths.append(generation_path(run_root, exp))
            if not rows:
                continue
            benchmark_rows.extend(rows)
            all_rows.extend(rows)
            attempted_sets.append({row["theorem_name"] for row in rows})

            gen = generation_summary(generation_paths)
            tree_summary_row, trees = tree_summary(run_roots, exp)
            for tree in trees:
                tree_rows.append({"benchmark": benchmark, "experiment": exp, **tree})
            proof_times = [
                float(row["proof_time_in_secs"])
                for row in rows
                if isinstance(row.get("proof_time_in_secs"), (int, float))
            ]
            diagnostics_rows.append(
                {
                    "benchmark": benchmark,
                    "experiment": exp,
                    "theorems_attempted": len(rows),
                    "theorems_proved": sum(1 for row in rows if row["proof_found"]),
                    "pass_rate": safe_div(sum(1 for row in rows if row["proof_found"]), len(rows)),
                    "timeout_rate": safe_div(sum(1 for row in rows if row["is_timeout"]), len(rows)),
                    "mean_proof_time_in_secs": mean(proof_times),
                    **gen,
                    **tree_summary_row,
                }
            )

        benchmark_summaries[benchmark] = summarize_outcomes(benchmark_rows)
        intersection = set.intersection(*attempted_sets) if attempted_sets else set()
        intersection_summaries[benchmark] = summarize_outcomes(benchmark_rows, intersection)

        slug = benchmark_slug(benchmark)
        write_csv(TABLES / f"theorem_outcomes_{slug}.csv", benchmark_rows)
        write_summary_table_md(TABLES / f"main_comparison_{slug}.md", f"{benchmark} Main Comparison", benchmark_summaries[benchmark])
        write_summary_table_md(TABLES / f"intersection_comparison_{slug}.md", f"{benchmark} Intersection Comparison", intersection_summaries[benchmark])

        summary_csv_rows = []
        for exp, item in benchmark_summaries[benchmark].items():
            summary_csv_rows.append({"benchmark": benchmark, "experiment": exp, **item})
        write_csv(TABLES / f"main_comparison_{slug}.csv", summary_csv_rows)

        intersection_csv_rows = []
        for exp, item in intersection_summaries[benchmark].items():
            intersection_csv_rows.append({"benchmark": benchmark, "experiment": exp, "intersection_size": len(intersection), **item})
        write_csv(TABLES / f"intersection_comparison_{slug}.csv", intersection_csv_rows)

    write_csv(TABLES / "theorem_outcomes_all.csv", all_rows)
    write_csv(TABLES / "proof_tree_stats.csv", tree_rows)
    write_json(OUT / "analysis_payload.json", {
        "benchmark_summaries": benchmark_summaries,
        "intersection_summaries": intersection_summaries,
        "diagnostics": diagnostics_rows,
    })

    core = benchmark_summaries["CoreEval 250"]
    core_inter = intersection_summaries["CoreEval 250"]
    mini = benchmark_summaries["miniF2F"]
    mini_inter = intersection_summaries["miniF2F"]
    diag_by_bench_exp = {(row["benchmark"], row["experiment"]): row for row in diagnostics_rows}

    svg_bar_chart(
        FIGURES / "coreeval_pass_rates.svg",
        "CoreEval 250 Pass Rates",
        [
            ("All Attempted", {exp: core[exp]["pass_rate"] or 0.0 for exp in EXPERIMENTS}),
            ("Intersection", {exp: core_inter[exp]["pass_rate"] or 0.0 for exp in EXPERIMENTS}),
        ],
        "pass rate",
        max_value=1.0,
    )
    svg_bar_chart(
        FIGURES / "minif2f_pass_rates.svg",
        "miniF2F Pass Rates",
        [
            ("All Attempted", {exp: mini[exp]["pass_rate"] or 0.0 for exp in EXPERIMENTS}),
            ("Intersection", {exp: mini_inter[exp]["pass_rate"] or 0.0 for exp in EXPERIMENTS}),
        ],
        "pass rate",
        max_value=0.25,
    )
    svg_bar_chart(
        FIGURES / "coreeval_generated_action_quality.svg",
        "CoreEval Generated Action Quality",
        [
            (
                "accepted/action",
                {exp: diag_by_bench_exp[("CoreEval 250", exp)]["accepted_action_rate_after_model_call"] or 0.0 for exp in EXPERIMENTS},
            ),
            (
                "early dead-end",
                {exp: diag_by_bench_exp[("CoreEval 250", exp)]["early_dead_end_rate"] or 0.0 for exp in EXPERIMENTS},
            ),
        ],
        "rate",
        max_value=1.0,
    )
    svg_bar_chart(
        FIGURES / "coreeval_search_tree_size.svg",
        "CoreEval Search Tree Size",
        [
            (
                "mean nodes",
                {exp: diag_by_bench_exp[("CoreEval 250", exp)]["mean_node_count"] or 0.0 for exp in EXPERIMENTS},
            ),
            (
                "mean branching",
                {exp: diag_by_bench_exp[("CoreEval 250", exp)]["mean_average_branching_factor"] or 0.0 for exp in EXPERIMENTS},
            ),
        ],
        "count / factor",
    )

    for benchmark in BENCHMARKS:
        slug = benchmark_slug(benchmark)
        rows = [row for row in diagnostics_rows if row["benchmark"] == benchmark]
        write_csv(TABLES / f"search_diagnostics_{slug}.csv", rows)
        (TABLES / f"search_diagnostics_{slug}.md").write_text(
            diagnostics_table_markdown(f"{benchmark} Search Diagnostics", rows),
            encoding="utf-8",
        )

    memo = build_memo(benchmark_summaries, intersection_summaries, diagnostics_rows)
    (OUT / "internal_memo.md").write_text(memo, encoding="utf-8")

    index = "\n".join(
        [
            "# Day 8-10 Deliverables",
            "",
            "Generated local proof-search analysis deliverables from copied Nexus results.",
            "",
            "## Tables",
            "",
            "- `tables/main_comparison_core_eval.md`",
            "- `tables/intersection_comparison_core_eval.md`",
            "- `tables/main_comparison_minif2f.md`",
            "- `tables/intersection_comparison_minif2f.md`",
            "- `tables/search_diagnostics_core_eval.md`",
            "- `tables/search_diagnostics_minif2f.md`",
            "- `tables/theorem_outcomes_all.csv`",
            "- `tables/proof_tree_stats.csv`",
            "",
            "## Figures",
            "",
            "- `figures/coreeval_pass_rates.svg`",
            "- `figures/minif2f_pass_rates.svg`",
            "- `figures/coreeval_generated_action_quality.svg`",
            "- `figures/coreeval_search_tree_size.svg`",
            "",
            "## Memo",
            "",
            "- `internal_memo.md`",
            "",
        ]
    )
    (OUT / "README.md").write_text(index, encoding="utf-8")

    print(f"Wrote Day 8-10 deliverables under {OUT}")
    return 0


def build_memo(
    summaries: dict[str, dict[str, dict[str, Any]]],
    intersections: dict[str, dict[str, dict[str, Any]]],
    diagnostics: list[dict[str, Any]],
) -> str:
    core = summaries["CoreEval 250"]
    core_i = intersections["CoreEval 250"]
    mini = summaries["miniF2F"]
    mini_i = intersections["miniF2F"]
    diag = {(row["benchmark"], row["experiment"]): row for row in diagnostics}

    lines = [
        "# Day 8-10 Internal Memo",
        "",
        "## Scope",
        "",
        "This memo summarizes the local Day 8-10 deliverables built from the copied Nexus proof-search result directories:",
        "",
        "- `runs/proof_search_core_eval/6848604`",
        "- `runs/proof_search_minif2f_easy10/6849079`",
        "- `runs/proof_search_minif2f_remaining_9h20/6850148`",
        "",
        "CoreEval is the controlled in-project Lean 4 benchmark. The two miniF2F runs are combined below and treated as one external Lean 3 generalization check. CoreEval and miniF2F should be interpreted together rather than collapsed into a single winner.",
        "",
        "## Main CoreEval Result",
        "",
        markdown_table(
            ["experiment", "attempted", "proved", "pass_rate", "intersection_proved", "intersection_pass_rate"],
            [
                [
                    exp,
                    core[exp]["attempted"],
                    core[exp]["proved"],
                    core[exp]["pass_rate"],
                    core_i[exp]["proved"],
                    core_i[exp]["pass_rate"],
                ]
                for exp in EXPERIMENTS
            ],
        ),
        "",
        "On CoreEval, E4 is ahead of both E1 and E3. E1 is also ahead of E3 on the theorem-name intersection attempted by all three models. This is consistent with pseudo-multilingual regularization helping on Lean-like in-distribution theorem statements.",
        "",
        "## miniF2F Result",
        "",
        markdown_table(
            ["experiment", "attempted", "proved", "pass_rate", "intersection_proved", "intersection_pass_rate"],
            [
                [
                    exp,
                    mini[exp]["attempted"],
                    mini[exp]["proved"],
                    mini[exp]["pass_rate"],
                    mini_i[exp]["proved"],
                    mini_i[exp]["pass_rate"],
                ]
                for exp in EXPERIMENTS
            ],
        ),
        "",
        "Combined miniF2F makes E1 and E4 more comparable than CoreEval does, while E3 remains competitive. This supports the concern that CoreEval is favorable to E4 and that real multilingual training may matter more on external theorem styles.",
        "",
        "## CoreEval Search Diagnostics",
        "",
        markdown_table(
            [
                "experiment",
                "valid_tactics/state",
                "accepted_action_rate",
                "early_dead_end_rate",
                "mean_tree_nodes",
                "mean_branching",
                "mean_time_s",
            ],
            [
                [
                    exp,
                    diag[("CoreEval 250", exp)]["valid_tactics_per_model_called_state"],
                    diag[("CoreEval 250", exp)]["accepted_action_rate_after_model_call"],
                    diag[("CoreEval 250", exp)]["early_dead_end_rate"],
                    diag[("CoreEval 250", exp)]["mean_node_count"],
                    diag[("CoreEval 250", exp)]["mean_average_branching_factor"],
                    diag[("CoreEval 250", exp)]["mean_proof_time_in_secs"],
                ]
                for exp in EXPERIMENTS
            ],
        ),
        "",
        "## miniF2F Search Diagnostics",
        "",
        markdown_table(
            [
                "experiment",
                "valid_tactics/state",
                "accepted_action_rate",
                "early_dead_end_rate",
                "mean_tree_nodes",
                "mean_branching",
                "mean_time_s",
            ],
            [
                [
                    exp,
                    diag[("miniF2F", exp)]["valid_tactics_per_model_called_state"],
                    diag[("miniF2F", exp)]["accepted_action_rate_after_model_call"],
                    diag[("miniF2F", exp)]["early_dead_end_rate"],
                    diag[("miniF2F", exp)]["mean_node_count"],
                    diag[("miniF2F", exp)]["mean_average_branching_factor"],
                    diag[("miniF2F", exp)]["mean_proof_time_in_secs"],
                ]
                for exp in EXPERIMENTS
            ],
        ),
        "",
        "The generated-action metrics should be read as parser/action acceptance, not as guaranteed Lean compilation. Proof-tree statistics are a stronger proxy for search expansion because they are produced by the proof-search engine after interacting with Lean.",
        "",
        "## Token-Budget Caveat",
        "",
        "A finalized token-budget note was not present in the local artifacts used for this analysis. The plan records that E3 used a deadline-compatible multilingual split rather than the ideal final token-matched Lean+Coq mixture, and E4 still needs a more careful pseudo-Lean transformation audit. Therefore these results are useful pilot evidence, but they should not be presented as a clean causal token-matched comparison.",
        "",
        "## Interpretation",
        "",
        "- H1, structural transfer: not supported by CoreEval alone, but miniF2F provides suggestive evidence that real multilingual training can help external generalization.",
        "- H2, regularization: CoreEval favors E4, supporting the idea that pseudo-multilingual variation helps on in-distribution Lean-style proof search.",
        "- H3, search calibration: still plausible as a mechanism to inspect, especially because the miniF2F runs are timeout-heavy and differences may appear in search behavior before large pass-rate gaps emerge.",
        "- Distribution-dependent finding: the strongest current story is not one global winner. CoreEval shows when regularization matters; miniF2F shows where real multilingual transfer may matter.",
        "",
        "## Deliverable Files",
        "",
        "- Tables: `runs/analysis/day8_10/tables/`",
        "- Figures: `runs/analysis/day8_10/figures/`",
        "- Machine-readable payload: `runs/analysis/day8_10/analysis_payload.json`",
        "",
    ]
    return "\n".join(lines)


if __name__ == "__main__":
    raise SystemExit(main())
