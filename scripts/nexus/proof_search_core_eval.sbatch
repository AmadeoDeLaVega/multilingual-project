#!/bin/bash -l
#SBATCH --job-name=pw-core-eval
#SBATCH --account=class
#SBATCH --partition=class
#SBATCH --qos=medium
#SBATCH --gres=gpu:rtxa5000:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=12:00:00
#SBATCH --array=0-2
#SBATCH --output=proof-search-core-eval-%A_%a.out

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  sbatch scripts/nexus/proof_search_core_eval.sbatch --user USERNAME
  sbatch scripts/nexus/proof_search_core_eval.sbatch --USERNAME

Runs CoreEval.lean proof search for E1, E3, and E4 as a three-task SLURM array.
Each task gets one GPU and an isolated Ray/.log directory.

Useful overrides:
  PROOF_RETRIES=5 sbatch ...
  THEOREM_TIMEOUT=120 sbatch ...
  MODEL_E1=/path/to/final sbatch ...
  MODEL_E3=/path/to/final sbatch ...
  MODEL_E4=/path/to/final sbatch ...
EOF
}

NEXUS_USER="${NEXUS_USER:-${USER:-}}"
PROOF_RETRIES="${PROOF_RETRIES:-1}"
THEOREM_TIMEOUT="${THEOREM_TIMEOUT:-120}"
TOKENIZER_SOURCE="${TOKENIZER_SOURCE:-Salesforce/codet5-small}"
CONDA_ENV="${CONDA_ENV:-proofwala-pilot}"
CONFIG_NAME="${CONFIG_NAME:-eval_core_eval_250.yaml}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --user|--username)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for $1" >&2
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
  echo "Invalid or empty Nexus username: ${NEXUS_USER}" >&2
  exit 2
fi

PROJECT_ROOT="${PROJECT_ROOT:-/fs/classhomes/${NEXUS_USER}/multilingual-project}"
PROOF_WALA_ROOT="${PROJECT_ROOT}/proof-wala"
ITP_INTERFACE_ROOT="${PROJECT_ROOT}/itp-interface"
CONFIG_DIR="${PROOF_WALA_ROOT}/src/proof_wala/main/config"
LOCK_DIR="${PROJECT_ROOT}/runs/locks"
GROUP_ID="${SLURM_ARRAY_JOB_ID:-${SLURM_JOB_ID:-manual-$(date +%Y%m%d-%H%M%S)}}"
TASK_ID="${SLURM_ARRAY_TASK_ID:-0}"

case "${TASK_ID}" in
  0)
    EXPERIMENT="E1"
    MODEL_PATH="${MODEL_E1:-${PROJECT_ROOT}/runs/E1/model/pilot-e1-lean-only-34000x1/final}"
    ;;
  1)
    EXPERIMENT="E3"
    MODEL_PATH="${MODEL_E3:-${PROJECT_ROOT}/runs/E3/model/pilot-e3-real-multilingual/final}"
    ;;
  2)
    EXPERIMENT="E4"
    MODEL_PATH="${MODEL_E4:-${PROJECT_ROOT}/runs/E4/model/pilot-e4-pseudo-multilingual/final}"
    ;;
  *)
    echo "This script expects SLURM_ARRAY_TASK_ID in 0,1,2; got ${TASK_ID}" >&2
    exit 2
    ;;
esac

RUN_ROOT="${PROJECT_ROOT}/runs/proof_search_core_eval/${GROUP_ID}/${EXPERIMENT}"
GROUP_ROOT="${PROJECT_ROOT}/runs/proof_search_core_eval/${GROUP_ID}"
JOB_TMPDIR="/tmp/${USER}/pw-core-eval-${GROUP_ID}-${TASK_ID}"
GENERATION_DEBUG_JSONL="${RUN_ROOT}/generation_debug.jsonl"
METRICS_JSON="${RUN_ROOT}/proof_search_metrics.json"
RAY_MEMORY_BYTES="${RAY_MEMORY_BYTES:-8589934592}"
RAY_PID=""

