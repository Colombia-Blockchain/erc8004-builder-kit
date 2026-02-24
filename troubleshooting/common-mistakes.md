# Top 10 Mistakes Building ERC-8004 Agents

Hard-won lessons from building two production ERC-8004 agents. Every mistake here cost real debugging time.

---

## 1. Declaring Services Before Implementing Them

**What happened**: Listed A2A, MCP, and OASF endpoints in `registration.json` before any of them were built. The scanner immediately flagged unreachable endpoints (WA082), and the agent's Service score dropped to zero.

**Why it's wrong**: Scanners verify every service endpoint you declare. Listing unimplemented services is worse than listing none -- it signals an unreliable agent to both scanners and other agents trying to interoperate.

**Fix**: Only add a service to `registration.json` after the endpoint is live and returning valid responses.

```json
{
  "services": [
    {
      "name": "MCP",
      "endpoint": "https://your-agent.com/mcp",
      "version": "2025-11-25"
    }
  ]
}
```

**Prevention**: Add services incrementally. Deploy, verify with `curl`, then add to metadata. Never declare aspirational capabilities.

---

## 2. Using Local File Paths in Production Code

**What happened**: Had `fs.readFileSync('/Users/username/project/data/config.json')` in the codebase. Worked locally, crashed instantly on Railway with `ENOENT: no such file or directory`.

**Why it's wrong**: Absolute local paths don't exist in deployment environments. Even relative paths can break depending on the working directory at runtime.

**Fix**: Use environment variables or path resolution relative to the project root:

```typescript
import path from 'path';

// Bad
const config = fs.readFileSync('/Users/username/project/config.json');

// Good
const config = fs.readFileSync(path.join(process.cwd(), 'config.json'));

// Better
const config = JSON.parse(process.env.CONFIG || '{}');
```

**Prevention**: Search your codebase for absolute paths before every deploy: `grep -r "/Users/" src/`. Add it to your CI checks.

---

## 3. Forgetting to Update Agent ID After Registration

**What happened**: Registered the agent on-chain, got back agent ID `47`, but `registration.json` still had `"agentId": 0` from the template. Scanner showed WA080 (metadata conflict) and the agent was effectively invisible.

**Why it's wrong**: The `agentId` in your metadata must match your on-chain registration. Mismatches prevent scanners from linking your hosted metadata to your on-chain identity.

**Fix**: After calling `registerAgent()`, immediately update `registration.json`:

```json
{
  "registrations": [
    {
      "chainId": 8453,
      "agentId": 47,
      "contractAddress": "0x..."
    }
  ]
}
```

**Prevention**: Add a post-registration script that automatically patches the agent ID into your metadata file. Or use a dynamic endpoint that reads the ID from an environment variable.

---

## 4. Not Caching External API Calls

**What happened**: Every MCP tool invocation made fresh calls to CoinGecko, DefiLlama, and block explorers. Within an hour, hit rate limits (HTTP 429) on CoinGecko's free tier. Agent became useless during peak traffic.

**Why it's wrong**: External APIs have rate limits. Without caching, your agent's reliability depends entirely on third-party availability and generosity. One burst of requests can lock you out for minutes or hours.

**Fix**: Implement a simple in-memory cache with TTL:

```typescript
const cache = new Map<string, { data: any; expires: number }>();

async function cachedFetch(url: string, ttlMs: number = 60_000): Promise<any> {
  const cached = cache.get(url);
  if (cached && cached.expires > Date.now()) return cached.data;

  const response = await fetch(url);
  const data = await response.json();
  cache.set(url, { data, expires: Date.now() + ttlMs });
  return data;
}
```

**Prevention**: Cache by default. Use 60s TTL for price data, 300s for protocol metadata, 3600s for static data like token lists.

---

## 5. Sequential API Calls Instead of Parallel

**What happened**: A tool that fetched token price, TVL, and holder count made three API calls sequentially. Each took 200-500ms. Total response time: 1.2 seconds. Users experienced timeouts when the agent was under load.

**Why it's wrong**: Independent API calls should run concurrently. Sequential execution wastes time and increases the chance that at least one call will timeout.

**Fix**: Use `Promise.all` for independent requests:

```typescript
// Bad: ~1200ms
const price = await fetchPrice(token);
const tvl = await fetchTVL(protocol);
const holders = await fetchHolders(token);

// Good: ~400ms
const [price, tvl, holders] = await Promise.all([
  fetchPrice(token),
  fetchTVL(protocol),
  fetchHolders(token),
]);
```

**Prevention**: Whenever you write `await` inside a function, ask: "Does this depend on the result of the previous `await`?" If not, use `Promise.all`.

---

## 6. Hardcoding Port Instead of Using PORT Environment Variable

**What happened**: Server was hardcoded to `app.listen(3000)`. Railway assigns a dynamic port via the `PORT` environment variable. The app started but Railway's health check couldn't reach it, resulting in repeated 502 errors and deploy failures.

