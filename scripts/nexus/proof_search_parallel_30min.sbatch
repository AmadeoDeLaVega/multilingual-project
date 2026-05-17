#!/bin/bash -l
#SBATCH --job-name=pw-search-30m
#SBATCH --account=class
#SBATCH --partition=class
#SBATCH --qos=medium
#SBATCH --gres=gpu:rtxa5000:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=00:30:00
#SBATCH --array=0-2
#SBATCH --output=proof-search-30m-%A_%a.out

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  sbatch scripts/nexus/proof_search_parallel_30min.sbatch --user USERNAME
  sbatch scripts/nexus/proof_search_parallel_30min.sbatch --USERNAME

Runs E1, E3, and E4 as a three-task SLURM array. Each task gets one GPU and an
isolated Ray/.log working directory. By default the job uses the largest
conservative same-theorem subset estimated to fit a 30-minute allocation from
the observed easy-proof timings.

Useful overrides:
  THEOREM_COUNT=15 sbatch ...       # override the automatic safe count
  PROOF_RETRIES=5 sbatch ...        # collect observed pass@5, with fewer theorems recommended
  THEOREM_TIMEOUT=120 sbatch ...    # per-theorem timeout in seconds
  SEARCH_TIMEOUT_SECONDS=1500 sbatch ...
  MODEL_E1=/path/to/final sbatch ...
  MODEL_E3=/path/to/final sbatch ...
  MODEL_E4=/path/to/final sbatch ...
EOF
}

NEXUS_USER="${NEXUS_USER:-${USER:-}}"
BUDGET_MINUTES="${BUDGET_MINUTES:-30}"
USABLE_FRACTION="${USABLE_FRACTION:-0.75}"
SLOWEST_OBSERVED_SECONDS="${SLOWEST_OBSERVED_SECONDS:-113.46}"
PROOF_RETRIES="${PROOF_RETRIES:-1}"
THEOREM_TIMEOUT="${THEOREM_TIMEOUT:-120}"
TOKENIZER_SOURCE="${TOKENIZER_SOURCE:-Salesforce/codet5-small}"
CONDA_ENV="${CONDA_ENV:-proofwala-pilot}"
LEAN_VERSION="${LEAN_VERSION:-4.15.0}"
THEOREM_COUNT="${THEOREM_COUNT:-}"
SEARCH_TIMEOUT_SECONDS="${SEARCH_TIMEOUT_SECONDS:-}"

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

if [[ -z "${THEOREM_COUNT}" ]]; then
  THEOREM_COUNT="$(python3 - "${BUDGET_MINUTES}" "${USABLE_FRACTION}" "${SLOWEST_OBSERVED_SECONDS}" "${PROOF_RETRIES}" <<'PY'
import math
import sys

budget_minutes = float(sys.argv[1])
usable_fraction = float(sys.argv[2])
slowest_seconds = float(sys.argv[3])
proof_retries = max(1, int(sys.argv[4]))
usable_seconds = budget_minutes * 60.0 * usable_fraction
print(max(1, math.floor(usable_seconds / (slowest_seconds * proof_retries))))
PY
)"
fi

TOTAL_SECONDS=$((BUDGET_MINUTES * 60))
if [[ -z "${SEARCH_TIMEOUT_SECONDS}" ]]; then
  SEARCH_TIMEOUT_SECONDS=$((TOTAL_SECONDS - 240))
  if [[ "${SEARCH_TIMEOUT_SECONDS}" -lt 300 ]]; then
    SEARCH_TIMEOUT_SECONDS=$((TOTAL_SECONDS - 60))
  fi
fi

RUN_ROOT="${PROJECT_ROOT}/runs/proof_search_parallel_30min/${GROUP_ID}/${EXPERIMENT}"
GROUP_ROOT="${PROJECT_ROOT}/runs/proof_search_parallel_30min/${GROUP_ID}"
JOB_TMPDIR="/tmp/${USER}/pw-search-30m-${GROUP_ID}-${TASK_ID}"
HOST_TAG="$(hostname -s)"
MATHLIB_WORK_ROOT="${MATHLIB_WORK_ROOT:-/tmp/${USER}/pw-search-30m-${GROUP_ID}-${HOST_TAG}-mathlib}"
GENERATION_DEBUG_JSONL="${RUN_ROOT}/generation_debug.jsonl"
METRICS_JSON="${RUN_ROOT}/proof_search_metrics.json"
BENCHMARK_NAME="leandojo_test_30min_${GROUP_ID}_${TASK_ID}_${EXPERIMENT}"
BENCHMARK_CONFIG="${CONFIG_DIR}/benchmark/${BENCHMARK_NAME}.yaml"
RUNTIME_BENCHMARK_CONFIG="${RUN_ROOT}/benchmark.yaml"
SELECTED_REFS="${RUN_ROOT}/selected_theorems.jsonl"
SELECTED_MANIFEST="${RUN_ROOT}/selected_theorems_manifest.yaml"
RAY_MEMORY_BYTES="${RAY_MEMORY_BYTES:-8589934592}"
RAY_PID=""

mkdir -p "${RUN_ROOT}" "${JOB_TMPDIR}" "${LOCK_DIR}"
exec > "${RUN_ROOT}/slurm-${SLURM_JOB_ID:-manual}_${TASK_ID}.out" 2>&1

