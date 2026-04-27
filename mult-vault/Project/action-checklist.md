# Action Checklist

This is the short execution sheet for the pilot. Use it alongside [[Project/runbook]].

## Day 1: environment and E0

- [ ] SSH into NEXUS submission node
- [ ] Confirm partition, qos, and account with `show_partitions`
- [ ] Activate `proofwala-pilot` conda env
- [ ] Verify `torch.cuda.is_available()`
- [ ] Verify Lean tooling (`lean --version`)
- [ ] Verify `proof-wala` and `itp-interface` import
- [ ] Build the Lean project needed for the first eval
- [ ] Submit or run E0 sanity check
- [ ] Confirm proof search completes successfully
- [ ] Save `runs/E0/environment_note.md`

## Day 2: data and split freeze

- [ ] Decide whether to reuse or regenerate Lean data
- [ ] Decide whether to reuse or regenerate Coq data for E3
- [ ] Freeze Lean train/val/test split
- [ ] Freeze Coq subset for E3
- [ ] Define E3 as Lean base plus Coq augmentation
- [ ] Define E4 as Lean base plus synthetic Lean augmentation
- [ ] Freeze shared prompt grammar and prompt field order for E1/E3/E4
- [ ] Freeze reduced base evaluation subset
- [ ] Write dataset manifest
- [ ] Write split manifest
- [ ] Write token budget note
- [ ] Estimate token counts for Lean base, Coq augmentation, and synthetic Lean augmentation
- [ ] Choose the token-matching and step-matching rule for all runs
- [ ] Define pseudo-multilingual transformation for E4

## Day 3: configs and smoke tests

- [ ] Fill in real paths in `pilot_e1.yaml`
- [ ] Fill in real paths in `pilot_e3.yaml`
- [ ] Fill in real paths in `pilot_e4.yaml`
- [ ] Fill in NEXUS placeholders in sbatch scripts
- [ ] Generate a small E4 sample
- [ ] Audit the E4 sample for semantics, parseability, and naturalness
- [ ] Recompute token counts after E4 generation
- [ ] Run smoke test for E1
- [ ] Run smoke test for E3
- [ ] Run smoke test for E4
- [ ] Confirm checkpoints and logs are created
- [ ] Confirm optimization-step matching actually holds across runs

## Days 4-5: E1

- [ ] Submit `train_e1.sbatch`
- [ ] Monitor job with `squeue` / `sacct`
- [ ] Record checkpoint path
- [ ] Record wall-clock time
- [ ] Record actual step count and effective token budget
- [ ] Save `runs/E1/training_summary.md`

## Days 6-7: E3 and E4

- [ ] Finalize E4 augmentation size to match the chosen E3 budget
- [ ] Submit `train_e3.sbatch`
- [ ] Submit `train_e4.sbatch`
- [ ] Audit pseudo-multilingual data sample before full E4 training
- [ ] Verify E3 and E4 still match E1 on the planned control dimensions
- [ ] Log any unavoidable budget mismatch explicitly
- [ ] Record checkpoint paths
- [ ] Save `runs/E3/training_summary.md`
- [ ] Save `runs/E4/training_summary.md`

## Day 8: base evaluation

- [ ] Prepare pilot eval configs if needed
- [ ] Run base evaluation for E1
- [ ] Run base evaluation for E3
- [ ] Run base evaluation for E4
- [ ] Compute pass@1
- [ ] Compute pass@5
- [ ] Compute compilable tactic rate
- [ ] Save `reports/tables/base_results.csv`
- [ ] Write first interpretation note

## Days 9-10: diagnostics

- [ ] Compute valid tactics per state
- [ ] Compute early dead-end rate
- [ ] Compute proof tree nodes and edges
- [ ] Compute branching factor
- [ ] Compute average proof search time
- [ ] Compare results against the matched-budget note before interpreting them
- [ ] Save `reports/tables/search_diagnostics.csv`
- [ ] Make core figures

## Optional Days 11-12: adaptation

- [ ] Decide if core experiments are stable enough to proceed
- [ ] Create `pilot_e5a.yaml`
- [ ] Create `pilot_e5b.yaml`
- [ ] Submit E5a fine-tuning
- [ ] Submit E5b fine-tuning
- [ ] Evaluate E5a vs E5b
- [ ] Save adaptation results table

## Day 13: memo

- [ ] Draft 3 to 5 page memo
- [ ] Insert figures
- [ ] State results for E3 vs E1
- [ ] State results for E3 vs E4
- [ ] State search-calibration interpretation
- [ ] Add limitations

## Day 14: packaging

- [ ] Archive configs
- [ ] Archive split files
- [ ] Archive budget-matching note
- [ ] Archive commands used
- [ ] Archive checkpoint inventory
- [ ] Archive figures and tables
- [ ] Save reproducibility note
- [ ] Make one-slide or one-page summary

## Decision rule at the end

- If **E3 > E1** and **E3 > E4**, that supports real cross-system transfer.
- If **E3 > E1** but **E3 ≈ E4**, regularization may explain much of the gain.
- If gains mostly show up in search metrics, search calibration is probably a big part of the story.
