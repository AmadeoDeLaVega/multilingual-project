#!/bin/bash -l
#SBATCH --job-name=proofwala-e1-cont
#SBATCH --account=class
#SBATCH --partition=class
#SBATCH --qos=medium
#SBATCH --gres=gpu:rtxa5000:1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --time=06:00:00
#SBATCH --output=proofwala-e1-cont-%j.out

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  sbatch scripts/nexus/train_e1_continue.sbatch [--user USERNAME]
  sbatch scripts/nexus/train_e1_continue.sbatch --adelaveg

Stage controls:
  STAGE_STEPS is the number of new optimizer steps to run in this submission.
  MAX_STEPS is the total target global step, not additional steps. The default
  is auto: latest checkpoint step + STAGE_STEPS, or STAGE_STEPS from scratch.
  RESUME_FROM_CHECKPOINT defaults to auto. It uses the latest full checkpoint
  under MODEL_RUN_NAME, or starts from scratch when none exists.
  MODEL_RUN_NAME controls the output subdirectory under runs/E1/model.

Example:
  STAGE_STEPS=5000 \
  MODEL_RUN_NAME=pilot-e1-lean-only-34000x1 \
  sbatch scripts/nexus/train_e1_continue.sbatch --adelaveg

Environment overrides:
  NEXUS_USER=adelaveg sbatch scripts/nexus/train_e1_continue.sbatch
  PROJECT_ROOT=/fs/classhomes/adelaveg/multilingual-project sbatch scripts/nexus/train_e1_continue.sbatch
  CONDA_ENV=proofwala-pilot sbatch scripts/nexus/train_e1_continue.sbatch
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

EXPERIMENT="E1"
CONFIG_NAME="pilot_e1.yaml"
PROJECT_ROOT="${PROJECT_ROOT:-/fs/classhomes/${NEXUS_USER}/multilingual-project}"
PROOF_WALA_ROOT="${PROJECT_ROOT}/proof-wala"
RUN_ROOT="${PROJECT_ROOT}/runs/${EXPERIMENT}"
MODEL_RUN_NAME="${MODEL_RUN_NAME:-pilot-e1-lean-only-34000x1}"
STAGE_STEPS="${STAGE_STEPS:-5000}"
MAX_STEPS="${MAX_STEPS:-auto}"
RESUME_FROM_CHECKPOINT="${RESUME_FROM_CHECKPOINT:-auto}"
MODEL_OUTPUT_DIR="${RUN_ROOT}/model/${MODEL_RUN_NAME}"
MODEL_FINAL_DIR="${MODEL_OUTPUT_DIR}/final"
SOURCE_TRAIN_DATA_DIR="${PROJECT_ROOT}/data/proofwala_dataset/ProofWalaDataset/lean/train"
TRAIN_DATA_DIR="${PROJECT_ROOT}/data/frozen_splits/e1_lean_train_compat"
EVAL_DATA_DIR="${PROJECT_ROOT}/data/frozen_splits/lean_eval_1000"
RUN_DIAGNOSTICS="${RUN_DIAGNOSTICS:-1}"
DIAGNOSTICS_LIMIT="${DIAGNOSTICS_LIMIT:-1000}"
DIAGNOSTICS_BATCH_SIZE="${DIAGNOSTICS_BATCH_SIZE:-1}"
DIAGNOSTICS_OUTPUT="${DIAGNOSTICS_OUTPUT:-${RUN_ROOT}/diagnostics/e1_continue_${MODEL_RUN_NAME}_step${MAX_STEPS}.json}"
CONDA_ENV="${CONDA_ENV:-proofwala-pilot}"
JOB_TMPDIR="/tmp/${USER}/pw-train-${EXPERIMENT}-cont-${SLURM_JOB_ID:-manual}"

if [[ ! "${STAGE_STEPS}" =~ ^[0-9]+$ ]] || [[ "${STAGE_STEPS}" -le 0 ]]; then
  echo "STAGE_STEPS must be a positive integer, got: ${STAGE_STEPS}" >&2
  exit 2
fi

mkdir -p "${RUN_ROOT}" "${JOB_TMPDIR}"
exec > "${RUN_ROOT}/slurm-e1-continue-${SLURM_JOB_ID:-manual}.out" 2>&1

