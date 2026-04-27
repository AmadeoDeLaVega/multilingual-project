# Runbook

This runbook explains how to implement the current `PLAN.md` using:

- `~/Desktop/multilingual-project/proof-wala/README.md`
- `~/Desktop/multilingual-project/itp-interface/README.md`
- the UMD NEXUS cluster documentation: <https://wiki.umiacs.umd.edu/umiacs/index.php/Nexus>

It is written for the reduced pilot plan with required experiments:

- **E0**: released multilingual sanity check
- **E1**: Lean-only baseline
- **E3**: real multilingual
- **E4**: pseudo-multilingual

Optional stretch goal:

- **E5a/E5b**: CategoryTheory adaptation

---

## 1. Goal of this runbook

The purpose of this runbook is to turn the project plan into an executable workflow.

It covers:

1. environment setup
2. data preparation
3. split freezing
4. pseudo-multilingual data creation
5. training on NEXUS
6. evaluation and proof search
7. search diagnostics
8. optional adaptation
9. reproducibility and final packaging

The runbook assumes that:

- the project root is `~/Desktop/multilingual-project`
- the two repositories already exist locally:
  - `proof-wala/`
  - `itp-interface/`
- NEXUS will be used for GPU training
- proof search may be run either locally or on NEXUS, but the commands below are written so they can run on NEXUS as well

---

## 2. Directory layout to use

Use the following directories consistently.

```text
~/Desktop/multilingual-project/
├── Background/
├── PLAN.md
├── proof-wala/
├── itp-interface/
├── mult-vault/
│   └── Project/
│       └── runbook.md
├── data/
│   ├── manifests/
│   ├── frozen_splits/
│   ├── generated/
│   ├── pseudo_multilingual/
│   └── eval_subsets/
├── runs/
│   ├── E0/
│   ├── E1/
│   ├── E3/
│   ├── E4/
│   ├── E5a/
│   └── E5b/
├── scripts/
│   ├── nexus/
│   ├── data/
│   └── analysis/
└── reports/
    ├── tables/
    ├── figures/
    └── memo/
```

Create these early and keep them stable.

---

## 3. What each repository is responsible for

### `itp-interface`
Use `itp-interface` for:

- Lean and Coq environment interaction
- building theorem-prover projects
- generating proof-step data

Important config location:

- `~/Desktop/multilingual-project/itp-interface/src/itp_interface/main/configs/`

Examples found there include:

- `mathlib_data_gen.yaml`
- `leandojo_random_data_gen.yaml`
- `math_comp_data_gen.yaml`
- `math_comp_data_gen_random.yaml`
- `compcert_data_gen_train.yaml`
- `compcert_data_gen_test.yaml`
- `category_theory_data_gen.yaml`
- `category_theory_data_gen_random.yaml`
- `geo_coq_data_gen.yaml`

### `proof-wala`
Use `proof-wala` for:

- training proof-step generation models
- proof search evaluation
- proof-tree diagnostics

Important config location:

- `~/Desktop/multilingual-project/proof-wala/src/proof_wala/main/config/`

Relevant configs include:

- training:
  - `mathlib_random_base_experiment.yaml`
  - `multilingual_random_base_experiment.yaml`
  - `further_cat_theory_coq_base_experiment.yaml`
  - `further_cat_theory_multi_base_experiment.yaml`
- evaluation:
  - `eval_simple_lean_test_multilingual.yaml`
  - `eval_leandojo_experiment_lean.yaml`
  - `eval_leandojo_experiment_multilingual.yaml`
  - `eval_category_theory_coq_test.yaml`
  - `eval_category_theory_multilingual_test.yaml`

Entry points from the README:

- training:
  - `proof-wala-train`
  - underlying file: `src/proof_wala/main/run.py`
- proof search:
  - `proof-wala-search`
  - underlying file: `src/proof_wala/main/run_proof_search.py`
- ray init:
  - `proof-wala-init-ray`
  - underlying file: `src/proof_wala/main/init_ray.py`

---

## 4. Mapping the runbook to the plan

### Required experiments

