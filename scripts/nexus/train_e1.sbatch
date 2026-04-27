#!/bin/bash
#SBATCH --job-name=proofwala-e1
#SBATCH --account=<ACCOUNT>
#SBATCH --partition=<PARTITION>
#SBATCH --qos=<QOS>
#SBATCH --gres=gpu:2
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --time=24:00:00
#SBATCH --output=/home/%u/Desktop/multilingual-project/runs/E1/slurm-%j.out

set -euo pipefail
source ~/.bashrc
conda activate proofwala-pilot

mkdir -p ~/Desktop/multilingual-project/runs/E1
cd ~/Desktop/multilingual-project/proof-wala

export ROOT=~/Desktop/multilingual-project/proof-wala
export TRANSFORMERS_CACHE=~/Desktop/multilingual-project/.hf_cache
export HF_HOME=~/Desktop/multilingual-project/.hf_cache

echo "Host: $(hostname)"
echo "CUDA_VISIBLE_DEVICES=${CUDA_VISIBLE_DEVICES:-unset}"
nvidia-smi || true

torchrun --nproc-per-node 2 --master-port 31052 \
  proof-wala-train \
  --config-dir=src/proof_wala/main/config \
  --config-name=pilot_e1.yaml
