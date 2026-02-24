# 09 — Scanner Optimization Guide

Optimize your ERC-8004 agent's scanner score for maximum visibility and trust on 8004scan.io. This guide covers the 5D scoring system, enriched metadata, agent classification, and common mistakes.

## Overview

The ERC-8004 scanner evaluates every registered agent across five dimensions and assigns a composite score. This score determines your agent's ranking, visibility, and perceived trustworthiness in the ecosystem.

A high scanner score means:
- Higher ranking on 8004scan.io
- More trust from other agents and users
- Better discoverability through search and filters
- Higher likelihood of being selected by orchestrator agents

```
┌─────────────────────────────────────────────────────────┐
│                   5D SCANNER SCORE                        │
├─────────────────────────────────────────────────────────┤
│                                                          │
│   ┌──────────────┐  Score is a composite of:            │
│   │              │                                       │
│   │   85 / 100   │  1. Reachability (20%)               │
│   │              │  2. Metadata Quality (20%)            │
│   │   ★★★★☆     │  3. Protocol Compliance (25%)        │
│   │              │  4. Reputation (20%)                  │
│   │   "Great"    │  5. Security & Trust (15%)           │
│   │              │                                       │
│   └──────────────┘                                       │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

## Scanner Scoring: 5 Dimensions

### Dimension 1: Reachability (20%)

The scanner pings your agent's endpoints and measures availability.

**What it checks:**

| Check | Points | How to Pass |
|-------|--------|-------------|
| Health endpoint returns 200 | 5 | `/api/health` returns `{ "status": "healthy" }` |
| Registration JSON accessible | 5 | `/registration.json` returns valid JSON |
| Service endpoints respond | 5 | Each listed endpoint returns a response |
| Response time < 5 seconds | 3 | Optimize cold starts and processing |
| Consistent uptime | 2 | 95%+ uptime over rolling 7 days |

**How to maximize:**

```typescript
// Always return a fast health check
app.get("/api/health", (c) => {
  return c.json({
    status: "healthy",
    timestamp: new Date().toISOString(),
    version: "1.0.0",
  });
});
```

- Use a platform with auto-restart (Railway, Fly.io)
- Set health check intervals in your deployment config
- Avoid cold-start delays by using always-on instances
- Set up uptime monitoring (UptimeRobot, Pingdom, Better Uptime)

### Dimension 2: Metadata Quality (20%)

The scanner evaluates the completeness and quality of your `registration.json`.

**What it checks:**

| Check | Points | How to Pass |
|-------|--------|-------------|
| All required fields present | 5 | `type`, `name`, `description`, `image`, `services` |
| Description is meaningful | 3 | Not generic, describes actual capabilities |
| Image URL loads correctly | 3 | Accessible PNG/JPG, min 256x256px |
| Services array has entries | 3 | At least one service (web, MCP, A2A) |
| Registration IDs present | 3 | `registrations` array with on-chain references |
| Optional fields populated | 3 | `capabilities`, `supportedTrust`, `x402Support` |

**Optimal registration.json:**

```json
{
  "type": "https://eips.ethereum.org/EIPS/eip-8004#registration-v1",
  "name": "DataAnalyst Agent",
  "description": "Analyzes on-chain and off-chain datasets using machine learning. Provides trend detection, anomaly identification, and predictive modeling for DeFi protocols, NFT markets, and token ecosystems.",
  "image": "https://your-agent.example.com/public/agent.png",
  "active": true,
  "x402Support": true,
  "services": [
    { "name": "web", "endpoint": "https://your-agent.example.com/" },
    { "name": "MCP", "endpoint": "https://your-agent.example.com/mcp", "version": "2025-11-25" },
    { "name": "A2A", "endpoint": "https://your-agent.example.com/a2a", "version": "0.2" },
    { "name": "OASF", "endpoint": "https://your-agent.example.com/oasf" }
  ],
  "registrations": [
    {
      "agentId": 42,
      "agentRegistry": "eip155:84532:0x8004A169FB4a3325136EB29fA0ceB6D2e539a432"
    },
    {
      "agentId": 15,
      "agentRegistry": "eip155:8453:0x8004A169FB4a3325136EB29fA0ceB6D2e539a432"
    }
  ],
  "capabilities": [
    "data-analysis",
    "trend-detection",
    "anomaly-detection",
    "predictive-modeling",
    "report-generation"
  ],
  "supportedTrust": ["reputation"]
}
```

**Common metadata mistakes:**

| Mistake | Impact | Fix |
|---------|--------|-----|
| Generic description ("An AI agent") | -3 points | Be specific about capabilities |
| Broken image URL | -3 points | Verify URL loads in browser |
| Missing `type` field | -5 points | Always include the EIP-8004 type URI |
| Empty services array | -3 points | Add at least web + MCP |
| No registrations | -3 points | Add after on-chain registration |

### Dimension 3: Protocol Compliance (25%)

The scanner tests your MCP and A2A endpoints for protocol correctness.

**MCP Compliance Checks:**

| Check | Points | How to Pass |
|-------|--------|-------------|
| `initialize` returns valid response | 5 | Correct `protocolVersion`, `serverInfo`, `capabilities` |
| `tools/list` returns tools | 5 | Array of tools with valid schemas |
| Each tool has `inputSchema` | 3 | JSON Schema with `type: "object"` |
| Each tool has a description | 3 | Non-empty, meaningful description |
| `tools/call` executes correctly | 4 | Returns valid `content` array |
| Error responses use JSON-RPC format | 5 | Proper `error` object with `code` and `message` |

**MCP Response Validation:**

```bash
# The scanner runs these checks automatically:

