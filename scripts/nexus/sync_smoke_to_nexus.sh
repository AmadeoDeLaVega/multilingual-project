#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/nexus/sync_smoke_to_nexus.sh --user USERNAME
  scripts/nexus/sync_smoke_to_nexus.sh --user USERNAME --host nexusclass01.umiacs.umd.edu

This syncs only the small smoke-test assets and config changes needed for
Day 3 smoke jobs. It does not sync the full ProofWalaDataset.
EOF
}

NEXUS_USER=""
NEXUS_HOST="nexusclass01.umiacs.umd.edu"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --user|--username)
      NEXUS_USER="${2:-}"
      shift 2
      ;;
    --host)
      NEXUS_HOST="${2:-}"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "${NEXUS_USER}" ]]; then
  echo "Missing --user" >&2
  usage >&2
  exit 2
fi

PROJECT_ROOT="/fs/classhomes/${NEXUS_USER}/multilingual-project"
REMOTE="${NEXUS_USER}@${NEXUS_HOST}:${PROJECT_ROOT}/"

rsync -azR \
  .gitignore \
  scripts/data/download_proofwala_dataset.py \
  scripts/data/freeze_pilot_splits.py \
  scripts/data/materialize_smoke_datasets.py \
  scripts/nexus/train_smoke.sbatch \
  scripts/nexus/download_proofwala_dataset.sbatch \
  scripts/nexus/sync_smoke_to_nexus.sh \
  proof-wala/src/proof_wala/llm_helpers/model.py \
  proof-wala/src/proof_wala/main/config/__init__.py \
  proof-wala/src/proof_wala/main/run.py \
  proof-wala/src/proof_wala/main/run_training.py \
  proof-wala/src/proof_wala/main/config/smoke_e1.yaml \
  proof-wala/src/proof_wala/main/config/smoke_e3.yaml \
  proof-wala/src/proof_wala/main/config/smoke_e4.yaml \
  data/manifests/dataset_manifest.yaml \
  data/manifests/smoke_manifest.yaml \
  data/frozen_splits/lean_eval_1000_proofs.jsonl \
  data/frozen_splits/lean_test_991_proofs.jsonl \
  data/frozen_splits/split_manifest.yaml \
  data/pseudo_multilingual/e4_audit.md \
  data/smoke/ \
  "${REMOTE}"

echo "Synced smoke assets to ${REMOTE}"
