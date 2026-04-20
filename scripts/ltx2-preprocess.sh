#!/usr/bin/env bash
set -euo pipefail

repo_root="${LTX2_REPO:-/opt/LTX-2}"
venv_root="${LTX2_VENV:-$repo_root/.venv}"
trainer_dir="$repo_root/packages/ltx-trainer"
models_root="${LTX2_MODELS_ROOT:-/workspace/models}"
default_model_path="${LTX2_MODEL_PATH:-$models_root/LTX-2.3/ltx-2.3-22b-dev.safetensors}"
default_text_encoder_path="${LTX2_TEXT_ENCODER_PATH:-$models_root/gemma-3-12b-it-qat-q4_0-unquantized}"
default_output_dir="${LTX2_PREPROCESSED_ROOT:-/workspace/datasets/preprocessed}"

usage() {
    cat <<'EOF'
Usage:
  ltx2-preprocess DATASET_PATH [process_dataset.py args...]

Examples:
  ltx2-preprocess /workspace/datasets/my-dataset/dataset.json --resolution-buckets "960x544x49"
  ltx2-preprocess /workspace/datasets/my-dataset/dataset.json --resolution-buckets "960x544x49" --with-audio

Defaults supplied by this wrapper:
  --model-path        /workspace/models/LTX-2.3/ltx-2.3-22b-dev.safetensors
  --text-encoder-path /workspace/models/gemma-3-12b-it-qat-q4_0-unquantized
  --output-dir        /workspace/datasets/preprocessed

Pass explicit flags to override any default path.
EOF
}

if [[ $# -eq 0 ]]; then
    usage >&2
    exit 1
fi

dataset_path=""
has_model_path=0
has_text_encoder_path=0
has_output_dir=0
args=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --model-path)
            has_model_path=1
            args+=("$1" "$2")
            shift 2
            ;;
        --text-encoder-path)
            has_text_encoder_path=1
            args+=("$1" "$2")
            shift 2
            ;;
        --output-dir)
            has_output_dir=1
            args+=("$1" "$2")
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            if [[ -z "$dataset_path" && "$1" != -* ]]; then
                dataset_path="$1"
            fi
            args+=("$1")
            shift
            ;;
    esac
done

if [[ -z "$dataset_path" ]]; then
    echo "A dataset metadata file path is required." >&2
    usage >&2
    exit 1
fi

if [[ $has_model_path -eq 0 && ! -f "$default_model_path" ]]; then
    echo "Default model checkpoint not found: $default_model_path" >&2
    echo "Run ltx2-download-models or pass --model-path explicitly." >&2
    exit 1
fi

if [[ $has_text_encoder_path -eq 0 && ! -d "$default_text_encoder_path" ]]; then
    echo "Default Gemma directory not found: $default_text_encoder_path" >&2
    echo "Run ltx2-download-models or pass --text-encoder-path explicitly." >&2
    exit 1
fi

if [[ $has_model_path -eq 0 ]]; then
    args+=(--model-path "$default_model_path")
fi

if [[ $has_text_encoder_path -eq 0 ]]; then
    args+=(--text-encoder-path "$default_text_encoder_path")
fi

if [[ $has_output_dir -eq 0 ]]; then
    mkdir -p "$default_output_dir"
    args+=(--output-dir "$default_output_dir")
fi

cd "$trainer_dir"
exec "$venv_root/bin/python" scripts/process_dataset.py "${args[@]}"
