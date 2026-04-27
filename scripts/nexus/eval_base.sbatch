#!/bin/bash
#SBATCH --job-name=proofwala-eval-base
#SBATCH --account=<ACCOUNT>
#SBATCH --partition=<PARTITION>
#SBATCH --qos=<QOS>
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=12
#SBATCH --mem=64G
#SBATCH --time=12:00:00
#SBATCH --output=/home/%u/Desktop/multilingual-project/runs/eval-base-slurm-%j.out

set -euo pipefail
source ~/.bashrc
conda activate proofwala-pilot

cd ~/Desktop/multilingual-project/proof-wala
export ROOT=~/Desktop/multilingual-project/proof-wala
export TRANSFORMERS_CACHE=~/Desktop/multilingual-project/.hf_cache
export HF_HOME=~/Desktop/multilingual-project/.hf_cache
export FOLLOW_SEED=True

rm -f .log/ray/session_latest || true
proof-wala-init-ray --num_cpus 12 --object_store_memory 25769803776 --memory 25769803776 --metrics_report_interval_ms 300000000 &
sleep 15

proof-wala-search --config-dir=src/proof_wala/main/config --config-name=pilot_eval_e1.yaml
proof-wala-search --config-dir=src/proof_wala/main/config --config-name=pilot_eval_e3.yaml
proof-wala-search --config-dir=src/proof_wala/main/config --config-name=pilot_eval_e4.yaml