**Why it's wrong**: Cloud platforms (Railway, Render, Heroku, Cloud Run) inject the port dynamically. Ignoring `PORT` means your app listens on the wrong port and the platform's reverse proxy can't route traffic to it.

**Fix**:

```typescript
// Bad
app.listen(3000);

// Good
const PORT = parseInt(process.env.PORT || '3000', 10);
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

**Prevention**: Never hardcode ports. Always use `process.env.PORT` with a fallback for local development.

---

## 7. Serving JSON at Root URL Instead of HTML Dashboard

**What happened**: The root route (`/`) returned raw `registration.json`. Looked fine in development. But when shared on social media or in documentation, the link preview showed raw JSON. No human-readable landing page, no explanation of what the agent does.

**Why it's wrong**: The root URL is your agent's front door for humans. Browsers, link previews, and curious developers will visit `/` first. Raw JSON is hostile to humans and misses an opportunity to explain your agent.

**Fix**: Serve an HTML dashboard at `/` and JSON at `/registration.json`:

```typescript
app.get('/', (req, res) => {
  res.send(`
    <html>
      <head><title>My Agent - ERC-8004</title></head>
      <body>
        <h1>My Agent</h1>
        <p>An ERC-8004 compliant AI agent.</p>
        <a href="/registration.json">View Registration Metadata</a>
      </body>
    </html>
  `);
});

app.get('/registration.json', (req, res) => {
  res.json(registrationMetadata);
});
```

**Prevention**: Always build a minimal HTML dashboard for `/`. It can be simple, but it should be human-readable.

---

## 8. Setting x402Support: true Without Payment Endpoints

**What happened**: Copied a template that included `"x402Support": true` in the registration metadata. Had no idea what x402 was. Scanner didn't flag it, but another agent tried to pay for a service and got a 404 on the payment endpoint.

**Why it's wrong**: `x402Support: true` tells other agents "I accept HTTP 402 payment flows." If you don't implement the payment negotiation endpoints, agents that try to pay you will fail silently or error out. It's a broken promise.

**Fix**: Either implement x402 payment flow or remove the flag:

```json
{
  "x402Support": false
}
```

If you do want x402, implement the full flow: payment negotiation, invoice generation, and payment verification.

**Prevention**: Don't copy template fields you don't understand. Read the ERC-8004 spec for every field you include. If in doubt, leave it out.

---

## 9. Not Running setAgentURI After Metadata Updates

**What happened**: Updated `registration.json` with new services and redeployed. The hosted file was correct, but the scanner still showed the old metadata. Spent an hour debugging before realizing the on-chain `tokenURI` still pointed to the old version (or was cached by the scanner using the on-chain pointer).

**Why it's wrong**: Scanners use the on-chain `tokenURI` as the source of truth for where to find metadata. If you change your metadata URL or want scanners to re-fetch, you need to update the on-chain pointer. Even if the URL hasn't changed, calling `setAgentURI` signals a metadata update.

**Fix**:

```bash
# After every significant metadata update
CHAIN=base PRIVATE_KEY=$KEY ./scripts/update-uri.sh <agent-id> "https://your-agent.com/registration.json"
```

**Prevention**: Add `setAgentURI` to your deployment pipeline. Every deploy that changes `registration.json` should trigger an on-chain URI update.

---

## 10. Claiming Capabilities the Agent Doesn't Have

**What happened**: Listed "real-time portfolio tracking" and "cross-chain bridging recommendations" in the agent description. The agent could only fetch token prices. Users and other agents expected functionality that didn't exist, leading to frustration and negative reputation feedback.

**Why it's wrong**: Your description is a contract with users and other agents. Overclaiming destroys trust. In the ERC-8004 ecosystem, agents can leave on-chain reputation feedback. Negative feedback from broken promises tanks your Engagement score.

**Fix**: Be precise and honest in your description:

```json
{
  "description": "Fetches current token prices and 24h price changes for tokens on Base and Avalanche using CoinGecko data. Updated every 60 seconds."
}
```

**Prevention**: Write your description last, after all features are implemented and tested. Describe what the agent does today, not what you plan to build. Update the description as capabilities grow.

---

## Summary

| # | Mistake | Severity | Time to Debug |
|---|---------|----------|---------------|
| 1 | Declaring unimplemented services | High | 30 min |
| 2 | Local file paths in production | High | 15 min |
| 3 | Wrong agent ID after registration | High | 60 min |
| 4 | No API caching | Medium | 2 hours |
| 5 | Sequential instead of parallel calls | Medium | 45 min |
| 6 | Hardcoded port | High | 30 min |
| 7 | JSON at root URL | Low | 10 min |
| 8 | x402Support without implementation | Medium | 1 hour |
| 9 | Missing setAgentURI call | High | 60 min |
| 10 | Overclaiming capabilities | High | Ongoing |
