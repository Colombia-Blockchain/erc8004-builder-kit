# ERC-8004 Agent — Python/FastAPI Starter

A minimal but complete ERC-8004 agent built with [FastAPI](https://fastapi.tiangolo.com/).

## What's Included

- Dashboard at `/`
- Health check at `/api/health`
- ERC-8004 metadata at `/registration.json`
- A2A agent card at `/.well-known/agent-card.json`
- MCP server at `POST /mcp` (2 sample tools)
- OASF discovery at `GET /oasf`
- A2A natural language endpoint at `POST /a2a/ask`
- x402 payment decorator for paid endpoints
- Thread-safe circular buffer interaction log

## Quick Start

```bash
pip install -r requirements.txt
python server.py
# Open http://localhost:3000
```

## Customize

1. Edit `registration.json` — your agent's name, description, capabilities
2. Edit `server.py` — add your own MCP tools and API endpoints
3. Add `public/agent.png` — your agent's avatar image

## Deploy to Railway

1. Push to GitHub
2. Connect repo in [Railway](https://railway.app)
3. Set environment variables (see `.env.example`)
4. Railway auto-builds and deploys via Dockerfile

## Register On-Chain

```bash
CHAIN=base-sepolia PRIVATE_KEY=$KEY ../../scripts/register.sh https://YOUR-URL/registration.json
```

## Adding x402 Paid Endpoints

```python
from x402_middleware import require_x402_payment

@app.post("/api/premium")
@require_x402_payment(price=10000, description="Premium analysis")
async def premium(request: Request):
    return {"data": "premium content"}
```
