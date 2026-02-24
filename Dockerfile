# ─────────────────────────────────────────────────────────────
# AI Town — All-in-one Cloudflare Container
# Generative AI agents living in a virtual 2D world
# Runs: Convex self-hosted backend + AI Town React frontend
# Port 8080 (Node.js proxy) → Convex API + Vite frontend
# ─────────────────────────────────────────────────────────────

# Stage 1: Get Convex self-hosted backend binaries
FROM ghcr.io/get-convex/convex-backend:latest AS convex

# Stage 2: AI Town combined runtime
# node:20-bookworm includes git, curl, and other common tools
FROM node:20-bookworm

# Copy Convex backend (binaries + helpers from /convex working dir)
COPY --from=convex /convex /opt/convex

# Copy pre-downloaded AI Town source (avoids SSL issues with proxy)
COPY ai-town-src /app
WORKDIR /app

# node_modules are pre-installed in ai-town-src (avoids npm registry SSL issues)

# Copy proxy and startup scripts
COPY proxy.mjs /proxy.mjs
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=180s --retries=3 \
  CMD curl -sf http://127.0.0.1:8080/ || exit 1

CMD ["/start.sh"]