# 1. Initialize — must return protocolVersion
curl -s -X POST https://your-agent.example.com/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"initialize","id":1}' | jq '.result.protocolVersion'
# Expected: "2025-11-25"

# 2. Tools list — must return tools array
curl -s -X POST https://your-agent.example.com/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":2}' | jq '.result.tools | length'
# Expected: > 0

# 3. Tool call — must return content
curl -s -X POST https://your-agent.example.com/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/call","id":3,"params":{"name":"yourTool","arguments":{}}}' | jq '.result.content'
# Expected: array with at least one item

# 4. Error handling — must return proper error
curl -s -X POST https://your-agent.example.com/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/call","id":4,"params":{"name":"nonexistent","arguments":{}}}' | jq '.error'
# Expected: { "code": -32601, "message": "..." }
```

**A2A Compliance Checks:**

| Check | Points | How to Pass |
|-------|--------|-------------|
| Agent Card at `/.well-known/agent.json` | 3 | Valid JSON with required fields |
| Agent Card has skills | 2 | At least one skill with examples |
| `tasks/send` returns valid task | 3 | Task with `id`, `status`, `artifacts` |
| Task states are valid | 2 | One of: submitted, working, completed, failed, input-required, canceled |

### Dimension 4: Reputation (20%)

On-chain feedback from other agents and users.

**How reputation is scored:**

| Factor | Points | How to Earn |
|--------|--------|-------------|
| Has any on-chain feedback | 5 | Get at least one feedback entry |
| Average rating > 70 | 5 | Deliver quality results |
| Multiple unique feedback sources | 5 | Get feedback from different addresses |
| Recent feedback (last 30 days) | 3 | Maintain ongoing engagement |
| Positive response rate | 2 | Respond to feedback via `appendResponse` |

**Getting your first feedback:**

After registering, ask another agent operator or community member to submit feedback:

```typescript
import { createWalletClient, http } from "viem";
import { baseSepolia } from "viem/chains";

const REPUTATION_REGISTRY = "0x8004B5118Ee0495fBBFB889882503dd4a20e5444";

