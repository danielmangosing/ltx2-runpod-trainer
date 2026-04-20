#!/usr/bin/env bash
set -euo pipefail

workspace="${LTX2_WORKSPACE:-/workspace/ltx2-runpod}"
repo_root="${LTX2_REPO:-/opt/LTX-2}"
models_root="${LTX2_MODELS_ROOT:-/workspace/models}"
preprocessed_root="${LTX2_PREPROCESSED_ROOT:-/workspace/datasets/preprocessed}"
template_root="/opt/ltx2-runpod/workspace-template"

mkdir -p \
    "$workspace" \
    "$workspace/configs" \
    "$workspace/configs/accelerate" \
    /workspace/models \
    /workspace/datasets \
    /workspace/datasets/reference \
    /workspace/outputs \
    /workspace/cache/huggingface \
    /workspace/cache/torch \
    /workspace/cache/wandb

cp -an "$template_root/." "$workspace/"

if [[ ! -e /workspace/LTX-2-source ]]; then
    ln -s "$repo_root" /workspace/LTX-2-source
elif [[ -L /workspace/LTX-2-source ]]; then
    current_target="$(readlink /workspace/LTX-2-source)"
    if [[ "$current_target" != "$repo_root" ]]; then
        rm /workspace/LTX-2-source
        ln -s "$repo_root" /workspace/LTX-2-source
    fi
fi

copy_accelerate_config() {
    local source_name="$1"
    local source_path="$repo_root/packages/ltx-trainer/configs/accelerate/$source_name"
    local target_path="$workspace/configs/accelerate/$source_name"

    if [[ ! -f "$target_path" ]]; then
        cp "$source_path" "$target_path"
    fi
}

copy_and_patch_trainer_config() {
    local source_name="$1"
    local target_name="$2"
    local default_output_dir="$3"
    local target_path="$workspace/configs/$target_name"

    if [[ -f "$target_path" ]]; then
        return
    fi

    cp "$repo_root/packages/ltx-trainer/configs/$source_name" "$target_path"

    python3 - "$target_path" "$models_root" "$preprocessed_root" "$default_output_dir" <<'PY'
from pathlib import Path
import sys

target_path = Path(sys.argv[1])
models_root = Path(sys.argv[2])
preprocessed_root = Path(sys.argv[3])
output_dir = sys.argv[4]

content = target_path.read_text()
content = content.replace(
    'model_path: "path/to/ltx-2-model.safetensors"',
    f'model_path: "{models_root / "LTX-2.3" / "ltx-2.3-22b-dev.safetensors"}"',
)
content = content.replace(
    'text_encoder_path: "path/to/gemma-text-encoder"',
    f'text_encoder_path: "{models_root / "gemma-3-12b-it-qat-q4_0-unquantized"}"',
)
content = content.replace(
    'preprocessed_data_root: "/path/to/preprocessed/data"',
    f'preprocessed_data_root: "{preprocessed_root}"',
)
content = content.replace(
    'output_dir: "outputs/ltx2_av_lora"',
    f'output_dir: "{output_dir}"',
)
content = content.replace(
    'output_dir: "outputs/ltx2_v2v_ic_lora"',
    f'output_dir: "{output_dir}"',
)
content = content.replace(
    '    - "/path/to/reference_video_1.mp4"',
    '    - "/workspace/datasets/reference/reference_video_1.mp4"',
)
content = content.replace(
    '    - "/path/to/reference_video_2.mp4"',
    '    - "/workspace/datasets/reference/reference_video_2.mp4"',
)
target_path.write_text(content)
PY
}

copy_accelerate_config "ddp.yaml"
copy_accelerate_config "ddp_compile.yaml"
copy_accelerate_config "fsdp.yaml"
copy_accelerate_config "fsdp_compile.yaml"

copy_and_patch_trainer_config \
    "ltx2_av_lora.yaml" \
    "ltx2_av_lora.runpod.yaml" \
    "/workspace/outputs/ltx2_av_lora"

copy_and_patch_trainer_config \
    "ltx2_av_lora_low_vram.yaml" \
    "ltx2_av_lora_low_vram.runpod.yaml" \
    "/workspace/outputs/ltx2_av_lora_low_vram"

copy_and_patch_trainer_config \
    "ltx2_v2v_ic_lora.yaml" \
    "ltx2_v2v_ic_lora.runpod.yaml" \
    "/workspace/outputs/ltx2_v2v_ic_lora"
