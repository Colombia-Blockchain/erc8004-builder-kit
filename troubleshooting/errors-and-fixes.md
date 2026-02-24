# Errors and Fixes

Real errors encountered while building and deploying two ERC-8004 agents on Base and Avalanche. Every issue here happened in production.

---

## Deployment Issues

### 502 Bad Gateway After Deploy

**Environment**: Railway, Node.js 20, Express

**Symptom**: Deploy succeeds (green checkmark in Railway dashboard), but visiting the URL returns `502 Bad Gateway`. Logs show the app starting, but Railway's health check fails.

**Root Cause**: The application was listening on a hardcoded port (`3000`) instead of the `PORT` environment variable that Railway injects dynamically.

**Diagnosis**:
```bash
# Check Railway logs
railway logs --tail 50

# Look for the actual assigned port
railway logs | grep -i "port"
```

**Fix**:
```typescript
// Before (broken)
app.listen(3000, () => {
  console.log('Server running on port 3000');
});

// After (working)
const PORT = parseInt(process.env.PORT || '3000', 10);
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
});
```

Key details:
- Bind to `0.0.0.0`, not `localhost` or `127.0.0.1`
- Always use `process.env.PORT`
- The fallback (`3000`) is only for local development

**Also check**:
- Railway requires a successful HTTP response on `/` or a configured health check path within 5 minutes of deploy
- If using a custom health check, ensure the endpoint exists and returns 200

---

### Build Fails: TypeScript Errors

**Environment**: Railway with `npm run build` using `tsc`

**Symptom**: Build fails with TypeScript errors that don't appear locally. Common errors:
```
error TS2307: Cannot find module './types' or its corresponding type declarations.
error TS18046: 'response' is of type 'unknown'.
error TS2345: Argument of type 'string | undefined' is not assignable to parameter of type 'string'.
```

**Root Cause**: Local TypeScript version differs from the one in `package.json`, or `tsconfig.json` has different `strict` settings than expected. Also, `node_modules` might include `@types` packages locally that aren't in `package.json`.

**Diagnosis**:
```bash
# Check local vs declared TypeScript version
npx tsc --version
cat package.json | jq '.devDependencies.typescript'

# Run a clean build locally
rm -rf node_modules dist
npm ci
npm run build
```

