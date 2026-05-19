# Multilingual ProofWala Pilot

This repository contains the code, configs, benchmark definitions, and copied
evaluation summaries for a CMSC848T pilot project on why multilingual training
helps ProofWala-style theorem proving.

The final comparison trains three `Salesforce/codet5-small` models with the same
prompt format and proof-search pipeline:

- **E1:** Lean-only baseline.
- **E3:** real multilingual Lean+Rocq model.
- **E4:** pseudo-multilingual Lean control with meaning-preserving syntax
  variation.

The main question is whether multilingual gains come from real cross-language
transfer, from regularization due to syntax variation, or from proof-search
behavior.

## Final Benchmarks

The report uses two benchmark names:

- **Easy_Lean:** controlled Lean 4 benchmark built for this project.  Its source
  file is `proof-wala/src/proof_wala/data/proofs/lean/lean4_proj/Lean4Proj/CoreEval.lean`.
- **Hard_Lean:** combined miniF2F-derived Lean benchmark, using the deterministic
  easy-10 subset plus the remaining 9h20 run.

The old internal filenames still contain `core_eval` and `minif2f`; the paper and
presentation call them `Easy_Lean` and `Hard_Lean`.

## Final Result

The result is distribution-dependent.

| Benchmark | Best model | Interpretation |
|---|---|---|
| Easy_Lean | E4 | Syntax variation helps strongly on Lean-like in-project theorem patterns. |
| Hard_Lean | E3 | Real multilingual training is most useful on harder external theorem styles. |

Main proof-search results:

| Benchmark | Model | Attempted | Proved | Pass rate | Shared-intersection pass rate |
|---|---|---:|---:|---:|---:|
| Easy_Lean | E1 | 127 | 49 | 38.6% | 38.6% |
| Easy_Lean | E3 | 141 | 43 | 30.5% | 30.7% |
| Easy_Lean | E4 | 198 | 126 | 63.6% | 61.4% |
| Hard_Lean | E1 | 77 | 2 | 2.6% | 2.6% |
| Hard_Lean | E3 | 81 | 4 | 4.9% | 5.2% |
| Hard_Lean | E4 | 87 | 3 | 3.4% | 3.9% |

## Local and Nexus Workflow

Edit locally:

```bash
cd ~/multilingual-project
```

Run training and proof search on Nexus:

```bash
cd /fs/classhomes/<username>/multilingual-project
```

Replace `<username>` with your Nexus username.  Scripts are written to accept:

```bash
sbatch scripts/nexus/<script>.sbatch --user <username>
```

## Dataset Setup

Each Nexus user downloads the dataset separately under their own project copy:

```bash
cd /fs/classhomes/<username>/multilingual-project
sbatch scripts/nexus/download_proofwala_dataset.sbatch --user <username>
```

The dataset comes from Hugging Face:

- `amitayusht/ProofWalaDataset`

Large dataset files and Hugging Face caches are intentionally not committed.

## Training E1, E3, and E4

The final models were trained on Nexus with one RTX A5000 GPU per job and an
approximately 12-hour wall-time budget:

```bash
cd /fs/classhomes/<username>/multilingual-project

sbatch scripts/nexus/train_e1.sbatch --user <username>
sbatch scripts/nexus/train_e3.sbatch --user <username>
sbatch scripts/nexus/train_e4.sbatch --user <username>
```

Expected final model directories on Nexus:

```text
runs/E1/model/pilot-e1-lean-only-34000x1/final
runs/E3/model/pilot-e3-real-multilingual/final
runs/E4/model/pilot-e4-pseudo-multilingual/final
```

Monitor jobs with:

```bash
squeue -u <username>
sacct -j <jobid> --format=JobID,JobName%24,State,ExitCode,Elapsed,MaxRSS
```

## Running Proof Search

### Easy_Lean

Run all three models as a SLURM array:

```bash
cd /fs/classhomes/<username>/multilingual-project
sbatch scripts/nexus/proof_search_core_eval.sbatch --user <username>
```

The script writes one result directory per model:

```text
runs/proof_search_core_eval/<jobid>/E1/
runs/proof_search_core_eval/<jobid>/E3/
runs/proof_search_core_eval/<jobid>/E4/
```

### Hard_Lean

Run the deterministic miniF2F easy-10 subset:

```bash
sbatch scripts/nexus/proof_search_minif2f_easy10.sbatch --user <username>
```

Run the remaining miniF2F-derived set:

```bash
sbatch scripts/nexus/proof_search_minif2f_remaining_9h20.sbatch --user <username>
```

These scripts write:

```text
runs/proof_search_minif2f_easy10/<jobid>/<EXPERIMENT>/
runs/proof_search_minif2f_remaining_9h20/<jobid>/<EXPERIMENT>/
```

## Rebuilding the Result Tables

The copied final result directories used for the report are:

```text
runs/proof_search_core_eval/6848604
runs/proof_search_minif2f_easy10/6849079
runs/proof_search_minif2f_remaining_9h20/6850148
```

Regenerate the final tables, figures, and internal memo locally with:

```bash
python3 scripts/eval/build_day8_10_deliverables.py
```

Outputs are written to:

```text
runs/analysis/day8_10/
```

Important files:

```text
runs/analysis/day8_10/internal_memo.md
runs/analysis/day8_10/analysis_payload.json
runs/analysis/day8_10/tables/
runs/analysis/day8_10/figures/
```

## What Is Committed

Commit source code, configs, benchmark definitions, frozen manifests, and compact
result summaries.  Do not commit datasets, caches, model checkpoints, or large
model weights.

The benchmark definitions and copied result summaries are intentionally allowed
by `.gitignore`; model files such as `*.safetensors` remain ignored.
