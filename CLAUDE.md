# CLAUDE.md - AI Town

## Overview
This repo deploys **AI Town** to Cloudflare Workers + Containers.
- Hostname: aitown.megabyte.space
- Image: node:20-bookworm
- Port: 8080

## Commands
| Command | Description |
|---------|-------------|
| `npm run deploy` | Deploy to Cloudflare Workers |
| `npm run dev` | Run local development server |
| `npm run typecheck` | TypeScript type checking |
| `npm run logs` | Tail live worker logs |
| `npm run health` | Check /__health endpoint |

## Architecture
- `src/index.ts` - Container-based worker using `@cloudflare/containers`
- `wrangler.jsonc` - Cloudflare Workers configuration
- `Dockerfile` - Container image reference
- `package.json` - Dependencies and scripts

## Key Design Decisions
1. Uses `Container` class from `@cloudflare/containers` (not raw DurableObject)
2. Buffers request/response bodies as ArrayBuffer for DO compatibility
3. Follows internal redirects to prevent HTTP->HTTPS redirect loops
4. Shows branded spinning-up page while container boots (~30-120s)
5. Container auto-sleeps after 30 minutes of inactivity
6. Includes /__health and /__version diagnostic endpoints