- **E0**: verify end-to-end environment and proof search using a released model
- **E1**: train Lean-only model
- **E3**: train Lean+Coq model
- **E4**: train Lean + pseudo-Lean model

### Optional experiments

- **E5a**: fine-tune E1 on CategoryTheory
- **E5b**: fine-tune E3 on CategoryTheory

### Main scientific comparisons

1. **E3 vs E1**
   - does multilingual training help?
2. **E3 vs E4**
   - is it more than added variation?
3. search metrics across E1/E3/E4
   - does the gain mostly appear through search behavior?

---

## 5. NEXUS cluster workflow

From the NEXUS documentation:

- NEXUS uses **SLURM**
- interactive jobs use `srun`
- batch jobs use `sbatch`
- jobs may require explicit:
  - `--account`
  - `--partition`
  - `--qos`
- resource requests should specify:
  - `--time`
  - `--cpus-per-task`
  - `--mem`
  - `--gres=gpu:<n>`

### 5.1 Before using NEXUS

1. connect to UMD VPN if required
2. SSH into the correct NEXUS submission node
3. check which partitions are available to you

Useful commands:

```bash
show_partitions
show_partitions --all
```

### 5.2 Recommended usage pattern

Use:

- **interactive jobs** for debugging and smoke tests
- **batch jobs** for training runs and longer evaluations

### 5.3 Minimal interactive GPU shell

Use this only for debugging:

```bash
srun --pty \
  --account=<ACCOUNT> \
  --partition=<PARTITION> \
  --qos=<QOS> \
  --time=02:00:00 \
  --cpus-per-task=8 \
  --mem=32G \
  --gres=gpu:1 \
  bash
```

Inside the shell, verify:

```bash
hostname
nvidia-smi
python -c "import torch; print(torch.cuda.is_available())"
```

### 5.4 Recommended batch-job pattern

For all real training runs, use `sbatch` and keep one script per experiment family.

Create scripts in:

- `~/Desktop/multilingual-project/scripts/nexus/`

Suggested files:

- `train_e1.sbatch`
- `train_e3.sbatch`
- `train_e4.sbatch`
- `eval_e0.sbatch`
- `eval_base.sbatch`
- `adapt_e5a.sbatch`
- `adapt_e5b.sbatch`

---

## 6. Environment setup

There are two separate environment needs:

1. Python + PyTorch + ProofWala
2. Lean and Coq interfaces via `itp-interface`

### 6.1 Choose a Python version

Use a standard Python version supported by PyTorch and both repos, for example Python 3.10 or 3.11.

Do **not** use Python 3.14 free-threading for this project unless you have a very specific reason, because:

- `itp-interface` notes that Ray is not supported there
- this project uses ProofWala’s Ray-based proof search

### 6.2 Create the conda environment

On NEXUS or on your working machine:

```bash
conda create -n proofwala-pilot python=3.10 -y
conda activate proofwala-pilot
```

### 6.3 Install PyTorch

Install the correct PyTorch build for the CUDA version available on your assigned NEXUS nodes.

The ProofWala README gives examples such as:

```bash
pip install torch==2.5.0 torchvision==0.20.0 torchaudio==2.5.0 --index-url https://download.pytorch.org/whl/cu124
```

If the NEXUS node uses a different CUDA stack, adapt this accordingly.

### 6.4 Install the repos

Prefer editable installs from the local repository checkout.

```bash
cd ~/Desktop/multilingual-project/itp-interface
pip install -e .

cd ~/Desktop/multilingual-project/proof-wala
pip install -e .
```

### 6.5 Install Lean support

Per `itp-interface` README:

```bash
install-lean-repl
install-itp-interface
```

Important:

- the Lean version must match the project version
- ensure `$HOME/.elan/bin` is in `PATH`
- verify `lean --version`

### 6.6 Install Coq support

Per `itp-interface` README, Coq requires:

- `opam`
- the correct Coq version per project
- correct `coq-lsp` version

The exact supported project setup can depend on the target repository. Also inspect:

- `~/Desktop/multilingual-project/itp-interface/src/itp_interface/main/configs/repo/coq_repos.yaml`

