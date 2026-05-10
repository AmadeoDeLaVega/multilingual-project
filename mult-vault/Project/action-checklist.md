# Action Checklist

This is the short execution sheet for the current parallel-training pilot. Use it alongside [[Project/runbook]] and [[PLAN]].

## Day 1: Environment and E0

- [ ] SSH into Nexus with VPN enabled.
- [ ] Confirm class access with `show_partitions`, `show_qos`, and `show_partition_qos`.
- [ ] Confirm RTX A5000 availability with `show_available_nodes --partition class --account class --qos medium --gpus rtxa5000:1`.
- [ ] Confirm one tiny A5000 allocation with `nvidia-smi`.
- [ ] Verify each student has a Nexus checkout at `/fs/classhomes/<username>/multilingual-project`.
- [ ] Pull the latest code from GitHub on local and Nexus copies.
- [ ] Activate `proofwala-pilot`.
- [ ] Verify `torch.cuda.is_available()` inside an allocated GPU job.
- [ ] Verify Lean tooling with `lean --version`.
- [ ] Verify `proof_wala` and `itp_interface` imports.
- [ ] Run E0 using released `amitayusht/ProofWala-Multilingual`.
- [ ] Confirm proof search completes and writes JSON results.
- [ ] Save `runs/E0/environment_note.md`.

## Day 2: Dataset and Experiment Freeze

- [ ] Use the GitHub repo for source code, configs, scripts, docs, and small manifests only.
- [ ] Confirm `.gitignore` excludes `.log/`, `runs/`, `data/`, caches, venvs, and checkpoints.
- [ ] Keep large artifacts out of GitHub.
- [ ] Stage or download [amitayusht/ProofWalaDataset](https://huggingface.co/datasets/amitayusht/ProofWalaDataset).
- [ ] Set explicit `HF_HOME`, `HF_DATASETS_CACHE`, and `TRANSFORMERS_CACHE` paths.
- [ ] Check `/fs/classhomes/<username>` space usage for each student.
- [ ] If storage is tight, reduce dataset shards or request class project storage.
- [ ] Freeze the E1 Lean training subset.
- [ ] Freeze E3 smoke source as ProofWalaDataset `multilingual/train`.
- [ ] Define the final E3 token-matched Lean+Coq mixture rule.
- [ ] Freeze the E4 Lean base subset.
- [ ] Freeze the shared Lean eval/test subset for E1, E3, and E4.
- [ ] Define the E4 pseudo-multilingual transformation.
- [ ] Write `data/manifests/dataset_manifest.yaml`.
- [ ] Write `data/frozen_splits/split_manifest.yaml`.
- [ ] Write `data/manifests/token_budget_note.md`.
- [ ] Write the student assignment table.

## Day 3: Calibration and Smoke Tests

- [ ] Generate a small E4 pseudo-Lean sample.
- [ ] Inspect at least 50 transformed examples.
- [ ] Save `data/pseudo_multilingual/e4_audit.md`.
- [ ] Run E3 smoke test with `multilingual/train`.
- [ ] Build and validate the final E3 token-matched Lean+Coq mixture manifest.
- [ ] Run one 100-step calibration on RTX A5000.
- [ ] Estimate full-run time from calibration.
- [ ] Run short smoke tests for E1, E3, and E4.
- [ ] Confirm E1, E3, and E4 smoke configs all use `Salesforce/codet5-small`.
- [ ] Confirm fp16/bf16, gradient checkpointing, batch size 1, and checkpoint saving.
- [ ] Save smoke logs under `runs/smoke/`.

## Days 4-5: Parallel Training

- [ ] Student 1 submits E1 on Nexus with `class` / `medium` / `gpu:rtxa5000:1`.
- [ ] Student 2 submits E3 on Nexus with `class` / `medium` / `gpu:rtxa5000:1`.
- [ ] Student 3 submits E4 on Nexus with `class` / `medium` / `gpu:rtxa5000:1`.
- [ ] Confirm all three full runs start from `Salesforce/codet5-small` with the same tokenizer.
- [ ] Monitor with `squeue -u $USER` and `sacct -j <JOBID>`.
- [ ] Resume from checkpoint if a job hits wall time.
- [ ] Keep only the latest few checkpoints.
- [ ] Record wall-clock time, steps, examples, estimated token budget, GPU type, and final checkpoint.
- [ ] Save `runs/E1/training_summary.md`.
- [ ] Save `runs/E3/training_summary.md`.
- [ ] Save `runs/E4/training_summary.md`.

## Days 6-7: Base Evaluation

- [ ] Prepare eval config for trained E1.
- [ ] Prepare eval config for trained E3.
- [ ] Prepare eval config for trained E4.
- [ ] Optionally prepare reference eval configs for released ProofWala-Lean and ProofWala-Multilingual.
- [ ] Use the same fixed Lean eval subset and proof-search budget for all models.
- [ ] Run E1 evaluation.
- [ ] Run E3 evaluation.
- [ ] Run E4 evaluation.
- [ ] Compute pass@1, pass@5, and compilable-tactic rate.
- [ ] Save `reports/tables/base_results.csv`.
- [ ] Write the first interpretation note.

## Days 8-10: Diagnostics

- [ ] Compute valid tactics per state.
- [ ] Compute early dead-end rate.
- [ ] Compute proof tree nodes and edges.
- [ ] Compute branching factor.
- [ ] Compute average proof search time.
- [ ] Compare results against the token-budget note.
- [ ] Save `reports/tables/search_diagnostics.csv`.
- [ ] Make core figures under `reports/figures/`.

## Optional Days 11-12: Adaptation

- [ ] Decide if core experiments are stable enough to proceed.
- [ ] Fine-tune E1 on CategoryTheory as E5a.
- [ ] Fine-tune E3 on CategoryTheory as E5b.
- [ ] Evaluate E5a vs E5b on the same held-out split.
- [ ] Save adaptation results table.

## Day 13: Memo

- [ ] Draft 3 to 5 page memo.
- [ ] Include dataset and released model reference links.
- [ ] State E3 vs E1 result.
- [ ] State E3 vs E4 result.
- [ ] State search-calibration interpretation.
- [ ] Add limitations.

## Day 14: Packaging

- [ ] Archive source code, configs, scripts, and docs in GitHub.
- [ ] Archive split files and small manifests.
- [ ] Archive command log.
- [ ] Archive checkpoint inventory, not full checkpoints in GitHub.
- [ ] Archive figures and tables.
- [ ] Save reproducibility note.
- [ ] Make one-slide or one-page summary.

## Decision Rule

- If **E3 > E1** and **E3 > E4**, that supports real cross-system transfer.
- If **E3 > E1** but **E3 ~= E4**, regularization may explain much of the gain.
- If gains mostly show up in search metrics, search calibration is probably a big part of the story.
