#!/bin/bash
#SBATCH --job-name=proofwala-e5b
#SBATCH --account=<ACCOUNT>
#SBATCH --partition=<PARTITION>
#SBATCH --qos=<QOS>
#SBATCH --gres=gpu:2
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --time=12:00:00
#SBATCH --output=/home/%u/Desktop/multilingual-project/runs/E5b/slurm-%j.out

set -euo pipefail
source ~/.bashrc
conda activate proofwala-pilot

mkdir -p ~/Desktop/multilingual-project/runs/E5b
cd ~/Desktop/multilingual-project/proof-wala

export ROOT=~/Desktop/multilingual-project/proof-wala
export TRANSFORMERS_CACHE=~/Desktop/multilingual-project/.hf_cache
export HF_HOME=~/Desktop/multilingual-project/.hf_cache

torchrun --nproc-per-node 2 --master-port 31056 \
  proof-wala-train \
  --config-dir=src/proof_wala/main/config \
  --config-name=pilot_e5b.yaml