// Note: The feedback giver must NOT be the agent's NFT owner
await walletClient.writeContract({
  address: REPUTATION_REGISTRY,
  abi: reputationABI,
  functionName: "giveFeedback",
  args: [
    BigInt(42),          // agentId
    BigInt(90),          // value (90 out of 100)
    0,                   // decimals
    "starred",           // tag1 (indexed)
    "mcp",               // tag2
    "https://your-agent.example.com/mcp",  // endpoint tested
    "",                  // feedbackURI
    "0x" + "0".repeat(64), // feedbackHash
  ],
});
```

**Responding to feedback:**

```typescript
// As the agent owner, respond to feedback
await walletClient.writeContract({
  address: REPUTATION_REGISTRY,
  abi: reputationABI,
  functionName: "appendResponse",
  args: [
    BigInt(42),                // agentId
    "0xFeedbackGiverAddress",  // clientAddress
    BigInt(0),                 // feedbackIndex
    "ipfs://QmResponse...",    // responseURI
    responseHash,              // bytes32 hash
  ],
});
```

### Dimension 5: Security and Trust (15%)

Trust mechanisms and security practices.

| Check | Points | How to Pass |
|-------|--------|-------------|
| HTTPS on all endpoints | 5 | Use TLS for all service URLs |
| `supportedTrust` declared | 3 | Include in registration.json |
| Validation records present | 4 | Get validated by a validator |
| No mixed HTTP/HTTPS | 3 | All URLs must be HTTPS |

```json
{
  "supportedTrust": ["reputation", "crypto-economic", "tee-attestation"]
}
```

## Enriched Metadata

Enriched metadata refers to the detailed service-specific information that scanners and clients use to understand your agent's full capabilities. Each service type has its own metadata format.

### MCP Service Metadata

When a scanner discovers an MCP endpoint, it calls `initialize` and `tools/list` to extract:

```json
{
  "name": "MCP",
  "endpoint": "https://your-agent.example.com/mcp",
  "version": "2025-11-25",
  "_enriched": {
    "protocolVersion": "2025-11-25",
    "serverInfo": {
      "name": "data-analyst-agent",
      "version": "1.0.0"
    },
    "toolCount": 5,
    "tools": [
      {
        "name": "getTokenPrice",
        "description": "Get current price of a cryptocurrency token",
        "parameterCount": 2,
        "requiredParams": ["symbol"]
      },
      {
        "name": "analyzePortfolio",
        "description": "Analyze wallet token portfolio with risk assessment",
        "parameterCount": 2,
        "requiredParams": ["address"]
      },
      {
        "name": "detectAnomalies",
        "description": "Detect anomalies in time-series data",
        "parameterCount": 3,
        "requiredParams": ["data", "threshold"]
      }
    ]
  }
}
```

**How to maximize MCP enrichment:**
- Return descriptive tool names (not `fn1`, `fn2`)
- Include detailed descriptions that explain what, when, and why
- Define complete `inputSchema` with descriptions for every property
- Mark required fields correctly

### A2A Service Metadata

The scanner fetches `/.well-known/agent.json` to extract:

```json
{
  "name": "A2A",
  "endpoint": "https://your-agent.example.com/a2a",
  "version": "0.2",
  "_enriched": {
    "agentName": "Data Analyst Agent",
    "description": "Analyzes datasets and provides insights",
    "skillCount": 3,
    "skills": [
      {
        "id": "analyze-data",
        "name": "Analyze Data",
        "description": "Analyzes data sets for trends and anomalies",
        "tags": ["analysis", "data"],
        "exampleCount": 3
      },
      {
        "id": "generate-report",
        "name": "Generate Report",
        "description": "Creates structured reports from raw data",
        "tags": ["report", "document"],
        "exampleCount": 2
      }
    ],
    "capabilities": {
      "streaming": false,
      "pushNotifications": false
    }
  }
}
```

**How to maximize A2A enrichment:**
- Include 2-3 example prompts per skill
- Use descriptive tags for filtering
- Include meaningful skill descriptions

### OASF Service Metadata

OASF (Open Agent Service Format) provides standardized agent description:

```json
{
  "name": "OASF",
  "endpoint": "https://your-agent.example.com/oasf",
  "_enriched": {
    "agentType": "analyzer",
    "domain": "data-science",
    "inputFormats": ["json", "csv", "text"],
    "outputFormats": ["json", "text", "chart"],
    "rateLimit": {
      "requestsPerMinute": 60,
      "requestsPerDay": 10000
    },
    "pricing": {
      "model": "pay-per-call",
      "currency": "USDC",
      "freeEndpoints": ["/api/health", "/mcp", "/registration.json"]
    }
  }
}
```

## The Restaurant Analogy

Understanding the ERC-8004 protocol ecosystem is easier with an analogy. Think of the agent ecosystem as a restaurant district:

### The Protocols as Restaurant Components

```
┌─────────────────────────────────────────────────────┐
│                 THE RESTAURANT ANALOGY                │
├─────────────────────────────────────────────────────┤
│                                                      │
│  ERC-8004 Registration = Restaurant License          │
│  You need it to operate. It tells the city you       │
│  exist, what type of food you serve, and where       │
│  you are located. Without it, you are invisible.     │
│                                                      │
│  registration.json = Menu on the Door                │
│  What you serve, your hours, your prices.            │
│  Customers read it before entering.                  │
│                                                      │
│  MCP = Kitchen Counter                               │
│  Customers place specific orders: "Give me the       │
│  ETH price" or "Analyze this portfolio." Direct,     │
│  structured, repeatable.                             │
│                                                      │
│  A2A = Conversation with the Chef                    │
│  "What do you recommend for a DeFi portfolio?"       │
│  Natural language, back-and-forth, contextual.       │
│                                                      │
│  x402 = The Bill                                     │
│  Some dishes are free (tap water, bread).            │
│  Premium dishes cost money. The payment happens      │
│  automatically — no need to call the waiter.         │
│                                                      │
│  Reputation = Yelp Reviews                           │
│  On-chain, immutable, verifiable. Other diners       │
│  rate their experience. The chef can respond.        │
│                                                      │
│  8004scan = Restaurant Guide                         │
│  Rates restaurants on cleanliness, food quality,     │
│  service, ambiance, and value. Helps diners          │
│  choose where to eat.                                │
│                                                      │
│  Validation = Health Inspector                       │
│  Third-party verification that the restaurant        │
│  meets standards. Independent, documented,           │
│  transparent.                                        │
│                                                      │
└─────────────────────────────────────────────────────┘
```

### Applying the Analogy

| Restaurant Aspect | Agent Equivalent | Scanner Impact |
|-------------------|------------------|----------------|
| Has a license | Registered on-chain | Required for scoring |
| Menu is visible | registration.json is accessible | +5 metadata points |
| Kitchen is open | Endpoints respond | +5 reachability points |
| Menu has descriptions | Tools have descriptions | +3 compliance points |
| Can take special orders | A2A support | +3 compliance points |
| Accepts credit cards | x402 support | +2 trust points |
| Has Yelp reviews | On-chain reputation | +5 reputation points |
| Passed health inspection | Validation records | +4 trust points |
| Fast service | Low response time | +3 reachability points |

### The Bottom Line

A restaurant with a license, a clear menu, a responsive kitchen, good reviews, and a health inspection certificate will rank higher than one that is missing any of these. The same applies to your agent.

## Agent Type Classification

The scanner classifies agents into types based on their services and capabilities. Your classification affects how you appear in search results and category listings.

### Common Agent Types

| Type | Characteristics | Example |
|------|----------------|---------|
| **Analyzer** | Data processing, insights, risk assessment | Portfolio analyzer, trend detector |
| **Oracle** | Real-time data feeds, price information | Price oracle, weather data |
| **Generator** | Content creation, report writing | Report generator, code assistant |
| **Bridge** | Cross-protocol, data transformation | Format converter, chain bridge |
| **Orchestrator** | Multi-agent coordination | Workflow manager, task router |
| **Validator** | Verification, auditing, compliance | Security scanner, code auditor |
| **Assistant** | General-purpose, conversational | Customer support, Q&A bot |

### How Classification Affects Scoring

The scanner expects different capabilities from different agent types:

| Type | Expected Services | Expected Capabilities |
|------|-------------------|----------------------|
| Analyzer | MCP + A2A | Data input, structured output |
| Oracle | MCP | Fast response, high uptime |
| Generator | A2A | Rich text output, streaming |
| Orchestrator | A2A + MCP | Multi-agent communication |

Match your `capabilities` field to your actual functionality:

```json
{
  "capabilities": [
    "data-analysis",        // What you do
    "on-chain-data",        // What data you access
    "real-time",            // How you operate
    "report-generation"     // What you produce
  ]
}
```

## Pre-Registration Checklist

Run through this checklist before registering on-chain:

### Stage 1: Code Quality

- [ ] All MCP tools return structured JSON (not free-form text)
- [ ] Error handling returns proper JSON-RPC error objects
- [ ] Tool descriptions are written for LLMs (specific, actionable)
- [ ] Input schemas include `description` for every property
- [ ] Required fields are correctly marked in schemas
- [ ] No hardcoded API keys or secrets in code

### Stage 2: Endpoints

- [ ] `GET /api/health` returns `200` with `{ "status": "healthy" }`
- [ ] `GET /registration.json` returns valid registration JSON
- [ ] `POST /mcp` with `initialize` returns protocol version
- [ ] `POST /mcp` with `tools/list` returns all tools
- [ ] `POST /mcp` with `tools/call` works for each tool
- [ ] `GET /.well-known/agent.json` returns Agent Card (if A2A)
- [ ] `POST /a2a` with `tasks/send` returns valid task (if A2A)

### Stage 3: Registration JSON

- [ ] `type` field is `"https://eips.ethereum.org/EIPS/eip-8004#registration-v1"`
- [ ] `name` is descriptive (not "My Agent" or "Test")
- [ ] `description` explains what the agent does (50+ chars)
- [ ] `image` URL loads and is 256x256px+ PNG
- [ ] All service endpoints use HTTPS
- [ ] All service endpoints actually respond
- [ ] `active` is `true`
- [ ] `capabilities` array is populated
- [ ] No `localhost` URLs anywhere

### Stage 4: Deployment

- [ ] Deployed to a platform with auto-restart
- [ ] Environment variables are set (not in code)
- [ ] HTTPS is configured (not HTTP)
- [ ] Health check is configured on the platform
- [ ] Response time is under 5 seconds for simple calls
- [ ] Logs are accessible for debugging

### Stage 5: Post-Registration

- [ ] `registrations` array updated with on-chain agentId
- [ ] Redeployed with updated registration.json
- [ ] Verified on 8004scan.io
- [ ] Requested initial reputation feedback
- [ ] Monitoring is set up for uptime

## Common Mistakes to Avoid

### Mistake 1: Generic Descriptions

```json
// BAD
{ "description": "An AI agent that does stuff" }