This file is important for matching Coq repos to their required toolchain.

### 6.7 Install graphviz

For proof-tree visualization:

```bash
sudo apt-get install graphviz
```

If sudo is unavailable on NEXUS worker nodes, skip this there and do visualization elsewhere.

### 6.8 Basic validation

Run:

```bash
python -c "import torch; print(torch.__version__); print(torch.cuda.is_available())"
python -c "import proof_wala; import itp_interface; print('imports ok')"
```

---

## 7. Freeze the project manifests early

Before training starts, create four explicit artifacts.

### 7.1 Dataset manifest

Save as:

- `~/Desktop/multilingual-project/data/manifests/dataset_manifest.yaml`

Record:

- source repos used
- which generated datasets are used
- exact file locations
- whether datasets are reused or regenerated
- token counts if already computed

### 7.2 Split manifest

Save as:

- `~/Desktop/multilingual-project/data/frozen_splits/split_manifest.yaml`

Record:

- training split files
- validation split files
- test split files
- reduced fixed evaluation subset used for early evaluation

### 7.3 Experiment manifest

Save as:

- `~/Desktop/multilingual-project/data/manifests/experiment_manifest.yaml`

Include for each experiment:

- experiment ID
- training data source
- config base file
- modified overrides
- output directory
- checkpoint path
- evaluation config(s)

### 7.4 Hardware manifest

Save as:

- `~/Desktop/multilingual-project/data/manifests/hardware_manifest.md`

Record:

- NEXUS account
- partition
- qos
- GPU type
- CUDA version
- node name(s)
- torch version

---

## 8. Data strategy

The plan says: reuse existing extracted data if available.

So the first decision is:

### 8.1 Check whether ProofWala-style data already exists

Look for existing generated proof-step data in either repository or prior project artifacts.

If usable data is already present and consistent with your selected subsets, **reuse it**.

If not, generate only what is necessary for:

- Lean baseline data
- Coq data for E3
- CategoryTheory data only if doing E5

### 8.2 Recommended pilot dataset choices

For a tight two-week pilot:

- **Lean side**: use one Lean dataset family consistently, ideally the random Mathlib/LeanDojo-style setup already reflected by configs such as:
  - `mathlib_random_base_experiment.yaml`
  - `eval_leandojo_experiment_lean.yaml`
- **Coq side**: choose one Coq family only for E3, preferably the one easiest to build and already represented in configs
- **Optional adaptation**: CategoryTheory only if time remains

The key is not broad coverage. The key is a clean controlled comparison.

---

## 9. Generating proof-step data with `itp-interface`

Use this section only if the required data is not already generated.

### 9.1 Build the theorem-prover project first

The `itp-interface` README is explicit: the project must be built before data generation.

#### Lean example

```bash
cd <LEAN_PROJECT_ROOT>
lake build
```

#### Coq example

Build the Coq project with the correct opam switch and dependencies.

Important reminder from the README:

- Coq projects may require different Coq versions
- ensure the correct switch is active before building or generating data

### 9.2 Run data generation

The command pattern is:

```bash
run-itp-data-gen --config-dir src/itp_interface/main/configs --config-name <CONFIG_NAME>
```

Examples from the repo:

```bash
cd ~/Desktop/multilingual-project/itp-interface
run-itp-data-gen --config-dir src/itp_interface/main/configs --config-name mathlib_data_gen
run-itp-data-gen --config-dir src/itp_interface/main/configs --config-name math_comp_data_gen_random
run-itp-data-gen --config-dir src/itp_interface/main/configs --config-name compcert_data_gen_train
run-itp-data-gen --config-dir src/itp_interface/main/configs --config-name category_theory_data_gen_random
```

### 9.3 Save generated data into the project data area

Standardize outputs by copying or symlinking the generated artifacts into:

- `~/Desktop/multilingual-project/data/generated/lean/`
- `~/Desktop/multilingual-project/data/generated/coq/`
- `~/Desktop/multilingual-project/data/generated/category_theory/`

Do not leave the final project dependent on ad hoc scattered outputs.

### 9.4 Validate data before freezing splits

For each dataset, inspect:

