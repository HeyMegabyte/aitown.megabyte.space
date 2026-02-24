# AI Town

> Deployment wrapper for **AI Town** on Cloudflare Workers + Containers.

## Quick Start

| Command | Description |
|---------|-------------|
| `npm run deploy` | Deploy to Cloudflare |
| `npm run dev` | Run locally |
| `npm run logs` | Tail worker logs |
| `npm run health` | Check health endpoint |

## Architecture

```
Client -> Cloudflare Edge -> Worker (fetch handler)
                              |
                         Container (node:20-bookworm)
                              |
                         Port 8080 -> AI Town
```

## Configuration

| Setting | Value |
|---------|-------|
| **URL** | https://aitown.megabyte.space |
| **Image** | `node:20-bookworm` |
| **Port** | 8080 |
| **Postgres** | no |
| **Redis** | no |

## Troubleshooting

1. **Check worker status**: `wrangler tail --name aitown`
2. **Verify DNS**: `dig aitown.megabyte.space`
3. **Health check**: `curl https://aitown.megabyte.space/__health`
4. **Container logs**: Check Cloudflare dashboard -> Workers -> aitown
