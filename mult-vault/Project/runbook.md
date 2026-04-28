# Runbook

This runbook implements the current `PLAN.md`.

The project now uses [amitayusht/ProofWalaDataset](https://huggingface.co/datasets/amitayusht/ProofWalaDataset) and trains the three core models in parallel:

- **E0**: sanity-check the evaluation stack with released ProofWala-Multilingual
- **E1**: train Lean-only from `Salesforce/codet5-base`
- **E3**: train real multilingual from `Salesforce/codet5-base`
- **E4**: train pseudo-multilingual from `Salesforce/codet5-base`

Released artifacts:

- Dataset: [amitayusht/ProofWalaDataset](https://huggingface.co/datasets/amitayusht/ProofWalaDataset)
- Lean-only reference model: [amitayusht/ProofWala-Lean](https://huggingface.co/amitayusht/ProofWala-Lean)
- Multilingual reference model: [amitayusht/ProofWala-Multilingual](https://huggingface.co/amitayusht/ProofWala-Multilingual)

The released checkpoints are references and fallbacks. The primary comparison should use our freshly trained E1, E3, and E4 checkpoints.

---

## 1. Working Locations

Use two working copies:

```text
Local:
  /home/fall2025/multilingual-project

Nexus:
  /fs/classhomes/<username>/multilingual-project
```

For this project, `<username>` is currently `adelaveg`.

Use GitHub for source control, but keep large artifacts out of Git:

```text
GitHub:
  source code
  scripts
  configs
  small manifests
  notes
  small result summaries

Not GitHub:
  Hugging Face caches
  ProofWalaDataset shards
  checkpoints
  .log/
  runs/
  generated data
  virtual environments
  proof dumps
```

GitHub is useful for code and reproducibility, but it is not runtime storage.

Recommended `.gitignore` entries:

```gitignore
.log/
runs/
data/
checkpoints/
.cache/
wandb/
*.pt
*.bin
*.safetensors
__pycache__/
.venv/
```

---

## 2. Nexus Hardware Plan

Verified live class-account resources:

```text
partition: class
account: class
nodes: tron[06-44,46-61]
tron06-44: RTX A4000, 16GB VRAM, 4 GPUs/node
tron46-61: RTX A5000, 24GB VRAM, 8 GPUs/node
confirmed allocation: NVIDIA RTX A5000, 24564 MiB VRAM, driver 590.48.01
```

QoS limits:

| QoS | Max wall time | Max per job |
|---|---:|---|
| `default` | 3 days | 4 CPU, 1 GPU, 32GB RAM |
| `medium` | 2 days | 8 CPU, 2 GPU, 64GB RAM |
| `high` | 1 day | 16 CPU, 4 GPU, 128GB RAM |

Each student should train one model with:

```bash
#SBATCH --partition=class
#SBATCH --account=class
#SBATCH --qos=medium
#SBATCH --gres=gpu:rtxa5000:1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --time=2-00:00:00
```

Use RTX A4000 only for evaluation or tiny smoke tests. Its 16GB VRAM is likely too tight for comfortable CodeT5-base training.

Useful checks:

```bash
show_partitions
show_qos
show_partition_qos
show_nodes -p class
show_available_nodes --partition class --account class --qos medium --gpus rtxa5000:1
```

Tiny GPU verification:

```bash
srun --partition=class --account=class --qos=default \
  --time=00:02:00 --cpus-per-task=1 --mem=2G \
  --gres=gpu:rtxa5000:1 \
  nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv
```

---

## 3. Environment Setup

Use Python 3.10 or 3.11.

```bash
conda create -n proofwala-pilot python=3.10 -y
conda activate proofwala-pilot
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
```

Install both repos editable:

```bash
cd /fs/classhomes/<username>/multilingual-project/itp-interface
pip install -e .

cd /fs/classhomes/<username>/multilingual-project/proof-wala
pip install -e .
```

Install Lean support as needed:

```bash
install-lean-repl
install-itp-interface
```

Validate inside an allocated GPU job:

```bash
python -c "import torch; print(torch.__version__); print(torch.cuda.is_available())"
python -c "import proof_wala; import itp_interface; print('imports ok')"
lean --version
```

---

## 4. Storage and Caches

Set explicit caches before downloading models or datasets:

```bash
export PROJECT_ROOT=/fs/classhomes/<username>/multilingual-project
export HF_HOME=$PROJECT_ROOT/.hf_cache
export HF_DATASETS_CACHE=$PROJECT_ROOT/.hf_cache/datasets
export TRANSFORMERS_CACHE=$PROJECT_ROOT/.hf_cache/transformers
```

Because class home storage is limited:

- start with reduced ProofWalaDataset shards
- avoid duplicate dataset copies across accounts where possible
- keep only the latest few checkpoints
- remove failed-run checkpoints
- do not commit caches or checkpoints to GitHub
- request class project storage through the TA/instructor if needed

---

## 5. Dataset Plan

Use [amitayusht/ProofWalaDataset](https://huggingface.co/datasets/amitayusht/ProofWalaDataset).

Required:

- **E1:** Lean training split
- **E3 smoke:** ProofWalaDataset `multilingual/train`
- **E3 final:** token-matched Lean+Coq mixture
- **E4:** Lean training split plus synthetic Lean augmentation
- **Evaluation:** one fixed Lean eval/test subset shared by E1, E3, and E4

Create:

```text
data/manifests/dataset_manifest.yaml
data/frozen_splits/split_manifest.yaml
data/eval_subsets/base_eval_subset.txt
data/manifests/token_budget_note.md
```

For the final E3 mixture, record:

- Lean example count
- Coq example count
- estimated token count by source
- sampling rule
- target token budget
- how closely it matches E1 and E4

---

## 6. Pseudo-Multilingual E4 Data

E4 is:

```text
original Lean training data
plus synthetic Lean augmentation
```

Do not replace original Lean data with transformed-only data.

Good transformations:

- consistent variable renaming
- harmless formatting variation
- selected non-semantic local identifier renaming
- theorem-name anonymization only if theorem names are visible in the prompt

Avoid:

- changing proof meaning
- changing hypotheses or goals
- changing mathematical operators
- changing prompt headers
- reordering prompt fields
- unnatural text
- adding real Coq data

Create:

```text
scripts/data/make_pseudo_multilingual.py
data/pseudo_multilingual/
data/pseudo_multilingual/e4_audit.md
```

Before full training, inspect at least 50 transformed examples.

---

## 7. E0 Sanity Check

Use released [ProofWala-Multilingual](https://huggingface.co/amitayusht/ProofWala-Multilingual).

Pattern:

```bash
cd /fs/classhomes/<username>/multilingual-project/proof-wala
proof-wala-init-ray --num_cpus 8 --object_store_memory 8000000000 --memory 16000000000 &
export FOLLOW_SEED=True
proof-wala-search --config-dir=src/proof_wala/main/config --config-name=eval_simple_lean_test_multilingual_easy.yaml
```

Exit condition:

- job completes
- `proof_results.json` exists
- no infrastructure exception

Save:

```text
runs/E0/environment_note.md
runs/E0/proof_results_path.txt
```

---

## 8. Training Plan

All three training runs start from:

```text
Salesforce/codet5-base
```

Use:

- per-device batch size 1
- fp16 or bf16 where supported
- gradient checkpointing
- frequent checkpoint saves
- resume-from-checkpoint support
- reduced subset first

Parallel assignment:

```text
Student 1: E1, Lean-only
Student 2: E3, final token-matched Lean+Coq mixture
Student 3: E4, Lean + pseudo-Lean
```

Expected runtime on one RTX A5000:

| Run | Expected time |
|---|---:|
| E1 | 6-14 hours |
| E3 | 8-18 hours |
| E4 | 8-20 hours |

Run a 100-step calibration first. If 100 steps takes `T` minutes:

```text
5000-step estimate ~= T * 50
```

Record one summary per run:

```text
runs/E1/training_summary.md
runs/E3/training_summary.md
runs/E4/training_summary.md
```

Include job IDs, GPU type, wall-clock time, steps, examples, estimated token budget, final checkpoint path, and restarts/OOMs.

---

## 9. Evaluation

Evaluate all three trained models on the same fixed Lean subset:

- E1: local trained checkpoint
- E3: local trained checkpoint
- E4: local trained checkpoint

Optionally evaluate released ProofWala-Lean and ProofWala-Multilingual as references.

Keep identical:

- eval subset
- proof-search budget
- beam width
- timeout
- prompt format
- metric scripts

Create or update:

```text
proof-wala/src/proof_wala/main/config/pilot_eval_e1.yaml
proof-wala/src/proof_wala/main/config/pilot_eval_e3.yaml
proof-wala/src/proof_wala/main/config/pilot_eval_e4.yaml
```

Save:

```text
runs/E1/eval/
runs/E3/eval/
runs/E4/eval/
reports/tables/base_results.csv
reports/tables/base_results.md
```

---

## 10. Metrics and Diagnostics

Primary metrics:

- `pass@1`
- `pass@5`
- compilable-tactic rate

Secondary metrics:

- next-tactic top-k accuracy
- average valid tactics per state
- early dead-end rate
- proof tree node count
- proof tree edge count
- average branching factor
- average proof search time

Save:

```text
reports/tables/search_diagnostics.csv
reports/tables/search_diagnostics.md
reports/figures/
```

Interpretation:

- E3 > E1 and E3 > E4 supports real cross-system transfer.
- E3 > E1 and E3 ~= E4 supports a regularization or surface-variation explanation.
- Gains mainly in pass@k and compilable-tactic rate support the search-calibration hypothesis.

---

## 11. Reproducibility Package

Required:

- `runs/E0/environment_note.md`
- `data/manifests/dataset_manifest.yaml`
- `data/frozen_splits/split_manifest.yaml`
- `data/manifests/token_budget_note.md`
- `data/pseudo_multilingual/e4_audit.md`
- `runs/E1/training_summary.md`
- `runs/E3/training_summary.md`
- `runs/E4/training_summary.md`
- E1/E3/E4 checkpoint paths
- `reports/tables/base_results.csv`
- `reports/tables/search_diagnostics.csv`
- final figures
- final memo

Keep source code, configs, scripts, docs, and small manifests in GitHub. Keep datasets, checkpoints, logs, proof dumps, and caches out of Git.

---

## 12. Minimum Command Summary

Check Nexus resources:

```bash
show_partitions
show_qos
show_nodes -p class
show_available_nodes --partition class --account class --qos medium --gpus rtxa5000:1
```

Smoke GPU:

```bash
srun --partition=class --account=class --qos=default \
  --time=00:02:00 --cpus-per-task=1 --mem=2G \
  --gres=gpu:rtxa5000:1 nvidia-smi
```

Submit training:

```bash
sbatch scripts/nexus/train_e1.sbatch
sbatch scripts/nexus/train_e3.sbatch
sbatch scripts/nexus/train_e4.sbatch
```

Monitor:

```bash
squeue -u $USER
sacct -j <JOBID>
```

Find JSON outputs:

```bash
find proof-wala/.log/proofs_dumps -name proof_results.json | sort
```

---

## 13. Final Recommendation

Use Nexus first:

- RTX A5000 is adequate for a careful CodeT5-base pilot.
- Three accounts let E1, E3, and E4 train in parallel.
- Keep jobs checkpointed and resumable.
- Keep GitHub clean: code and manifests only.

Rent a 48GB GPU instance only if:

- RTX A5000 OOMs after reasonable memory-saving settings,
- class storage blocks the workflow,
- queue delays become unacceptable,
- or the final run needs more uninterrupted wall time.