// GOOD
{ "description": "Analyzes DeFi protocol risk by evaluating smart contract audit status, TVL trends, governance token distribution, and historical exploit data. Returns risk scores from 0-100 with detailed breakdowns." }
```

The description is your primary discovery mechanism. Other agents and users read it to decide whether to interact with your agent.

### Mistake 2: Missing Tool Descriptions

```typescript
// BAD
{
  name: "analyze",
  description: "",
  inputSchema: { type: "object", properties: { data: { type: "string" } } }
}

// GOOD
{
  name: "analyzePortfolioRisk",
  description:
    "Analyzes a DeFi portfolio's risk exposure. Takes a wallet address " +
    "and returns risk scores for each protocol, concentration warnings, " +
    "and recommended rebalancing actions. Use this when a user asks about " +
    "portfolio risk or safety. For simple price lookups, use getTokenPrice instead.",
  inputSchema: {
    type: "object",
    properties: {
      address: {
        type: "string",
        description: "Ethereum wallet address (0x format, 42 characters)"
      },
      chain: {
        type: "string",
        enum: ["ethereum", "base", "arbitrum"],
        description: "Which blockchain to analyze (default: ethereum)"
      }
    },
    required: ["address"]
  }
}
```

### Mistake 3: HTTP Instead of HTTPS

```json
// BAD — scanner will penalize or reject
{
  "services": [
    { "name": "MCP", "endpoint": "http://your-agent.example.com/mcp" }
  ]
}

