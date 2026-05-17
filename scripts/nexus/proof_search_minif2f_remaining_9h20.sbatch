#!/bin/bash -l
#SBATCH --job-name=pw-mf2f-rem
#SBATCH --account=class
#SBATCH --partition=class
#SBATCH --qos=medium
#SBATCH --gres=gpu:rtxa5000:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=40G
#SBATCH --time=09:20:00
#SBATCH --array=0-2
#SBATCH --output=proof-search-minif2f-remaining-%A_%a.out

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  sbatch scripts/nexus/proof_search_minif2f_remaining_9h20.sbatch --user USERNAME
  sbatch scripts/nexus/proof_search_minif2f_remaining_9h20.sbatch --USERNAME

Runs miniF2F Lean 3 proof search for E1, E3, and E4 on all test.lean theorem
declarations except the deterministic easy-10 subset already used by job 6849079.
The job is time-boxed to 9h20m and writes proof_results.json after each theorem.
Metrics are refreshed periodically so partial results remain usable after timeout.
EOF
}

NEXUS_USER="${NEXUS_USER:-${USER:-}}"
PROOF_RETRIES="${PROOF_RETRIES:-1}"
THEOREM_TIMEOUT="${THEOREM_TIMEOUT:-180}"
METRICS_INTERVAL="${METRICS_INTERVAL:-120}"
SEARCH_WALL_TIMEOUT="${SEARCH_WALL_TIMEOUT:-545m}"
TOKENIZER_SOURCE="${TOKENIZER_SOURCE:-Salesforce/codet5-small}"
CONDA_ENV="${CONDA_ENV:-proofwala-pilot}"

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
BASE_CONFIG_DIR="${PROOF_WALA_ROOT}/src/proof_wala/main/config"
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

RUN_ROOT="${PROJECT_ROOT}/runs/proof_search_minif2f_remaining_9h20/${GROUP_ID}/${EXPERIMENT}"
GROUP_ROOT="${PROJECT_ROOT}/runs/proof_search_minif2f_remaining_9h20/${GROUP_ID}"
# Keep this short: Ray's Unix socket path must stay below 107 bytes.
JOB_TMPDIR="/tmp/pwmr${GROUP_ID}_${TASK_ID}"
MINIF2F_STAGE="${JOB_TMPDIR}/miniF2F"
RUN_CONFIG_DIR="${RUN_ROOT}/config"
GENERATION_DEBUG_JSONL="${RUN_ROOT}/generation_debug.jsonl"
METRICS_JSON="${RUN_ROOT}/proof_search_metrics.json"
RAY_MEMORY_BYTES="${RAY_MEMORY_BYTES:-8589934592}"
RAY_PID=""
METRICS_PID=""
SEARCH_EXIT_CODE=0

mkdir -p "${RUN_ROOT}" "${GROUP_ROOT}" "${JOB_TMPDIR}"
exec > "${RUN_ROOT}/slurm-${SLURM_JOB_ID:-manual}_${TASK_ID}.out" 2>&1

refresh_metrics() {
  local results_json
  results_json="$(find "${RUN_ROOT}/proof_dumps" -name proof_results.json -type f | sort | tail -n 1 || true)"
  if [[ -n "${results_json}" && -f "${results_json}" ]]; then
    python "${PROJECT_ROOT}/scripts/eval/proof_search_metrics.py" \
      --run-root "${RUN_ROOT}" \
      --results-json "${results_json}" \
      --generation-debug-jsonl "${GENERATION_DEBUG_JSONL}" \
      --output "${METRICS_JSON}" \
      --include-all-trees || true
  fi
}

metrics_loop() {
  while true; do
    sleep "${METRICS_INTERVAL}" || true
    refresh_metrics
  done
}

cleanup() {
  set +e
  refresh_metrics
  if [[ -n "${METRICS_PID}" ]] && kill -0 "${METRICS_PID}" 2>/dev/null; then
    kill "${METRICS_PID}" >/dev/null 2>&1
  fi
  if [[ -n "${RAY_PID}" ]] && kill -0 "${RAY_PID}" 2>/dev/null; then
    kill "${RAY_PID}" >/dev/null 2>&1
  fi
  rm -rf "${JOB_TMPDIR}"
}
trap cleanup EXIT
trap 'echo "Received termination signal at $(date -Is); refreshing metrics before exit"; cleanup; exit 124' TERM INT

module load miniforge3/24.3.0
module load cuda/12.4.1 || true

source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "${CONDA_ENV}"

