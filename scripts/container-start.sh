#!/usr/bin/env bash
set -euo pipefail

/opt/ltx2-runpod/scripts/init-workspace.sh

echo "[ltx2-runpod] Workspace initialized at /workspace/ltx2-runpod"
echo "[ltx2-runpod] Helper commands: ltx2-download-models, ltx2-preprocess, ltx2-train"
echo "[ltx2-runpod] Upstream source snapshot: /opt/LTX-2"

exec /start.sh