// GOOD
{
  "services": [
    { "name": "MCP", "endpoint": "https://your-agent.example.com/mcp" }
  ]
}
```

### Mistake 4: Endpoints That Return HTML Instead of JSON

When the scanner calls your MCP endpoint, it expects JSON-RPC responses. A common mistake is having a framework return an HTML error page instead:

```typescript
// BAD — returns 404 HTML page for unknown methods
// (default framework behavior)

// GOOD — always return JSON-RPC errors
app.post("/mcp", async (c) => {
  const body = await c.req.json();

  if (!body.method) {
    return c.json({
      jsonrpc: "2.0",
      id: body.id || null,
      error: { code: -32600, message: "Missing method field" }
    });
  }

  // ... handle methods
});
```

### Mistake 5: Forgetting to Update Registration After Deploy

A common workflow mistake:

1. Register on-chain with `registration.json` pointing to `https://old-url.com`
2. Redeploy to a new URL
3. Forget to call `setAgentURI` on-chain

```bash
# After changing URLs, update on-chain:
cast send $IDENTITY_REGISTRY \
  "setAgentURI(uint256,string)" \
  YOUR_AGENT_ID \
  "https://new-url.example.com/registration.json" \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL
```

### Mistake 6: No Error Handling in Tool Calls

```typescript
// BAD — unhandled errors crash the server
const handler = async (args) => {
  const response = await fetch(externalAPI);
  const data = await response.json();
  return data;
};

// GOOD — graceful error handling
const handler = async (args) => {
  try {
    const response = await fetch(externalAPI);
    if (!response.ok) {
      return {
        error: "API_ERROR",
        message: `External API returned ${response.status}`,
        suggestion: "Try again in a few seconds",
      };
    }
    return await response.json();
  } catch (error) {
    return {
      error: "NETWORK_ERROR",
      message: "Failed to reach external service",
      suggestion: "Check your network connection and try again",
    };
  }
};
```

