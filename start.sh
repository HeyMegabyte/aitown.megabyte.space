#!/bin/bash
set -e

echo "============================================"
echo "  AI Town — The Hippest Town on the Internet"
echo "============================================"

# ── Step 1: Start Convex Backend ──
echo "[1/5] Starting Convex self-hosted backend..."
mkdir -p /convex/data
cd /opt/convex

# Generate instance secret
INSTANCE_SECRET=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
INSTANCE_NAME="aitown"

# Start Convex backend (background)
./convex-local-backend \
  --port 3210 \
  --site-proxy-port 3211 \
  --instance-name "$INSTANCE_NAME" \
  --instance-secret "$INSTANCE_SECRET" \
  --local-storage /convex/data \
  --disable-beacon &
BACKEND_PID=$!

# ── Step 2: Wait for backend ──
echo "[2/5] Waiting for Convex backend to be ready..."
for i in $(seq 1 90); do
  if curl -sf http://localhost:3210/version >/dev/null 2>&1; then
    echo "  Convex backend is ready! (${i}s)"
    break
  fi
  if [ $i -eq 90 ]; then
    echo "  WARNING: Convex backend did not start within 90s"
  fi
  sleep 1
done

# ── Step 3: Generate admin key and deploy functions ──
echo "[3/5] Configuring Convex..."
ADMIN_KEY=""
if [ -x ./generate_admin_key.sh ]; then
  ADMIN_KEY=$(./generate_admin_key.sh 2>/dev/null || echo "")
fi

cd /app

# Set the Convex URL for the frontend
# The browser connects to the public URL, which nginx proxies to the backend
echo "VITE_CONVEX_URL=https://aitown.megabyte.space" > .env.local

# Deploy Convex functions to self-hosted backend
if [ -n "$ADMIN_KEY" ] && curl -sf http://localhost:3210/version >/dev/null 2>&1; then
  echo "[3/5] Deploying Convex functions..."
  CONVEX_DEPLOY_KEY="$ADMIN_KEY" npx convex deploy \
    --url "http://127.0.0.1:3210" \
    --yes 2>&1 || echo "  Function deploy: attempted (may need manual config)"

  echo "[3/5] Initializing AI Town world..."
  CONVEX_DEPLOY_KEY="$ADMIN_KEY" npx convex run init \
    --url "http://127.0.0.1:3210" 2>&1 || echo "  World init: attempted"
else
  echo "  Skipping function deploy (no admin key or backend not ready)"
fi

# ── Step 4: Start nginx reverse proxy ──
echo "[4/5] Starting nginx reverse proxy on port 8080..."
nginx

# ── Step 5: Start Vite frontend ──
echo "[5/5] Starting AI Town frontend..."
echo ""
echo "  Frontend:  http://0.0.0.0:5173"
echo "  Convex:    http://127.0.0.1:3210"
echo "  Proxy:     http://0.0.0.0:8080"
echo ""
echo "  Welcome to the hippest town!"
echo ""

exec npx vite --host 0.0.0.0
