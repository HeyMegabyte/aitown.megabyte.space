# ─────────────────────────────────────────────────────────────
# AI Town — All-in-one Cloudflare Container
# Generative AI agents living in a virtual 2D world
# Runs: Convex self-hosted backend + AI Town React frontend
# Port 8080 (nginx reverse proxy) → Convex API + Vite frontend
# ─────────────────────────────────────────────────────────────

# Stage 1: Get Convex self-hosted backend binaries
FROM ghcr.io/get-convex/convex-backend:latest AS convex

# Stage 2: AI Town combined runtime
FROM node:20-bookworm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git curl nginx procps \
    && rm -rf /var/lib/apt/lists/*

# Copy Convex backend (binaries + helpers from /convex working dir)
COPY --from=convex /convex /opt/convex

# Clone AI Town source
RUN git clone --depth 1 https://github.com/a16z-infra/ai-town.git /app
WORKDIR /app

# Install Node.js dependencies
RUN npm install

# Copy configuration files
COPY nginx.conf /etc/nginx/conf.d/aitown.conf
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Remove default nginx site
RUN rm -f /etc/nginx/sites-enabled/default

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=180s --retries=3 \
  CMD curl -sf http://127.0.0.1:8080/ || exit 1

CMD ["/start.sh"]
