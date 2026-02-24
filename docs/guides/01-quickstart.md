# 01 — Quickstart: Zero to Registered Agent in 30 Minutes

Get your first ERC-8004 agent deployed and registered on-chain. Choose TypeScript or Python.

## Prerequisites

- Node.js 18+ (TypeScript) or Python 3.11+ (Python)
- Git
- A code editor
- A crypto wallet with testnet tokens

## Step 1: Clone the Starter (2 min)

### TypeScript/Hono

```bash
cp -r examples/typescript-hono my-agent
cd my-agent
npm install
```

### Python/FastAPI

```bash
cp -r examples/python-fastapi my-agent
cd my-agent
pip install -r requirements.txt
```

## Step 2: Customize Your Agent (5 min)

Edit `registration.json`:

```json
{
  "name": "Your Agent Name",
  "description": "What your agent does — be honest and specific",
  "image": "https://your-domain.com/public/agent.png",
  "services": [
    { "name": "web", "endpoint": "https://your-domain.com/" },
    { "name": "MCP", "endpoint": "https://your-domain.com/mcp", "version": "2025-11-25" }
  ]
}
```

Replace `public/agent.png` with your agent's avatar (min 256x256px PNG).

### Registration JSON Fields

| Field | Required | Description |
|-------|----------|-------------|
| `type` | Yes | Always `"https://eips.ethereum.org/EIPS/eip-8004#registration-v1"` |
| `name` | Yes | Human-readable agent name |
| `description` | Yes | What your agent does — be specific |
| `image` | Yes | URL to agent avatar (min 256x256px PNG) |
| `services` | Yes | Array of service endpoints |
| `active` | No | Whether the agent is currently active (default `true`) |
| `x402Support` | No | Whether the agent supports x402 payments |
| `registrations` | No | Array of on-chain registration records |
| `capabilities` | No | Array of capability strings |
| `supportedTrust` | No | Trust mechanisms supported |

### Service Types

Your agent can expose multiple service types:

```json
{
  "services": [
    { "name": "web", "endpoint": "https://your-domain.com/" },
    { "name": "MCP", "endpoint": "https://your-domain.com/mcp", "version": "2025-11-25" },
    { "name": "A2A", "endpoint": "https://your-domain.com/a2a", "version": "0.2" },
    { "name": "OASF", "endpoint": "https://your-domain.com/oasf" }
  ]
}
```

## Step 3: Run Locally (2 min)

### TypeScript

```bash
npm run dev
# Open http://localhost:3000
```

The TypeScript starter uses Hono, a fast web framework that runs on Node.js, Deno, and Bun. Your agent will be available at `http://localhost:3000` with hot-reload enabled.

### Python

```bash
python server.py
# Open http://localhost:3000
```

The Python starter uses FastAPI with Uvicorn. Hot-reload is enabled by default in development mode.

### What You Should See

When your agent starts, you should see output like:

```
🚀 Agent server running on http://localhost:3000
📋 Registration: http://localhost:3000/registration.json
🔧 MCP endpoint: http://localhost:3000/mcp
❤️ Health check: http://localhost:3000/api/health
```

## Step 4: Test Endpoints (3 min)

### Health Check

```bash
curl http://localhost:3000/api/health
```

Expected response:

```json
{
  "status": "healthy",
  "timestamp": "2025-01-15T10:30:00Z",
  "version": "1.0.0"
}
```

### Registration Metadata

```bash
curl http://localhost:3000/registration.json
```

This should return your full registration JSON with all services listed.

### MCP Initialize

```bash
curl -X POST http://localhost:3000/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"initialize","id":1}'
```