- number of examples
- number of theorems
- training/val/test availability
- prompt format consistency
- missing fields
- obvious corrupt records

Save a short audit note in:

- `~/Desktop/multilingual-project/data/manifests/data_audit.md`

---

## 10. Freezing the pilot splits

This is one of the most important steps.

### 10.1 Freeze Lean splits for E1/E4

Create files such as:

- `data/frozen_splits/lean_train.txt`
- `data/frozen_splits/lean_val.txt`
- `data/frozen_splits/lean_test.txt`

### 10.2 Freeze Coq subset for E3

Create:

- `data/frozen_splits/coq_train_for_e3.txt`
- `data/frozen_splits/coq_val_for_e3.txt`

If the pilot only evaluates on Lean, Coq test split is optional.

### 10.3 Freeze reduced evaluation subset

Create one fixed reduced theorem subset for fast iteration:

- `data/eval_subsets/base_eval_subset.txt`

This subset should be used first for all early evaluations.

### 10.4 Match token budgets

The plan requires tight matching across E1, E3, and E4.

Implement this explicitly.

For example:

- choose a target total token budget `T`
- E1 uses Lean-only data totaling about `T`
- E3 uses Lean+Coq totaling about `T`
- E4 uses Lean+pseudo-Lean totaling about `T`

Important clarification:

- E3 should be built as Lean base data plus Coq augmentation
- E4 should be built as Lean base data plus synthetic Lean augmentation
- E4 should not replace the original Lean data with transformed-only data

Also keep matched:

- max steps
- architecture
- tokenizer
- prompt grammar and prompt field order
- batch size policy
- evaluation subset

Create a short note:

- `data/manifests/token_budget_note.md`

This should explain exactly how the matching was done.

---

## 11. Creating pseudo-multilingual data for E4

The plan requires a conservative, meaning-preserving transformation.

### 11.1 Design rule

Do **not** change proof semantics.

Only change surface form in limited ways.

Also:

- keep the original Lean training data
- add synthetic Lean augmentation on top of it
- keep the same prompt grammar as E1 and E3
- do not use prompt-format variation as the main source of augmentation

Because the current ProofWala-style setup often uses `no_steps: True`, prioritize changes that affect the visible proof state or tactic text rather than proof-history context.

### 11.2 Recommended transformations

Apply one or more of these:

1. consistent variable renaming
2. harmless formatting changes
3. consistent renaming of non-semantic local identifiers where safe
4. optional theorem-name anonymization only if theorem names are actually present in the chosen training records

### 11.3 Avoid these transformations

Do not:

- alter tactic meaning
- change hypotheses or goals
- edit mathematical operators
- break parser-sensitive formatting if the downstream code depends on it
- introduce unnatural text that would never appear in real data
- change prompt headers, prompt grammar, or prompt section order

### 11.4 Implementation approach

Create a script:

- `scripts/data/make_pseudo_multilingual.py`

The script should:

1. read frozen Lean training records
2. emit a transformed copy
3. preserve record IDs via a suffix like `_pseudo`
4. write output under:
   - `data/pseudo_multilingual/lean_pseudo_train.*`

Then build the final E4 training mixture as:

- original Lean training data
- plus the generated pseudo-Lean augmentation

### 11.5 Validation of E4 data

Before training E4, inspect a sample of at least 50 transformed examples.

Check:

- semantics appear unchanged
- prompts still look natural
- no broken fields or encoding issues

Save this audit in:

- `data/pseudo_multilingual/e4_audit.md`

Also record:

- whether the transformed examples still parse
- whether the prompt grammar is unchanged
- whether the final E4 mixture matches the planned token budget

---

## 12. Training design

### 12.1 Model choice

Per the plan:

- use one ProofWala-compatible seq2seq model for all experiments
- recommended:
  - `CodeT5-small`, or
  - `CodeT5-base` with reduced budget

### 12.2 Base configs to use

Use existing ProofWala configs as starting points instead of building everything from scratch.

Recommended starting points:

- **E1** Lean-only baseline:
  - start from `mathlib_random_base_experiment.yaml`
