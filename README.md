# AI Town

> Generative AI agents living, chatting, and forming relationships in a virtual 2D world — deployed on Cloudflare Workers + Containers.

Based on [a16z-infra/ai-town](https://github.com/a16z-infra/ai-town), inspired by the Stanford/Google research paper *"Generative Agents: Interactive Simulacra of Human Behavior"*.

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
                         Container (all-in-one)
                              |
                    nginx (port 8080) reverse proxy
                     /                    \
           Convex Backend           Vite Frontend
           (port 3210)             (port 5173)
                |                       |
        AI agent logic          React + PixiJS 2D world
        Game simulation         Character sprites
        Memory & chat           Real-time updates
```

## How It Works

- **Convex Self-Hosted Backend**: Runs the game simulation, AI agent logic, memory system, and real-time state sync
- **React + PixiJS Frontend**: Renders the 2D world with animated character sprites, buildings, and interactions
- **nginx Reverse Proxy**: Routes `/api/*` to Convex backend and `/*` to the frontend — all through a single port
- **Cloudflare Container**: Auto-sleeps after 30 minutes of inactivity, wakes on next request

## Configuration

| Setting | Value |
|---------|-------|
| **URL** | https://aitown.megabyte.space |
| **Frontend Port** | 5173 (Vite) |
| **Backend Port** | 3210 (Convex) |
| **Proxy Port** | 8080 (nginx) |
| **Container Port** | 8080 |

## LLM Configuration

AI Town agents can use various LLM providers. Set environment variables to enable AI conversations:

| Provider | Env Vars |
|----------|----------|
| OpenAI | `OPENAI_API_KEY`, `OPENAI_CHAT_MODEL` |
| Together.ai | `TOGETHER_API_KEY`, `TOGETHER_CHAT_MODEL` |
| Ollama | `OLLAMA_HOST`, `OLLAMA_MODEL` |