**Fix**:
1. Run `npm ci && npm run build` locally to reproduce
2. Fix all type errors (don't use `// @ts-ignore` as a band-aid)
3. Ensure `tsconfig.json` matches what CI uses:

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "commonjs",
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

4. Lock TypeScript version in `devDependencies`:
```json
"typescript": "5.3.3"
```

---

### App Crashes: Missing Environment Variables

**Environment**: Railway, any runtime

**Symptom**: App starts, then immediately crashes with:
```
Error: COINGECKO_API_KEY is required
```
or
```
TypeError: Cannot read properties of undefined (reading 'split')
```

**Root Cause**: Environment variables set locally (in `.env`) but not configured in the deployment platform.

**Diagnosis**:
```bash
# List all env vars your app expects
grep -r "process.env\." src/ | grep -oP 'process\.env\.(\w+)' | sort -u

# Compare with what's set in Railway
railway variables
```

**Fix**:
1. Create an `.env.example` file listing all required variables (without values):
```bash
# .env.example
COINGECKO_API_KEY=
PRIVATE_KEY=
AGENT_ID=
CHAIN_RPC_URL=
PORT=3000
```

2. Add startup validation:
```typescript
const REQUIRED_VARS = ['COINGECKO_API_KEY', 'AGENT_ID', 'CHAIN_RPC_URL'];

for (const varName of REQUIRED_VARS) {
  if (!process.env[varName]) {
    console.error(`Missing required environment variable: ${varName}`);
    process.exit(1);
  }
}
```

3. Set all variables in Railway:
```bash
railway variables set COINGECKO_API_KEY=your-key-here
railway variables set AGENT_ID=47
```

---

### Auto-Deploy Stops Working

**Environment**: Railway connected to GitHub repo

**Symptom**: Pushing to `main` no longer triggers a deploy. Manual deploys from the dashboard still work.

**Root Cause**: One of:
1. GitHub webhook was deleted or disabled
2. Railway's GitHub app lost permissions
3. Branch filter changed (Railway deploys from a specific branch)
4. The repo was transferred or renamed

**Diagnosis**:
```bash
# Check GitHub webhooks
gh api repos/OWNER/REPO/hooks | jq '.[].config.url'

# Check if Railway app is linked
railway status
```

**Fix**:
1. Go to Railway dashboard > project settings > check the connected repo
2. Disconnect and reconnect the GitHub repo
3. Verify the deploy branch is correct (usually `main`)
4. In GitHub: Settings > Applications > Railway > check repo access

If all else fails:
```bash
# Manual deploy as workaround
railway up
```

---

## API Issues

### CoinGecko Rate Limiting

**Environment**: Any, using CoinGecko free tier

**Symptom**: API calls start returning HTTP 429 with body:
```json
{"status":{"error_code":429,"error_message":"You've exceeded the Rate Limit."}}
```
Agent returns empty or error responses for price queries.

**Root Cause**: CoinGecko free tier allows ~10-30 calls/minute. Without caching, every MCP tool invocation hits the API directly. A burst of 5 users each requesting 3 tokens = 15 API calls in seconds.

**Diagnosis**:
```bash
# Test current rate limit status
curl -s -o /dev/null -w "%{http_code}" "https://api.coingecko.com/api/v3/ping"

# Check response headers for rate limit info
curl -sI "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd"
```

**Fix**: Implement caching with appropriate TTLs:

```typescript
class APICache {
  private cache = new Map<string, { data: any; expiresAt: number }>();

  get(key: string): any | null {
    const entry = this.cache.get(key);
    if (!entry) return null;
    if (Date.now() > entry.expiresAt) {
      this.cache.delete(key);
      return null;
    }
    return entry.data;
  }

  set(key: string, data: any, ttlMs: number): void {
    this.cache.set(key, { data, expiresAt: Date.now() + ttlMs });
  }

  cleanup(): void {
    const now = Date.now();
    for (const [key, entry] of this.cache) {
      if (now > entry.expiresAt) this.cache.delete(key);
    }
  }
}

const apiCache = new APICache();

// Clean up every 5 minutes
setInterval(() => apiCache.cleanup(), 5 * 60 * 1000);

async function getTokenPrice(tokenId: string): Promise<number> {
  const cacheKey = `price:${tokenId}`;
  const cached = apiCache.get(cacheKey);
  if (cached) return cached;

  const response = await fetch(
    `https://api.coingecko.com/api/v3/simple/price?ids=${tokenId}&vs_currencies=usd`
  );

  if (response.status === 429) {
    // Return stale data if available, or throw
    throw new Error('Rate limited by CoinGecko. Try again in 60 seconds.');
  }

  const data = await response.json();
  const price = data[tokenId]?.usd;
  apiCache.set(cacheKey, price, 60_000); // 60s TTL
  return price;
}
```

**Recommended TTLs**:
- Token prices: 60 seconds
- Market cap / volume: 120 seconds
- Token metadata (name, symbol): 1 hour
- Token lists: 6 hours

---

### Sequential API Calls Causing Timeouts

**Environment**: Any, Express with MCP endpoint

**Symptom**: MCP tool responses take 2-5 seconds. When multiple tools are called, total response time exceeds 10 seconds and clients time out.

**Root Cause**: API calls made sequentially when they have no dependencies:

```typescript
// This pattern is the problem
const price = await fetchPrice(token);        // 400ms
const tvl = await fetchTVL(protocol);         // 300ms
const holders = await fetchHolders(token);    // 500ms
// Total: 1200ms
```

**Fix**: Use `Promise.all` for independent requests:

```typescript
const [price, tvl, holders] = await Promise.all([
  fetchPrice(token),
  fetchTVL(protocol),
  fetchHolders(token),
]);
// Total: ~500ms (max of the three)
```

For requests with partial dependencies, use `Promise.all` in stages:

```typescript
// Stage 1: Independent calls
const [tokenInfo, protocolInfo] = await Promise.all([
  fetchTokenInfo(token),
  fetchProtocolInfo(protocol),
]);

