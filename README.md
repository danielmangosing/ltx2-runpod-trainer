# LTX-2 RunPod Trainer Image

This project packages the official [Lightricks/LTX-2](https://github.com/Lightricks/LTX-2) trainer into a RunPod-ready
Docker image with a persistent `/workspace` layout, helper commands, seeded configs, and an optional GitHub Actions
build workflow.

It currently vendors the upstream repository at:

- Commit: `a2c3f24078eb918171967f74b6f66b756b29ee45`
- Commit date: `2026-04-13 18:30:04 +0300`

## What This Image Includes

- The official `packages/ltx-trainer` monorepo installation via `uv sync --frozen`
- A RunPod-friendly startup script that preserves Jupyter/SSH from the `runpod/pytorch` base image
- Helper commands:
  - `ltx2-download-models`
  - `ltx2-preprocess`
  - `ltx2-train`
- First-boot seeding of editable configs into `/workspace/ltx2-runpod/configs`
- A stable data layout for models, datasets, caches, and outputs

## Runtime Layout

The image keeps the vendored upstream code in the container and writes user data to the mounted RunPod volume:

- `/opt/LTX-2` - immutable upstream source snapshot inside the image
- `/workspace/ltx2-runpod` - editable configs and quick-start notes
- `/workspace/models` - model checkpoints and Gemma assets
- `/workspace/datasets` - raw datasets and preprocessed latents
- `/workspace/outputs` - checkpoints, logs, and validation samples
- `/workspace/cache` - Hugging Face, Torch, and W&B caches
- `/workspace/LTX-2-source` - symlink back to the vendored upstream source tree

## Build Locally

```bash
docker build --platform linux/amd64 -t yourname/ltx2-runpod-trainer:v1 .
docker push yourname/ltx2-runpod-trainer:v1
```

If you do not want to build locally, push this project to GitHub and use the included workflow in
`.github/workflows/build-image.yml` to publish a public GHCR image.

## Recommended RunPod Template Settings

- Container image: `yourname/ltx2-runpod-trainer:v1`
- Container disk: at least `60 GB`
- Volume mount path: `/workspace`
- HTTP ports: `8888`
- TCP ports: `22`
- Start command: leave blank so the image default command runs

Recommended template environment variables:

- `HF_TOKEN` for gated Hugging Face downloads
- `WANDB_API_KEY` if you want Weights & Biases logging

## First Pod Boot

Once the pod is running, connect over the web terminal, SSH, or Jupyter terminal and use:

```bash
ltx2-download-models
ltx2-preprocess /workspace/datasets/my-dataset/dataset.json --resolution-buckets "960x544x49" --with-audio
ltx2-train /workspace/ltx2-runpod/configs/ltx2_av_lora.runpod.yaml
```

The helper commands default to these paths:

- Model checkpoint: `/workspace/models/LTX-2.3/ltx-2.3-22b-dev.safetensors`
- Gemma text encoder: `/workspace/models/gemma-3-12b-it-qat-q4_0-unquantized`
- Preprocessed data root: `/workspace/datasets/preprocessed`

If you want a different checkpoint, either:

- pass explicit flags such as `--model-path ...`, or
- set environment variables like `LTX2_MODEL_FILE`, `LTX2_MODEL_PATH`, or `LTX2_TEXT_ENCODER_PATH`

## Included Configs

On first startup, the container copies editable training configs into `/workspace/ltx2-runpod/configs`:

- `ltx2_av_lora.runpod.yaml`
- `ltx2_av_lora_low_vram.runpod.yaml`
- `ltx2_v2v_ic_lora.runpod.yaml`
- `accelerate/ddp.yaml`
- `accelerate/ddp_compile.yaml`
- `accelerate/fsdp.yaml`
- `accelerate/fsdp_compile.yaml`

The copied trainer configs are based on the official samples and patched to use `/workspace/...` paths.

## Notes

- The upstream trainer docs still mention the older `ltx-2-19b-dev.safetensors` in one quick-start page, but the
  repository root now references `LTX-2.3` model assets. This image defaults to the current `LTX-2.3` naming while
  keeping everything path-driven so you can swap checkpoints without rebuilding the image.
- Standard training still wants very large GPUs. The official trainer docs recommend `80 GB+` VRAM for the default
  config and the low-VRAM config for `32 GB` cards.
