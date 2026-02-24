#!/bin/bash
set -e

echo "============================================"
echo "  AI Town — The Hippest Town on the Internet"
echo "============================================"

# ── Step 1: Start Convex Backend ──
echo "[1/4] Starting Convex self-hosted backend..."
mkdir -p /convex/data
cd /opt/convex

# Generate instance secret
INSTANCE_SECRET=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
INSTANCE_NAME="aitown"

# Start Convex backend (background)
if [ -x ./convex-local-backend ]; then
  ./convex-local-backend \
    --port 3210 \
    --site-proxy-port 3211 \
    --instance-name "$INSTANCE_NAME" \
    --instance-secret "$INSTANCE_SECRET" \
    --local-storage /convex/data \
    --disable-beacon &
  BACKEND_PID=$!
else
  echo "  WARNING: convex-local-backend not found at ./convex-local-backend"
  ls -la /opt/convex/ 2>/dev/null || echo "  /opt/convex does not exist"
fi

# ── Step 2: Wait for backend ──
echo "[2/4] Waiting for Convex backend..."
for i in $(seq 1 90); do
  if curl -sf http://localhost:3210/version >/dev/null 2>&1; then
    echo "  Convex backend ready! (${i}s)"
    break
  fi
  [ $i -eq 90 ] && echo "  WARNING: Backend did not start within 90s"
  sleep 1
done

# Generate admin key and deploy functions
ADMIN_KEY=""
if [ -x ./generate_admin_key.sh ] && curl -sf http://localhost:3210/version >/dev/null 2>&1; then
  ADMIN_KEY=$(./generate_admin_key.sh 2>/dev/null || echo "")
fi

cd /app

# Set VITE_CONVEX_URL for the browser (connects via public URL → proxy → backend)
echo "VITE_CONVEX_URL=https://aitown.megabyte.space" > .env.local

# Deploy Convex functions
if [ -n "$ADMIN_KEY" ]; then
  echo "[2/4] Deploying Convex functions..."
  CONVEX_DEPLOY_KEY="$ADMIN_KEY" npx convex deploy \
    --url "http://127.0.0.1:3210" --yes 2>&1 || echo "  (deploy attempted)"
  echo "[2/4] Initializing world..."
  CONVEX_DEPLOY_KEY="$ADMIN_KEY" npx convex run init \
    --url "http://127.0.0.1:3210" 2>&1 || echo "  (init attempted)"
fi

# ── Step 3: Start Node.js proxy ──
echo "[3/4] Starting reverse proxy on port 8080..."
node /proxy.mjs &

# ── Step 4: Start Vite frontend ──
echo "[4/4] Starting AI Town frontend on port 5173..."
echo ""
echo "  Welcome to the hippest town!"
echo "  Frontend: http://0.0.0.0:5173"
echo "  Convex:   http://127.0.0.1:3210"
echo "  Proxy:    http://0.0.0.0:8080"
echo ""

exec npx vite --host 0.0.0.0
