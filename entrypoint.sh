#!/usr/bin/env bash
# ============================================================
# entrypoint.sh — Start Ollama and pull models on first run
# ============================================================
set -euo pipefail

# ── Models to make available ─────────────────────────────────
# Edit this list to add/remove models.
# They are pulled once and cached in $OLLAMA_MODELS (/models).
MODELS=(
  "gemma3:27b"          # Gemma 4 27B  — best quality in the family
  "gemma3:4b-it-qat"   # Gemma 4 E4B  — INT4-quantized, very fast
  "qwen2.5:7b"         # Qwen 2.5 7B  — strong multilingual / coding
  "llama4:scout"       # Llama 4 Scout — long-context (10M tokens)
  "mistral:7b-instruct-q4_K_M" # Mistral 7B Q4 — fast, great instruction following
  "phi4:14b-q4_K_M"   # Phi-4 14B Q4 — excellent reasoning per GB of RAM
)

# ── Start Ollama server in the background ─────────────────────
echo "[entrypoint] Starting Ollama server..."
ollama serve &
OLLAMA_PID=$!

# ── Wait for Ollama to be ready ───────────────────────────────
echo "[entrypoint] Waiting for Ollama API..."
until curl -sf http://localhost:11434/api/tags > /dev/null 2>&1; do
  sleep 1
done
echo "[entrypoint] Ollama is ready."

# ── Pull models if not already cached ────────────────────────
for MODEL in "${MODELS[@]}"; do
  if ollama list | grep -q "^${MODEL%%:*}"; then
    echo "[entrypoint] Model already cached, skipping: $MODEL"
  else
    echo "[entrypoint] Pulling model: $MODEL"
    ollama pull "$MODEL" || echo "[entrypoint] WARNING: failed to pull $MODEL — skipping"
  fi
done

echo "[entrypoint] All models ready. Ollama listening on :11434"

# ── Hand off to Ollama process (blocks until killed) ──────────
wait $OLLAMA_PID
