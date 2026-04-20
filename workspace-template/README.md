# LTX-2 RunPod Workspace

This directory is created on first container start and is safe to edit. The image will not overwrite files you change
here on future pod restarts.

## Key Paths

- `configs/` - editable training configs
- `/workspace/models` - model checkpoints and Gemma assets
- `/workspace/datasets` - raw datasets and metadata files
- `/workspace/datasets/preprocessed` - cached latents and text embeddings
- `/workspace/outputs` - training outputs and validation samples
- `/workspace/LTX-2-source` - symlink to the vendored upstream code inside the image

## Helper Commands

```bash
ltx2-download-models
ltx2-preprocess /workspace/datasets/my-dataset/dataset.json --resolution-buckets "960x544x49" --with-audio
ltx2-train /workspace/ltx2-runpod/configs/ltx2_av_lora.runpod.yaml
```

For DDP or FSDP, pass one of the copied Accelerate configs:

```bash
CUDA_VISIBLE_DEVICES=0,1 ltx2-train \
  --accelerate-config /workspace/ltx2-runpod/configs/accelerate/ddp.yaml \
  /workspace/ltx2-runpod/configs/ltx2_av_lora.runpod.yaml
```