export ROOT="${PROOF_WALA_ROOT}"
export HF_HOME="${PROJECT_ROOT}/.hf_cache"
export HF_DATASETS_CACHE="${PROJECT_ROOT}/.hf_cache/datasets"
export TRANSFORMERS_CACHE="${PROJECT_ROOT}/.hf_cache/transformers"
export TMPDIR="${JOB_TMPDIR}"
export ELAN_HOME="${JOB_TMPDIR}/elan"
export FOLLOW_SEED=True
export STRICT_TIME_BUDGET_ACCROSS_ATTEMPTS=True
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
echo "Theorem timeout seconds: ${THEOREM_TIMEOUT}"
echo "Search wall timeout: ${SEARCH_WALL_TIMEOUT}"
echo "Metrics refresh interval seconds: ${METRICS_INTERVAL}"
python --version
command -v proof-wala-search
command -v proof-wala-init-ray
nvidia-smi || true

if [[ ! -d "${MODEL_PATH}" ]]; then
  echo "Model path does not exist: ${MODEL_PATH}" >&2
  exit 2
fi
if [[ ! -d "${PROJECT_ROOT}/miniF2F" ]]; then
  echo "Missing ${PROJECT_ROOT}/miniF2F. Sync the cloned miniF2F repo before running this job." >&2
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

rsync -a --delete --exclude '.git' "${PROJECT_ROOT}/miniF2F/" "${MINIF2F_STAGE}/"
cd "${MINIF2F_STAGE}"

elan toolchain install leanprover-community/lean:3.42.1
elan override set leanprover-community/lean:3.42.1
export PATH="${ELAN_HOME}/toolchains/leanprover-community--lean---v3.42.1/bin:${PATH}"
export LEAN3_BINARY="${ELAN_HOME}/toolchains/leanprover-community--lean---v3.42.1/bin/lean"
lean --version
leanpkg configure

if ! command -v leanproject >/dev/null 2>&1; then
  python -m venv "${JOB_TMPDIR}/mathlibtools-venv"
  "${JOB_TMPDIR}/mathlibtools-venv/bin/pip" install --quiet --upgrade pip
  "${JOB_TMPDIR}/mathlibtools-venv/bin/pip" install --quiet mathlibtools
  export PATH="${JOB_TMPDIR}/mathlibtools-venv/bin:${PATH}"
fi

leanproject get-mathlib-cache

mkdir -p "${RUN_CONFIG_DIR}/benchmark" "${RUN_CONFIG_DIR}/eval_settings" "${RUN_CONFIG_DIR}/env_settings"
rsync -a "${BASE_CONFIG_DIR}/eval_settings/" "${RUN_CONFIG_DIR}/eval_settings/"
rsync -a "${BASE_CONFIG_DIR}/env_settings/" "${RUN_CONFIG_DIR}/env_settings/"

python - "${MINIF2F_STAGE}/lean/src/test.lean" "${RUN_CONFIG_DIR}" "${RUN_ROOT}/theorem_manifest.json" <<'PY'
import json
import re
import sys
from pathlib import Path

test_file = Path(sys.argv[1])
config_dir = Path(sys.argv[2])
manifest_path = Path(sys.argv[3])
excluded = {
    "mathd_algebra_478",
    "mathd_algebra_141",
    "mathd_numbertheory_3",
    "mathd_algebra_209",
    "mathd_algebra_33",
    "mathd_numbertheory_299",
    "amc12b_2020_p2",
    "mathd_numbertheory_345",
    "mathd_numbertheory_207",
    "mathd_numbertheory_342",
}
names = re.findall(r"^theorem\s+([A-Za-z0-9_]+)\b", test_file.read_text(encoding="utf-8", errors="replace"), flags=re.M)
remaining = [name for name in names if name not in excluded]
if len(names) != 244:
    raise SystemExit(f"Expected 244 miniF2F test theorems, found {len(names)}")
if len(remaining) != 234:
    raise SystemExit(f"Expected 234 remaining theorems after excluding easy-10, found {len(remaining)}")

benchmark = config_dir / "benchmark" / "miniF2F_test_remaining_lean3.yaml"
with benchmark.open("w", encoding="utf-8") as handle:
    handle.write("name: miniF2F_test_remaining_lean3\n")
    handle.write("num_files: 1\n")
    handle.write("language: LEAN\n")
    handle.write("few_shot_data_path_for_retrieval: null\n")
    handle.write("few_shot_metadata_filename_for_retrieval: null\n")
    handle.write("dfs_data_path_for_retrieval: null\n")
    handle.write("dfs_metadata_filename_for_retrieval: local.meta.json\n")
    handle.write(f"theorem_cnt: {len(remaining)}\n")
    handle.write("timeout_per_theorem_in_secs: 180\n")
    handle.write("datasets:\n")
    handle.write("- project: <root>/../miniF2F\n")
    handle.write("  files:\n")
    handle.write("  - path: lean/src/test.lean\n")
    handle.write("    theorems:\n")
    for name in remaining:
        handle.write(f"    - {name}\n")

