#!/bin/bash -l
#SBATCH --job-name=proofwala-overfit
#SBATCH --account=class
#SBATCH --partition=class
#SBATCH --qos=medium
#SBATCH --gres=gpu:rtxa5000:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=02:00:00
#SBATCH --output=proofwala-overfit-%j.out

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  sbatch scripts/nexus/overfit_100_diagnostics.sbatch --experiment E3 [--user USERNAME]
  sbatch scripts/nexus/overfit_100_diagnostics.sbatch --experiment E4 --user adelaveg

Environment overrides:
  NEXUS_USER=adelaveg sbatch scripts/nexus/overfit_100_diagnostics.sbatch --experiment E3
  PROJECT_ROOT=/fs/classhomes/adelaveg/multilingual-project sbatch scripts/nexus/overfit_100_diagnostics.sbatch --experiment E3
  LIMIT=100 sbatch scripts/nexus/overfit_100_diagnostics.sbatch --experiment E3
  MAX_STEPS=1000 sbatch scripts/nexus/overfit_100_diagnostics.sbatch --experiment E3
EOF
}

NEXUS_USER="${NEXUS_USER:-${USER:-}}"
EXPERIMENT="${EXPERIMENT:-}"

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
  E3)
    CONFIG_NAME="pilot_e3.yaml"
    MODEL_RUN_NAME="overfit-e3-100"
    SOURCE_DATA_DIR_NAME="e3_multilingual_train_compat"
    SOURCE_DATA_DIR_REL="data/frozen_splits/e3_multilingual_train_compat"
    ;;
  E4)
    CONFIG_NAME="pilot_e4.yaml"
    MODEL_RUN_NAME="overfit-e4-100"
    SOURCE_DATA_DIR_NAME="e4_train"
    SOURCE_DATA_DIR_REL="data/pseudo_multilingual/e4_train"
    ;;
  *)
    echo "Invalid or missing experiment. Expected E3 or E4; got: ${EXPERIMENT:-<empty>}" >&2
    usage >&2
    exit 2
    ;;
esac

PROJECT_ROOT="${PROJECT_ROOT:-/fs/classhomes/${NEXUS_USER}/multilingual-project}"
PROOF_WALA_ROOT="${PROJECT_ROOT}/proof-wala"
RUN_ROOT="${PROJECT_ROOT}/runs/overfit/${EXPERIMENT}"
SOURCE_DATA_DIR="${PROJECT_ROOT}/${SOURCE_DATA_DIR_REL}"
SUBSET_DATA_DIR="${PROJECT_ROOT}/data/overfit/${EXPERIMENT}/train100_from_${SOURCE_DATA_DIR_NAME}"
MODEL_OUTPUT_DIR="${RUN_ROOT}/model"
MODEL_FINAL_DIR="${MODEL_OUTPUT_DIR}/${MODEL_RUN_NAME}/final"
MODEL_CHECKPOINT_DIR="${MODEL_OUTPUT_DIR}/${MODEL_RUN_NAME}/checkpoint-${MAX_STEPS:-1000}"
DIAGNOSTICS_OUTPUT="${RUN_ROOT}/diagnostics/${EXPERIMENT,,}_overfit100_diagnostics.json"
CONDA_ENV="${CONDA_ENV:-proofwala-pilot}"
LIMIT="${LIMIT:-100}"
MAX_STEPS="${MAX_STEPS:-1000}"
BATCH_SIZE="${BATCH_SIZE:-1}"
TOKENIZER_SOURCE="${TOKENIZER_SOURCE:-Salesforce/codet5-small}"
JOB_TMPDIR="/tmp/${USER}/pw-overfit-${EXPERIMENT}-${SLURM_JOB_ID:-manual}"

mkdir -p "${RUN_ROOT}" "${JOB_TMPDIR}" "$(dirname "${DIAGNOSTICS_OUTPUT}")"
exec > "${RUN_ROOT}/slurm-${SLURM_JOB_ID:-manual}.out" 2>&1

write_summary() {
  local status="$1"
  cat > "${RUN_ROOT}/summary.md" <<EOF
# ${EXPERIMENT} Overfit-100 Summary

- job_id: ${SLURM_JOB_ID:-manual}
- host: $(hostname)
- config: ${CONFIG_NAME}
- source_data_dir: ${SOURCE_DATA_DIR}
- subset_data_dir: ${SUBSET_DATA_DIR}
- model_final_dir: ${MODEL_FINAL_DIR}
- diagnostics_output: ${DIAGNOSTICS_OUTPUT}
- limit: ${LIMIT}
- max_steps: ${MAX_STEPS}
- completed_at: $(date -Is)
- status: ${status}
EOF
}