- **E3** real multilingual:
  - start from `multilingual_random_base_experiment.yaml`
- **E4** pseudo-multilingual:
  - duplicate the E1 training config and point the training data to Lean + pseudo-Lean mixture
- **E5a/E5b** optional adaptation:
  - start from
    - `further_cat_theory_coq_base_experiment.yaml` and/or
    - `further_cat_theory_multi_base_experiment.yaml`
  - but adapt them to your actual E1/E3 checkpoints

### 12.3 Create experiment-specific config copies

Do not edit upstream configs directly.

Create local copies such as:

- `proof-wala/src/proof_wala/main/config/pilot_e1.yaml`
- `proof-wala/src/proof_wala/main/config/pilot_e3.yaml`
- `proof-wala/src/proof_wala/main/config/pilot_e4.yaml`
- `proof-wala/src/proof_wala/main/config/pilot_e5a.yaml`
- `proof-wala/src/proof_wala/main/config/pilot_e5b.yaml`

Document at the top of each file:

- which base config it came from
- what was changed
- the intended experiment ID

### 12.4 Things to keep matched across E1/E3/E4

Keep these identical unless there is a strong reason otherwise:

- model architecture
- tokenizer
- prompt grammar
- prompt field order
- max sequence lengths
- optimizer settings
- scheduler
- max steps
- save steps
- eval steps
- batch size policy
- random seed policy

Only the dataset composition should differ.

---

## 13. NEXUS training scripts

### 13.1 Use SLURM batch jobs

Make one sbatch script per required training run.

A minimal template:

```bash
#!/bin/bash
#SBATCH --job-name=e1-proofwala
#SBATCH --account=<ACCOUNT>
#SBATCH --partition=<PARTITION>
#SBATCH --qos=<QOS>
#SBATCH --gres=gpu:2
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --time=24:00:00
#SBATCH --output=/home/%u/Desktop/multilingual-project/runs/E1/slurm-%j.out

set -euo pipefail
source ~/.bashrc
conda activate proofwala-pilot

cd ~/Desktop/multilingual-project/proof-wala
export ROOT=~/Desktop/multilingual-project/proof-wala
export TRANSFORMERS_CACHE=~/Desktop/multilingual-project/.hf_cache

torchrun --nproc-per-node 2 --master-port 31052 \
  proof-wala-train \
  --config-dir=src/proof_wala/main/config \
  --config-name=pilot_e1.yaml
```

### 13.2 Why this matches the repo README

This follows the README’s training pattern:

```bash
torchrun --nproc-per-node 2 --master-port 31052 proof-wala-train --config-dir=src/proof_wala/main/config --config-name multilingual_random_base_experiment.yaml
```

### 13.3 Use the provided scripts only as reference

The repo contains:

- `per_node_job.sh`
- `tacc_slurm.sh`

These are useful examples of distributed training structure, but they are cluster-specific and should not be copied blindly to NEXUS.

For NEXUS, write simpler SLURM scripts targeted to your actual account/partition/qos.

### 13.4 Launch commands

Submit jobs with:

```bash
sbatch scripts/nexus/train_e1.sbatch
sbatch scripts/nexus/train_e3.sbatch
sbatch scripts/nexus/train_e4.sbatch
```

Monitor with:

```bash
squeue -u $USER
sacct -j <JOBID>
```

---

## 14. E0: released multilingual sanity check

This is Day 1 priority.

### 14.1 Goal

Verify that:

- environment works
- proof search works
- model loading works
- Lean project build works
- outputs are written correctly

### 14.2 Steps

1. build the relevant Lean project
2. start Ray
3. run a small eval config using a released multilingual model

### 14.3 Start Ray

Per README:

```bash
proof-wala-init-ray --num_cpus 20 --object_store_memory 53687091200 --memory 53687091200 --metrics_report_interval_ms 300000000 &
```

Important note from README:

- delete `.log/ray/session_latest` if you want a fresh Ray session

### 14.4 Build the project

Example from README:

```bash
cd src/proof_wala/data/proofs/lean/lean4_proj
lake build
```

In your actual pilot, build the project required by the chosen eval config.

### 14.5 Run E0 proof search