eval_config = config_dir / "eval_miniF2F_remaining_lean3.yaml"
eval_config.write_text(
    "# @package _global_\n"
    "defaults:\n"
    "  - benchmark: miniF2F_test_remaining_lean3\n"
    "  - eval_settings: codet5_beam_16\n"
    "  - env_settings: bm25_retrieval\n"
    "  - override hydra/job_logging: 'disabled'\n\n"
    "log_dir: <root>/data/miniF2F_remaining/proof_logs\n"
    "eval_settings:\n"
    "  proof_dump_dir: <root>/data/miniF2F_remaining/proof_dumps\n"
    "  model_name: Salesforce/codet5-small\n"
    "  checkpoint_dir: .log/checkpoints/miniF2F_remaining\n"
    "  proof_retries: 1\n"
    "  timeout_in_secs: 60\n"
    "  max_proof_depth: 20\n"
    "  width: 16\n"
    "  model_parallelism: 1\n"
    "  temperature: 0.75\n"
    "  do_sample: True\n"
    "  search_params:\n"
    "    beam_width: 16\n\n"
    "benchmark:\n"
    "  timeout_per_theorem_in_secs: 180\n",
    encoding="utf-8",
)
manifest_path.write_text(
    json.dumps(
        {
            "source": str(test_file),
            "total_test_theorems": len(names),
            "excluded_easy10_from_job_6849079": sorted(excluded),
            "remaining_theorem_count": len(remaining),
            "remaining_theorems": remaining,
            "benchmark_config": str(benchmark),
            "eval_config": str(eval_config),
        },
        indent=2,
    )
    + "\n",
    encoding="utf-8",
)
print(f"Wrote {benchmark}")
print(f"Wrote {eval_config}")
print(f"Wrote {manifest_path}")
PY

cd "${RUN_ROOT}"
proof-wala-init-ray \
  --num_cpus "${SLURM_CPUS_PER_TASK:-4}" \
  --object_store_memory "${RAY_MEMORY_BYTES}" \
  --memory "${RAY_MEMORY_BYTES}" \
  --metrics_report_interval_ms 300000000 &
RAY_PID=$!

sleep 20
metrics_loop &
METRICS_PID=$!

set +e
timeout --preserve-status --signal=TERM --kill-after=120s "${SEARCH_WALL_TIMEOUT}" \
  proof-wala-search \
    --config-dir="${RUN_CONFIG_DIR}" \
    --config-name="eval_miniF2F_remaining_lean3.yaml" \
    "log_dir=${RUN_ROOT}/logs" \
    "eval_settings.proof_dump_dir=${RUN_ROOT}/proof_dumps" \
    "eval_settings.checkpoint_dir=${RUN_ROOT}/checkpoints" \
    "eval_settings.model_name=${MODEL_PATH}" \
    "eval_settings.proof_retries=${PROOF_RETRIES}" \
    "eval_settings.timeout_in_secs=60" \
    "benchmark.timeout_per_theorem_in_secs=${THEOREM_TIMEOUT}" \
    "benchmark.datasets.0.project=${MINIF2F_STAGE}"
SEARCH_EXIT_CODE=$?
set -e

refresh_metrics

RESULTS_JSON="$(find "${RUN_ROOT}/proof_dumps" -name proof_results.json -type f | sort | tail -n 1 || true)"
{
  echo "# ${EXPERIMENT} miniF2F Remaining Proof Search Summary"
  echo
  echo "- job_id: ${SLURM_JOB_ID:-manual}"
  echo "- array_job_id: ${GROUP_ID}"
  echo "- array_task_id: ${TASK_ID}"
  echo "- model_path: ${MODEL_PATH}"
  echo "- run_root: ${RUN_ROOT}"
  echo "- theorem_manifest: ${RUN_ROOT}/theorem_manifest.json"
  echo "- results_json: ${RESULTS_JSON:-not_found}"
  echo "- generation_debug_jsonl: ${GENERATION_DEBUG_JSONL}"
  echo "- metrics_json: ${METRICS_JSON}"
  echo "- proof_wala_search_exit_code: ${SEARCH_EXIT_CODE}"
  echo "- completed_at: $(date -Is)"
} > "${RUN_ROOT}/summary.md"

if [[ "${TASK_ID}" == "2" ]]; then
  sleep 10
  python "${PROJECT_ROOT}/scripts/eval/summarize_parallel_proof_search.py" \
    --group-root "${GROUP_ROOT}" \
    --output-prefix "${GROUP_ROOT}/parallel_summary" || true
fi

exit "${SEARCH_EXIT_CODE}"
