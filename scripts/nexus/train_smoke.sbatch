#!/bin/bash -l
#SBATCH --job-name=proofwala-smoke
#SBATCH --account=class
#SBATCH --partition=class
#SBATCH --qos=default
#SBATCH --gres=gpu:rtxa5000:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=04:00:00
#SBATCH --output=proofwala-smoke-%j.out

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  sbatch scripts/nexus/train_smoke.sbatch --experiment E1 [--user USERNAME]
  sbatch scripts/nexus/train_smoke.sbatch --experiment E3 [--adelaveg]
  sbatch scripts/nexus/train_smoke.sbatch --experiment E4

Environment overrides:
  NEXUS_USER=adelaveg sbatch scripts/nexus/train_smoke.sbatch --experiment E1
  PROJECT_ROOT=/fs/classhomes/adelaveg/multilingual-project sbatch scripts/nexus/train_smoke.sbatch --experiment E1
  CONDA_ENV=proofwala-pilot sbatch scripts/nexus/train_smoke.sbatch --experiment E1
EOF
}

NEXUS_USER="${NEXUS_USER:-${USER:-}}"
SMOKE_EXPERIMENT="${SMOKE_EXPERIMENT:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --experiment)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for $1" >&2
        usage >&2
        exit 2
      fi
      SMOKE_EXPERIMENT="$2"
      shift 2
      ;;
    --experiment=*)
      SMOKE_EXPERIMENT="${1#*=}"
      shift
      ;;
    --user|--username)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for $1" >&2
        usage >&2
        exit 2
      fi
      NEXUS_USER="$2"
      shift 2
      ;;
    --user=*|--username=*)
      NEXUS_USER="${1#*=}"
      shift
      ;;
    --*)
      NEXUS_USER="${1#--}"
      shift
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "${NEXUS_USER}" || ! "${NEXUS_USER}" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "Invalid or empty NEXUS username: ${NEXUS_USER}" >&2
  exit 2
fi

case "${SMOKE_EXPERIMENT}" in
  E1|e1)
    SMOKE_EXPERIMENT="E1"
    CONFIG_NAME="smoke_e1.yaml"
    ;;
  E3|e3)
    SMOKE_EXPERIMENT="E3"
    CONFIG_NAME="smoke_e3.yaml"
    ;;
  E4|e4)
    SMOKE_EXPERIMENT="E4"
    CONFIG_NAME="smoke_e4.yaml"
    ;;
  *)
    echo "Invalid --experiment '${SMOKE_EXPERIMENT}'. Expected E1, E3, or E4." >&2
    usage >&2
    exit 2
    ;;
esac

PROJECT_ROOT="${PROJECT_ROOT:-/fs/classhomes/${NEXUS_USER}/multilingual-project}"
PROOF_WALA_ROOT="${PROJECT_ROOT}/proof-wala"
RUN_ROOT="${PROJECT_ROOT}/runs/smoke/${SMOKE_EXPERIMENT}"
CONDA_ENV="${CONDA_ENV:-proofwala-pilot}"
JOB_TMPDIR="/tmp/${USER}/pw-smoke-${SMOKE_EXPERIMENT}-${SLURM_JOB_ID:-manual}"

mkdir -p "${RUN_ROOT}" "${JOB_TMPDIR}"
exec > "${RUN_ROOT}/slurm-${SLURM_JOB_ID:-manual}.out" 2>&1

module load miniforge3/24.3.0
module load cuda/12.4.1 || true

source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "${CONDA_ENV}"

export ROOT="${PROJECT_ROOT}"
export HF_HOME="${PROJECT_ROOT}/.hf_cache"
export HF_DATASETS_CACHE="${PROJECT_ROOT}/.hf_cache/datasets"
export TRANSFORMERS_CACHE="${PROJECT_ROOT}/.hf_cache/transformers"
export COMET_MODE=DISABLED
export TMPDIR="${JOB_TMPDIR}"
export RAY_TMPDIR="${JOB_TMPDIR}/ray"
export RAY_NUM_CPUS="${SLURM_CPUS_PER_TASK:-4}"
export RAY_OBJECT_STORE_MEMORY="$((8 * 1024 * 1024 * 1024))"
export RAY_MEMORY="$((16 * 1024 * 1024 * 1024))"
export PROOFWALA_SKIP_MODEL_SAVE=1
export PYTHONUNBUFFERED=1

echo "Host: $(hostname)"
echo "Job: ${SLURM_JOB_ID:-unknown}"
echo "NEXUS user: ${NEXUS_USER}"
echo "Project root: ${PROJECT_ROOT}"
echo "ProofWala root: ${PROOF_WALA_ROOT}"
echo "Smoke experiment: ${SMOKE_EXPERIMENT}"
echo "Config: ${CONFIG_NAME}"
echo "Conda env: ${CONDA_DEFAULT_ENV:-unset}"
echo "CUDA_VISIBLE_DEVICES=${CUDA_VISIBLE_DEVICES:-unset}"
python --version
command -v proof-wala-train
nvidia-smi || true

cd "${PROOF_WALA_ROOT}"

set +e
proof-wala-train \
  --config-dir=src/proof_wala/main/config \
  --config-name="${CONFIG_NAME}"
TRAIN_STATUS=$?
set -e

SMOKE_STATUS="completed"
if [[ "${TRAIN_STATUS}" -ne 0 ]]; then
  if grep -q "'train_runtime':" "${RUN_ROOT}/slurm-${SLURM_JOB_ID:-manual}.out"; then
    SMOKE_STATUS="completed_training_nonzero_exit_${TRAIN_STATUS}"
  else
    exit "${TRAIN_STATUS}"
  fi
fi

cat > "${RUN_ROOT}/smoke_summary.md" <<EOF
# ${SMOKE_EXPERIMENT} Smoke Summary

- job_id: ${SLURM_JOB_ID:-manual}
- host: $(hostname)
- config: ${CONFIG_NAME}
- project_root: ${PROJECT_ROOT}
- completed_at: $(date -Is)
- expected_steps: 100
- status: ${SMOKE_STATUS}
EOF

rm -rf "${JOB_TMPDIR}"
