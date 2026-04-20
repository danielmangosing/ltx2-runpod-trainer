#!/usr/bin/env bash
set -euo pipefail

repo_root="${LTX2_REPO:-/opt/LTX-2}"
venv_root="${LTX2_VENV:-$repo_root/.venv}"
models_root="${LTX2_MODELS_ROOT:-/workspace/models}"
checkpoint_repo="${LTX2_MODEL_REPO:-Lightricks/LTX-2.3}"
checkpoint_file="${LTX2_MODEL_FILE:-ltx-2.3-22b-dev.safetensors}"
gemma_repo="${LTX2_GEMMA_REPO:-google/gemma-3-12b-it-qat-q4_0-unquantized}"
download_ltx=1
download_gemma=1

usage() {
    cat <<'EOF'
Usage:
  ltx2-download-models [options]

Options:
  --checkpoint-repo REPO     Hugging Face repo for the LTX checkpoint
  --checkpoint-file FILE     Checkpoint filename to download from the repo
  --gemma-repo REPO          Hugging Face repo for the Gemma text encoder
  --models-root DIR          Destination root directory
  --skip-ltx                 Skip the LTX checkpoint download
  --skip-gemma               Skip the Gemma repo download
  -h, --help                 Show this message

Defaults:
  checkpoint repo  = Lightricks/LTX-2.3
  checkpoint file  = ltx-2.3-22b-dev.safetensors
  gemma repo       = google/gemma-3-12b-it-qat-q4_0-unquantized
  models root      = /workspace/models

Notes:
  Set HF_TOKEN or HUGGING_FACE_HUB_TOKEN before running this command if the
  target repositories require authentication or license acceptance.
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --checkpoint-repo)
            checkpoint_repo="$2"
            shift 2
            ;;
        --checkpoint-file)
            checkpoint_file="$2"
            shift 2
            ;;
        --gemma-repo)
            gemma_repo="$2"
            shift 2
            ;;
        --models-root)
            models_root="$2"
            shift 2
            ;;
        --skip-ltx)
            download_ltx=0
            shift
            ;;
        --skip-gemma)
            download_gemma=0
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

mkdir -p "$models_root"

ltx_dir="$models_root/$(basename "$checkpoint_repo")"
gemma_dir="$models_root/$(basename "$gemma_repo")"

if [[ $download_ltx -eq 1 ]]; then
    mkdir -p "$ltx_dir"
    "$venv_root/bin/huggingface-cli" download \
        "$checkpoint_repo" \
        "$checkpoint_file" \
        --local-dir "$ltx_dir"
    echo "Downloaded checkpoint to $ltx_dir/$checkpoint_file"
fi

if [[ $download_gemma -eq 1 ]]; then
    mkdir -p "$gemma_dir"
    "$venv_root/bin/huggingface-cli" download \
        "$gemma_repo" \
        --local-dir "$gemma_dir"
    echo "Downloaded Gemma assets to $gemma_dir"
fi