// Stage 2: Depends on Stage 1
const [price, tvl] = await Promise.all([
  fetchPrice(tokenInfo.coingeckoId),
  fetchTVL(protocolInfo.defillamaSlug),
]);
```

**Measuring improvement**:
```typescript
const start = Date.now();
// ... your calls ...
const elapsed = Date.now() - start;
console.log(`API calls completed in ${elapsed}ms`);
```

---

### Memory Leaks from Uncleaned Caches

**Environment**: Long-running Node.js process on Railway

**Symptom**: Memory usage grows linearly over hours/days. Eventually the process is killed by Railway (OOM) or becomes very slow due to garbage collection pressure.

**Root Cause**: In-memory caches (`Map`, `Object`) that grow without bounds. Every unique API request adds an entry, but expired entries are never removed.

**Diagnosis**:
```typescript
// Add memory monitoring
setInterval(() => {
  const used = process.memoryUsage();
  console.log({
    rss: `${Math.round(used.rss / 1024 / 1024)}MB`,
    heap: `${Math.round(used.heapUsed / 1024 / 1024)}MB`,
    cacheSize: apiCache.size,
  });
}, 60_000);
```

**Fix**: Implement a size-bounded LRU cache or add periodic cleanup:

```typescript
class BoundedCache {
  private cache = new Map<string, { data: any; expiresAt: number }>();
  private maxSize: number;

  constructor(maxSize: number = 1000) {
    this.maxSize = maxSize;
  }

  set(key: string, data: any, ttlMs: number): void {
    // Evict oldest if at capacity
    if (this.cache.size >= this.maxSize) {
      const firstKey = this.cache.keys().next().value;
      if (firstKey) this.cache.delete(firstKey);
    }
    this.cache.set(key, { data, expiresAt: Date.now() + ttlMs });
  }

  get(key: string): any | null {
    const entry = this.cache.get(key);
    if (!entry) return null;
    if (Date.now() > entry.expiresAt) {
      this.cache.delete(key);
      return null;
    }
    return entry.data;
  }

  get size(): number {
    return this.cache.size;
  }

  cleanup(): void {
    const now = Date.now();
    for (const [key, entry] of this.cache) {
      if (now > entry.expiresAt) this.cache.delete(key);
    }
  }
}
```

Schedule cleanup:
```typescript
const cache = new BoundedCache(500);
setInterval(() => cache.cleanup(), 5 * 60 * 1000);
```

---

## On-Chain Issues

### Transaction Reverted: Insufficient Gas

**Environment**: Base or Avalanche, using ethers.js or viem

**Symptom**: Registration or URI update transaction fails with:
```
Error: transaction reverted: out of gas
```
or
```
Error: execution reverted (unknown custom error)
```

**Root Cause**: Gas estimation failed or was too low. Common with contract calls that involve string storage (like `setAgentURI` with a long URL).

**Diagnosis**:
```bash
# Estimate gas manually
cast estimate --rpc-url $RPC_URL \
  $CONTRACT_ADDRESS \
  "setAgentURI(uint256,string)" \
  $AGENT_ID \
  "https://your-agent.com/registration.json"
```

**Fix**: Add a gas buffer to your transaction:

```typescript
import { ethers } from 'ethers';

const provider = new ethers.JsonRpcProvider(process.env.CHAIN_RPC_URL);
const wallet = new ethers.Wallet(process.env.PRIVATE_KEY!, provider);
const contract = new ethers.Contract(contractAddress, abi, wallet);

// Estimate and add 20% buffer
const estimated = await contract.setAgentURI.estimateGas(agentId, metadataUrl);
const gasLimit = estimated * 120n / 100n;

const tx = await contract.setAgentURI(agentId, metadataUrl, { gasLimit });
const receipt = await tx.wait();
console.log(`Transaction confirmed: ${receipt.hash}`);
```

**Also check**:
- Sufficient native token balance (ETH on Base, AVAX on Avalanche)
- Correct contract address for the network
- Wallet is the registered owner of the agent

---

### Wrong Agent ID in Registration

**Environment**: Any chain

**Symptom**: Agent registered successfully, but `registration.json` has the wrong `agentId`. Scanner shows WA080 (metadata conflict). Agent doesn't appear in search results.

**Root Cause**: Copied `agentId` from a test deployment, forgot to update after mainnet registration, or parsed the registration event incorrectly.

**Diagnosis**:
```bash
# Check your actual on-chain agent ID
cast call --rpc-url $RPC_URL \
  $CONTRACT_ADDRESS \
  "balanceOf(address)(uint256)" \
  $WALLET_ADDRESS

