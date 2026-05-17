# Multilingual ProofWala Pilot

This repository supports a pilot experiment on why multilingual training helps
ProofWala-style theorem proving. The main comparison trains three CodeT5-small
models under the same prompt format and evaluation subset:

- **E1:** Lean-only baseline.
- **E3:** real multilingual model.
- **E4:** pseudo-multilingual Lean control.

Released assets used by the project:

- Dataset: `amitayusht/ProofWalaDataset`
- Base model for all primary runs: `Salesforce/codet5-small`
- Reference models: `amitayusht/ProofWala-Lean`,
  `amitayusht/ProofWala-Multilingual`

## Workflow

Edit code locally first:

```bash
~/multilingual-project
```

Run training and evaluation on Nexus:

```bash
/fs/classhomes/<username>/multilingual-project
```

Replace `<username>` with your Nexus username in the commands below.

## Data Setup

On Nexus, download the ProofWala dataset:

```bash
cd /fs/classhomes/<username>/multilingual-project
sbatch scripts/nexus/download_proofwala_dataset.sbatch --user <username>
```

Freeze the shared Lean evaluation/test refs if they are not already present:

```bash
python3 scripts/data/freeze_pilot_splits.py \
  --dataset-root data/proofwala_dataset/ProofWalaDataset \
  --output-dir data/frozen_splits
```

The training scripts materialize these derived directories when needed:

- E1: `data/frozen_splits/e1_lean_train_compat`
- E3: `data/frozen_splits/e3_multilingual_train_compat`
- E4: `data/pseudo_multilingual/e4_train`
- shared eval: `data/frozen_splits/lean_eval_1000`

## Training

Current long-run scripts use:

- one RTX A5000 GPU
- `medium` QoS
- `12:00:00` wall time
- `MAX_STEPS=240000`
- `SAVE_STEPS=60000`
- `save_only_model=True`
- `save_total_limit=1`

Submit the three main trainings:

```bash
cd /fs/classhomes/<username>/multilingual-project

sbatch scripts/nexus/train_e1.sbatch --user <username>
sbatch scripts/nexus/train_e3.sbatch --user <username>
sbatch scripts/nexus/train_e4.sbatch --user <username>
```

Expected final model directories:

```text
runs/E1/model/pilot-e1-lean-only-34000x1/final
runs/E3/model/pilot-e3-real-multilingual/final
runs/E4/model/pilot-e4-pseudo-multilingual/final
```

Monitor jobs:

```bash
squeue -u <username>
sacct -j <jobid> --format=JobID,JobName%24,State,ExitCode,Elapsed,MaxRSS
tail -f runs/E1/slurm-<jobid>.out
```

## Next-Step Diagnostics

Run diagnostics on the frozen Lean eval subset:

```bash
cd /fs/classhomes/<username>/multilingual-project

sbatch scripts/nexus/eval_model_diagnostics.sbatch \
  --experiment E1 \
  --user <username> \
  --model /fs/classhomes/<username>/multilingual-project/runs/E1/model/pilot-e1-lean-only-34000x1/final \
  --output /fs/classhomes/<username>/multilingual-project/runs/E1/diagnostics/e1_model_diagnostics.json

sbatch scripts/nexus/eval_model_diagnostics.sbatch \
  --experiment E3 \
  --user <username> \
  --model /fs/classhomes/<username>/multilingual-project/runs/E3/model/pilot-e3-real-multilingual/final \
  --output /fs/classhomes/<username>/multilingual-project/runs/E3/diagnostics/e3_final_diagnostics.json

sbatch scripts/nexus/eval_model_diagnostics.sbatch \
  --experiment E4 \
  --user <username> \
  --model /fs/classhomes/<username>/multilingual-project/runs/E4/model/pilot-e4-pseudo-multilingual/final \
  --output /fs/classhomes/<username>/multilingual-project/runs/E4/diagnostics/e4_final_diagnostics.json
```

These diagnostics report strict exact match, normalized exact match, parseable
output rate, and mean eval loss.

## Proof-Search Metrics

Run the same proof-search smoke fixture for each model. The default fixture is
`eval_simple_lean_test_multilingual_easy.yaml`, which targets an unfinished
`sorry` theorem in `Lean4Proj/Basic.lean`; do not use already-completed Lean
theorems for this check, because ProofWala will see no active goals and skip the
model.

```bash
cd /fs/classhomes/<username>/multilingual-project

sbatch --qos=medium scripts/nexus/proof_search_smoke.sbatch \
  --experiment E1 \
  --user <username> \
  --model /fs/classhomes/<username>/multilingual-project/runs/E1/model/pilot-e1-lean-only-34000x1/final

sbatch --qos=medium scripts/nexus/proof_search_smoke.sbatch \
  --experiment E3 \
  --user <username> \
  --model /fs/classhomes/<username>/multilingual-project/runs/E3/model/pilot-e3-real-multilingual/final

sbatch --qos=medium scripts/nexus/proof_search_smoke.sbatch \
  --experiment E4 \
  --user <username> \
  --model /fs/classhomes/<username>/multilingual-project/runs/E4/model/pilot-e4-pseudo-multilingual/final
```

Each proof-search run writes:

```text
runs/<EXPERIMENT>/proof_search/<jobid>/proof_search_metrics.json
runs/<EXPERIMENT>/proof_search/<jobid>/proof_search_metrics.md
runs/<EXPERIMENT>/proof_search/<jobid>/summary.md
```

Metrics include pass rate, theorem timeouts, generated-tactic parseability,
accepted-action rate, no-start-goal rate, proof-tree size, and branching stats.

## Combined Summary

After diagnostics and proof-search runs finish, generate comparison tables:

```bash
cd /fs/classhomes/<username>/multilingual-project

/fs/classhomes/<username>/.conda/envs/proofwala-pilot/bin/python \
  scripts/eval/summarize_model_metrics.py \
  --project-root /fs/classhomes/<username>/multilingual-project \
  --output-dir /fs/classhomes/<username>/multilingual-project/runs/metrics
```

Outputs:

```text
runs/metrics/model_metrics_summary.md
runs/metrics/model_metrics_summary.csv
```

## Notes

Large artifacts should not be committed:

- `data/proofwala_dataset/`
- `.hf_cache/`
- `runs/`
- model checkpoints

If storage is tight, delete failed-run model directories and stale checkpoints,
but keep final model directories needed for evaluation.