materialize_subset() {
  python - "${SOURCE_DATA_DIR}" "${SUBSET_DATA_DIR}" "${LIMIT}" <<'PY'
import json
import sys
from pathlib import Path

source_dir = Path(sys.argv[1])
output_dir = Path(sys.argv[2])
limit = int(sys.argv[3])
if limit <= 0:
    raise SystemExit(f"Invalid limit: {limit}")
meta_path = source_dir / "local.meta.json"
if not meta_path.is_file():
    raise SystemExit(f"Missing source metadata: {meta_path}")
data_files = sorted(source_dir.glob("local_data_*.json"))
if not data_files:
    raise SystemExit(f"Missing source local_data_*.json files in: {source_dir}")

records = []
for path in data_files:
    payload = json.loads(path.read_text(encoding="utf-8"))
    for record in payload.get("training_data", []):
        records.append(record)
        if len(records) >= limit:
            break
    if len(records) >= limit:
        break
if len(records) < limit:
    raise SystemExit(f"Only loaded {len(records)} records from {source_dir}; wanted {limit}")

output_dir.mkdir(parents=True, exist_ok=True)
for old in output_dir.glob("local_data_*.json"):
    old.unlink()
(output_dir / f"local_data_{len(records):010d}.json").write_text(
    json.dumps({"training_data": records}, ensure_ascii=False) + "\n",
    encoding="utf-8",
)
(output_dir / "local_lemma_0000000000.json").write_text(
    json.dumps({"training_data": []}) + "\n",
    encoding="utf-8",
)
(output_dir / "local.meta.json").write_text(
    json.dumps(
        {
            "training_data_buffer_size": max(1000, len(records)),
            "last_training_data": len(records),
            "last_proof_id": records[-1].get("proof_id"),
            "external_theorems_used_cnt": 0,
            "local_theorems_used_cnt": 0,
            "total_data_count": len(records),
            "data_filename_prefix": "local_data_",
            "data_filename_suffix": ".json",
            "lemma_ref_filename_prefix": "local_lemma_",
            "lemma_ref_filename_suffix": ".json",
            "num_theorems": len({record.get("proof_id") for record in records}),
        },
        ensure_ascii=False,
    )
    + "\n",
    encoding="utf-8",
)
print(f"Materialized overfit subset: {output_dir} ({len(records)} records)")
PY
}

validate_model_dir() {
  local model_dir="$1"
  python - "${model_dir}" <<'PY'
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
}

module load miniforge3/24.3.0
module load cuda/12.4.1 || true

source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "${CONDA_ENV}"

export PROJECT_ROOT
export ROOT="${PROJECT_ROOT}"
export HF_HOME="${PROJECT_ROOT}/.hf_cache"
export HF_DATASETS_CACHE="${PROJECT_ROOT}/.hf_cache/datasets"
export TRANSFORMERS_CACHE="${PROJECT_ROOT}/.hf_cache/transformers"
export TMPDIR="${JOB_TMPDIR}"
export COMET_MODE=DISABLED
export PROOFWALA_TRAINING_DATA_USE_RAY=0
export PROOFWALA_SKIP_MODEL_SAVE=0
export PYTHONUNBUFFERED=1
export PYTHONPATH="${PROJECT_ROOT}/proof-wala/src:${PROJECT_ROOT}/itp-interface/src:${PYTHONPATH:-}"

echo "Host: $(hostname)"
echo "Experiment: ${EXPERIMENT}"
echo "Project root: ${PROJECT_ROOT}"
echo "Source data dir: ${SOURCE_DATA_DIR}"
echo "Subset data dir: ${SUBSET_DATA_DIR}"
echo "Model output dir: ${MODEL_OUTPUT_DIR}"
echo "Model final dir: ${MODEL_FINAL_DIR}"
echo "Max steps: ${MAX_STEPS}"
echo "Limit: ${LIMIT}"
python --version
nvidia-smi || true

materialize_subset

cd "${PROOF_WALA_ROOT}"
set +e
proof-wala-train \
  --config-dir=src/proof_wala/main/config \
  --config-name="${CONFIG_NAME}" \
  "name=${MODEL_RUN_NAME}" \
  "model_settings.logging_dir=${RUN_ROOT}/logs/model" \
  "training_data_settings.training_data_dir=${SUBSET_DATA_DIR}" \
  "training_data_settings.training_data_log_dir=${RUN_ROOT}/data_logs" \
  "training_data_settings.evals.0.eval_name=overfit_train100" \
  "training_data_settings.evals.0.eval_data_dir=${SUBSET_DATA_DIR}" \
  "training_data_settings.evals.0.eval_data_log_dir=${RUN_ROOT}/eval_logs" \
  "training_settings.training_args.output_dir=${MODEL_OUTPUT_DIR}" \
  "training_settings.training_args.logging_dir=${RUN_ROOT}/logs/trainer" \
  "training_settings.training_args.overwrite_output_dir=True" \
  "training_settings.training_args.max_steps=${MAX_STEPS}" \
  "training_settings.training_args.save_only_model=True" \
  "training_settings.training_args.save_steps=${MAX_STEPS}" \
  "training_settings.training_args.eval_steps=${MAX_STEPS}" \
  "training_settings.training_args.save_total_limit=1" \
  "training_settings.training_args.load_best_model_at_end=False"
TRAIN_STATUS=$?
set -e

if [[ "${TRAIN_STATUS}" -ne 0 ]]; then
  write_summary "failed_training_exit_${TRAIN_STATUS}"
  exit "${TRAIN_STATUS}"
fi

MODEL_VALIDATION_DIR="${MODEL_FINAL_DIR}"
if [[ ! -d "${MODEL_VALIDATION_DIR}" ]]; then
  echo "Final model directory missing; falling back to checkpoint: ${MODEL_CHECKPOINT_DIR}"
  MODEL_VALIDATION_DIR="${MODEL_CHECKPOINT_DIR}"
fi
validate_model_dir "${MODEL_VALIDATION_DIR}"

python "${PROJECT_ROOT}/scripts/eval/e1_diagnostics.py" \
  --project-root "${PROJECT_ROOT}" \
  --run-root "${RUN_ROOT}" \
  --model "${MODEL_VALIDATION_DIR}" \
  --eval-dir "${SUBSET_DATA_DIR}" \
  --tokenizer-source "${TOKENIZER_SOURCE}" \
  --output "${DIAGNOSTICS_OUTPUT}" \
  --limit "${LIMIT}" \
  --batch-size "${BATCH_SIZE}"

echo "Diagnostics written:"
ls -lh "${DIAGNOSTICS_OUTPUT}" "${DIAGNOSTICS_OUTPUT%.json}.md"
write_summary "completed"
rm -rf "${JOB_TMPDIR}"