Expected response:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "protocolVersion": "2025-11-25",
    "serverInfo": {
      "name": "your-agent-name",
      "version": "1.0.0"
    },
    "capabilities": {
      "tools": { "listChanged": false }
    }
  }
}
```

### MCP List Tools

```bash
curl -X POST http://localhost:3000/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":2}'
```

### Test a Tool Call

```bash
curl -X POST http://localhost:3000/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/call","id":3,"params":{"name":"hello","arguments":{"name":"World"}}}'
```

## Step 5: Deploy to Railway (5 min)

### Option A: Railway (Recommended for Getting Started)

1. Push your code to GitHub
2. Go to [railway.app](https://railway.app) and create a new project
3. Select "Deploy from GitHub Repo"
4. Select your repo — Railway auto-detects and builds
5. Set environment variables in Railway dashboard (see `.env.example`)
6. Note your deployment URL: `https://your-project.up.railway.app`

### Option B: Docker (Any Cloud Provider)

Both starters include a `Dockerfile`:

```bash
# Build
docker build -t my-agent .

# Run
docker run -p 3000:3000 --env-file .env my-agent
```

### Option C: Fly.io

```bash
fly launch
fly deploy
```

### Option D: Vercel (TypeScript Only)

```bash
npm i -g vercel
vercel
```

## Step 6: Update Registration URLs (2 min)

Update `registration.json` with your production URL:

```json
{
  "name": "Your Agent Name",
  "description": "What your agent does",
  "image": "https://your-project.up.railway.app/public/agent.png",
  "services": [
    { "name": "web", "endpoint": "https://your-project.up.railway.app/" },
    { "name": "MCP", "endpoint": "https://your-project.up.railway.app/mcp", "version": "2025-11-25" }
  ]
}
```

Push changes — Railway auto-deploys on every push to `main`.

### Verify Production Endpoints

```bash
# Verify health
curl https://your-project.up.railway.app/api/health

# Verify registration
curl https://your-project.up.railway.app/registration.json

# Verify MCP
curl -X POST https://your-project.up.railway.app/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"initialize","id":1}'
```

## Step 7: Register On-Chain (5 min)

### Get Testnet Tokens

Get free test tokens from a faucet for your target chain:

| Chain | Faucet |
|-------|--------|
| Sepolia (Ethereum testnet) | [sepoliafaucet.com](https://sepoliafaucet.com) |
| Base Sepolia | [faucet.quicknode.com/base/sepolia](https://faucet.quicknode.com/base/sepolia) |
| Fuji (Avalanche testnet) | [faucet.avax.network](https://faucet.avax.network) |

### Install Foundry

Foundry provides the `cast` CLI tool for interacting with smart contracts:

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### Register Your Agent

```bash
# Base Sepolia (testnet)
CHAIN=base-sepolia PRIVATE_KEY=0xYourKey \
  ./scripts/register.sh "https://your-project.up.railway.app/registration.json"
```

This will:
1. Call `register(string agentURI)` on the Identity Registry
2. Mint an ERC-721 NFT to your wallet
3. Output your new agent ID

### Get Your Agent ID

Check the transaction on the block explorer. Your agent ID is in the `Registered` event:

```
Registered(agentId: 42, agentURI: "https://...", owner: 0xYou...)
```

### Programmatic Registration (TypeScript)

```typescript
import { createPublicClient, createWalletClient, http } from "viem";
import { baseSepolia } from "viem/chains";
import { privateKeyToAccount } from "viem/accounts";

const IDENTITY_REGISTRY = "0x8004A169FB4a3325136EB29fA0ceB6D2e539a432";

const account = privateKeyToAccount(process.env.PRIVATE_KEY as `0x${string}`);

const walletClient = createWalletClient({
  account,
  chain: baseSepolia,
  transport: http(),
});

const hash = await walletClient.writeContract({
  address: IDENTITY_REGISTRY,
  abi: [
    {
      name: "register",
      type: "function",
      stateMutability: "nonpayable",
      inputs: [{ name: "agentURI", type: "string" }],
      outputs: [{ name: "agentId", type: "uint256" }],
    },
  ],
  functionName: "register",
  args: ["https://your-project.up.railway.app/registration.json"],
});

console.log("Transaction hash:", hash);
```

### Programmatic Registration (Python)

```python
from web3 import Web3

IDENTITY_REGISTRY = "0x8004A169FB4a3325136EB29fA0ceB6D2e539a432"
RPC_URL = "https://sepolia.base.org"

w3 = Web3(Web3.HTTPProvider(RPC_URL))
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
    "https://your-project.up.railway.app/registration.json"
).build_transaction({
    "from": account.address,
    "nonce": w3.eth.get_transaction_count(account.address),
})

signed = account.sign_transaction(tx)
tx_hash = w3.eth.send_raw_transaction(signed.raw_transaction)
receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
print(f"Agent registered! TX: {tx_hash.hex()}")
```

### Update registration.json

Add your agent ID to the `registrations` array and redeploy:

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

## Step 8: Verify (3 min)

### Run the Verification Suite

```bash
# Run verification suite
CHAIN=base-sepolia ./scripts/verify-agent.sh YOUR_AGENT_ID
```

The verification script checks:
- Registration JSON is accessible and valid
- All service endpoints respond
- MCP initialize returns correct protocol version
- MCP tools/list returns valid tool definitions
- Image URL is accessible

### Check on 8004scan

Visit [8004scan.io](https://8004scan.io) and search for your agent ID to see:
- Your agent's public profile
- Service endpoints and their status
- Scanner score breakdown
- On-chain registration details

### Manual Verification

```bash
# Check registration on-chain
cast call $IDENTITY_REGISTRY \
  "tokenURI(uint256)" YOUR_AGENT_ID \
  --rpc-url https://sepolia.base.org

# Check owner
cast call $IDENTITY_REGISTRY \
  "ownerOf(uint256)" YOUR_AGENT_ID \
  --rpc-url https://sepolia.base.org
```

## Troubleshooting

### Common Issues

| Problem | Solution |
|---------|----------|
| `registration.json` returns 404 | Ensure the file is served as a static asset at the root |
| MCP endpoint returns 405 | Make sure you handle POST requests, not just GET |
| Registration tx reverts | Check you have enough gas and the URI is a valid string |
| Health check fails | Ensure `/api/health` returns a 200 status code |
| Image not loading | Use an absolute URL, not a relative path. Min 256x256px. |

### TypeScript-Specific Issues

```bash
# Clear build cache
rm -rf dist node_modules
npm install
npm run build
```

### Python-Specific Issues

```bash
# Recreate virtual environment
rm -rf venv
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

## Project Structure

### TypeScript Starter

```
my-agent/
├── src/
│   ├── index.ts          # Hono server setup
│   ├── mcp/
│   │   ├── handler.ts    # MCP JSON-RPC handler
│   │   └── tools.ts      # Tool definitions
│   └── routes/
│       └── health.ts     # Health check route
├── public/
│   ├── agent.png         # Agent avatar
│   └── registration.json # Registration metadata
├── package.json
├── tsconfig.json
├── Dockerfile
└── railway.toml
```

### Python Starter

```
my-agent/
├── server.py             # FastAPI server setup
├── mcp/
│   ├── handler.py        # MCP JSON-RPC handler
│   └── tools.py          # Tool definitions
├── routes/
│   └── health.py         # Health check route
├── public/
│   ├── agent.png         # Agent avatar
│   └── registration.json # Registration metadata
├── requirements.txt
├── Dockerfile
└── railway.toml
```

## What's Next?

- [Add A2A endpoints](02-a2a-guide.md) for natural language communication
- [Add MCP tools](03-mcp-guide.md) for programmatic access
- [Add x402 payments](04-x402-guide.md) for monetization
- [Optimize scanner score](09-scanner-optimization.md) for visibility
- [Deploy to production](06-deployment-guide.md) with best practices

---

*Time to first agent: ~30 minutes. Time to production: add your own logic and register on mainnet.*