cleanup() {
  set +e
  if [[ -n "${RAY_PID}" ]] && kill -0 "${RAY_PID}" 2>/dev/null; then
    kill "${RAY_PID}" >/dev/null 2>&1
  fi
  rm -f "${BENCHMARK_CONFIG}"
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
export LEAN_VERSION

echo "Host: $(hostname)"
echo "Job: ${SLURM_JOB_ID:-unknown}"
echo "Array job: ${GROUP_ID}"
echo "Array task: ${TASK_ID}"
echo "Experiment: ${EXPERIMENT}"
echo "Project root: ${PROJECT_ROOT}"
echo "Run root: ${RUN_ROOT}"
echo "Model path: ${MODEL_PATH}"
echo "Tokenizer source: ${TOKENIZER_SOURCE}"
echo "Theorem count: ${THEOREM_COUNT}"
echo "Budget minutes: ${BUDGET_MINUTES}"
echo "Search timeout seconds: ${SEARCH_TIMEOUT_SECONDS}"
echo "Theorem timeout seconds: ${THEOREM_TIMEOUT}"
echo "Proof retries: ${PROOF_RETRIES}"
echo "Benchmark name: ${BENCHMARK_NAME}"
echo "Mathlib work root: ${MATHLIB_WORK_ROOT}"
echo "CUDA_VISIBLE_DEVICES=${CUDA_VISIBLE_DEVICES:-unset}"
python --version
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
  if [[ ! -f "${MATHLIB_WORK_ROOT}/.proofwala-ready" ]]; then
    rm -rf "${MATHLIB_WORK_ROOT}"
    mkdir -p "${MATHLIB_WORK_ROOT}"
    cp "${ITP_INTERFACE_ROOT}/src/data/test/Mathlib/lakefile.lean" "${MATHLIB_WORK_ROOT}/"
    cp "${ITP_INTERFACE_ROOT}/src/data/test/Mathlib/lake-manifest.json" "${MATHLIB_WORK_ROOT}/"
    cp "${ITP_INTERFACE_ROOT}/src/data/test/Mathlib/lean-toolchain" "${MATHLIB_WORK_ROOT}/"
    cp "${ITP_INTERFACE_ROOT}/src/data/test/Mathlib/ReplMathlibTests.lean" "${MATHLIB_WORK_ROOT}/"
    cd "${MATHLIB_WORK_ROOT}"
    lake exe cache get
    lake build ReplMathlibTests
    touch "${MATHLIB_WORK_ROOT}/.proofwala-ready"
  fi
) 9>"${LOCK_DIR}/mathlib_test_stage_${HOST_TAG}.lock"

python "${PROJECT_ROOT}/scripts/data/freeze_proof_search_subset.py" \
  --input-refs "${PROJECT_ROOT}/data/proof_search_subsets/lean_test_250_refs.jsonl" \
  --source-benchmark "${PROJECT_ROOT}/proof-wala/src/proof_wala/main/config/benchmark/leandojo_test.yaml" \
  --count "${THEOREM_COUNT}" \
  --seed 20260516 \
  --name "${BENCHMARK_NAME//_/-}" \
  --project-override "${MATHLIB_WORK_ROOT}" \
  --timeout-per-theorem "${THEOREM_TIMEOUT}" \
  --output-refs "${SELECTED_REFS}" \
  --output-benchmark "${RUNTIME_BENCHMARK_CONFIG}" \
  --output-manifest "${SELECTED_MANIFEST}"
cp "${RUNTIME_BENCHMARK_CONFIG}" "${BENCHMARK_CONFIG}"

cd "${RUN_ROOT}"
proof-wala-init-ray \
  --num_cpus "${SLURM_CPUS_PER_TASK:-4}" \
  --object_store_memory "${RAY_MEMORY_BYTES}" \
  --memory "${RAY_MEMORY_BYTES}" \
  --metrics_report_interval_ms 300000000 &
RAY_PID=$!

sleep 20

set +e
timeout --kill-after=60s "${SEARCH_TIMEOUT_SECONDS}s" proof-wala-search \
  --config-dir="${CONFIG_DIR}" \
  --config-name=eval_leandojo_test_30min_calibration.yaml \
  "benchmark=${BENCHMARK_NAME}" \
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
  echo "# ${EXPERIMENT} 30-Minute Proof Search Summary"
  echo
  echo "- job_id: ${SLURM_JOB_ID:-manual}"
  echo "- array_job_id: ${GROUP_ID}"
  echo "- array_task_id: ${TASK_ID}"
  echo "- model_path: ${MODEL_PATH}"
  echo "- theorem_count_requested: ${THEOREM_COUNT}"
  echo "- selected_refs: ${SELECTED_REFS}"
  echo "- selected_manifest: ${SELECTED_MANIFEST}"
  echo "- benchmark_config: ${RUNTIME_BENCHMARK_CONFIG}"
  echo "- temporary_hydra_benchmark_config: ${BENCHMARK_CONFIG}"
  echo "- run_root: ${RUN_ROOT}"
  echo "- results_json: ${RESULTS_JSON:-not_found}"
  echo "- generation_debug_jsonl: ${GENERATION_DEBUG_JSONL}"
  echo "- metrics_json: ${METRICS_JSON}"
  echo "- proof_wala_search_exit_code: ${SEARCH_EXIT_CODE}"
  echo "- completed_at: $(date -Is)"
} > "${RUN_ROOT}/summary.md"

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