write_summary() {
  local status="$1"
  local summary_tmp="${RUN_ROOT}/training_continue_summary.${SLURM_JOB_ID:-manual}.tmp"
  cat > "${summary_tmp}" <<EOF
# ${EXPERIMENT} Continuation Training Summary

- job_id: ${SLURM_JOB_ID:-manual}
- host: $(hostname)
- config: ${CONFIG_NAME}
- project_root: ${PROJECT_ROOT}
- train_data_dir: ${TRAIN_DATA_DIR}
- eval_data_dir: ${EVAL_DATA_DIR}
- model_run_name: ${MODEL_RUN_NAME}
- model_output_dir: ${MODEL_OUTPUT_DIR}
- final_model_dir: ${MODEL_FINAL_DIR}
- resume_from_checkpoint: ${RESUME_FROM_CHECKPOINT}
- stage_steps: ${STAGE_STEPS}
- max_steps: ${MAX_STEPS}
- diagnostics_output: ${DIAGNOSTICS_OUTPUT}
- completed_at: $(date -Is)
- status: ${status}
EOF
  mv "${summary_tmp}" "${RUN_ROOT}/training_continue_summary.md"
}

resolve_training_stage() {
  local current_step=0
  local latest_checkpoint=""
  local checkpoint_step=""

  if [[ "${RESUME_FROM_CHECKPOINT}" == "auto" ]]; then
    if [[ -d "${MODEL_OUTPUT_DIR}" ]]; then
      latest_checkpoint="$(find "${MODEL_OUTPUT_DIR}" -maxdepth 1 -type d -name 'checkpoint-*' -printf '%f\n' \
        | sed 's/^checkpoint-//' \
        | sort -n \
        | tail -n 1 || true)"
    fi
    if [[ -n "${latest_checkpoint}" ]]; then
      RESUME_FROM_CHECKPOINT="${MODEL_OUTPUT_DIR}/checkpoint-${latest_checkpoint}"
      current_step="${latest_checkpoint}"
    else
      RESUME_FROM_CHECKPOINT="False"
    fi
  elif [[ "${RESUME_FROM_CHECKPOINT}" =~ ^([Ff]alse|none|NONE|0)$ ]]; then
    RESUME_FROM_CHECKPOINT="False"
  else
    checkpoint_step="$(basename "${RESUME_FROM_CHECKPOINT}" | sed -n 's/^checkpoint-\([0-9][0-9]*\)$/\1/p')"
    if [[ -n "${checkpoint_step}" ]]; then
      current_step="${checkpoint_step}"
    fi
  fi

  if [[ "${MAX_STEPS}" == "auto" ]]; then
    MAX_STEPS="$((current_step + STAGE_STEPS))"
  fi

  if [[ ! "${MAX_STEPS}" =~ ^[0-9]+$ ]] || [[ "${MAX_STEPS}" -le 0 ]]; then
    echo "MAX_STEPS must be a positive integer or auto, got: ${MAX_STEPS}" >&2
    exit 2
  fi
  if [[ "${current_step}" -ge "${MAX_STEPS}" ]]; then
    echo "Current checkpoint step (${current_step}) is already >= MAX_STEPS (${MAX_STEPS}). Nothing to train." >&2
    exit 2
  fi

  DIAGNOSTICS_OUTPUT="${DIAGNOSTICS_OUTPUT/stepauto/step${MAX_STEPS}}"
}

validate_data_dir() {
  local dir="$1"
  local label="$2"
  if [[ ! -d "${dir}" ]]; then
    echo "Missing ${label} directory: ${dir}" >&2
    exit 1
  fi
  if [[ ! -f "${dir}/local.meta.json" ]]; then
    echo "Missing ${label} metadata: ${dir}/local.meta.json" >&2
    exit 1
  fi
  if ! compgen -G "${dir}/local_data_*.json" >/dev/null; then
    echo "Missing ${label} local_data_*.json files in: ${dir}" >&2
    exit 1
  fi
}

