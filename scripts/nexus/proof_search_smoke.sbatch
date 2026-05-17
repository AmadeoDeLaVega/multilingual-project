#!/bin/bash -l
#SBATCH --job-name=proofwala-search-smoke
#SBATCH --account=class
#SBATCH --partition=class
#SBATCH --qos=default
#SBATCH --gres=gpu:rtxa5000:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=02:00:00
#SBATCH --output=proof-search-smoke-%j.out

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  sbatch scripts/nexus/proof_search_smoke.sbatch [--user USERNAME] [--model MODEL_PATH] [--experiment E1]
  sbatch scripts/nexus/proof_search_smoke.sbatch [--USERNAME] [--model MODEL_PATH]

Defaults:
  CONFIG_NAME defaults to eval_simple_lean_test_multilingual_easy.yaml, which
  targets an unfinished Lean theorem in Lean4Proj/Basic.lean. This is the
  intended proof-search smoke fixture because it gives ProofWala an active goal.
  MODEL_PATH defaults to runs/smoke/E1/model/smoke-e1-lean-only/final.

Examples:
  sbatch scripts/nexus/proof_search_smoke.sbatch --user adelaveg
  sbatch scripts/nexus/proof_search_smoke.sbatch --adelaveg --model runs/smoke/E1/model/smoke-e1-lean-only/final

Environment overrides:
  NEXUS_USER=adelaveg sbatch scripts/nexus/proof_search_smoke.sbatch
  PROJECT_ROOT=/fs/classhomes/adelaveg/multilingual-project sbatch scripts/nexus/proof_search_smoke.sbatch
  MODEL_PATH=/fs/classhomes/adelaveg/multilingual-project/runs/smoke/E1/model/smoke-e1-lean-only/final sbatch scripts/nexus/proof_search_smoke.sbatch
  TOKENIZER_SOURCE=Salesforce/codet5-small sbatch scripts/nexus/proof_search_smoke.sbatch
  EXPERIMENT=E1 sbatch scripts/nexus/proof_search_smoke.sbatch
EOF
}

