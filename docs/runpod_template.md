# RunPod Template

This fork now includes a RunPod-ready container and a matching GitHub Actions workflow.

## What Was Added

- A root `Dockerfile` based on `runpod/pytorch:1.0.2-cu1281-torch280-ubuntu2404`
- A root `.dockerignore` to keep the image smaller
- `.github/workflows/runpod-image.yml` to build on pull requests and publish to GHCR on branch or tag pushes
- A ready-to-edit H200 training bundle at `configs/runpod/ltx23_character_i2v_lokr_h200/`

## GitHub Actions Publishing

The workflow publishes images to:

```text
ghcr.io/<github-owner>/<repo>
```

Tags are generated automatically:

- `latest` from the default branch
- branch tags such as `ltx-2`
- git tag releases such as `v0.2.15`
- immutable `sha-<commit>` tags

After the first successful publish, make the GHCR package public if you want RunPod to pull it without registry credentials.

## RunPod Template Settings

Recommended Pod template settings:

- Container image: `ghcr.io/<github-owner>/<repo>:latest`
- Container disk: `60 GB` minimum
- Network volume: `200-400 GB` mounted at `/workspace`
- HTTP ports:
  - `8888` for JupyterLab
  - `6006` for TensorBoard
  - `7860` if you decide to expose the optional dashboard
- TCP port:
  - `22` for SSH

If you prefer RunPod's GitHub build flow instead of pulling from GHCR, point RunPod at this repository and use the root `Dockerfile`.

## Workspace Layout

The bundled H200 config expects this layout:

```text
/workspace/
  musubi-tuner/
  models/
    ltx/
      ltx-2.3-22b-dev.safetensors
    gemma/
      gemma-3-12b-it/
  data/
    ltx23_character_i2v/
      train/
      val/
  output/
  logs/
```

The training bundle lives here:

```text
/workspace/musubi-tuner/configs/runpod/ltx23_character_i2v_lokr_h200/
```

## First Run In The Pod

1. Put the LTX 2.3 checkpoint at `/workspace/models/ltx/ltx-2.3-22b-dev.safetensors`.
2. Put the Gemma directory at `/workspace/models/gemma/gemma-3-12b-it/`.
3. Arrange your dataset to match the folder structure described in `configs/runpod/ltx23_character_i2v_lokr_h200/README.md`.
4. Launch caching plus training:

```bash
cd /workspace/musubi-tuner
bash configs/runpod/ltx23_character_i2v_lokr_h200/run_training.sh
```

## Notes

- The Docker image keeps RunPod's default Jupyter and SSH startup behavior intact.
- The H200 training bundle is tuned for a single-GPU RunPod pod.
- Sample prompt text and dataset paths are easy to change without touching the Docker image or workflow.

