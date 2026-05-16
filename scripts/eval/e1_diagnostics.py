#!/usr/bin/env python3
"""Run E1 training sanity and next-step prediction diagnostics.

This script is intentionally standalone so it can be copied to Nexus and run
against the existing E1 checkpoint without retraining.
"""

from __future__ import annotations

import argparse
import json
import math
import os
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any


DEFAULT_MODEL = "runs/E1/model/pilot-e1-lean-only/final"
DEFAULT_RUN_ROOT = "runs/E1"
DEFAULT_EVAL_DIR = "data/frozen_splits/lean_eval_1000"
DEFAULT_OUTPUT = "runs/E1/diagnostics/e1_diagnostics.json"


def resolve_project_path(project_root: Path, value: str | Path) -> Path:
    path = Path(value)
    return path if path.is_absolute() else project_root / path


def load_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def write_json(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2, ensure_ascii=False, sort_keys=True)
        handle.write("\n")


def numeric_history(log_history: list[dict[str, Any]], key: str) -> list[tuple[int, float]]:
    points = []
    for item in log_history:
        if key not in item:
            continue
        step = int(item.get("step", 0))
        try:
            value = float(item[key])
        except (TypeError, ValueError):
            continue
        points.append((step, value))
    return points


def trend(points: list[tuple[int, float]]) -> dict[str, Any]:
    if not points:
        return {"count": 0}
    first_step, first_value = points[0]
    last_step, last_value = points[-1]
    best_step, best_value = min(points, key=lambda item: item[1])
    return {
        "count": len(points),
        "first": {"step": first_step, "value": first_value},
        "last": {"step": last_step, "value": last_value},
        "best_min": {"step": best_step, "value": best_value},
        "absolute_change_first_to_last": last_value - first_value,
        "relative_change_first_to_last": (
            (last_value - first_value) / first_value if first_value else None
        ),
    }


def find_files(root: Path, name: str) -> list[Path]:
    if not root.exists():
        return []
    return sorted(root.rglob(name))


def parse_trainer_states(run_root: Path) -> dict[str, Any]:
    trainer_states = []
    for path in find_files(run_root, "trainer_state.json"):
        try:
            state = load_json(path)
        except Exception as exc:  # noqa: BLE001
            trainer_states.append({"path": str(path), "error": f"{type(exc).__name__}: {exc}"})
            continue
        history = state.get("log_history") or []
        eval_exact_keys = sorted(
            {
                key
                for row in history
                for key in row
                if key.endswith("exact_match") or key == "eval_exact_match"
            }
        )
        trainer_states.append(
            {
                "path": str(path),
                "global_step": state.get("global_step"),
                "best_metric": state.get("best_metric"),
                "best_model_checkpoint": state.get("best_model_checkpoint"),
                "train_loss": trend(numeric_history(history, "loss")),
                "eval_loss": trend(numeric_history(history, "eval_loss")),
                "eval_exact_match": {
                    key: trend(numeric_history(history, key))
                    for key in eval_exact_keys
                },
                "log_history_count": len(history),
            }
        )
    return {
        "run_root": str(run_root),
        "trainer_state_files": trainer_states,
        "trainer_state_file_count": len(trainer_states),
    }


TRAINER_LOG_PATTERNS = {
    "loss": re.compile(r"'loss':\s*([0-9.eE+-]+).*?'step':\s*([0-9]+)"),
    "eval_loss": re.compile(r"'eval_loss':\s*([0-9.eE+-]+).*?'step':\s*([0-9]+)"),
    "exact_match": re.compile(r"'(?:eval_[^']*_)?exact_match':\s*([0-9.eE+-]+).*?'step':\s*([0-9]+)"),
}


def parse_text_logs(run_root: Path) -> dict[str, Any]:
    points: dict[str, list[tuple[int, float]]] = {key: [] for key in TRAINER_LOG_PATTERNS}
    scanned = 0
    if run_root.exists():
        for path in sorted(run_root.rglob("*.out")) + sorted(run_root.rglob("*.log")):
            if path.stat().st_size > 200_000_000:
                continue
            scanned += 1
            text = path.read_text(encoding="utf-8", errors="replace")
            for key, pattern in TRAINER_LOG_PATTERNS.items():
                for match in pattern.finditer(text):
                    value = float(match.group(1))
                    step = int(match.group(2))
                    points[key].append((step, value))
    return {
        "text_log_files_scanned": scanned,
        "loss": trend(sorted(points["loss"])),
        "eval_loss": trend(sorted(points["eval_loss"])),
        "exact_match": trend(sorted(points["exact_match"])),
    }