NEXUS_USER="${NEXUS_USER:-${USER:-}}"
MODEL_PATH="${MODEL_PATH:-}"
TOKENIZER_SOURCE="${TOKENIZER_SOURCE:-Salesforce/codet5-small}"
EXPERIMENT="${EXPERIMENT:-}"
CONFIG_NAME="${CONFIG_NAME:-eval_simple_lean_test_multilingual_easy.yaml}"
CONDA_ENV="${CONDA_ENV:-proofwala-pilot}"
LEAN_VERSION="${LEAN_VERSION:-4.15.0}"
THEOREM_TIMEOUT="${THEOREM_TIMEOUT:-180}"
PROOF_RETRIES="${PROOF_RETRIES:-1}"

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
    --tokenizer-source)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for $1" >&2
        usage >&2
        exit 2
      fi
      TOKENIZER_SOURCE="$2"
      shift 2
      ;;
    --tokenizer-source=*)
      TOKENIZER_SOURCE="${1#*=}"
      shift
      ;;
    --config-name)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for $1" >&2
        usage >&2
        exit 2
      fi
      CONFIG_NAME="$2"
      shift 2
      ;;
    --config-name=*)
      CONFIG_NAME="${1#*=}"
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
ITP_INTERFACE_ROOT="${PROJECT_ROOT}/itp-interface"
TACTIC_PARSER_ROOT="${ITP_INTERFACE_ROOT}/src/itp_interface/lean/tactic_parser"
TACTIC_PARSER_BIN="${TACTIC_PARSER_ROOT}/.lake/build/bin/tactic-parser"
DEPENDENCY_PARSER_BIN="${TACTIC_PARSER_ROOT}/.lake/build/bin/dependency-parser"
MODEL_PATH="${MODEL_PATH:-runs/smoke/E1/model/smoke-e1-lean-only/final}"
if [[ "${MODEL_PATH}" != /* ]]; then
  MODEL_PATH="${PROJECT_ROOT}/${MODEL_PATH}"
fi

RUN_TAG="${SLURM_JOB_ID:-manual-$(date +%Y%m%d-%H%M%S)}"
if [[ -n "${EXPERIMENT}" ]]; then
  if [[ ! "${EXPERIMENT}" =~ ^E[0-9A-Za-z_-]+$ ]]; then
    echo "Invalid experiment label: ${EXPERIMENT}" >&2
    exit 2
  fi
  RUN_ROOT="${PROJECT_ROOT}/runs/${EXPERIMENT}/proof_search/${RUN_TAG}"
else
  RUN_ROOT="${PROJECT_ROOT}/runs/proof_search/smoke_lean5/${RUN_TAG}"
fi
GENERATION_DEBUG_JSONL="${RUN_ROOT}/generation_debug.jsonl"
METRICS_JSON="${RUN_ROOT}/proof_search_metrics.json"
JOB_TMPDIR="/tmp/${USER}/pw-search-smoke-${RUN_TAG}"
RAY_MEMORY_BYTES="${RAY_MEMORY_BYTES:-8589934592}"
RAY_PID=""

mkdir -p "${RUN_ROOT}" "${JOB_TMPDIR}"
exec > "${RUN_ROOT}/slurm-${SLURM_JOB_ID:-manual}.out" 2>&1

cleanup() {
  set +e
  ray stop --force >/dev/null 2>&1
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
export LEAN_VERSION

echo "Host: $(hostname)"
echo "Job: ${SLURM_JOB_ID:-unknown}"
echo "NEXUS user: ${NEXUS_USER}"
echo "Project root: ${PROJECT_ROOT}"
echo "ProofWala root: ${PROOF_WALA_ROOT}"
echo "ITP interface root: ${ITP_INTERFACE_ROOT}"
echo "Tactic parser root: ${TACTIC_PARSER_ROOT}"
echo "Model path: ${MODEL_PATH}"
echo "Tokenizer source: ${TOKENIZER_SOURCE}"
echo "Experiment: ${EXPERIMENT:-unset}"
echo "Config: ${CONFIG_NAME}"
echo "Proof retries: ${PROOF_RETRIES}"
echo "Run root: ${RUN_ROOT}"
echo "Generation debug JSONL: ${GENERATION_DEBUG_JSONL}"
echo "Conda env: ${CONDA_DEFAULT_ENV:-unset}"
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

try:
    with safe_open(str(safetensors_path), framework="pt") as handle:
        tensor_count = len(handle.keys())
except Exception as exc:
    raise SystemExit(f"Invalid model.safetensors at {safetensors_path}: {type(exc).__name__}: {exc}") from exc

print(f"Validated model.safetensors before Ray launch: {safetensors_path} ({tensor_count} tensors)")
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

if [[ ! -d "${TACTIC_PARSER_ROOT}" ]]; then
  echo "Tactic parser project does not exist: ${TACTIC_PARSER_ROOT}" >&2
  exit 2
fi

cd "${TACTIC_PARSER_ROOT}"
echo "Building itp-interface Lean tactic parser..."
python - <<'PY'
from itp_interface.lean.tactic_parser import build_tactic_parser_if_needed

build_tactic_parser_if_needed()
PY

if [[ ! -x "${DEPENDENCY_PARSER_BIN}" ]]; then
  echo "dependency-parser was not built or is not executable: ${DEPENDENCY_PARSER_BIN}" >&2
  exit 2
fi
if [[ ! -x "${TACTIC_PARSER_BIN}" ]]; then
  echo "tactic-parser was not built or is not executable: ${TACTIC_PARSER_BIN}" >&2
  exit 2
fi

echo "Validated tactic parser binaries:"
ls -lh "${TACTIC_PARSER_BIN}"
ls -lh "${DEPENDENCY_PARSER_BIN}"

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

sleep 20

set +e
proof-wala-search \
  --config-dir=src/proof_wala/main/config \
  --config-name="${CONFIG_NAME}" \
  "log_dir=${RUN_ROOT}/logs" \
  "eval_settings.proof_dump_dir=${RUN_ROOT}/proof_dumps" \
  "eval_settings.checkpoint_dir=${RUN_ROOT}/checkpoints" \
  "eval_settings.model_name=${MODEL_PATH}" \
  "eval_settings.proof_retries=${PROOF_RETRIES}" \
  "benchmark.timeout_per_theorem_in_secs=${THEOREM_TIMEOUT}"
SEARCH_EXIT_CODE=$?
set -e

RESULTS_JSON="$(find "${RUN_ROOT}/proof_dumps" -name proof_results.json -type f | sort | tail -n 1 || true)"
{
  echo "# Proof Search Smoke Summary"
  echo
  echo "- job_id: ${SLURM_JOB_ID:-manual}"
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
    for path, theorem, ok in rows:
        f.write(f"- {theorem}: {'proved' if ok else 'not_proved'} ({path})\n")
PY
fi

python "${PROJECT_ROOT}/scripts/eval/proof_search_metrics.py" \
  --run-root "${RUN_ROOT}" \
  --output "${METRICS_JSON}"

{
  echo
  echo "## Metrics"
  echo "- metrics_json: ${METRICS_JSON}"
  echo "- metrics_md: ${METRICS_JSON%.json}.md"
} >> "${RUN_ROOT}/summary.md"

if [[ -f "${GENERATION_DEBUG_JSONL}" ]]; then
  python - "${GENERATION_DEBUG_JSONL}" "${RUN_ROOT}/summary.md" <<'PY'
import json
import sys

debug_path, summary_path = sys.argv[1:3]
records = []
with open(debug_path, encoding="utf-8") as handle:
    for line in handle:
        line = line.strip()
        if line:
            records.append(json.loads(line))

with open(summary_path, "a", encoding="utf-8") as f:
    f.write("\n## Generation Debug\n")
    f.write(f"- prompt_count: {len(records)}\n")
    for record in records:
        accepted = sum(1 for output in record.get("outputs", []) if output.get("accepted_as_action"))
        total = len(record.get("outputs", []))
        problem = " ".join(str(record.get("problem", "")).split())
        f.write(f"- {problem[:120]}: {accepted}/{total} parsed as actions\n")
PY
fi

exit "${SEARCH_EXIT_CODE}"
