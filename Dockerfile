FROM runpod/pytorch:1.0.2-cu1281-torch280-ubuntu2404

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    XDG_CACHE_HOME=/workspace/.cache \
    HF_HOME=/workspace/.cache/huggingface \
    HUGGINGFACE_HUB_CACHE=/workspace/.cache/huggingface/hub \
    HF_HUB_ENABLE_HF_TRANSFER=1 \
    TORCH_HOME=/workspace/.cache/torch \
    MPLCONFIGDIR=/workspace/.cache/matplotlib \
    MUSUBI_HOME=/workspace/musubi-tuner

WORKDIR /workspace/musubi-tuner

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        ffmpeg \
        git \
        git-lfs \
        libgl1 \
        libglib2.0-0 \
        rsync \
        tmux \
        wget && \
    git lfs install --system && \
    rm -rf /var/lib/apt/lists/*

COPY . /workspace/musubi-tuner

RUN python -m pip install --upgrade pip setuptools wheel && \
    python -m pip install -e ".[dashboard]" && \
    python -m pip install \
        ascii-magic \
        hf_transfer \
        lycoris-lora \
        matplotlib \
        prompt-toolkit \
        tensorboard && \
    python -c "import musubi_tuner, torch; print('musubi-tuner ready on torch', torch.__version__)"

RUN mkdir -p \
    /workspace/.cache/huggingface \
    /workspace/.cache/torch \
    /workspace/data \
    /workspace/logs \
    /workspace/models \
    /workspace/output

EXPOSE 22 8888 6006 7860