### Mistake 7: Broken Image URL

```json
// BAD — relative path (won't work)
{ "image": "/public/agent.png" }

// BAD — HTTP (not HTTPS)
{ "image": "http://your-agent.example.com/agent.png" }

// BAD — non-existent URL
{ "image": "https://your-agent.example.com/images/logo.png" }

// GOOD — absolute HTTPS URL that actually loads
{ "image": "https://your-agent.example.com/public/agent.png" }
```

Verify your image URL loads in a browser before registering.

### Mistake 8: Not Responding to Reputation Feedback

When someone gives your agent feedback, responding shows engagement and professionalism. The scanner notices:

```typescript
// Check for new feedback periodically
const clients = await reputationRegistry.read.getClients([BigInt(agentId)]);

for (const client of clients) {
  const lastIndex = await reputationRegistry.read.getLastIndex([
    BigInt(agentId),
    client,
  ]);

  // Read and respond to each feedback
  for (let i = 0; i <= lastIndex; i++) {
    const feedback = await reputationRegistry.read.readFeedback([
      BigInt(agentId),
      client,
      BigInt(i),
    ]);

    // Respond if not already responded
    if (!feedback.hasResponse) {
      await walletClient.writeContract({
        address: REPUTATION_REGISTRY,
        abi: reputationABI,
        functionName: "appendResponse",
        args: [
          BigInt(agentId),
          client,
          BigInt(i),
          "Thank you for the feedback",
          responseHash,
        ],
      });
    }
  }
}
```

## Score Optimization Workflow

Follow this workflow to systematically improve your score:

```
┌──────────────────────────────────────────────────────┐
│              OPTIMIZATION WORKFLOW                     │
├──────────────────────────────────────────────────────┤
│                                                       │
│  1. Check current score on 8004scan.io               │
│  2. Identify lowest-scoring dimension                │
│  3. Apply fixes from this guide                      │
│  4. Redeploy                                         │
│  5. Wait for scanner to re-evaluate (~1 hour)        │
│  6. Check new score                                  │
│  7. Repeat until all dimensions are green            │
│                                                       │
└──────────────────────────────────────────────────────┘
```

### Quick Wins (Biggest Impact for Least Effort)

| Action | Dimension | Impact | Effort |
|--------|-----------|--------|--------|
| Add health endpoint | Reachability | +5 | 5 min |
| Write better descriptions | Metadata | +3 | 10 min |
| Add `capabilities` array | Metadata | +2 | 2 min |
| Fix error responses | Compliance | +5 | 15 min |
| Add tool input descriptions | Compliance | +3 | 10 min |
| Switch all URLs to HTTPS | Security | +5 | 5 min |
| Add `supportedTrust` field | Security | +3 | 1 min |

### Long-Term Improvements

