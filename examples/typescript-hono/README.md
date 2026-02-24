# ERC-8004 Agent — TypeScript/Hono Starter

A minimal but complete ERC-8004 agent built with [Hono](https://hono.dev/) and TypeScript.

## What's Included

- Dashboard at `/` (visual webpage for scanner links)
- Health check at `/api/health` (JSON for Railway)
- ERC-8004 metadata at `/registration.json`
- A2A agent card at `/.well-known/agent-card.json`
- Domain verification at `/.well-known/agent-registration.json`
- MCP server at `POST /mcp` (2 sample tools)
- x402 middleware for paid endpoints
- Circular buffer interaction log

## Quick Start

```bash
# Install dependencies
npm install

# Run locally
npm run dev

# Open http://localhost:3000
```

## Customize

1. Edit `registration.json` — your agent's name, description, capabilities
2. Edit `src/server.ts` — add your own MCP tools and API endpoints
3. Replace `public/agent.png` — your agent's avatar image
4. Edit `dashboard.html` — customize the visual dashboard

## Deploy to Railway

1. Push to GitHub
2. Connect repo in [Railway](https://railway.app)
3. Set environment variables (see `.env.example`)
4. Railway auto-builds and deploys

## Register On-Chain

```bash
# Testnet (Base Sepolia)
CHAIN=base-sepolia PRIVATE_KEY=$KEY ../../scripts/register.sh https://YOUR-URL/registration.json

# Mainnet (Base)
CHAIN=base PRIVATE_KEY=$KEY ../../scripts/register.sh https://YOUR-URL/registration.json
```

## Project Structure

```
├── src/
│   ├── server.ts           # Main Hono server
│   ├── x402-middleware.ts   # x402 payment middleware
│   └── interaction-log.ts   # Circular buffer logger
├── .well-known/
│   └── agent-registration.json  # Domain verification
├── public/
│   └── agent.png           # Agent avatar
├── registration.json        # ERC-8004 metadata
├── dashboard.html           # Visual dashboard
├── Dockerfile               # Docker build
├── railway.toml             # Railway config
├── package.json
├── tsconfig.json
└── .env.example
```

## Adding MCP Tools

1. Add tool definition to `MCP_TOOLS` array in `server.ts`
2. Add handler in the `tools/call` switch statement
3. Test with curl:

```bash
curl -X POST http://localhost:3000/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/call","id":1,"params":{"name":"your_tool","arguments":{}}}'
```

## Adding x402 Paid Endpoints

```typescript
import { x402Middleware } from "./x402-middleware";

app.post("/api/premium", x402Middleware({ price: 10000 }), async (c) => {
  // This endpoint costs $0.01 USDC
  return c.json({ data: "premium content" });
});
```
