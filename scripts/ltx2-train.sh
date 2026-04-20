#!/usr/bin/env bash
set -euo pipefail

repo_root="${LTX2_REPO:-/opt/LTX-2}"
venv_root="${LTX2_VENV:-$repo_root/.venv}"
trainer_dir="$repo_root/packages/ltx-trainer"
workspace_root="${LTX2_WORKSPACE:-/workspace/ltx2-runpod}"
default_config="${LTX2_CONFIG_PATH:-$workspace_root/configs/ltx2_av_lora.runpod.yaml}"
accelerate_config="${LTX2_ACCELERATE_CONFIG:-}"
num_processes="${LTX2_NUM_PROCESSES:-}"

usage() {
    cat <<'EOF'
Usage:
  ltx2-train [CONFIG_PATH] [trainer args...]
  ltx2-train --accelerate-config CONFIG_PATH [CONFIG_PATH] [trainer args...]

Examples:
  ltx2-train
  ltx2-train /workspace/ltx2-runpod/configs/ltx2_av_lora_low_vram.runpod.yaml
  CUDA_VISIBLE_DEVICES=0,1 ltx2-train \
    --accelerate-config /workspace/ltx2-runpod/configs/accelerate/ddp.yaml \
    /workspace/ltx2-runpod/configs/ltx2_av_lora.runpod.yaml

Defaults:
  config path        = /workspace/ltx2-runpod/configs/ltx2_av_lora.runpod.yaml
  single-GPU launch  = python scripts/train.py
  multi-GPU launch   = accelerate launch when --accelerate-config is provided
EOF
}

config_path=""
trainer_args=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --accelerate-config)
            accelerate_config="$2"
            shift 2
            ;;
        --num-processes)
            num_processes="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            if [[ -z "$config_path" && "$1" != -* ]]; then
                config_path="$1"
            else
                trainer_args+=("$1")
            fi
            shift
            ;;
    esac
done

if [[ -z "$config_path" ]]; then
    config_path="$default_config"
fi

if [[ ! -f "$config_path" ]]; then
    echo "Training config not found: $config_path" >&2
    exit 1
fi

cd "$trainer_dir"

if [[ -n "$accelerate_config" ]]; then
    cmd=("$venv_root/bin/accelerate" launch)
    if [[ -n "$num_processes" ]]; then
        cmd+=(--num_processes "$num_processes")
    fi
    cmd+=(--config_file "$accelerate_config" scripts/train.py "$config_path")
    exec "${cmd[@]}" "${trainer_args[@]}"
fi

exec "$venv_root/bin/python" scripts/train.py "$config_path" "${trainer_args[@]}"