Pattern from README:

```bash
export FOLLOW_SEED="True"
export CUDA_VISIBLE_DEVICES="0,1"
proof-wala-search --config-dir=src/proof_wala/main/config --config-name=eval_simple_lean_test_multilingual.yaml
```

For the pilot, prefer a small eval config or reduced eval subset.

### 14.6 Exit condition

Do not move on to training until E0 completes successfully end to end.

Save outputs under:

- `runs/E0/`

Also write:

- `runs/E0/environment_note.md`

---

## 15. E1, E3, E4 training sequence

### 15.1 E1: Lean-only baseline

Use `pilot_e1.yaml`.

Training command pattern:

```bash
cd ~/Desktop/multilingual-project/proof-wala
torchrun --nproc-per-node 2 --master-port 31052 \
  proof-wala-train \
  --config-dir=src/proof_wala/main/config \
  --config-name=pilot_e1.yaml
```

Outputs:

- checkpoint(s) -> `runs/E1/` or configured save directory
- training log -> `runs/E1/train.log`
- summary note -> `runs/E1/training_summary.md`

### 15.2 E3: real multilingual

Use `pilot_e3.yaml`.

Same training recipe, same budget.

Data composition should be:

- Lean base data
- plus Coq augmentation

Command:

```bash
cd ~/Desktop/multilingual-project/proof-wala
torchrun --nproc-per-node 2 --master-port 31053 \
  proof-wala-train \
  --config-dir=src/proof_wala/main/config \
  --config-name=pilot_e3.yaml
```

### 15.3 E4: pseudo-multilingual

Use `pilot_e4.yaml`.

Data composition should be:

- Lean base data
- plus synthetic Lean augmentation

Do not point E4 to transformed-only Lean data.

Command:

```bash
cd ~/Desktop/multilingual-project/proof-wala
torchrun --nproc-per-node 2 --master-port 31054 \
  proof-wala-train \
  --config-dir=src/proof_wala/main/config \
  --config-name=pilot_e4.yaml
```

### 15.4 During training, record these for all runs

- effective token budget
- step count
- wall-clock time
- GPUs used
- final validation loss
- checkpoint path

If there is any unavoidable mismatch across E1, E3, and E4, write it down explicitly instead of leaving it implicit.

Write one summary file per run:

- `runs/E1/training_summary.md`
- `runs/E3/training_summary.md`
- `runs/E4/training_summary.md`

---

## 16. Smoke tests before long training

Before running full jobs, do a short smoke test for E1/E3/E4.

### 16.1 What to test

- config loads correctly
- model starts training
- checkpoint save works
- validation runs
- logs appear in expected directory
- step matching behaves as expected
- E4 sample data still looks natural and parseable

### 16.2 How

Either:

- make temporary smoke-test configs with very small max steps
- or use Hydra overrides at launch time

Example pattern:

```bash
proof-wala-train --config-dir=src/proof_wala/main/config --config-name=pilot_e1.yaml training_settings.training_args.max_steps=20 training_settings.training_args.save_steps=10 training_settings.training_args.eval_steps=10
```

Save smoke test outputs under:

- `runs/smoke/`

Also save:

- `runs/smoke/e4_sample_audit.md`

---

## 17. Base evaluation after training

This is Day 8 in the plan.

### 17.1 What to evaluate first

Use the same reduced fixed theorem subset for all three models:

- E1
- E3
- E4

### 17.2 Evaluation config strategy

Create pilot eval configs rather than editing large upstream configs directly.

Suggested files:

- `pilot_eval_e1.yaml`
- `pilot_eval_e3.yaml`
- `pilot_eval_e4.yaml`

Each should specify:

- model checkpoint path
- same eval subset
- same search budget
- same beam width
- same timeout

### 17.3 Start Ray if needed

```bash
proof-wala-init-ray --num_cpus 20 --object_store_memory 53687091200 --memory 53687091200 --metrics_report_interval_ms 300000000 &
```

### 17.4 Run proof search

Pattern:

