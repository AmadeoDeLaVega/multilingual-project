#!/bin/bash -l
#SBATCH --job-name=proofwala-e0-simple
#SBATCH --account=class
#SBATCH --partition=class
#SBATCH --qos=default
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=02:00:00
#SBATCH --output=/fs/classhomes/adelaveg/multilingual-project/runs/E0/simple-slurm-%j.out

set -euo pipefail

PROJECT_ROOT=/fs/classhomes/adelaveg/multilingual-project
PROOF_WALA_ROOT="${PROJECT_ROOT}/proof-wala"
RUN_ROOT="${PROJECT_ROOT}/runs/E0"
CONDA_ENV="${CONDA_ENV:-proofwala-pilot}"
LEAN_VERSION="${LEAN_VERSION:-4.15.0}"
JOB_TMPDIR="/tmp/${USER}/pw-e0s-${SLURM_JOB_ID:-manual}"
RAY_MEMORY_BYTES=8589934592
RUN_TAG="${SLURM_JOB_ID:-manual-$(date +%Y%m%d-%H%M%S)}"

mkdir -p "${RUN_ROOT}" "${JOB_TMPDIR}"

module load miniforge3/24.3.0
module load cuda/12.4.1 || true

source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "${CONDA_ENV}"

export ROOT="${PROOF_WALA_ROOT}"
export TRANSFORMERS_CACHE="${PROJECT_ROOT}/.hf_cache"
export HF_HOME="${PROJECT_ROOT}/.hf_cache"
export TMPDIR="${JOB_TMPDIR}"
export FOLLOW_SEED=True
export PYTHONUNBUFFERED=1
export PATH="${HOME}/.elan/bin:${PATH}"
export LEAN_VERSION

echo "Host: $(hostname)"
echo "Job: ${SLURM_JOB_ID:-unknown}"
echo "Project root: ${PROJECT_ROOT}"
echo "ProofWala root: ${PROOF_WALA_ROOT}"
echo "Conda env: ${CONDA_DEFAULT_ENV:-unset}"
echo "CUDA_VISIBLE_DEVICES=${CUDA_VISIBLE_DEVICES:-unset}"
python --version
command -v proof-wala-search
command -v proof-wala-init-ray
elan run "leanprover/lean4:v${LEAN_VERSION}" lean --version
nvidia-smi || true

cd "${PROOF_WALA_ROOT}"
rm -f .log/ray/session_latest || true
proof-wala-init-ray \
  --num_cpus "${SLURM_CPUS_PER_TASK:-4}" \
  --object_store_memory "${RAY_MEMORY_BYTES}" \
  --memory "${RAY_MEMORY_BYTES}" \
  --metrics_report_interval_ms 300000000 &
RAY_PID=$!

cleanup() {
  ray stop --force || true
  if kill -0 "${RAY_PID}" 2>/dev/null; then
    kill "${RAY_PID}" || true
  fi
  rm -rf "${JOB_TMPDIR}" || true
}
trap cleanup EXIT

sleep 20

proof-wala-search \
  --config-dir=src/proof_wala/main/config \
  --config-name=eval_simple_lean_test_multilingual_easy.yaml \
  "log_dir=.log/proofs_logs/e0_simple/${RUN_TAG}" \
  "eval_settings.proof_dump_dir=.log/proofs_dumps/e0_simple/${RUN_TAG}" \
  "eval_settings.checkpoint_dir=.log/checkpoints/e0_simple/${RUN_TAG}"
