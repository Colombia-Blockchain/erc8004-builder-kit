# 06 — Deployment Guide

Deploy your ERC-8004 agent to production with confidence. This guide covers deployment platforms, configuration, on-chain registration, and production best practices.

## Overview

Deploying an ERC-8004 agent involves two distinct steps:
1. **Off-chain deployment** — Your server (the agent's code, endpoints, and services)
2. **On-chain registration** — Recording the agent in the ERC-8004 Identity Registry

```
┌──────────────────────────────────────────────────────────┐
│                    DEPLOYMENT FLOW                         │
├──────────────────────────────────────────────────────────┤
│                                                           │
│  1. Code → GitHub                                        │
│  2. GitHub → Platform (Railway/Fly/Vercel/Docker)        │
│  3. Platform → HTTPS URL                                 │
│  4. Update registration.json with production URL         │
│  5. Register on-chain (Identity Registry)                │
│  6. Verify with scanner                                  │
│                                                           │
└──────────────────────────────────────────────────────────┘
```

## TypeScript vs Python: Deployment Differences

| Aspect | TypeScript/Hono | Python/FastAPI |
|--------|----------------|----------------|
| Build step | `npm run build` (tsc) | None (interpreted) |
| Runtime | Node.js 20+ | Python 3.11+ |
| Package manager | npm | pip |
| Railway builder | Nixpacks (auto-detect) | Dockerfile |
| Start command | `npm start` | `python server.py` |
| Docker base | `node:20-alpine` | `python:3.12-slim` |
| Memory usage | ~80-150MB | ~60-120MB |
| Cold start | ~2-4 seconds | ~1-3 seconds |

Both starters include a `Dockerfile` and `railway.toml` ready for Railway deployment.

## Platform: Railway (Recommended)

Railway is the fastest way to deploy. It auto-detects your stack, provides HTTPS, and scales automatically.

### Step 1: Push to GitHub

```bash
git init
git add .
git commit -m "Initial agent deployment"
git remote add origin https://github.com/you/your-agent.git
git push -u origin main
```

### Step 2: Create Railway Project

1. Go to [railway.app](https://railway.app) and sign in
2. Click "New Project" and select "Deploy from GitHub Repo"
3. Select your repository
4. Railway auto-detects TypeScript or Python and configures the build

### Step 3: Set Environment Variables

In the Railway dashboard, go to your service and click "Variables":

```
# Required
NODE_ENV=production

# Optional — for agents using LLMs
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...

# Optional — for x402 payments
PAYMENT_ADDRESS=0xYourWalletAddress

# Optional — for on-chain operations
PRIVATE_KEY=0xYourPrivateKey
RPC_URL=https://mainnet.base.org
```

> Never commit `.env` files to git. Use the platform's secrets management.

### Step 4: Configure Railway

Both starters include a `railway.toml`:

#### TypeScript

```toml
[build]
builder = "nixpacks"

[deploy]
startCommand = "npm start"
healthcheckPath = "/api/health"
healthcheckTimeout = 30
restartPolicyType = "ON_FAILURE"
restartPolicyMaxRetries = 3
```

#### Python

```toml
[build]
builder = "dockerfile"

[deploy]
startCommand = "python server.py"
healthcheckPath = "/api/health"
healthcheckTimeout = 30
restartPolicyType = "ON_FAILURE"
restartPolicyMaxRetries = 3
```

### Step 5: Deploy

Railway deploys automatically on every push to `main`. Your agent will be available at:

```
https://your-project-name.up.railway.app
```

### Step 6: Custom Domain (Optional)

1. In Railway dashboard, go to Settings and then Domains
2. Add your custom domain (e.g., `agent.yourdomain.com`)
3. Add the CNAME record to your DNS provider
4. Railway automatically provisions TLS

## Platform: Docker (Any Cloud)

### TypeScript Dockerfile

```dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./
COPY --from=builder /app/public ./public

EXPOSE 3000
CMD ["node", "dist/index.js"]
```

### Python Dockerfile

```dockerfile
FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 3000
CMD ["python", "server.py"]
```

### Build and Run

```bash
# Build
docker build -t my-agent .

# Run locally
docker run -p 3000:3000 --env-file .env my-agent

# Push to registry
docker tag my-agent your-registry/my-agent:latest
docker push your-registry/my-agent:latest
```

### Deploy to AWS ECS

```bash
# Create an ECR repository
aws ecr create-repository --repository-name my-agent

# Login to ECR
aws ecr get-login-password | docker login --username AWS --password-stdin $ECR_URL

# Push
docker tag my-agent $ECR_URL/my-agent:latest
docker push $ECR_URL/my-agent:latest

# Create ECS service (use AWS Console or CLI)
```

### Deploy to Google Cloud Run

```bash
# Build with Cloud Build
gcloud builds submit --tag gcr.io/$PROJECT_ID/my-agent

# Deploy
gcloud run deploy my-agent \
  --image gcr.io/$PROJECT_ID/my-agent \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --port 3000
```

### Deploy to Fly.io

```bash
# Initialize
fly launch

# Set secrets
fly secrets set OPENAI_API_KEY=sk-...

# Deploy
fly deploy
```

## Platform: Vercel (TypeScript Only)

Vercel works well for TypeScript agents using serverless functions:

```bash
npm i -g vercel
vercel
```

Note: Vercel serverless functions have a 10-second timeout on the free tier. For long-running MCP tools or A2A tasks, use Railway or Docker instead.

## On-Chain Registration Flow

After deploying your server, register on-chain:

```
┌────────────────────────────────────────────────────┐
│              REGISTRATION FLOW                      │
├────────────────────────────────────────────────────┤
│                                                     │
│  1. Deploy server → Get production URL              │
│  2. Update registration.json → Push & redeploy      │
│  3. Verify endpoints respond correctly              │
│  4. Register on testnet → Get agent ID              │
│  5. Update registration.json with agentId           │
│  6. Verify with scanner                            │
│  7. (Optional) Register on mainnet                 │
│                                                     │
└────────────────────────────────────────────────────┘
```

### Step 1: Update registration.json

Replace all placeholder URLs with your production URL:

```json
{
  "type": "https://eips.ethereum.org/EIPS/eip-8004#registration-v1",
  "name": "Your Agent Name",
  "description": "Clear description of what your agent does",
  "image": "https://your-agent.example.com/public/agent.png",
  "active": true,
  "services": [
    { "name": "web", "endpoint": "https://your-agent.example.com/" },
    { "name": "MCP", "endpoint": "https://your-agent.example.com/mcp", "version": "2025-11-25" },
    { "name": "A2A", "endpoint": "https://your-agent.example.com/a2a", "version": "0.2" }
  ],
  "x402Support": false,
  "capabilities": ["data-analysis", "report-generation"],
  "supportedTrust": ["reputation"]
}
```

### Step 2: Verify Endpoints

Before registering on-chain, verify everything works:

```bash
# Health
curl -s https://your-agent.example.com/api/health | jq .

# Registration JSON
curl -s https://your-agent.example.com/registration.json | jq .

# MCP Initialize
curl -s -X POST https://your-agent.example.com/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"initialize","id":1}' | jq .

# MCP Tools List
curl -s -X POST https://your-agent.example.com/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":2}' | jq .

# A2A Agent Card (if implemented)
curl -s https://your-agent.example.com/.well-known/agent.json | jq .
```

### Step 3: Register on Testnet

```bash
# Using the provided script
CHAIN=base-sepolia PRIVATE_KEY=0xYourKey \
  ./scripts/register.sh "https://your-agent.example.com/registration.json"
```

Or register programmatically:

#### TypeScript

```typescript
import { createWalletClient, http, parseAbi } from "viem";
import { baseSepolia } from "viem/chains";
import { privateKeyToAccount } from "viem/accounts";

const IDENTITY_REGISTRY = "0x8004A169FB4a3325136EB29fA0ceB6D2e539a432";

const account = privateKeyToAccount(process.env.PRIVATE_KEY as `0x${string}`);
const client = createWalletClient({
  account,
  chain: baseSepolia,
  transport: http(),
});

const hash = await client.writeContract({
  address: IDENTITY_REGISTRY,
  abi: parseAbi([
    "function register(string agentURI) returns (uint256)",
  ]),
  functionName: "register",
  args: ["https://your-agent.example.com/registration.json"],
});

console.log(`Registration TX: ${hash}`);
```

#### Python

```python
from web3 import Web3

IDENTITY_REGISTRY = "0x8004A169FB4a3325136EB29fA0ceB6D2e539a432"

w3 = Web3(Web3.HTTPProvider("https://sepolia.base.org"))
account = w3.eth.account.from_key(PRIVATE_KEY)

registry = w3.eth.contract(
    address=IDENTITY_REGISTRY,
    abi=[{
        "name": "register",
        "type": "function",
        "stateMutability": "nonpayable",
        "inputs": [{"name": "agentURI", "type": "string"}],
        "outputs": [{"name": "agentId", "type": "uint256"}],
    }]
)

tx = registry.functions.register(
    "https://your-agent.example.com/registration.json"
).build_transaction({
    "from": account.address,
    "nonce": w3.eth.get_transaction_count(account.address),
})

signed = account.sign_transaction(tx)
tx_hash = w3.eth.send_raw_transaction(signed.raw_transaction)
receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
print(f"Registered! TX: {tx_hash.hex()}")
```

### Step 4: Update registration.json with Agent ID

After registration, update your `registration.json` with the on-chain reference:

```json
{
  "registrations": [
    {
      "agentId": 42,
      "agentRegistry": "eip155:84532:0x8004A169FB4a3325136EB29fA0ceB6D2e539a432"
    }
  ]
}
```

Push and redeploy.

### Step 5: Verify with Scanner

```bash
CHAIN=base-sepolia ./scripts/verify-agent.sh 42
```

Visit [8004scan.io](https://8004scan.io) to see your agent's profile and score.

## Production Checklist

### Before Going Live

- [ ] All endpoints return correct responses
- [ ] `registration.json` has production URLs (no localhost)
- [ ] Image URL is accessible and loads correctly
- [ ] Health endpoint returns 200
- [ ] MCP initialize returns correct protocol version
- [ ] MCP tools/list returns all your tools
- [ ] Each MCP tool call works with valid inputs
- [ ] Error handling returns proper JSON-RPC errors
- [ ] No secrets in `registration.json` or public files
- [ ] `.env` file is in `.gitignore`
- [ ] CORS headers are configured if needed
- [ ] Rate limiting is configured
- [ ] Logging is set up for monitoring

### Testnet to Mainnet

When moving from testnet to mainnet:

1. **Switch network configuration**: Change from `base-sepolia` to `base` (or your target mainnet)
2. **Update registration.json**: Add the mainnet registration alongside testnet
3. **Verify wallet funding**: Ensure your wallet has mainnet ETH for gas
4. **Register on mainnet**: Use the same script with `CHAIN=base`

```json
{
  "registrations": [
    {
      "agentId": 42,
      "agentRegistry": "eip155:84532:0x8004A169FB4a3325136EB29fA0ceB6D2e539a432"
    },
    {
      "agentId": 15,
      "agentRegistry": "eip155:8453:0x8004A169FB4a3325136EB29fA0ceB6D2e539a432"
    }
  ]
}
```

## Environment Variables Reference

| Variable | Required | Description |
|----------|----------|-------------|
| `NODE_ENV` | Yes | `production` for deployed agents |
| `PORT` | No | Server port (default: 3000) |
| `PRIVATE_KEY` | For registration | Wallet private key for on-chain operations |
| `RPC_URL` | For registration | RPC endpoint for blockchain interactions |
| `OPENAI_API_KEY` | If using OpenAI | API key for OpenAI models |
| `ANTHROPIC_API_KEY` | If using Anthropic | API key for Claude models |
| `PAYMENT_ADDRESS` | If using x402 | Wallet address to receive payments |
| `FACILITATOR_URL` | If using x402 | x402 facilitator URL |

## Monitoring and Observability

### Health Check Endpoint

Both starters include a health endpoint. Extend it for production:

```typescript
app.get("/api/health", async (c) => {
  const checks = {
    status: "healthy",
    timestamp: new Date().toISOString(),
    version: process.env.npm_package_version || "1.0.0",
    uptime: process.uptime(),
    services: {
      mcp: await checkMCP(),
      database: await checkDB(),
    },
  };

  const allHealthy = Object.values(checks.services).every((s) => s === "ok");

  return c.json(checks, allHealthy ? 200 : 503);
});
```

### Logging

```typescript
// Structured logging for production
import { logger } from "hono/logger";

app.use("*", logger());

// Custom request logging
app.use("*", async (c, next) => {
  const start = Date.now();
  await next();
  const duration = Date.now() - start;

  console.log(
    JSON.stringify({
      method: c.req.method,
      path: c.req.path,
      status: c.res.status,
      duration,
      timestamp: new Date().toISOString(),
    })
  );
});
```

### Error Tracking

```typescript
app.onError((err, c) => {
  console.error(
    JSON.stringify({
      error: err.message,
      stack: err.stack,
      path: c.req.path,
      method: c.req.method,
      timestamp: new Date().toISOString(),
    })
  );

  return c.json(
    { error: "Internal server error" },
    500
  );
});
```

## Scaling Considerations

### Horizontal Scaling

ERC-8004 agents are stateless by default, making them easy to scale horizontally:

```yaml
# docker-compose.yml for multi-instance deployment
version: "3.8"
services:
  agent:
    build: .
    deploy:
      replicas: 3
    ports:
      - "3000-3002:3000"
    environment:
      - NODE_ENV=production

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - agent
```

### Caching

```typescript
// Cache MCP tool results that don't change frequently
const cache = new Map<string, { data: any; expiry: number }>();

function withCache(ttlMs: number) {
  return async (key: string, fn: () => Promise<any>) => {
    const cached = cache.get(key);
    if (cached && cached.expiry > Date.now()) {
      return cached.data;
    }
    const data = await fn();
    cache.set(key, { data, expiry: Date.now() + ttlMs });
    return data;
  };
}

const cache5min = withCache(5 * 60 * 1000);
```

### Rate Limiting

```typescript
// Per-IP rate limiting
import { rateLimiter } from "hono-rate-limiter";

app.use(
  "/mcp",
  rateLimiter({
    windowMs: 60 * 1000, // 1 minute
    limit: 60,            // 60 requests per minute
    message: { error: "Too many requests" },
  })
);

app.use(
  "/a2a",
  rateLimiter({
    windowMs: 60 * 1000,
    limit: 30,
    message: { error: "Too many requests" },
  })
);
```

## Multi-Chain Registration

Register your agent on multiple chains for broader discoverability:

```bash
# Register on Base (mainnet)
CHAIN=base PRIVATE_KEY=0xYourKey \
  ./scripts/register.sh "https://your-agent.example.com/registration.json"

# Register on Avalanche
CHAIN=avalanche PRIVATE_KEY=0xYourKey \
  ./scripts/register.sh "https://your-agent.example.com/registration.json"

# Register on Arbitrum
CHAIN=arbitrum PRIVATE_KEY=0xYourKey \
  ./scripts/register.sh "https://your-agent.example.com/registration.json"
```

All ERC-8004 registries use the same contract addresses across chains:

| Registry | Address |
|----------|---------|
| Identity | `0x8004A169FB4a3325136EB29fA0ceB6D2e539a432` |
| Reputation | `0x8004B5118Ee0495fBBFB889882503dd4a20e5444` |
| Validation | `0x8004C11CeD79AE1A66e121600E41DA4BEdf60888` |

## Troubleshooting Deployment

| Problem | Solution |
|---------|----------|
| Build fails on Railway | Check `package.json` scripts and `tsconfig.json` |
| 502 Bad Gateway | Ensure your app listens on the correct PORT |
| registration.json 404 | Verify static file serving in your framework |
| MCP 500 error | Check server logs for unhandled exceptions |
| Docker image too large | Use multi-stage builds and `.dockerignore` |
| Slow cold starts | Use smaller base images (alpine/slim) |
| Memory issues | Set `--max-old-space-size` for Node.js |
| Python import errors | Ensure all dependencies are in `requirements.txt` |

---

*A well-deployed agent is a reliable agent. Use the production checklist, monitor your endpoints, and register on testnet before going to mainnet.*
