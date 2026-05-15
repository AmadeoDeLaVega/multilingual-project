#!/bin/bash -l
#SBATCH --job-name=proofwala-e1-diag
#SBATCH --account=class
#SBATCH --partition=class
#SBATCH --qos=medium
#SBATCH --gres=gpu:rtxa5000:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=01:00:00
#SBATCH --output=proofwala-e1-diag-%j.out

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  sbatch scripts/nexus/eval_e1_diagnostics.sbatch [--user USERNAME]
  sbatch scripts/nexus/eval_e1_diagnostics.sbatch --adelaveg

Environment overrides:
  NEXUS_USER=adelaveg sbatch scripts/nexus/eval_e1_diagnostics.sbatch
  PROJECT_ROOT=/fs/classhomes/adelaveg/multilingual-project sbatch scripts/nexus/eval_e1_diagnostics.sbatch
  MODEL_PATH=/fs/classhomes/adelaveg/multilingual-project/runs/E1/model/pilot-e1-lean-only/final sbatch scripts/nexus/eval_e1_diagnostics.sbatch
  EVAL_DIR=/fs/classhomes/adelaveg/multilingual-project/data/frozen_splits/lean_eval_1000 sbatch scripts/nexus/eval_e1_diagnostics.sbatch
  LIMIT=1000 sbatch scripts/nexus/eval_e1_diagnostics.sbatch
EOF
}

NEXUS_USER="${NEXUS_USER:-${USER:-}}"
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
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

PROJECT_ROOT="${PROJECT_ROOT:-/fs/classhomes/${NEXUS_USER}/multilingual-project}"
MODEL_PATH="${MODEL_PATH:-${PROJECT_ROOT}/runs/E1/model/pilot-e1-lean-only/final}"
RUN_ROOT="${RUN_ROOT:-${PROJECT_ROOT}/runs/E1}"
EVAL_DIR="${EVAL_DIR:-${PROJECT_ROOT}/data/frozen_splits/lean_eval_1000}"
OUTPUT="${OUTPUT:-${PROJECT_ROOT}/runs/E1/diagnostics/e1_diagnostics.json}"
CONDA_ENV="${CONDA_ENV:-proofwala-pilot}"
LIMIT="${LIMIT:-1000}"
BATCH_SIZE="${BATCH_SIZE:-1}"
TOKENIZER_SOURCE="${TOKENIZER_SOURCE:-Salesforce/codet5-small}"
JOB_TMPDIR="/tmp/${USER}/pw-e1-diag-${SLURM_JOB_ID:-manual}"

mkdir -p "${PROJECT_ROOT}/runs/E1/diagnostics" "${JOB_TMPDIR}"
exec > "${PROJECT_ROOT}/runs/E1/diagnostics/slurm-${SLURM_JOB_ID:-manual}.out" 2>&1

module load miniforge3/24.3.0
module load cuda/12.4.1 || true

source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "${CONDA_ENV}"

export PROJECT_ROOT
export ROOT="${PROJECT_ROOT}/proof-wala"
export HF_HOME="${PROJECT_ROOT}/.hf_cache"
export HF_DATASETS_CACHE="${PROJECT_ROOT}/.hf_cache/datasets"
export TRANSFORMERS_CACHE="${PROJECT_ROOT}/.hf_cache/transformers"
export TMPDIR="${JOB_TMPDIR}"
export COMET_MODE=DISABLED
export PROOFWALA_TRAINING_DATA_USE_RAY=0
export PYTHONUNBUFFERED=1
export PYTHONPATH="${PROJECT_ROOT}/proof-wala/src:${PROJECT_ROOT}/itp-interface/src:${PYTHONPATH:-}"

echo "Host: $(hostname)"
echo "Project root: ${PROJECT_ROOT}"
echo "Model path: ${MODEL_PATH}"
echo "Run root: ${RUN_ROOT}"
echo "Eval dir: ${EVAL_DIR}"
echo "Output: ${OUTPUT}"
echo "Limit: ${LIMIT}"
echo "Batch size: ${BATCH_SIZE}"
python --version
nvidia-smi || true

if [[ ! -d "${MODEL_PATH}" ]]; then
  echo "Missing model path: ${MODEL_PATH}" >&2
  exit 2
fi
if [[ ! -d "${EVAL_DIR}" ]]; then
  echo "Missing eval dir: ${EVAL_DIR}" >&2
  exit 2
fi

python "${PROJECT_ROOT}/scripts/eval/e1_diagnostics.py" \
  --project-root "${PROJECT_ROOT}" \
  --run-root "${RUN_ROOT}" \
  --model "${MODEL_PATH}" \
  --eval-dir "${EVAL_DIR}" \
  --tokenizer-source "${TOKENIZER_SOURCE}" \
  --output "${OUTPUT}" \
  --limit "${LIMIT}" \
  --batch-size "${BATCH_SIZE}"

echo "Diagnostics written:"
ls -lh "${OUTPUT}" "${OUTPUT%.json}.md"