def import_proofwala(project_root: Path) -> None:
    for relative in ("proof-wala/src", "itp-interface/src"):
        candidate = project_root / relative
        if candidate.exists() and str(candidate) not in sys.path:
            sys.path.insert(0, str(candidate))


@dataclass
class PredictionRow:
    index: int
    label: str
    prediction: str
    exact_match: bool
    normalized_exact_match: bool
    parseable: bool
    prompt_chars: int


def normalize_completion(text: str) -> str:
    text = text.strip()
    if text.endswith("[END]"):
        text = text[: -len("[END]")]
    return text.strip()


def first_prediction_text(raw_prediction: Any) -> str:
    if isinstance(raw_prediction, list):
        return str(raw_prediction[0]) if raw_prediction else ""
    return str(raw_prediction)


def run_next_step_eval(
    project_root: Path,
    model_path: Path,
    eval_dir: Path,
    tokenizer_source: str,
    limit: int,
    batch_size: int,
    seed: int,
) -> dict[str, Any]:
    import_proofwala(project_root)

    import torch
    from torch.utils.data import DataLoader
    from transformers import AutoModelForSeq2SeqLM, AutoTokenizer, set_seed

    from itp_interface.tools.log_utils import setup_logger
    from itp_interface.tools.training_data import TrainingData
    from proof_wala.itp.codet5_training_data_formatter import (
        CodeT5PromptTrainingDataFormatter,
        CodeT5TrainingDataset,
    )

    set_seed(seed)
    tokenizer_files = ["tokenizer_config.json", "special_tokens_map.json", "vocab.json", "merges.txt"]
    tokenizer_path = (
        model_path
        if all((model_path / name).exists() for name in tokenizer_files)
        else tokenizer_source
    )
    tokenizer = AutoTokenizer.from_pretrained(
        tokenizer_path,
        padding=True,
        truncation=True,
        max_length=2048,
    )
    model = AutoModelForSeq2SeqLM.from_pretrained(model_path)
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    model.to(device)
    model.eval()

    training_data = TrainingData(
        str(eval_dir),
        "local.meta.json",
        logger=setup_logger("E1NextStepEval", os.devnull),
        use_ray=False,
    )
    formatter = CodeT5PromptTrainingDataFormatter()
    rows: list[PredictionRow] = []
    losses: list[float] = []
    examples_seen = 0

    with CodeT5TrainingDataset(
        training_data,
        characters_per_token=3.6,
        max_tokens=2048,
        no_steps=True,
    ) as dataset:
        hf_dataset = dataset.get_hf_dataset()
        if limit > 0:
            hf_dataset = hf_dataset.select(range(min(limit, len(hf_dataset))))
        dataloader = DataLoader(hf_dataset, batch_size=batch_size, shuffle=False)

        for batch in dataloader:
            pairs = formatter.get_prompt_and_completion(batch)
            prompts = [prompt for prompt, _ in pairs]
            labels = [label for _, label in pairs]
            label_tokens = tokenizer(labels, return_tensors="pt", padding=True, truncation=True)
            max_new_tokens = int(label_tokens["input_ids"].shape[1])
            model_inputs = tokenizer(
                prompts,
                return_tensors="pt",
                padding=True,
                truncation=True,
                max_length=2048,
            ).to(device)
            labels_for_loss = label_tokens["input_ids"].to(device)
            labels_for_loss[labels_for_loss == tokenizer.pad_token_id] = -100
            with torch.no_grad():
                loss_out = model(**model_inputs, labels=labels_for_loss)
                generated = model.generate(
                    **model_inputs,
                    max_new_tokens=max_new_tokens,
                    do_sample=True,
                    temperature=0.1,
                    top_k=5,
                    num_return_sequences=1,
                    pad_token_id=tokenizer.pad_token_id,
                    eos_token_id=tokenizer.eos_token_id,
                )
            if not math.isnan(float(loss_out.loss.detach().cpu())):
                losses.append(float(loss_out.loss.detach().cpu()))
            predictions = tokenizer.batch_decode(generated, skip_special_tokens=True)

            for prompt, label, prediction in zip(prompts, labels, predictions):
                parseable = False
                try:
                    CodeT5TrainingDataset.response_parser(prediction)
                    parseable = True
                except Exception:  # noqa: BLE001
                    parseable = False
                prediction_text = first_prediction_text(prediction)
                rows.append(
                    PredictionRow(
                        index=examples_seen,
                        label=label,
                        prediction=prediction_text,
                        exact_match=prediction_text == label,
                        normalized_exact_match=normalize_completion(prediction_text)
                        == normalize_completion(label),
                        parseable=parseable,
                        prompt_chars=len(prompt),
                    )
                )
                examples_seen += 1

    correct = sum(row.exact_match for row in rows)
    norm_correct = sum(row.normalized_exact_match for row in rows)
    parseable = sum(row.parseable for row in rows)
    return {
        "model_path": str(model_path),
        "eval_dir": str(eval_dir),
        "tokenizer_source": str(tokenizer_source),
        "device": str(device),
        "examples": len(rows),
        "strict_exact_match": correct / len(rows) if rows else None,
        "normalized_exact_match": norm_correct / len(rows) if rows else None,
        "parseable_rate": parseable / len(rows) if rows else None,
        "mean_eval_loss": sum(losses) / len(losses) if losses else None,
        "sample_predictions": [row.__dict__ for row in rows[:20]],
    }