```bash
cd ~/Desktop/multilingual-project/proof-wala
export FOLLOW_SEED="True"
export CUDA_VISIBLE_DEVICES="0,1"
proof-wala-search --config-dir=src/proof_wala/main/config --config-name=pilot_eval_e1.yaml
proof-wala-search --config-dir=src/proof_wala/main/config --config-name=pilot_eval_e3.yaml
proof-wala-search --config-dir=src/proof_wala/main/config --config-name=pilot_eval_e4.yaml
```

### 17.5 Save outputs

Save all raw eval outputs under:

- `runs/E1/eval/`
- `runs/E3/eval/`
- `runs/E4/eval/`

Also create:

- `reports/tables/base_results.csv`
- `reports/tables/base_results.md`

---

## 18. Metrics to compute

### 18.1 Primary metrics

The plan prioritizes:

- `pass@1`
- `pass@5`
- compilable tactic rate

### 18.2 Secondary metrics

Also compute:

- next-tactic top-k accuracy
- average valid tactics per state
- early dead-end rate
- proof tree node count
- proof tree edge count
- average branching factor
- average proof search time

### 18.3 Metric interpretation

Use the project interpretation template:

- if E3 beats E1 and E4, that supports structural transfer
- if E3 is close to E4, regularization may explain much of the gain
- if gains appear mainly on pass@k and compilable tactic rate, search calibration is likely important

Before making those claims, compare the results against the token-budget and step-matching notes.

---

## 19. Search diagnostics

This is where the plan keeps the “tactic diversification / better branching” idea alive.

### 19.1 Diagnostics to compute

From the raw proof-search artifacts, compute:

1. average valid tactics per state
2. early dead-end rate
3. node count per proof tree
4. edge count per proof tree
5. branching factor
6. time to first proof
7. number of successful proofs per theorem, if available

### 19.2 Save these in

- `reports/tables/search_diagnostics.csv`
- `reports/tables/search_diagnostics.md`

### 19.3 Plot suggestions

Create:

- pass@1 / pass@5 bar chart
- compilable tactic rate bar chart
- branching factor comparison chart
- early dead-end comparison chart

Save plots under:

- `reports/figures/`

---

## 20. Optional CategoryTheory adaptation

Only do this if E0/E1/E3/E4 are already stable.

### 20.1 Goal

Compare:

- **E5a**: E1 checkpoint -> CategoryTheory fine-tuning
- **E5b**: E3 checkpoint -> CategoryTheory fine-tuning

### 20.2 Config starting points

Use these as references:

- `further_cat_theory_coq_base_experiment.yaml`
- `further_cat_theory_multi_base_experiment.yaml`

But adapt them so that:

- E5a starts from the E1 checkpoint
- E5b starts from the E3 checkpoint
- both use the same CategoryTheory subset
- both use the same fine-tuning budget

### 20.3 Commands

Pattern:

```bash
torchrun --nproc-per-node 2 --master-port 31055 \
  proof-wala-train \
  --config-dir=src/proof_wala/main/config \
  --config-name=pilot_e5a.yaml

torchrun --nproc-per-node 2 --master-port 31056 \
  proof-wala-train \
  --config-dir=src/proof_wala/main/config \
  --config-name=pilot_e5b.yaml
```

### 20.4 Evaluation

Use pilot eval configs modeled after:

- `eval_category_theory_coq_test.yaml`
- `eval_category_theory_multilingual_test.yaml`

Save:

- `reports/tables/adaptation_results.csv`
- `reports/figures/adaptation_comparison.png`

---

## 21. Recommended implementation order

### Day 1

1. build environment
2. verify Lean and Coq support
3. run E0 sanity check
4. record environment note

### Day 2

1. finalize data sources
2. freeze splits
3. define E3 as Lean base plus Coq augmentation
4. define E4 as Lean base plus synthetic Lean augmentation
5. freeze prompt grammar and prompt field order
6. write manifests and budget note

### Day 3

1. create pilot configs
2. generate and inspect an E4 sample
3. run smoke tests for E1/E3/E4
4. fix any config or path errors

### Days 4-5

1. train E1
2. record actual step count and token budget
3. archive checkpoint path and logs

### Days 6-7

