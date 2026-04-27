#!/bin/bash -l
#SBATCH --job-name=proofwala-e0
#SBATCH --account=class
#SBATCH --partition=class
#SBATCH --qos=default
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=04:00:00
#SBATCH --output=eval_e0-%j.out

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  sbatch scripts/nexus/eval_e0.sbatch [--user USERNAME]
  sbatch scripts/nexus/eval_e0.sbatch [--USERNAME]

Examples:
  sbatch scripts/nexus/eval_e0.sbatch --user adelaveg
  sbatch scripts/nexus/eval_e0.sbatch --adelaveg

Environment overrides:
  NEXUS_USER=adelaveg sbatch scripts/nexus/eval_e0.sbatch
  PROJECT_ROOT=/fs/classhomes/adelaveg/multilingual-project sbatch scripts/nexus/eval_e0.sbatch
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
PROOF_WALA_ROOT="${PROJECT_ROOT}/proof-wala"
RUN_ROOT="${PROJECT_ROOT}/runs/E0"
CONDA_ENV="${CONDA_ENV:-proofwala-pilot}"
LEAN_VERSION="${LEAN_VERSION:-4.15.0}"
JOB_TMPDIR="/tmp/${USER}/pw-e0-${SLURM_JOB_ID:-manual}"
RAY_MEMORY_BYTES=8589934592

mkdir -p "${RUN_ROOT}" "${PROJECT_ROOT}/.hf_cache" "${JOB_TMPDIR}"
exec > "${RUN_ROOT}/slurm-${SLURM_JOB_ID:-manual}.out" 2>&1

module load miniforge3/24.3.0
module load cuda/12.4.1 || true

source "$(conda info --base)/etc/profile.d/conda.sh"

if ! conda env list | awk '{print $1}' | grep -Fxq "${CONDA_ENV}"; then
  echo "Creating conda environment ${CONDA_ENV}"
  conda create -y -n "${CONDA_ENV}" python=3.10 pip
fi

conda activate "${CONDA_ENV}"

if ! python -c "import proof_wala, torch, transformers, ray; from itp_interface.lean.tactic_parser import build_tactic_parser_if_needed" >/dev/null 2>&1; then
  echo "Installing ProofWala dependencies into ${CONDA_ENV}"
  python -m pip install --upgrade pip
  python -m pip install -r "${PROJECT_ROOT}/itp-interface/requirements.txt"
  PROOF_WALA_REQ="${RUN_ROOT}/proof-wala-requirements-e0.txt"
  grep -Ev '^(itp-interface|protobuf==)' "${PROJECT_ROOT}/proof-wala/requirements.txt" > "${PROOF_WALA_REQ}"
  python -m pip install protobuf==3.20.3
  python -m pip install --use-deprecated=legacy-resolver -r "${PROOF_WALA_REQ}"
  python -m pip install \
    'setuptools<81' \
    'pydantic>=2.10.6' \
    'ray>=2.50.0' \
    'numpy==1.26.4' \
    'huggingface-hub>=0.24.0,<1.0' \
    'pylspclient==0.0.3' \
    'fsspec[http]>=2023.1.0,<=2023.10.0' \
    'multiprocess==0.70.15'
  python -m pip install --no-deps -e "${PROJECT_ROOT}/itp-interface" -e "${PROJECT_ROOT}/proof-wala"
fi

if ! python -c "import pkg_resources" >/dev/null 2>&1; then
  echo "Installing setuptools for pkg_resources"
  python -m pip install 'setuptools<81'
fi

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
echo "NEXUS user: ${NEXUS_USER}"
echo "Project root: ${PROJECT_ROOT}"
echo "ProofWala root: ${PROOF_WALA_ROOT}"
echo "Conda env: ${CONDA_DEFAULT_ENV:-unset}"
echo "CUDA_VISIBLE_DEVICES=${CUDA_VISIBLE_DEVICES:-unset}"
python --version
command -v proof-wala-search
command -v proof-wala-init-ray
command -v elan || true
elan --version || true
nvidia-smi || true

if ! command -v lake >/dev/null 2>&1; then
  install-lean-repl
  export PATH="${HOME}/.elan/bin:${PATH}"
fi

elan toolchain install "leanprover/lean4:v${LEAN_VERSION}" || true
elan override unset --path "${PROJECT_ROOT}" || true
elan run "leanprover/lean4:v${LEAN_VERSION}" lean --version
install-itp-interface
elan override unset --path "${PROJECT_ROOT}" || true

cd "${PROOF_WALA_ROOT}/src/proof_wala/data/proofs/lean/lean4_proj"
lake build

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
  --config-name=eval_simple_lean_test_multilingual_easy.yaml
