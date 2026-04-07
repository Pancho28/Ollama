#!/usr/bin/env bash
# ============================================================
# entrypoint.sh — Start Ollama and pull models in background
# ============================================================
set -euo pipefail

# ── Models to make available ─────────────────────────────────
MODELS=(
  "gemma3:27b"
  "gemma3:4b-it-qat"
  "qwen2.5:7b"
  "llama4:scout"
  "mistral:7b-instruct-q4_K_M"
  "phi4:14b-q4_K_M"
)

# ── Start Ollama server ───────────────────────────────────────
echo "[entrypoint] Starting Ollama server..."
ollama serve &
OLLAMA_PID=$!

# ── Wait for API to respond (healthcheck pasará aquí) ─────────
echo "[entrypoint] Waiting for Ollama API..."
until curl -sf http://localhost:11434/api/tags > /dev/null 2>&1; do
  sleep 1
done
echo "[entrypoint] Ollama is ready — healthcheck will pass now."

# ── Pull models en background (no bloquea el healthcheck) ─────
(
  for MODEL in "${MODELS[@]}"; do
    if ollama list | grep -q "${MODEL%%:*}"; then
      echo "[pull] Already cached, skipping: $MODEL"
    else
      echo "[pull] Downloading: $MODEL"
      ollama pull "$MODEL" \
        && echo "[pull] Done: $MODEL" \
        || echo "[pull] WARNING: failed to pull $MODEL — skipping"
    fi
  done
  echo "[pull] All models processed."
) &

# ── Mantener vivo el proceso principal ───────────────────────
wait $OLLAMA_PID