# Get agent details
cast call --rpc-url $RPC_URL \
  $CONTRACT_ADDRESS \
  "tokenURI(uint256)(string)" \
  $AGENT_ID
```

**Fix**:

1. Find your correct agent ID from the registration transaction:
```bash
# Get registration event from your tx hash
cast receipt --rpc-url $RPC_URL $TX_HASH | grep -A5 "logs"
```

2. Update `registration.json`:
```json
{
  "registrations": [
    {
      "chainId": 8453,
      "agentId": 47,
      "contractAddress": "0x1234567890abcdef1234567890abcdef12345678"
    }
  ]
}
```

3. Redeploy and update on-chain URI:
```bash
CHAIN=base PRIVATE_KEY=$KEY ./scripts/update-uri.sh 47 "https://your-agent.com/registration.json"
```

---

### Snowtrace Shows Old Metadata

**Environment**: Avalanche C-Chain

**Symptom**: Updated `registration.json` and redeployed, but Snowtrace (Avalanche's block explorer) still shows old agent metadata.

**Root Cause**: Snowtrace caches NFT metadata aggressively. Even after calling `setAgentURI`, Snowtrace may serve cached data for hours.

**Diagnosis**:
```bash
# Verify the on-chain URI is correct
cast call --rpc-url https://api.avax.network/ext/bc/C/rpc \
  $CONTRACT_ADDRESS \
  "tokenURI(uint256)(string)" \
  $AGENT_ID

# Verify your hosted metadata is correct
curl -s https://your-agent.com/registration.json | jq .
```

**Fix**:
1. Ensure the on-chain `tokenURI` points to your current URL
2. Use Snowtrace's metadata refresh feature (if available on the NFT page)
3. Wait -- Snowtrace typically refreshes within 24 hours
4. For 8004scan.io specifically, metadata is re-fetched more frequently (every few hours)

**Workaround for faster refresh**:
```bash
# Some explorers support a refresh API
curl -X POST "https://api.snowtrace.io/api?module=token&action=tokeninfo&contractaddress=$CONTRACT_ADDRESS"
```

---

## Health Check and Monitoring

### Health Endpoint Returns 500

**Environment**: Express/Fastify

**Symptom**: The `/api/health` endpoint intermittently returns 500 instead of 200. Deployment platform marks the service as unhealthy.

**Root Cause**: Health endpoint checks dependencies (database, external APIs) that are temporarily unavailable.

**Fix**: Implement a two-tier health check:

```typescript
// Liveness: "Is the process running?" - always returns 200
app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
  });
});

// Readiness: "Can I serve traffic?" - checks dependencies
app.get('/api/ready', async (req, res) => {
  const checks = {
    coingecko: false,
    rpc: false,
  };

  try {
    const cgResponse = await fetch('https://api.coingecko.com/api/v3/ping', {
      signal: AbortSignal.timeout(3000),
    });
    checks.coingecko = cgResponse.ok;
  } catch {}

  try {
    const provider = new ethers.JsonRpcProvider(process.env.CHAIN_RPC_URL);
    await provider.getBlockNumber();
    checks.rpc = true;
  } catch {}

  const allHealthy = Object.values(checks).every(Boolean);
  res.status(allHealthy ? 200 : 503).json({ checks });
});
```

Configure your deployment platform to use `/api/health` for liveness and `/api/ready` for readiness.

---

### MCP Endpoint Returns Invalid JSON-RPC

**Environment**: Express with custom MCP handler

**Symptom**: MCP clients get parse errors or "invalid response" when calling tools. The endpoint returns HTTP 200 but the response body doesn't conform to JSON-RPC 2.0.

**Root Cause**: Missing required JSON-RPC fields (`jsonrpc`, `id`) in the response, or wrapping the result incorrectly.

**Diagnosis**:
```bash
# Test MCP tools/list
curl -s -X POST https://your-agent.com/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}' | jq .