1. train E3
2. train E4
3. verify budget matching
4. archive checkpoint paths and logs

### Day 8

1. evaluate E1/E3/E4 on reduced subset
2. compute base results
3. write preliminary interpretation note

### Days 9-10

1. compute search diagnostics
2. make figures
3. clean final tables

### Days 11-12 optional

1. run E5a and E5b
2. evaluate adaptation

### Day 13

1. draft memo

### Day 14

1. archive configs
2. archive commands
3. archive splits and outputs
4. package reproducibility materials

---

## 22. Reproducibility checklist

Before closing the project, verify that the following exist.

### Required

- frozen dataset manifest
- frozen split manifest
- token budget note
- E4 generation note
- E0 environment note
- E1 checkpoint path and training summary
- E3 checkpoint path and training summary
- E4 checkpoint path and training summary
- base results table
- search diagnostics table
- final figures
- short memo

### Optional

- E5a summary
- E5b summary
- adaptation results table

---

## 23. Things to watch carefully

### 23.1 Biggest technical risk

Coq environment setup can consume a lot of time.

Mitigation:

- prefer reusing already generated Coq data if possible
- keep the Coq contribution to E3 as simple as possible
- do not broaden Coq repo coverage during the pilot

### 23.2 Biggest scientific risk

Failing to match token budgets across E1/E3/E4.

Mitigation:

- write the token-budget note before full training starts
- freeze the prompt grammar before full training starts
- keep the comparison tight and explicit

### 23.3 Biggest E4 risk

Pseudo-multilingual transformation accidentally changes semantics or makes prompts unnatural.

Mitigation:

- keep transformations conservative
- inspect samples manually
- record an audit note
- do not use prompt-format changes as the augmentation

### 23.4 Biggest evaluation risk

Search takes too long on the full benchmark.

Mitigation:

- first run on the reduced fixed subset
- only scale up if the trend is already visible

---

## 24. Minimum viable command summary

### E0 sanity check

```bash
cd ~/Desktop/multilingual-project/proof-wala
proof-wala-init-ray --num_cpus 20 --object_store_memory 53687091200 --memory 53687091200 --metrics_report_interval_ms 300000000 &
export FOLLOW_SEED="True"
export CUDA_VISIBLE_DEVICES="0,1"
proof-wala-search --config-dir=src/proof_wala/main/config --config-name=eval_simple_lean_test_multilingual.yaml
```

### Generate data if needed

```bash
cd ~/Desktop/multilingual-project/itp-interface
run-itp-data-gen --config-dir src/itp_interface/main/configs --config-name mathlib_data_gen
run-itp-data-gen --config-dir src/itp_interface/main/configs --config-name compcert_data_gen_train
```

### Train

```bash
cd ~/Desktop/multilingual-project/proof-wala
torchrun --nproc-per-node 2 --master-port 31052 proof-wala-train --config-dir=src/proof_wala/main/config --config-name=pilot_e1.yaml
torchrun --nproc-per-node 2 --master-port 31053 proof-wala-train --config-dir=src/proof_wala/main/config --config-name=pilot_e3.yaml
torchrun --nproc-per-node 2 --master-port 31054 proof-wala-train --config-dir=src/proof_wala/main/config --config-name=pilot_e4.yaml
```

### Evaluate

```bash
cd ~/Desktop/multilingual-project/proof-wala
proof-wala-search --config-dir=src/proof_wala/main/config --config-name=pilot_eval_e1.yaml
proof-wala-search --config-dir=src/proof_wala/main/config --config-name=pilot_eval_e3.yaml
proof-wala-search --config-dir=src/proof_wala/main/config --config-name=pilot_eval_e4.yaml
```

---

## 25. Final recommendation

The most important thing is not breadth. It is discipline.

If you finish the project with:

- one clean Lean baseline
- one clean real multilingual model
- one clean pseudo-multilingual control
- matched budget
- shared prompt grammar
- shared eval subset
- good search diagnostics

then the pilot will have done its job.

That is enough to say something meaningful about whether multilingual gains in ProofWala are more likely due to:

- true cross-system transfer, or
- regularization from added variation.