materialize_training_compat_if_needed() {
  python - "${SOURCE_TRAIN_DATA_DIR}" "${TRAIN_DATA_DIR}" <<'PY'
import json
import os
import sys
from pathlib import Path

source_dir = Path(sys.argv[1])
output_dir = Path(sys.argv[2])
source_meta_path = source_dir / "local.meta.json"
if not source_meta_path.is_file():
    raise SystemExit(f"Missing source metadata: {source_meta_path}")
source_meta = json.loads(source_meta_path.read_text(encoding="utf-8"))
data_files = sorted(source_dir.glob("local_data_*.json"))
lemma_files = sorted(source_dir.glob("local_lemma_*.json"))
if not data_files:
    raise SystemExit(f"Missing source local_data_*.json files in: {source_dir}")
if len(lemma_files) != 1:
    raise SystemExit(f"Expected one source lemma file in {source_dir}, found {len(lemma_files)}")

output_dir.mkdir(parents=True, exist_ok=True)
for path in data_files:
    target = output_dir / path.name
    if target.exists() or target.is_symlink():
        target.unlink()
    os.symlink(path, target)

total_count = int(source_meta.get("total_data_count") or source_meta.get("total_proof_step_cnt") or source_meta.get("last_training_data"))
compat_meta = {
    "training_data_buffer_size": int(source_meta.get("training_data_buffer_size", 1000)),
    "last_training_data": int(source_meta.get("last_training_data", total_count)),
    "last_proof_id": source_meta.get("last_proof_id"),
    "external_theorems_used_cnt": int(source_meta.get("external_theorems_used_cnt", 0)),
    "local_theorems_used_cnt": int(source_meta.get("local_theorems_used_cnt", 0)),
    "total_data_count": total_count,
    "data_filename_prefix": source_meta.get("data_filename_prefix", "local_data_"),
    "data_filename_suffix": source_meta.get("data_filename_suffix", ".json"),
    "lemma_ref_filename_prefix": source_meta.get("lemma_ref_filename_prefix", "local_lemma_"),
    "lemma_ref_filename_suffix": source_meta.get("lemma_ref_filename_suffix", ".json"),
    "num_theorems": int(source_meta.get("num_theorems", 0)),
}
(output_dir / "local.meta.json").write_text(json.dumps(compat_meta, ensure_ascii=False) + "\n", encoding="utf-8")
(output_dir / lemma_files[0].name).write_text(json.dumps({"training_data": []}) + "\n", encoding="utf-8")
print(f"Materialized training metadata compatibility view: {output_dir} ({len(data_files)} data files, total_data_count={total_count})")
PY
}

materialize_frozen_eval_if_needed() {
  if [[ -d "${EVAL_DATA_DIR}" && -f "${EVAL_DATA_DIR}/local.meta.json" ]]; then
    return 0
  fi

  python - "${PROJECT_ROOT}" "${EVAL_DATA_DIR}" <<'PY'
import json
import sys
from pathlib import Path

project_root = Path(sys.argv[1])
output_dir = Path(sys.argv[2])
dataset_root = project_root / "data/proofwala_dataset/ProofWalaDataset"
refs_path = project_root / "data/frozen_splits/lean_eval_1000_proofs.jsonl"
if not refs_path.is_file():
    raise SystemExit(f"Missing frozen eval refs: {refs_path}")

cache = {}
records = []
with refs_path.open("r", encoding="utf-8") as handle:
    for line in handle:
        ref = json.loads(line)
        source_file = ref["source_file"]
        if source_file not in cache:
            with (dataset_root / source_file).open("r", encoding="utf-8") as source:
                cache[source_file] = json.load(source)["training_data"]
        records.append(cache[source_file][ref["record_index"]])

if not records:
    raise SystemExit(f"No records loaded from {refs_path}")

output_dir.mkdir(parents=True, exist_ok=True)
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
print(f"Materialized frozen eval data: {output_dir} ({len(records)} records)")
PY
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
with safe_open(str(safetensors_path), framework="pt") as handle:
    tensor_count = len(handle.keys())
print(f"Validated final model.safetensors: {safetensors_path} ({tensor_count} tensors)")
PY
}