# Test a specific tool
curl -s -X POST https://your-agent.com/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"get_price","arguments":{"token":"bitcoin"}},"id":2}' | jq .
```

**Fix**: Ensure every response includes the required JSON-RPC fields:

```typescript
// Correct JSON-RPC response
function jsonRpcResponse(id: number | string, result: any) {
  return {
    jsonrpc: '2.0',
    id,
    result,
  };
}

// Correct JSON-RPC error
function jsonRpcError(id: number | string | null, code: number, message: string) {
  return {
    jsonrpc: '2.0',
    id,
    error: { code, message },
  };
}

app.post('/mcp', async (req, res) => {
  const { jsonrpc, method, params, id } = req.body;

  if (jsonrpc !== '2.0') {
    return res.json(jsonRpcError(id, -32600, 'Invalid Request: must use JSON-RPC 2.0'));
  }

  if (method === 'tools/list') {
    return res.json(jsonRpcResponse(id, { tools: [...] }));
  }

  if (method === 'tools/call') {
    try {
      const result = await handleToolCall(params.name, params.arguments);
      return res.json(jsonRpcResponse(id, result));
    } catch (err) {
      return res.json(jsonRpcError(id, -32603, `Tool error: ${err.message}`));
    }
  }

  return res.json(jsonRpcError(id, -32601, `Method not found: ${method}`));
});
```

---

### A2A Endpoint Not Returning Proper Agent Card

**Environment**: Express with A2A protocol support

**Symptom**: Other agents can't discover your agent via A2A. The `/.well-known/agent.json` path returns 404 or malformed JSON.

**Root Cause**: Either the A2A endpoint isn't mounted, or it returns incomplete data.

**Diagnosis**:
```bash
# Test A2A discovery
curl -s https://your-agent.com/.well-known/agent.json | jq .

# Check required fields
curl -s https://your-agent.com/.well-known/agent.json | jq '{name, url, description, version, capabilities}'
```

**Fix**: Implement the A2A agent card endpoint:

```typescript
app.get('/.well-known/agent.json', (req, res) => {
  res.json({
    name: 'Your Agent Name',
    url: 'https://your-agent.com',
    description: 'What your agent does',
    version: '1.0.0',
    capabilities: {
      streaming: false,
      pushNotifications: false,
    },
    skills: [
      {
        id: 'get-token-price',
        name: 'Get Token Price',
        description: 'Fetches current price for a token',
        tags: ['defi', 'price'],
        examples: ['What is the price of ETH?'],
      },
    ],
    defaultInputModes: ['text/plain'],
    defaultOutputModes: ['text/plain'],
  });
});
```

---

## CORS and Network Issues

### CORS Errors from Browser Clients

**Environment**: Express, accessed from browser-based agents or dashboards

**Symptom**: Browser console shows:
```
Access to fetch at 'https://your-agent.com/mcp' from origin 'https://other-app.com' has been blocked by CORS policy
```

**Root Cause**: No CORS headers set on the server, or incorrect CORS configuration.

**Fix**:
```typescript
import cors from 'cors';

// Allow all origins (for public agents)
app.use(cors());