def write_markdown(path: Path, payload: dict[str, Any]) -> None:
    sanity = payload["training_sanity"]
    next_step = payload.get("next_step_prediction")
    lines = [
        "# E1 Diagnostics",
        "",
        "## Training Sanity",
        "",
        f"- run_root: `{sanity['trainer_states']['run_root']}`",
        f"- trainer_state files: `{sanity['trainer_states']['trainer_state_file_count']}`",
    ]
    for item in sanity["trainer_states"]["trainer_state_files"]:
        lines.extend(
            [
                f"- state: `{item.get('path')}`",
                f"  global_step: `{item.get('global_step')}`",
                f"  best_metric: `{item.get('best_metric')}`",
                f"  best_model_checkpoint: `{item.get('best_model_checkpoint')}`",
                f"  train_loss: `{item.get('train_loss')}`",
                f"  eval_loss: `{item.get('eval_loss')}`",
                f"  eval_exact_match: `{item.get('eval_exact_match')}`",
            ]
        )
    lines.extend(
        [
            "",
            "## Text Log Fallback",
            "",
            f"- log files scanned: `{sanity['text_logs']['text_log_files_scanned']}`",
            f"- loss: `{sanity['text_logs']['loss']}`",
            f"- eval_loss: `{sanity['text_logs']['eval_loss']}`",
            f"- exact_match: `{sanity['text_logs']['exact_match']}`",
        ]
    )
    if next_step:
        lines.extend(
            [
                "",
                "## Next-Step Prediction",
                "",
                f"- model: `{next_step['model_path']}`",
                f"- eval_dir: `{next_step['eval_dir']}`",
                f"- examples: `{next_step['examples']}`",
                f"- strict_exact_match: `{next_step['strict_exact_match']}`",
                f"- normalized_exact_match: `{next_step['normalized_exact_match']}`",
                f"- parseable_rate: `{next_step['parseable_rate']}`",
                f"- mean_eval_loss: `{next_step['mean_eval_loss']}`",
            ]
        )
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project-root", default=os.environ.get("PROJECT_ROOT", "."))
    parser.add_argument("--run-root", default=DEFAULT_RUN_ROOT)
    parser.add_argument("--model", default=DEFAULT_MODEL)
    parser.add_argument("--eval-dir", default=DEFAULT_EVAL_DIR)
    parser.add_argument("--tokenizer-source", default="Salesforce/codet5-small")
    parser.add_argument("--output", default=DEFAULT_OUTPUT)
    parser.add_argument("--limit", type=int, default=128)
    parser.add_argument("--batch-size", type=int, default=1)
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--skip-next-step", action="store_true")
    args = parser.parse_args()

    project_root = Path(args.project_root).resolve()
    run_root = resolve_project_path(project_root, args.run_root)
    model_path = resolve_project_path(project_root, args.model)
    eval_dir = resolve_project_path(project_root, args.eval_dir)
    output = resolve_project_path(project_root, args.output)

    payload: dict[str, Any] = {
        "project_root": str(project_root),
        "training_sanity": {
            "trainer_states": parse_trainer_states(run_root),
            "text_logs": parse_text_logs(run_root),
        },
    }

    if not args.skip_next_step:
        if not model_path.exists():
            raise SystemExit(f"Missing model path: {model_path}")
        if not eval_dir.exists():
            raise SystemExit(f"Missing eval dir: {eval_dir}")
        payload["next_step_prediction"] = run_next_step_eval(
            project_root=project_root,
            model_path=model_path,
            eval_dir=eval_dir,
            tokenizer_source=args.tokenizer_source,
            limit=args.limit,
            batch_size=args.batch_size,
            seed=args.seed,
        )

    write_json(output, payload)
    write_markdown(output.with_suffix(".md"), payload)
    print(f"wrote {output}")
    print(f"wrote {output.with_suffix('.md')}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