mkdir -p "${RUN_ROOT}" "${JOB_TMPDIR}" "${LOCK_DIR}"
exec > "${RUN_ROOT}/slurm-${SLURM_JOB_ID:-manual}_${TASK_ID}.out" 2>&1

cleanup() {
  set +e
  if [[ -n "${RAY_PID}" ]] && kill -0 "${RAY_PID}" 2>/dev/null; then
    kill "${RAY_PID}" >/dev/null 2>&1
  fi
  rm -rf "${JOB_TMPDIR}"
}
trap cleanup EXIT

module load miniforge3/24.3.0
module load cuda/12.4.1 || true

source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "${CONDA_ENV}"

export ROOT="${PROOF_WALA_ROOT}"
export HF_HOME="${PROJECT_ROOT}/.hf_cache"
export HF_DATASETS_CACHE="${PROJECT_ROOT}/.hf_cache/datasets"
export TRANSFORMERS_CACHE="${PROJECT_ROOT}/.hf_cache/transformers"
export TMPDIR="${JOB_TMPDIR}"
export FOLLOW_SEED=True
export PYTHONUNBUFFERED=1
export PROOFWALA_GENERATION_DEBUG_JSONL="${GENERATION_DEBUG_JSONL}"
export PYTHONPATH="${PROOF_WALA_ROOT}/src:${ITP_INTERFACE_ROOT}/src:${PYTHONPATH:-}"
export PATH="${HOME}/.elan/bin:${PATH}"

echo "Host: $(hostname)"
echo "Job: ${SLURM_JOB_ID:-unknown}"
echo "Array job: ${GROUP_ID}"
echo "Array task: ${TASK_ID}"
echo "Experiment: ${EXPERIMENT}"
echo "Project root: ${PROJECT_ROOT}"
echo "Run root: ${RUN_ROOT}"
echo "Model path: ${MODEL_PATH}"
echo "Tokenizer source: ${TOKENIZER_SOURCE}"
echo "Config: ${CONFIG_NAME}"
echo "Theorem timeout seconds: ${THEOREM_TIMEOUT}"
echo "Proof retries: ${PROOF_RETRIES}"
echo "CUDA_VISIBLE_DEVICES=${CUDA_VISIBLE_DEVICES:-unset}"
python --version
command -v proof-wala-search
command -v proof-wala-init-ray
nvidia-smi || true

if [[ ! -d "${MODEL_PATH}" ]]; then
  echo "Model path does not exist: ${MODEL_PATH}" >&2
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
if safetensors_path.stat().st_size == 0:
    raise SystemExit(f"Empty model.safetensors: {safetensors_path}")
with safe_open(str(safetensors_path), framework="pt") as handle:
    tensor_count = len(handle.keys())
print(f"Validated model.safetensors: {safetensors_path} ({tensor_count} tensors)")
PY

python - "${MODEL_PATH}" "${TOKENIZER_SOURCE}" <<'PY'
import sys
from pathlib import Path
from transformers import AutoTokenizer

model_path = Path(sys.argv[1])
tokenizer_source = sys.argv[2]
required = ["tokenizer_config.json", "special_tokens_map.json", "vocab.json", "merges.txt"]
if not all((model_path / name).exists() for name in required):
    tokenizer = AutoTokenizer.from_pretrained(tokenizer_source, padding=True, truncation=True, max_length=2048)
    tokenizer.save_pretrained(model_path)
    print(f"Saved tokenizer files into {model_path} from {tokenizer_source}")
else:
    print(f"Tokenizer files already present in {model_path}")
PY

(
  flock 9
  cd "${ITP_INTERFACE_ROOT}/src/itp_interface/lean/tactic_parser"
  python - <<'PY'
from itp_interface.lean.tactic_parser import build_tactic_parser_if_needed

build_tactic_parser_if_needed()
PY
) 9>"${LOCK_DIR}/tactic_parser.lock"

TACTIC_PARSER_ROOT="${ITP_INTERFACE_ROOT}/src/itp_interface/lean/tactic_parser"
if [[ ! -x "${TACTIC_PARSER_ROOT}/.lake/build/bin/tactic-parser" ]]; then
  echo "Missing tactic-parser binary after build" >&2
  exit 2
