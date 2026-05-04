#!/bin/bash -l
#SBATCH --job-name=proofwala-data
#SBATCH --account=class
#SBATCH --partition=class
#SBATCH --qos=default
#SBATCH --cpus-per-task=2
#SBATCH --mem=16G
#SBATCH --time=06:00:00
#SBATCH --output=proofwala-data-%j.out

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  sbatch scripts/nexus/download_proofwala_dataset.sbatch --user USERNAME
  sbatch scripts/nexus/download_proofwala_dataset.sbatch --adelaveg

Environment overrides:
  PROJECT_ROOT=/fs/classhomes/USER/multilingual-project
  DATASET_REPO=amitayusht/ProofWalaDataset
  DATASET_REVISION=main
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
DATASET_REPO="${DATASET_REPO:-amitayusht/ProofWalaDataset}"
DATASET_REVISION="${DATASET_REVISION:-main}"
DATASET_DIR="${PROJECT_ROOT}/data/proofwala_dataset/ProofWalaDataset"
MANIFEST_PATH="${PROJECT_ROOT}/.hf_cache/proofwala_dataset_tree.json"
RUN_ROOT="${PROJECT_ROOT}/runs/dataset"

mkdir -p "${RUN_ROOT}" "${PROJECT_ROOT}/.hf_cache"
exec > "${RUN_ROOT}/download_proofwala_dataset-${SLURM_JOB_ID:-manual}.out" 2>&1

module load miniforge3/24.3.0 || true

echo "Host: $(hostname)"
echo "Job: ${SLURM_JOB_ID:-unknown}"
echo "NEXUS user: ${NEXUS_USER}"
echo "Project root: ${PROJECT_ROOT}"
echo "Dataset repo: ${DATASET_REPO}"
echo "Dataset revision: ${DATASET_REVISION}"
echo "Dataset dir: ${DATASET_DIR}"
python3 --version
date -Is

cd "${PROJECT_ROOT}"

python3 scripts/data/download_proofwala_dataset.py \
  --repo "${DATASET_REPO}" \
  --revision "${DATASET_REVISION}" \
  --output-dir "${DATASET_DIR}" \
  --manifest "${MANIFEST_PATH}"

python3 - "${MANIFEST_PATH}" "${DATASET_DIR}" <<'PY'
import json
import pathlib
import sys

manifest_path = pathlib.Path(sys.argv[1])
dataset_dir = pathlib.Path(sys.argv[2])

rows = json.loads(manifest_path.read_text(encoding="utf-8"))
files = [row for row in rows if row.get("type") == "file"]
missing = []
bad_size = []

for row in files:
    relative_path = row["path"]
    expected_size = row.get("size", 0)
    path = dataset_dir / relative_path
    if not path.exists():
        missing.append(relative_path)
        continue
    actual_size = path.stat().st_size
    if actual_size != expected_size:
        bad_size.append((relative_path, actual_size, expected_size))

actual_files = [path for path in dataset_dir.rglob("*") if path.is_file()]
expected_bytes = sum(row.get("size", 0) for row in files)
actual_bytes = sum(path.stat().st_size for path in actual_files)

print(f"expected_files: {len(files)}")
print(f"actual_files: {len(actual_files)}")
print(f"expected_bytes: {expected_bytes}")
print(f"actual_bytes: {actual_bytes}")
print(f"missing_files: {len(missing)}")
print(f"bad_size_files: {len(bad_size)}")

if missing:
    print("first_missing:")
    for item in missing[:20]:
        print(item)
if bad_size:
    print("first_bad_size:")
    for item in bad_size[:20]:
        print(f"{item[0]} actual={item[1]} expected={item[2]}")

if missing or bad_size:
    raise SystemExit(1)

print("verification: ok")
PY

du -sh "${DATASET_DIR}"
date -Is
