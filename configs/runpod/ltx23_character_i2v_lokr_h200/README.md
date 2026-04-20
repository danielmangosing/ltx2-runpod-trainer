# LTX 2.3 Character I2V LoKR on H200

This bundle is a practical starting point for a small mixed image and video character dataset on a single H200.

## What It Assumes

- You are training on RunPod inside the included Docker image
- You want an LTX 2.3 image-to-video style character adapter
- You want `learning_rate = 1e-4`
- You want `max_train_steps = 5000`
- You want motion rehearsal enabled
- Your dataset contains both:
  - short character videos
  - still images that help lock identity
- Each training item has a matching reference image or video with the same filename stem

## Why This Preset Looks The Way It Does

- It uses `ic_lora_strategy = "v2v"` so the trainer runs the LTX in-context I2V path.
- It uses `lora_target_preset = "video_sa_ca_ff"` instead of the broader `v2v` preset so audio-side layers stay untouched even if the checkpoint exposes them.
- It uses LyCORIS LoKR with `base_factor = 16` and `lokr_norm = 1e-3`, which is a stable upstream-style starting point.
- It keeps resolution at `1024x576` and video length capped at `49` frames, which is a strong quality/speed balance on an H200.
- It biases the dataset slightly toward videos so motion signal is not drowned out by stills.

## Expected Dataset Layout

```text
/workspace/data/ltx23_character_i2v/
  train/
    videos/
      shot_0001.mp4
      shot_0001.txt
    references/
      videos/
        shot_0001.png
    images/
      portrait_0001.png
      portrait_0001.txt
    references/
      images/
        portrait_0001.png
  val/
    videos/
    references/
      videos/
    images/
    references/
      images/
```

Matching is stem-based:

- `train/videos/shot_0001.mp4` pairs with `train/references/videos/shot_0001.png`
- `train/images/portrait_0001.png` pairs with `train/references/images/portrait_0001.png`

## Files

- `dataset.toml`: mixed train and validation datasets
- `train.toml`: main 5000-step H200 training config
- `lycoris_lokr.toml`: LoKR algorithm settings
- `accelerate_single_h200.yaml`: single-GPU Accelerate config
- `sample_prompts.txt`: preview prompts for training samples
- `run_training.sh`: cache latents, cache text, then launch training

## Quick Start

```bash
cd /workspace/musubi-tuner
bash configs/runpod/ltx23_character_i2v_lokr_h200/run_training.sh
```

Edit `sample_prompts.txt` first so the reference paths and trigger token match your dataset.

