#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-/workspace/musubi-tuner}"
CONFIG_DIR="${CONFIG_DIR:-$REPO_DIR/configs/runpod/ltx23_character_i2v_lokr_h200}"
TRAIN_CONFIG="${TRAIN_CONFIG:-$CONFIG_DIR/train.toml}"
DATASET_CONFIG="${DATASET_CONFIG:-$CONFIG_DIR/dataset.toml}"
SAMPLE_PROMPTS="${SAMPLE_PROMPTS:-$CONFIG_DIR/sample_prompts.txt}"
ACCELERATE_CONFIG="${ACCELERATE_CONFIG:-$CONFIG_DIR/accelerate_single_h200.yaml}"

LTX2_CHECKPOINT="${LTX2_CHECKPOINT:-/workspace/models/ltx/ltx-2.3-22b-dev.safetensors}"
GEMMA_ROOT="${GEMMA_ROOT:-/workspace/models/gemma/gemma-3-12b-it}"
SAMPLE_PROMPTS_CACHE="${SAMPLE_PROMPTS_CACHE:-/workspace/data/ltx23_character_i2v/cache/shared/ltx2_sample_prompts_cache.pt}"
SAMPLE_LATENTS_CACHE="${SAMPLE_LATENTS_CACHE:-/workspace/data/ltx23_character_i2v/cache/shared/ltx2_sample_latents_cache.pt}"

if [[ ! -f "$LTX2_CHECKPOINT" ]]; then
  echo "Missing checkpoint: $LTX2_CHECKPOINT" >&2
  exit 1
fi

if [[ ! -d "$GEMMA_ROOT" ]]; then
  echo "Missing Gemma directory: $GEMMA_ROOT" >&2
  exit 1
fi

mkdir -p \
  /workspace/data/ltx23_character_i2v/cache/shared \
  /workspace/output/ltx23_character_i2v_lokr_h200 \
  /workspace/logs

cd "$REPO_DIR"

python ltx2_cache_latents.py \
  --dataset_config "$DATASET_CONFIG" \
  --ltx2_checkpoint "$LTX2_CHECKPOINT" \
  --ltx2_mode video \
  --device cuda \
  --vae_dtype bf16 \
  --reference_frames 1 \
  --reference_downscale 1 \
  --save_dataset_manifest \
  --precache_sample_latents \
  --sample_prompts "$SAMPLE_PROMPTS" \
  --sample_latents_cache "$SAMPLE_LATENTS_CACHE"

python ltx2_cache_text_encoder_outputs.py \
  --dataset_config "$DATASET_CONFIG" \
  --ltx2_checkpoint "$LTX2_CHECKPOINT" \
  --gemma_root "$GEMMA_ROOT" \
  --gemma_load_in_8bit \
  --device cuda \
  --mixed_precision bf16 \
  --precache_sample_prompts \
  --sample_prompts "$SAMPLE_PROMPTS" \
  --sample_prompts_cache "$SAMPLE_PROMPTS_CACHE"

accelerate launch --config_file "$ACCELERATE_CONFIG" --mixed_precision bf16 ltx2_train_network.py \
  --config_file "$TRAIN_CONFIG" \
  --ltx2_checkpoint "$LTX2_CHECKPOINT" \
  --gemma_root "$GEMMA_ROOT" \
  --sample_prompts "$SAMPLE_PROMPTS" \
  --sample_prompts_cache "$SAMPLE_PROMPTS_CACHE" \
  --sample_latents_cache "$SAMPLE_LATENTS_CACHE"