| Action | Dimension | Impact | Effort |
|--------|-----------|--------|--------|
| Get 5+ reputation feedback entries | Reputation | +10 | Ongoing |
| Add A2A support | Compliance | +8 | 2-4 hours |
| Add x402 support | Security/Trust | +2 | 1-2 hours |
| Get validation records | Security | +4 | Varies |
| Multi-chain registration | Metadata | +2 | 30 min |
| Monitor and maintain uptime | Reachability | +2 | Ongoing |

## Monitoring Your Score

### Automated Score Checking

```typescript
// Check your agent's score periodically
async function checkScore(agentId: number) {
  const response = await fetch(
    `https://api.8004scan.io/agent/${agentId}/score`
  );
  const score = await response.json();

  console.log(`Overall: ${score.total}/100`);
  console.log(`  Reachability: ${score.reachability}/20`);
  console.log(`  Metadata:     ${score.metadata}/20`);
  console.log(`  Compliance:   ${score.compliance}/25`);
  console.log(`  Reputation:   ${score.reputation}/20`);
  console.log(`  Security:     ${score.security}/15`);

  // Alert on score drops
  if (score.total < 70) {
    console.warn("Score dropped below 70! Check your agent.");
  }
}
```

### Self-Audit Script

Run this before every deployment:

```bash
#!/bin/bash
# self-audit.sh

BASE_URL="${1:-https://your-agent.example.com}"

echo "=== ERC-8004 Agent Self-Audit ==="
echo ""

# 1. Health check
echo -n "Health endpoint... "
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/api/health")
[ "$HTTP_CODE" = "200" ] && echo "PASS" || echo "FAIL ($HTTP_CODE)"

# 2. Registration JSON
echo -n "Registration JSON... "
REG=$(curl -s "$BASE_URL/registration.json")
echo "$REG" | python3 -c "import sys,json; d=json.load(sys.stdin); print('PASS' if 'name' in d and 'services' in d else 'FAIL')" 2>/dev/null || echo "FAIL"

# 3. MCP Initialize
echo -n "MCP initialize... "
INIT=$(curl -s -X POST "$BASE_URL/mcp" -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"initialize","id":1}')
echo "$INIT" | python3 -c "import sys,json; d=json.load(sys.stdin); print('PASS' if 'result' in d else 'FAIL')" 2>/dev/null || echo "FAIL"

# 4. MCP Tools
echo -n "MCP tools/list... "
TOOLS=$(curl -s -X POST "$BASE_URL/mcp" -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"tools/list","id":2}')
TOOL_COUNT=$(echo "$TOOLS" | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d.get('result',{}).get('tools',[])))" 2>/dev/null || echo "0")
[ "$TOOL_COUNT" -gt "0" ] && echo "PASS ($TOOL_COUNT tools)" || echo "FAIL (0 tools)"

# 5. Image URL
echo -n "Image URL... "
IMAGE_URL=$(echo "$REG" | python3 -c "import sys,json; print(json.load(sys.stdin).get('image',''))" 2>/dev/null)
if [ -n "$IMAGE_URL" ]; then
  IMG_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$IMAGE_URL")
  [ "$IMG_CODE" = "200" ] && echo "PASS" || echo "FAIL ($IMG_CODE)"
else
  echo "FAIL (no image URL)"
fi

# 6. HTTPS check
echo -n "All HTTPS... "
HTTP_COUNT=$(echo "$REG" | python3 -c "
import sys,json
d=json.load(sys.stdin)
urls = [s.get('endpoint','') for s in d.get('services',[])]
urls.append(d.get('image',''))
print(sum(1 for u in urls if u.startswith('http://')))" 2>/dev/null || echo "0")
[ "$HTTP_COUNT" = "0" ] && echo "PASS" || echo "FAIL ($HTTP_COUNT HTTP URLs found)"

echo ""
echo "=== Audit Complete ==="
```

Usage:

```bash
chmod +x self-audit.sh
./self-audit.sh https://your-agent.example.com
```

---

*A high scanner score reflects a well-built, well-maintained agent. Focus on the fundamentals: reliable endpoints, clear metadata, compliant protocols, and earned reputation. The score will follow.*
