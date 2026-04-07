# ============================================================
# Ollama on Railway — CPU-optimized, on-demand model loading
# Resources: up to 32 vCPU / 32 GB RAM
# ============================================================
FROM ubuntu:24.04

# ── System dependencies ──────────────────────────────────────
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    bash \
    tini \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# ── Install Ollama ───────────────────────────────────────────
RUN curl -fsSL https://ollama.com/install.sh | sh

# ── Entrypoint script ────────────────────────────────────────
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 11434

# tini handles PID 1 / signal forwarding cleanly
ENTRYPOINT ["/usr/bin/tini", "--", "/entrypoint.sh"]