// Or restrict to specific origins
app.use(cors({
  origin: ['https://8004scan.io', 'https://your-dashboard.com'],
  methods: ['GET', 'POST'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));
```

Install the package: `npm install cors @types/cors`

---

### Request Body Not Parsed

**Environment**: Express

**Symptom**: `req.body` is `undefined` in POST handlers. MCP calls fail silently.

**Root Cause**: Missing body parser middleware.

**Fix**: Add JSON body parsing before your routes:

```typescript
import express from 'express';

const app = express();

// This MUST come before route definitions
app.use(express.json());

// Now req.body will be parsed
app.post('/mcp', (req, res) => {
  console.log(req.body); // { jsonrpc: "2.0", method: "tools/list", id: 1 }
});
```

---

## Registration Issues

### Registration Transaction Succeeds But Agent Not Visible

**Environment**: Base or Avalanche

**Symptom**: The `registerAgent` transaction confirms on-chain, but the agent doesn't appear on 8004scan.io or any scanner.

**Root Cause**: One of:
1. Scanner hasn't indexed the new block yet (wait 5-10 minutes)
2. The `tokenURI` was set to an unreachable URL
3. The metadata at the URI doesn't conform to the ERC-8004 schema

**Diagnosis**:
```bash
# Verify on-chain registration
cast call --rpc-url $RPC_URL \
  $CONTRACT_ADDRESS \
  "tokenURI(uint256)(string)" \
  $AGENT_ID

# Fetch and validate metadata
curl -s $(cast call --rpc-url $RPC_URL $CONTRACT_ADDRESS "tokenURI(uint256)(string)" $AGENT_ID) | jq .

# Check required fields
curl -s https://your-agent.com/registration.json | jq '{type, name, description, image}'
```

**Fix**: Ensure metadata is:
1. Publicly accessible (no auth required)
2. Valid JSON
3. Contains all required fields (`type`, `name`, `description`, `image`)
4. The `type` field is exactly: `"https://eips.ethereum.org/EIPS/eip-8004#registration-v1"`

---

## Debugging Tips

### Enable Verbose Logging

Add structured logging to trace issues:

```typescript
function log(level: string, message: string, data?: any) {
  console.log(JSON.stringify({
    timestamp: new Date().toISOString(),
    level,
    message,
    ...data,
  }));
}

// Usage
log('info', 'MCP tool called', { method: 'get_price', token: 'bitcoin' });
log('error', 'API call failed', { url, status: response.status, elapsed: `${Date.now() - start}ms` });
```

### Test Your Agent Like a Scanner

Run the same checks scanners run:

```bash
#!/bin/bash
# verify-agent.sh
AGENT_URL=$1

echo "=== Health Check ==="
curl -sf "$AGENT_URL/api/health" | jq . || echo "FAIL: health endpoint"

echo ""
echo "=== Registration Metadata ==="
curl -sf "$AGENT_URL/registration.json" | jq . || echo "FAIL: registration.json"

echo ""
echo "=== MCP Tools ==="
curl -sf -X POST "$AGENT_URL/mcp" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}' | jq '.result.tools[] | .name' || echo "FAIL: MCP"

echo ""
echo "=== A2A Agent Card ==="
curl -sf "$AGENT_URL/.well-known/agent.json" | jq '{name, version}' || echo "FAIL: A2A"

echo ""
echo "=== Image ==="
IMAGE_URL=$(curl -sf "$AGENT_URL/registration.json" | jq -r '.image')
STATUS=$(curl -sf -o /dev/null -w "%{http_code}" "$IMAGE_URL")
echo "Image URL: $IMAGE_URL (HTTP $STATUS)"
```

### Monitor Response Times

Track how long your MCP tools take:

```typescript
app.post('/mcp', async (req, res) => {
  const start = Date.now();
  const { method, params, id } = req.body;

  try {
    const result = await handleRequest(method, params);
    const elapsed = Date.now() - start;

    log('info', 'MCP request completed', { method, elapsed: `${elapsed}ms` });

    if (elapsed > 5000) {
      log('warn', 'Slow MCP response', { method, elapsed: `${elapsed}ms` });
    }

    return res.json({ jsonrpc: '2.0', id, result });
  } catch (err) {
    const elapsed = Date.now() - start;
    log('error', 'MCP request failed', { method, elapsed: `${elapsed}ms`, error: err.message });
    return res.json({ jsonrpc: '2.0', id, error: { code: -32603, message: err.message } });
  }
});
```

---

## Quick Reference

| Error | Likely Cause | First Thing to Check |
|-------|-------------|---------------------|
| 502 Bad Gateway | Wrong port | `process.env.PORT` usage |
| 429 Too Many Requests | No caching | Add TTL cache |
| Transaction reverted | Low gas / wrong owner | Gas estimate + wallet check |
| WA080 scanner warning | Metadata mismatch | `tokenURI` vs hosted JSON |
| MCP parse error | Bad JSON-RPC format | Response includes `jsonrpc` and `id` |
| CORS blocked | No CORS middleware | Add `cors()` middleware |
| `req.body` undefined | No body parser | Add `express.json()` |
| Agent not in scanner | Bad metadata URL | `curl` the `tokenURI` value |
| Memory growing | Unbounded cache | Add max size + cleanup |
| Slow responses | Sequential API calls | Use `Promise.all` |
