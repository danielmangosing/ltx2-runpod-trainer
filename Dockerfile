FROM runpod/pytorch:1.0.2-cu1281-torch280-ubuntu2404

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    UV_LINK_MODE=copy \
    UV_COMPILE_BYTECODE=1 \
    UV_NO_CACHE=1 \
    HF_HOME=/workspace/cache/huggingface \
    HF_HUB_ENABLE_HF_TRANSFER=1 \
    HUGGINGFACE_HUB_CACHE=/workspace/cache/huggingface/hub \
    TRANSFORMERS_CACHE=/workspace/cache/huggingface/transformers \
    TORCH_HOME=/workspace/cache/torch \
    XDG_CACHE_HOME=/workspace/cache \
    WANDB_DIR=/workspace/cache/wandb \
    LTX2_REPO=/opt/LTX-2 \
    LTX2_WORKSPACE=/workspace/ltx2-runpod \
    LTX2_VENV=/opt/LTX-2/.venv

WORKDIR /workspace

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    ffmpeg \
    git \
    git-lfs \
    libgl1 \
    libglib2.0-0 \
    libgomp1 \
    libsndfile1 \
    libsm6 \
    libxext6 \
    libxrender1 \
    tini \
    && rm -rf /var/lib/apt/lists/* \
    && git lfs install --system

RUN python3 -m pip install --upgrade pip uv

COPY LTX-2 /opt/LTX-2
COPY scripts /opt/ltx2-runpod/scripts
COPY workspace-template /opt/ltx2-runpod/workspace-template
COPY README.md /opt/ltx2-runpod/project-README.md

RUN chmod +x /opt/ltx2-runpod/scripts/*.sh \
    && python3 -m venv --system-site-packages /opt/LTX-2/.venv \
    && /opt/LTX-2/.venv/bin/pip install --upgrade pip setuptools wheel \
    && cd /opt/LTX-2 \
    && /opt/LTX-2/.venv/bin/pip install --no-cache-dir \
        -e packages/ltx-core \
        -e packages/ltx-pipelines \
        -e packages/ltx-trainer \
    && ln -sf /opt/ltx2-runpod/scripts/ltx2-download-models.sh /usr/local/bin/ltx2-download-models \
    && ln -sf /opt/ltx2-runpod/scripts/ltx2-preprocess.sh /usr/local/bin/ltx2-preprocess \
    && ln -sf /opt/ltx2-runpod/scripts/ltx2-train.sh /usr/local/bin/ltx2-train

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/opt/ltx2-runpod/scripts/container-start.sh"]
