#!/bin/bash -l
#SBATCH --job-name=proofwala-orig-model
#SBATCH --account=class
#SBATCH --partition=class
#SBATCH --qos=default
#SBATCH --cpus-per-task=2
#SBATCH --mem=24G
#SBATCH --time=02:00:00
#SBATCH --output=proofwala-orig-model-%j.out

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  sbatch scripts/nexus/download_original_multilingual_model.sbatch --user USERNAME
  sbatch scripts/nexus/download_original_multilingual_model.sbatch --adelaveg

Environment overrides:
  PROJECT_ROOT=/fs/classhomes/USER/multilingual-project
  MODEL_REPO=amitayusht/ProofWala-Multilingual
  MODEL_REVISION=main
  MODEL_DIR=/fs/classhomes/USER/multilingual-project/original_trained_multilingual_model
  CONDA_ENV=proofwala-pilot
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
MODEL_REPO="${MODEL_REPO:-amitayusht/ProofWala-Multilingual}"
MODEL_REVISION="${MODEL_REVISION:-main}"
MODEL_DIR="${MODEL_DIR:-${PROJECT_ROOT}/original_trained_multilingual_model}"
CONDA_ENV="${CONDA_ENV:-proofwala-pilot}"
RUN_ROOT="${PROJECT_ROOT}/runs/model_download"
JOB_TMPDIR="/tmp/${USER}/proofwala-orig-model-${SLURM_JOB_ID:-manual}"

mkdir -p "${RUN_ROOT}" "${JOB_TMPDIR}" "${PROJECT_ROOT}/.hf_cache"
exec > "${RUN_ROOT}/download_original_multilingual_model-${SLURM_JOB_ID:-manual}.out" 2>&1

module load miniforge3/24.3.0 || true

source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "${CONDA_ENV}"

export HF_HOME="${PROJECT_ROOT}/.hf_cache"
export HF_DATASETS_CACHE="${PROJECT_ROOT}/.hf_cache/datasets"
export TRANSFORMERS_CACHE="${PROJECT_ROOT}/.hf_cache/transformers"
export TMPDIR="${JOB_TMPDIR}"
export PYTHONUNBUFFERED=1

cleanup() {
  rm -rf "${JOB_TMPDIR}"
}
trap cleanup EXIT

echo "Host: $(hostname)"
echo "Job: ${SLURM_JOB_ID:-unknown}"
echo "NEXUS user: ${NEXUS_USER}"
echo "Project root: ${PROJECT_ROOT}"
echo "Model repo: ${MODEL_REPO}"
echo "Model revision: ${MODEL_REVISION}"
echo "Model dir: ${MODEL_DIR}"
echo "Conda env: ${CONDA_DEFAULT_ENV:-unset}"
python --version
date -Is

python - "${MODEL_REPO}" "${MODEL_REVISION}" "${MODEL_DIR}" <<'PY'
import json
import shutil
import sys
from datetime import datetime, timezone
from pathlib import Path

from safetensors import safe_open
from transformers import AutoConfig, AutoModelForSeq2SeqLM, AutoTokenizer

repo, revision, model_dir_arg = sys.argv[1:4]
model_dir = Path(model_dir_arg)
tmp_dir = model_dir.with_name(model_dir.name + ".tmp")

if tmp_dir.exists():
    shutil.rmtree(tmp_dir)
tmp_dir.mkdir(parents=True, exist_ok=True)

print(f"loading model from {repo}@{revision}", flush=True)
model = AutoModelForSeq2SeqLM.from_pretrained(repo, revision=revision)
tokenizer = AutoTokenizer.from_pretrained(repo, revision=revision)

print(f"saving normalized model snapshot to {tmp_dir}", flush=True)
model.save_pretrained(tmp_dir, safe_serialization=True)
tokenizer.save_pretrained(tmp_dir)

manifest = {
    "repo": repo,
    "revision": revision,
    "downloaded_at": datetime.now(timezone.utc).isoformat(),
    "format": "transformers",
    "weight_file": "model.safetensors",
}
(tmp_dir / "download_manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")

required = ["config.json", "model.safetensors", "tokenizer_config.json", "special_tokens_map.json"]
missing = [name for name in required if not (tmp_dir / name).is_file()]
if missing:
    raise SystemExit(f"missing required files after save: {missing}")

safetensors_path = tmp_dir / "model.safetensors"
if safetensors_path.stat().st_size == 0:
    raise SystemExit(f"empty model.safetensors: {safetensors_path}")

with safe_open(str(safetensors_path), framework="pt") as handle:
    tensor_count = len(handle.keys())
if tensor_count == 0:
    raise SystemExit(f"model.safetensors has no tensors: {safetensors_path}")

AutoConfig.from_pretrained(tmp_dir)
AutoTokenizer.from_pretrained(tmp_dir)
AutoModelForSeq2SeqLM.from_pretrained(tmp_dir)

if model_dir.exists():
    backup_dir = model_dir.with_name(model_dir.name + ".previous")
    if backup_dir.exists():
        shutil.rmtree(backup_dir)
    model_dir.rename(backup_dir)
tmp_dir.rename(model_dir)
if "backup_dir" in locals() and backup_dir.exists():
    shutil.rmtree(backup_dir)

print(f"validated model.safetensors: {model_dir / 'model.safetensors'} ({tensor_count} tensors)")
print(f"model directory ready: {model_dir}")
PY

du -sh "${MODEL_DIR}"
find "${MODEL_DIR}" -maxdepth 1 -type f -printf "%f %s bytes\n" | sort
date -Is
