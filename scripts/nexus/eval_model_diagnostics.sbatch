#!/bin/bash -l
#SBATCH --job-name=proofwala-diag
#SBATCH --account=class
#SBATCH --partition=class
#SBATCH --qos=medium
#SBATCH --gres=gpu:rtxa5000:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=01:00:00
#SBATCH --output=proofwala-diag-%j.out

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  sbatch scripts/nexus/eval_model_diagnostics.sbatch --experiment E3 [--user USERNAME]
  sbatch scripts/nexus/eval_model_diagnostics.sbatch --experiment E4 --model /path/to/model
  sbatch scripts/nexus/eval_model_diagnostics.sbatch --experiment E3 --user adelaveg

Environment overrides:
  NEXUS_USER=adelaveg sbatch scripts/nexus/eval_model_diagnostics.sbatch --experiment E3
  PROJECT_ROOT=/fs/classhomes/adelaveg/multilingual-project sbatch scripts/nexus/eval_model_diagnostics.sbatch --experiment E3
  MODEL_PATH=/fs/classhomes/adelaveg/multilingual-project/runs/E3/model/pilot-e3-real-multilingual/final sbatch scripts/nexus/eval_model_diagnostics.sbatch --experiment E3
  OUTPUT=/fs/classhomes/adelaveg/multilingual-project/runs/E3/diagnostics/e3_final_diagnostics.json sbatch scripts/nexus/eval_model_diagnostics.sbatch --experiment E3
  LIMIT=1000 sbatch scripts/nexus/eval_model_diagnostics.sbatch --experiment E3
EOF
}

NEXUS_USER="${NEXUS_USER:-${USER:-}}"
EXPERIMENT="${EXPERIMENT:-}"
MODEL_PATH="${MODEL_PATH:-}"
OUTPUT="${OUTPUT:-}"

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
    --experiment)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for $1" >&2
        usage >&2
        exit 2
      fi
      EXPERIMENT="$2"
      shift 2
      ;;
    --experiment=*)
      EXPERIMENT="${1#*=}"
      shift
      ;;
    --model)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for $1" >&2
        usage >&2
        exit 2
      fi
      MODEL_PATH="$2"
      shift 2
      ;;
    --model=*)
      MODEL_PATH="${1#*=}"
      shift
      ;;
    --output)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for $1" >&2
        usage >&2
        exit 2
      fi
      OUTPUT="$2"
      shift 2
      ;;
    --output=*)
      OUTPUT="${1#*=}"
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

case "${EXPERIMENT}" in
  E1)
    MODEL_RUN_NAME="pilot-e1-lean-only"
    ;;
  E3)
    MODEL_RUN_NAME="pilot-e3-real-multilingual"
    ;;
  E4)
    MODEL_RUN_NAME="pilot-e4-pseudo-multilingual"
    ;;
  *)
    echo "Invalid or missing experiment. Expected E1, E3, or E4; got: ${EXPERIMENT:-<empty>}" >&2
    usage >&2
    exit 2
    ;;
esac

PROJECT_ROOT="${PROJECT_ROOT:-/fs/classhomes/${NEXUS_USER}/multilingual-project}"
RUN_ROOT="${RUN_ROOT:-${PROJECT_ROOT}/runs/${EXPERIMENT}}"
MODEL_PATH="${MODEL_PATH:-${RUN_ROOT}/model/${MODEL_RUN_NAME}/final}"
EVAL_DIR="${EVAL_DIR:-${PROJECT_ROOT}/data/frozen_splits/lean_eval_1000}"
OUTPUT="${OUTPUT:-${RUN_ROOT}/diagnostics/${EXPERIMENT,,}_model_diagnostics.json}"
CONDA_ENV="${CONDA_ENV:-proofwala-pilot}"
LIMIT="${LIMIT:-1000}"
BATCH_SIZE="${BATCH_SIZE:-1}"
TOKENIZER_SOURCE="${TOKENIZER_SOURCE:-Salesforce/codet5-small}"
JOB_TMPDIR="/tmp/${USER}/pw-diag-${EXPERIMENT}-${SLURM_JOB_ID:-manual}"

mkdir -p "$(dirname "${OUTPUT}")" "${JOB_TMPDIR}"
exec > "${RUN_ROOT}/diagnostics/slurm-${SLURM_JOB_ID:-manual}.out" 2>&1

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
echo "Experiment: ${EXPERIMENT}"
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

python - "${MODEL_PATH}" <<'PY'
import sys
from pathlib import Path
from safetensors import safe_open

model_path = Path(sys.argv[1])
safetensors_path = model_path / "model.safetensors"
if not safetensors_path.is_file():
    raise SystemExit(f"Missing model.safetensors: {safetensors_path}")
with safe_open(str(safetensors_path), framework="pt") as handle:
    print(f"Validated model.safetensors: {safetensors_path} ({len(handle.keys())} tensors)")
PY

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
rm -rf "${JOB_TMPDIR}"