run_diagnostics() {
  if [[ "${RUN_DIAGNOSTICS}" != "1" && "${RUN_DIAGNOSTICS}" != "true" && "${RUN_DIAGNOSTICS}" != "True" ]]; then
    echo "Skipping diagnostics because RUN_DIAGNOSTICS=${RUN_DIAGNOSTICS}"
    return 0
  fi

  mkdir -p "$(dirname "${DIAGNOSTICS_OUTPUT}")"
  python "${PROJECT_ROOT}/scripts/eval/e1_diagnostics.py" \
    --project-root "${PROJECT_ROOT}" \
    --run-root "${RUN_ROOT}" \
    --model "${MODEL_FINAL_DIR}" \
    --eval-dir "${EVAL_DATA_DIR}" \
    --tokenizer-source "Salesforce/codet5-small" \
    --output "${DIAGNOSTICS_OUTPUT}" \
    --limit "${DIAGNOSTICS_LIMIT}" \
    --batch-size "${DIAGNOSTICS_BATCH_SIZE}"

  echo "Diagnostics written:"
  ls -lh "${DIAGNOSTICS_OUTPUT}" "${DIAGNOSTICS_OUTPUT%.json}.md"
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
export RAY_NUM_CPUS="${SLURM_CPUS_PER_TASK:-8}"
export RAY_OBJECT_STORE_MEMORY="$((8 * 1024 * 1024 * 1024))"
export RAY_MEMORY="$((24 * 1024 * 1024 * 1024))"
export PROOFWALA_TRAINING_DATA_USE_RAY=0
export PROOFWALA_SKIP_MODEL_SAVE=0
export PYTHONUNBUFFERED=1
export PYTHONPATH="${PROJECT_ROOT}/proof-wala/src:${PROJECT_ROOT}/itp-interface/src:${PYTHONPATH:-}"

resolve_training_stage

echo "Host: $(hostname)"
echo "Job: ${SLURM_JOB_ID:-unknown}"
echo "NEXUS user: ${NEXUS_USER}"
echo "Project root: ${PROJECT_ROOT}"
echo "ProofWala root: ${PROOF_WALA_ROOT}"
echo "Experiment: ${EXPERIMENT}"
echo "Config: ${CONFIG_NAME}"
echo "Model run name: ${MODEL_RUN_NAME}"
echo "Stage steps: ${STAGE_STEPS}"
echo "Max steps: ${MAX_STEPS}"
echo "Resume from checkpoint: ${RESUME_FROM_CHECKPOINT}"
echo "Source train data dir: ${SOURCE_TRAIN_DATA_DIR}"
echo "Train data dir: ${TRAIN_DATA_DIR}"
echo "Eval data dir: ${EVAL_DATA_DIR}"
echo "Model output dir: ${MODEL_OUTPUT_DIR}"
echo "Final model dir: ${MODEL_FINAL_DIR}"
echo "Run diagnostics: ${RUN_DIAGNOSTICS}"
echo "Diagnostics output: ${DIAGNOSTICS_OUTPUT}"
echo "Conda env: ${CONDA_DEFAULT_ENV:-unset}"
echo "CUDA_VISIBLE_DEVICES=${CUDA_VISIBLE_DEVICES:-unset}"
python --version
command -v proof-wala-train
nvidia-smi || true

validate_data_dir "${SOURCE_TRAIN_DATA_DIR}" "source training data"
materialize_training_compat_if_needed
validate_data_dir "${TRAIN_DATA_DIR}" "training data"
materialize_frozen_eval_if_needed
validate_data_dir "${EVAL_DATA_DIR}" "eval data"

if [[ "${RESUME_FROM_CHECKPOINT}" != "False" && ! -d "${RESUME_FROM_CHECKPOINT}" ]]; then
  echo "Missing resume checkpoint: ${RESUME_FROM_CHECKPOINT}" >&2
  exit 2
fi
if [[ "${RESUME_FROM_CHECKPOINT}" != "False" && ! -f "${RESUME_FROM_CHECKPOINT}/trainer_state.json" ]]; then
  echo "Resume checkpoint lacks trainer_state.json; it was probably saved with save_only_model=True: ${RESUME_FROM_CHECKPOINT}" >&2
  exit 2
fi

cd "${PROOF_WALA_ROOT}"

set +e
proof-wala-train \
  --config-dir=src/proof_wala/main/config \
  --config-name="${CONFIG_NAME}" \
  "name=${MODEL_RUN_NAME}" \
  "training_settings.training_args.max_steps=${MAX_STEPS}" \
  "training_settings.training_args.resume_from_checkpoint=${RESUME_FROM_CHECKPOINT}" \
  "training_settings.training_args.save_only_model=False" \
  "training_settings.training_args.save_steps=5000" \
  "training_settings.training_args.eval_steps=5000" \
  "training_settings.training_args.save_total_limit=2"
TRAIN_STATUS=$?
set -e

if [[ "${TRAIN_STATUS}" -ne 0 ]]; then
  write_summary "failed_training_exit_${TRAIN_STATUS}"
  exit "${TRAIN_STATUS}"
fi

if ! validate_final_model; then
  write_summary "failed_model_validation"
  exit 1
fi

if ! run_diagnostics; then
  write_summary "failed_diagnostics"
  exit 1
fi

write_summary "completed"
rm -rf "${JOB_TMPDIR}"
