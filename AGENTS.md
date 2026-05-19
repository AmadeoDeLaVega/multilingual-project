# AGENTS.md

## Project Summary

This repository supports a completed CMSC848T pilot project on why multilingual
training improves ProofWala-style theorem proving.

The main question is whether ProofWala's multilingual gains come from:

- genuine Lean + Rocq cross-language transfer,
- regularization from syntax variation, or
- proof-search behavior.

The final finding is distribution-dependent.  On **Easy_Lean**, the
pseudo-multilingual E4 model is strongest.  On **Hard_Lean**, the real
multilingual E3 model is strongest.

## Final Experiment Set

The completed experiment set is:

- **E0:** sanity-check the environment and proof-search pipeline with the
  released `amitayusht/ProofWala-Multilingual` model.
- **E1:** Lean-only baseline trained from `Salesforce/codet5-small`.
- **E3:** real multilingual Lean+Rocq model trained from
  `Salesforce/codet5-small`.
- **E4:** pseudo-multilingual Lean control trained from
  `Salesforce/codet5-small` using Lean data plus meaning-preserving syntax
  variation.

Released Hugging Face assets are first-class references:

- Dataset: `amitayusht/ProofWalaDataset`
- Lean reference model: `amitayusht/ProofWala-Lean`
- Multilingual reference model: `amitayusht/ProofWala-Multilingual`

## Final Model Artifacts

The final reported E1, E3, and E4 models were trained on Nexus with continuous
approximately 12-hour runs on RTX A5000 GPUs.  Earlier 5000-step smoke and
staged runs were debugging artifacts, not the main reported results.

Final Nexus model directories:

```text
runs/E1/model/pilot-e1-lean-only-34000x1/final
runs/E3/model/pilot-e3-real-multilingual/final
runs/E4/model/pilot-e4-pseudo-multilingual/final
```

Do not commit model weights, checkpoints, Hugging Face caches, or datasets.

## Final Benchmark Names

Use these names in reports, docs, and new analysis:

- **Easy_Lean:** controlled Lean 4 benchmark built for this project.
- **Hard_Lean:** combined miniF2F-derived external Lean benchmark.

Implementation files still use older internal names:

| Final name | Internal names |
|---|---|
| Easy_Lean | `CoreEval.lean`, `core_eval_250.yaml`, `eval_core_eval_250.yaml`, `proof_search_core_eval.sbatch` |
| Hard_Lean | `miniF2F`, `proof_search_minif2f_easy10.sbatch`, `proof_search_minif2f_remaining_9h20.sbatch` |

## Final Results

| Benchmark | Model | Attempted | Proved | Pass rate | Intersection pass rate |
|---|---|---:|---:|---:|---:|
| Easy_Lean | E1 | 127 | 49 | 38.6% | 38.6% |
| Easy_Lean | E3 | 141 | 43 | 30.5% | 30.7% |
| Easy_Lean | E4 | 198 | 126 | 63.6% | 61.4% |
| Hard_Lean | E1 | 77 | 2 | 2.6% | 2.6% |
| Hard_Lean | E3 | 81 | 4 | 4.9% | 5.2% |
| Hard_Lean | E4 | 87 | 3 | 3.4% | 3.9% |

Interpretation:

- Easy_Lean supports the regularization hypothesis: syntax variation helps
  Lean-like proof search.
- Hard_Lean gives suggestive support for cross-language transfer: real
  multilingual Lean+Rocq training helps more on harder external theorem styles.
- The project should not claim a universal winner or a complete explanation.

## Development and Nexus Workflow

All code and documentation changes should be made first in the local checkout:

```bash
~/multilingual-project
```

Cluster runs happen from the Nexus copy:

```bash
/fs/classhomes/<username>/multilingual-project
```

When adding scripts, configs, or code, write and review them locally first, then
sync or pull the changes into the Nexus directory before submitting jobs.  Paths
embedded in Nexus job scripts should resolve relative to the Nexus project
directory.

Each student has their own Nexus class-home project copy and downloads or caches
the ProofWala dataset separately under their own account.

## Reproduction Commands

Download the dataset on Nexus:

```bash
cd /fs/classhomes/<username>/multilingual-project
sbatch scripts/nexus/download_proofwala_dataset.sbatch --user <username>
```

Train the three final models:

```bash
sbatch scripts/nexus/train_e1.sbatch --user <username>
sbatch scripts/nexus/train_e3.sbatch --user <username>
sbatch scripts/nexus/train_e4.sbatch --user <username>
```

Run Easy_Lean proof search:

```bash
sbatch scripts/nexus/proof_search_core_eval.sbatch --user <username>
```

Run Hard_Lean proof search:

```bash
sbatch scripts/nexus/proof_search_minif2f_easy10.sbatch --user <username>
sbatch scripts/nexus/proof_search_minif2f_remaining_9h20.sbatch --user <username>
```

Rebuild local result tables and figures from copied Nexus outputs:

```bash
python3 scripts/eval/build_day8_10_deliverables.py
```

Final copied result roots used for the report:

```text
runs/proof_search_core_eval/6848604
runs/proof_search_minif2f_easy10/6849079
runs/proof_search_minif2f_remaining_9h20/6850148
runs/analysis/day8_10
```

## Nexus Execution Rules

Use Nexus class-cluster policies for training and evaluation:

- Submit GPU jobs through SLURM, not interactive long-running shell processes.
- Use the `class` account and `medium` QoS for main training/evaluation jobs
  unless a script says otherwise.
- Target one RTX A5000 GPU per core training or proof-search array task.
- Monitor jobs with `squeue -u $USER` and `sacct -j <JOBID>`.
- Save logs, summaries, and result JSON files under `runs/`.
- Keep checkpoints limited; only final useful model directories should be
  retained when storage is tight.

## Experiment Discipline

For E1, E3, and E4, keep comparisons controlled:

- same base model: `Salesforce/codet5-small`
- same tokenizer
- same prompt grammar and field order
- same training settings where feasible
- same proof-search budget and decoding settings
- same metric scripts

Do not change benchmark definitions or reported result directories unless
rerunning the whole comparison deliberately.

## What To Commit

Commit:

- source code and scripts
- configs
- benchmark definitions
- frozen manifests
- compact result summaries under `runs/analysis/day8_10`
- copied proof-search result directories needed to reproduce the final tables

Do not commit:

- `data/proofwala_dataset/`
- `.hf_cache/`
- model checkpoints or final model weights
- `*.safetensors`, `*.bin`, `*.pt`, `*.pth`
- large local caches

## Remaining Caveats

- E3 used a practical multilingual-compatible split rather than a perfectly
  token-matched Lean+Rocq mixture.
- E4's pseudo-Lean transformation is conservative and audited, but its very
  large Easy_Lean gain is not fully understood and requires more research.
- The results use one model size and one seed, so they are pilot evidence rather
  than statistically confirmed effects.