fi
if [[ ! -x "${TACTIC_PARSER_ROOT}/.lake/build/bin/dependency-parser" ]]; then
  echo "Missing dependency-parser binary after build" >&2
  exit 2
fi

(
  flock 9
  cd "${PROOF_WALA_ROOT}/src/proof_wala/data/proofs/lean/lean4_proj"
  lake build
) 9>"${LOCK_DIR}/lean4_proj_core_eval.lock"

cd "${RUN_ROOT}"
proof-wala-init-ray \
  --num_cpus "${SLURM_CPUS_PER_TASK:-4}" \
  --object_store_memory "${RAY_MEMORY_BYTES}" \
  --memory "${RAY_MEMORY_BYTES}" \
  --metrics_report_interval_ms 300000000 &
RAY_PID=$!

sleep 20

set +e
proof-wala-search \
  --config-dir="${CONFIG_DIR}" \
  --config-name="${CONFIG_NAME}" \
  "log_dir=${RUN_ROOT}/logs" \
  "eval_settings.proof_dump_dir=${RUN_ROOT}/proof_dumps" \
  "eval_settings.checkpoint_dir=${RUN_ROOT}/checkpoints" \
  "eval_settings.model_name=${MODEL_PATH}" \
  "eval_settings.proof_retries=${PROOF_RETRIES}" \
  "eval_settings.timeout_in_secs=${THEOREM_TIMEOUT}" \
  "benchmark.timeout_per_theorem_in_secs=${THEOREM_TIMEOUT}"
SEARCH_EXIT_CODE=$?
set -e

RESULTS_JSON="$(find "${RUN_ROOT}/proof_dumps" -name proof_results.json -type f | sort | tail -n 1 || true)"
{
  echo "# ${EXPERIMENT} CoreEval Proof Search Summary"
  echo
  echo "- job_id: ${SLURM_JOB_ID:-manual}"
  echo "- array_job_id: ${GROUP_ID}"
  echo "- array_task_id: ${TASK_ID}"
  echo "- model_path: ${MODEL_PATH}"
  echo "- config: ${CONFIG_NAME}"
  echo "- run_root: ${RUN_ROOT}"
  echo "- results_json: ${RESULTS_JSON:-not_found}"
  echo "- generation_debug_jsonl: ${GENERATION_DEBUG_JSONL}"
  echo "- metrics_json: ${METRICS_JSON}"
  echo "- proof_wala_search_exit_code: ${SEARCH_EXIT_CODE}"
  echo "- completed_at: $(date -Is)"
} > "${RUN_ROOT}/summary.md"

if [[ -n "${RESULTS_JSON}" && -f "${RESULTS_JSON}" ]]; then
  python - "${RESULTS_JSON}" "${RUN_ROOT}/summary.md" <<'PY'
import json
import sys

results_path, summary_path = sys.argv[1:3]
data = json.load(open(results_path))
theorem_map = data.get("theorem_map", {})
rows = []
for path, proofs in theorem_map.items():
    for theorem, result in proofs.items():
        rows.append((path, theorem, bool(result.get("proof_found"))))
with open(summary_path, "a") as f:
    f.write(f"- attempted: {len(rows)}\n")
    f.write(f"- proved: {sum(1 for _, _, ok in rows if ok)}\n")
PY
fi

python "${PROJECT_ROOT}/scripts/eval/proof_search_metrics.py" \
  --run-root "${RUN_ROOT}" \
  --output "${METRICS_JSON}"

python "${PROJECT_ROOT}/scripts/eval/summarize_parallel_proof_search.py" \
  --group-root "${GROUP_ROOT}"

{
  echo
  echo "## Metrics"
  echo "- metrics_json: ${METRICS_JSON}"
  echo "- metrics_md: ${METRICS_JSON%.json}.md"
  echo "- group_summary_md: ${GROUP_ROOT}/parallel_summary.md"
  echo "- group_summary_csv: ${GROUP_ROOT}/parallel_summary.csv"
} >> "${RUN_ROOT}/summary.md"

exit "${SEARCH_EXIT_CODE}"
