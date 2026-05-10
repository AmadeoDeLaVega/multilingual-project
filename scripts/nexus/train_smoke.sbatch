#!/bin/bash -l
#SBATCH --job-name=proofwala-smoke
#SBATCH --account=class
#SBATCH --partition=class
#SBATCH --qos=medium
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
    MODEL_RUN_NAME="smoke-e1-lean-only"
    ;;
  E3|e3)
    SMOKE_EXPERIMENT="E3"
    CONFIG_NAME="smoke_e3.yaml"
    MODEL_RUN_NAME="smoke-e3-real-multilingual"
    ;;
  E4|e4)
    SMOKE_EXPERIMENT="E4"
    CONFIG_NAME="smoke_e4.yaml"
    MODEL_RUN_NAME="smoke-e4-pseudo-multilingual"
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
MODEL_OUTPUT_DIR="${RUN_ROOT}/model/${MODEL_RUN_NAME}"
MODEL_FINAL_DIR="${MODEL_OUTPUT_DIR}/final"
CONDA_ENV="${CONDA_ENV:-proofwala-pilot}"
JOB_TMPDIR="/tmp/${USER}/pw-smoke-${SMOKE_EXPERIMENT}-${SLURM_JOB_ID:-manual}"

mkdir -p "${RUN_ROOT}" "${JOB_TMPDIR}"
exec > "${RUN_ROOT}/slurm-${SLURM_JOB_ID:-manual}.out" 2>&1

write_summary() {
  local smoke_status="$1"
  local summary_tmp="${RUN_ROOT}/smoke_summary.${SLURM_JOB_ID:-manual}.tmp"
  cat > "${summary_tmp}" <<EOF
# ${SMOKE_EXPERIMENT} Smoke Summary

- job_id: ${SLURM_JOB_ID:-manual}
- host: $(hostname)
- config: ${CONFIG_NAME}
- project_root: ${PROJECT_ROOT}
- model_output_dir: ${MODEL_OUTPUT_DIR}
- final_model_dir: ${MODEL_FINAL_DIR}
- completed_at: $(date -Is)
- expected_steps: 100
- status: ${smoke_status}
EOF
  mv "${summary_tmp}" "${RUN_ROOT}/smoke_summary.md"
}

validate_final_model() {
  python - "${MODEL_FINAL_DIR}" <<'PY'
import sys
from pathlib import Path
from safetensors import safe_open

model_path = Path(sys.argv[1])
safetensors_path = model_path / "model.safetensors"
if not model_path.is_dir():
    raise SystemExit(f"Missing final model directory: {model_path}")
if not safetensors_path.is_file():
    raise SystemExit(f"Missing model.safetensors: {safetensors_path}")
if safetensors_path.stat().st_size == 0:
    raise SystemExit(f"Empty model.safetensors: {safetensors_path}")

try:
    with safe_open(str(safetensors_path), framework="pt") as handle:
        tensor_count = len(handle.keys())
except Exception as exc:
    raise SystemExit(f"Invalid model.safetensors at {safetensors_path}: {type(exc).__name__}: {exc}") from exc

print(f"Validated final model.safetensors: {safetensors_path} ({tensor_count} tensors)")
PY
}

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
export PROOFWALA_TRAINING_DATA_USE_RAY=0
export PROOFWALA_SKIP_MODEL_SAVE=0
export PYTHONUNBUFFERED=1

echo "Host: $(hostname)"
echo "Job: ${SLURM_JOB_ID:-unknown}"
echo "NEXUS user: ${NEXUS_USER}"
echo "Project root: ${PROJECT_ROOT}"
echo "ProofWala root: ${PROOF_WALA_ROOT}"
echo "Smoke experiment: ${SMOKE_EXPERIMENT}"
echo "Config: ${CONFIG_NAME}"
echo "Model output dir: ${MODEL_OUTPUT_DIR}"
echo "Final model dir: ${MODEL_FINAL_DIR}"
echo "Conda env: ${CONDA_DEFAULT_ENV:-unset}"
echo "CUDA_VISIBLE_DEVICES=${CUDA_VISIBLE_DEVICES:-unset}"
echo "PROOFWALA_TRAINING_DATA_USE_RAY=${PROOFWALA_TRAINING_DATA_USE_RAY}"
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

if ! validate_final_model; then
  write_summary "failed_model_validation"
  exit 1
fi

write_summary "${SMOKE_STATUS}"

rm -rf "${JOB_TMPDIR}"
