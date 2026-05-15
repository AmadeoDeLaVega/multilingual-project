# AGENTS.md

## Project Summary

This repository supports a pilot research project on why multilingual training improves theorem proving in ProofWala.

The main question is whether ProofWala's multilingual gains come from genuine Lean + Coq transfer, from regularization caused by more varied training data, or from better proof-search calibration.

## Core Experiments

The required experiment set is:

- **E0:** sanity-check the environment and proof-search pipeline with the released `amitayusht/ProofWala-Multilingual` model.
- **E1:** train a Lean-only baseline from `Salesforce/codet5-small` on the ProofWalaDataset Lean split.
- **E3:** train a real multilingual model from `Salesforce/codet5-small`; use `multilingual/train` for smoke tests, then a token-matched Lean+Coq mixture for final runs if feasible.
- **E4:** train a pseudo-multilingual control from `Salesforce/codet5-small` using Lean data plus meaning-preserving synthetic Lean variation.

Released Hugging Face assets are first-class references:

- Dataset: `amitayusht/ProofWalaDataset`
- Lean reference model: `amitayusht/ProofWala-Lean`
- Multilingual reference model: `amitayusht/ProofWala-Multilingual`

## Development and Nexus Workflow

All code and documentation changes should be made first in the local checkout:

```bash
~/multilingual-project
```

Cluster runs happen from the Nexus copy:

```bash
/fs/classhomes/<username>/multilingual-project
```

When adding scripts, configs, or code, write and review them locally first, then sync or pull the changes into the Nexus directory before submitting jobs. Paths embedded in Nexus job scripts should resolve relative to the Nexus project directory, not only the local checkout.

Each student has their own Nexus class-home project copy and downloads or caches the ProofWala dataset separately under their own account. Large artifacts such as datasets, checkpoints, logs, caches, and `runs/` outputs should stay out of GitHub.

## Current Progress Notes

Recent Nexus work completed:

- E1 full training completed successfully on Nexus with job `6822048`.
- The E1 model was trained from `Salesforce/codet5-small` for `5000` steps and saved at `/fs/classhomes/adelaveg/multilingual-project/runs/E1/model/pilot-e1-lean-only/final`.
- E1 checkpointing was patched to reduce storage pressure: `save_only_model: True`, `save_steps: 1000`, `eval_steps: 1000`, and `save_total_limit: 2`.
- The final E1 `model.safetensors` was validated after training.
- `scripts/nexus/proof_search_smoke.sbatch` ran successfully against the final E1 model with job `6822090`; the proof-search pipeline initialized, generated parseable actions, and wrote results, but proved `0/5` smoke theorems.

Immediate follow-up work:

- Patch E3 and E4 training configs/scripts with the same minimal-checkpoint strategy used for E1.
- Set up and verify the final Nexus dataset paths for E3 and E4 before submitting training jobs.
- Improve the Lean-to-pseudo-Lean transformation for E4 according to `PLAN.md`; identifier renaming still needs careful auditing, especially Lean names with suffixes, primes, numeric components, or subscript-like conventions.
- Re-run smoke checks for E3 and E4 after their dataset paths and checkpoint settings are fixed.

## Nexus Execution Rules

Use Nexus class-cluster policies for training and evaluation:

- Submit GPU jobs through SLURM, not interactive long-running shell processes.
- Use the `class` account and `medium` QoS for smoke and training jobs unless the plan says otherwise.
- Target one RTX A5000 GPU per core training job.
- Monitor jobs with `squeue -u $USER` and `sacct -j <JOBID>`.
- Save logs, summaries, and result JSON files under `runs/`.
- Keep checkpoints limited; only the latest useful checkpoint and final model should be retained when storage is tight.

## Experiment Discipline

For E1, E3, and E4, keep comparisons controlled:

- same base model: `Salesforce/codet5-small`
- same tokenizer
- same prompt grammar and field order
- same training settings where feasible
- same frozen Lean evaluation subset
- same proof-search budget and decoding settings
- same metric scripts

Freeze train, validation, and test subsets before full training starts. Do not change the evaluation subset after training begins unless there is a blocking bug.

## Expected Outputs

The project should produce:

- environment and E0 notes
- dataset and split manifests
- smoke-test logs and summaries
- final E1, E3, and E4 checkpoint inventories
- proof-search JSON results
- pass@1, pass@5, and compilable-tactic metrics
- search diagnostics such as valid tactics per state, early dead-end rate, proof-tree size, branching factor, and average proof-search time
- concise interpretation notes comparing E3 vs E1 and E3 vs E4

The final decision rule is:

- **E3 > E1 and E3 > E4:** evidence for real cross-system transfer.
- **E3 > E1 and E3 ~= E4:** regularization may explain much of the gain.
- **Gains mostly in search metrics:** search calibration is likely central.
