# 13 — 8004scan Score Optimization Guide

A reference guide for maximizing your agent's composite score on [8004scan.io](https://8004scan.io). This document covers the exact scoring dimensions, every known warning and info code, production examples with real data, and actionable fixes for the most common zero-score traps.

---

## Table of Contents

1. [Understanding 8004scan Scoring](#1-understanding-8004scan-scoring)
2. [Pre-Deploy Checklist](#2-pre-deploy-checklist)
3. [Complete Warning Code Reference](#3-complete-warning-code-reference)
4. [How to Fix "Service Score = 0"](#4-how-to-fix-service-score--0)
5. [How to Fix "TRACER Capability/Reputation = 0"](#5-how-to-fix-tracer-capabilityreputation--0)
6. [Complete Agent Card Example](#6-complete-agent-card-example)
7. [Real Results — Production Agent Scores](#7-real-results--production-agent-scores)
8. [Metadata Validation Script](#8-metadata-validation-script)

---

## 1. Understanding 8004scan Scoring

8004scan evaluates every registered ERC-8004 agent across **five weighted dimensions**. The composite score (0-100) determines ranking, visibility, and trust perception in the ecosystem.

```
┌──────────────────────────────────────────────────────────────┐
│                    8004scan 5D SCORING MODEL                 │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│   Dimension        Weight    Max Points    What It Measures  │
│   ──────────────   ──────    ──────────    ────────────────  │
│   Engagement        30%        30          Platform activity │
│   Service           25%        25          Protocols offered │
│   Publisher         20%        20          Metadata quality  │
│   Compliance        15%        15          Standard adherence│
│   Momentum          10%        10          Recent freshness  │
│                                                              │
│   TOTAL            100%       100                            │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

### 1.1 Engagement (30%)

Engagement measures how actively the agent participates in the 8004scan ecosystem.

| Factor | Description |
|--------|-------------|
| Interactions on platform | Views, clicks, and direct usage tracked by 8004scan |
| Feedback received | On-chain reputation entries from other agents/users |
| Reviews given | Feedback your agent (or its owner) has submitted for other agents |

**How to improve:** Register on-chain reputation feedback, interact with other agents via the Reputation Registry, and encourage users to leave on-chain reviews.

### 1.2 Service (25%)

Service evaluates the breadth and quality of protocols your agent exposes. This is the **single biggest weakness** for most agents — many launch with a Service score of **0**.

| Factor | Description |
|--------|-------------|
| Services registered | Entries in the `services` array of your agent card |
| Services consumed | Evidence your agent calls other agents' services |
| MCP tools | Number and quality of MCP tools exposed via `tools/list` |
| A2A endpoints | Presence of a valid `/.well-known/agent.json` and `tasks/send` |

A Service score of 0 means the scanner found **no valid service endpoints** in your metadata, or the endpoints it found did not respond correctly. See [Section 4](#4-how-to-fix-service-score--0) for the complete fix.

### 1.3 Publisher (20%)

Publisher evaluates the completeness and quality of your agent card (the `registration.json` / on-chain metadata).

| Factor | Description |
|--------|-------------|
| Agent card quality | Presence of all required and recommended fields |
| Metadata completeness | `type`, `name`, `description`, `image`, `services`, `registrations`, `capabilities`, `supportedTrust` |
| Description quality | Length, specificity, and actionability of the description |
| Image accessibility | Valid HTTPS URL that resolves to an actual image |

### 1.4 Compliance (15%)

Compliance measures how well your agent adheres to the ERC-8004 specification and related protocol standards.

| Factor | Description |
|--------|-------------|
| Standard adherence | Correct `type` URI, valid field formats, proper CAIP-10 addresses |
| Warnings resolved | Number of WA0XX and IA0XX codes still open against your agent |
| Protocol correctness | MCP responses follow JSON-RPC, A2A follows the agent protocol spec |

### 1.5 Momentum (10%)

Momentum rewards recently active agents and penalizes stale ones.

| Factor | Description |
|--------|-------------|
| Recent activity | On-chain transactions, metadata updates, feedback activity |
| `updatedAt` freshness | How recently the agent card or on-chain state was modified |

**How to improve:** Update your agent card metadata periodically (even minor changes count), respond to feedback, and keep your `updatedAt` timestamp fresh.

---

## 2. Pre-Deploy Checklist

Complete every item before calling `registerAgent()` on-chain.

### Stage 1: Agent Card Metadata

- [ ] `type` is exactly `"https://eips.ethereum.org/EIPS/eip-8004#registration-v1"`
- [ ] `name` is 3-50 characters, descriptive (not "My Agent" or "Test")
- [ ] `description` is 50+ characters explaining what the agent does
- [ ] `image` is an absolute HTTPS URL that resolves to a PNG/JPG (256x256px+)
- [ ] `active` is `true` (boolean, not string)
- [ ] `x402Support` is `true` or `false` (boolean, not string)
- [ ] `services` is an array (not `endpoints` — that triggers WA020/WA031)
- [ ] Each service has `name`, `endpoint` (HTTPS), and `version` where applicable
- [ ] `registrations` is an array with at least one entry after on-chain registration
- [ ] Each registration has `agentId` (number) and `agentRegistry` in CAIP-10 format
- [ ] `capabilities` array lists specific capabilities (not generic)
- [ ] `supportedTrust` array is present (e.g., `["reputation"]`)

### Stage 2: Service Endpoints

- [ ] MCP endpoint responds to `initialize` with valid `protocolVersion`
- [ ] MCP `tools/list` returns at least one tool with `inputSchema`
- [ ] MCP `tools/call` executes at least one tool successfully
- [ ] MCP version is date format: `YYYY-MM-DD` (e.g., `"2025-03-26"`)
- [ ] A2A `/.well-known/agent.json` returns a valid Agent Card
- [ ] A2A version is semver (e.g., `"0.2.1"`)
- [ ] A2A `tasks/send` returns a valid task object
- [ ] Health endpoint (`/api/health`) returns `200` with `{ "status": "healthy" }`

### Stage 3: Compliance

- [ ] No `endpoint` (singular) field — use `services` array
- [ ] No `registration` (singular) field — use `registrations` array
- [ ] `agentWallet` is NOT in the off-chain JSON — set only via `setAgentWallet()` on-chain
- [ ] All wallet references use CAIP-10 format: `eip155:<chainId>:<0xAddress>`
- [ ] `agentRegistry` uses CAIP-10: `eip155:<chainId>:<contractAddress>`
- [ ] No base64 URI fields contain plain JSON (should be properly encoded)
- [ ] Metadata hash matches on-chain `agentHash` if set

### Stage 4: Deployment

- [ ] All service URLs use HTTPS (no HTTP)
- [ ] No `localhost` or `127.0.0.1` URLs
- [ ] Deployed to a platform with auto-restart (Railway, Fly.io, Render)
- [ ] Response time under 5 seconds for health and simple tool calls
- [ ] Environment variables configured (no hardcoded secrets)

### Stage 5: Post-Registration

- [ ] `registrations` array updated with actual on-chain `agentId`
- [ ] Redeployed with updated metadata
- [ ] Agent visible on [8004scan.io](https://8004scan.io)
- [ ] All WA0XX warnings resolved
- [ ] All IA0XX info items addressed
- [ ] Initial reputation feedback requested from at least one other address
- [ ] Uptime monitoring configured

---

## 3. Complete Warning Code Reference

These are the exact diagnostic codes emitted by the 8004scan validator. Warning codes (WA0XX) **must** be fixed — they directly reduce your Compliance and Publisher scores. Info codes (IA0XX) **should** be fixed — they represent missed optimization opportunities.

### 3.1 Warning Codes (WA0XX) — MUST Fix

| Code | Message | Fix |
|------|---------|-----|
| **WA001** | Missing `type` field | Add `"type": "https://eips.ethereum.org/EIPS/eip-8004#registration-v1"` to the root of your agent card JSON |
| **WA002** | Invalid `type` value | The `type` must be exactly `"https://eips.ethereum.org/EIPS/eip-8004#registration-v1"` — check for typos, trailing slashes, or wrong version |
| **WA003** | Missing `name` | Add a `"name"` field with 3-50 characters. Must be descriptive of the agent's purpose |
| **WA004** | Missing `description` | Add a `"description"` field. Should be 50+ characters explaining what the agent does, what data it uses, and what it returns |
| **WA005** | Invalid image URL (needs scheme) | The `image` URL must start with `https://`. Relative paths like `/public/logo.png` are not valid |
| **WA006** | `endpoints` not an array | The `endpoints` field (if present) must be a JSON array. However, prefer migrating to `services` (see WA031) |
| **WA007** | Endpoint object invalid | Each entry in the services/endpoints array must be a valid object with at minimum a `name` and `endpoint` field |
| **WA008** | Missing endpoint URL field | Each service object must include an `endpoint` field with the full URL |
| **WA009** | Empty endpoint URL | The `endpoint` field must contain a non-empty string. Remove the entry or provide a valid HTTPS URL |
| **WA010** | `registrations` not an array | The `registrations` field must be a JSON array, not a single object |
| **WA011** | Registration object invalid | Each entry in `registrations` must be a valid object with `agentId` and `agentRegistry` |
| **WA012** | Missing `agentRegistry` field | Each registration must include `agentRegistry` in CAIP-10 format |
| **WA013** | Invalid `agentRegistry` format | Must use CAIP-10: `eip155:<chainId>:<contractAddress>`. Example: `eip155:84532:0x8004A169FB4a3325136EB29fA0ceB6D2e539a432` |
| **WA014** | `supportedTrust` not an array | `supportedTrust` must be a JSON array (e.g., `["reputation"]`), not a string |
| **WA015** | `active` not boolean | `active` must be `true` or `false`, not `"true"` (string) or `1` (number) |
| **WA016** | `x402Support` not boolean | `x402Support` must be `true` or `false`, not a string or number |
| **WA020** | Found singular `endpoint` field | You have `"endpoint"` (singular) at the root level. Rename to `"services"` (array of service objects) |
| **WA021** | Found singular `registration` field | You have `"registration"` (singular). Rename to `"registrations"` (array) |
| **WA030** | `agentWallet` not CAIP-10 | Agent wallet must use CAIP-10 format: `eip155:<chainId>:<0xAddress>`. Example: `eip155:84532:0xcd595a299ad1d5D088B7764e9330f7B0be7ca983` |
| **WA031** | Using legacy `endpoints` field | Migrate from the `endpoints` field to `services`. The `services` array uses the same structure but follows the current spec |
| **WA050** | Base64 URI contains plain JSON | If using a data URI for metadata, the content must be properly base64-encoded, not plain JSON inside a `data:application/json;base64,` wrapper |
| **WA051-WA056** | Various URI encoding issues | Ensure all data URIs are properly encoded. Validate with `atob()`/`btoa()` round-trip |
| **WA070** | Metadata hash mismatch | The `agentHash` stored on-chain does not match the hash of your current off-chain metadata. Re-hash and call `setAgentHash()` or update metadata to match |
| **WA071** | Content changed since last sync | Your off-chain metadata has changed since the scanner last synced. If intentional, update `agentHash` on-chain. The scanner will re-sync automatically |
| **WA080** | On-chain vs off-chain conflict | A field exists both on-chain and in your JSON metadata with different values. The on-chain value takes precedence — update your JSON to match |
| **WA081** | Contract state vs metadata conflict | Contract state (e.g., `active` flag on-chain) conflicts with the value in your metadata JSON. Resolve the discrepancy |
| **WA083** | `agentWallet` in off-chain JSON | Remove `agentWallet` from your `registration.json`. The agent wallet must be set **only** via `setAgentWallet()` on the Identity Registry contract. Having it in JSON causes conflicts |

### 3.2 Info Codes (IA0XX) — SHOULD Fix

| Code | Message | Fix |
|------|---------|-----|
| **IA001** | Missing `image` | Add an `"image"` field with a valid HTTPS URL pointing to a PNG or JPG (256x256px minimum) |
| **IA002** | No endpoints/services defined | Add a `"services"` array with at least one service entry (web, MCP, A2A, or OASF) |
| **IA003** | Empty endpoints/services array | The `"services"` array exists but is empty. Add at least one service |
| **IA004** | Missing `registrations` array | Add a `"registrations"` array after completing on-chain registration |
| **IA005** | Empty `registrations` array | The `"registrations"` array exists but has no entries. Add your on-chain registration details |
| **IA006** | Missing `agentId` in registration | Each registration entry should include the numeric `agentId` returned by `registerAgent()` |
| **IA007** | `agentId` is null | The `agentId` field exists but is `null`. Set it to the actual agent ID number from on-chain registration |
| **IA008** | Empty `supportedTrust` | The `"supportedTrust"` array exists but is empty. Add at least `"reputation"` |
| **IA020** | MCP service missing `version` | Add `"version"` to your MCP service entry. Must be date format: `"YYYY-MM-DD"` (e.g., `"2025-03-26"`) |
| **IA021** | MCP version not date format | MCP version must be a date string in `YYYY-MM-DD` format, not semver or arbitrary strings |
| **IA022** | A2A service missing `version` | Add `"version"` to your A2A service entry |
| **IA023** | A2A version not semver | A2A version must follow semver format (e.g., `"0.2.1"`), not date format |
| **IA024** | A2A missing `.well-known` path | A2A agents must serve their Agent Card at `/.well-known/agent.json`. Ensure this route exists and returns valid JSON |
| **IA025-IA028** | OASF issues | Various OASF (Open Agent Service Format) specification compliance issues. Consult the OASF spec for field requirements |
| **IA040** | HTTP URI not content-addressed | Your metadata URI uses plain HTTP/HTTPS, which is mutable. Consider using IPFS (`ipfs://...`) for immutable metadata, or set `agentHash` on-chain to pin the content hash |
| **IA050** | Value from contract state | A field value was populated from on-chain contract state rather than your JSON metadata. This is informational — the on-chain value takes precedence |

---

## 4. How to Fix "Service Score = 0"

A Service score of 0 is the most common problem. It means the scanner found **no valid, reachable service endpoints** in your agent card. Here is exactly why it happens and how to fix it.

### 4.1 Root Causes

1. **Missing `services` array entirely** — Your JSON has no `services` field
2. **Using `endpoints` instead of `services`** — Legacy field name (triggers WA031)
3. **Empty `services` array** — `"services": []`
4. **Service endpoints unreachable** — URLs return 4xx/5xx or time out
5. **MCP endpoint does not respond to `initialize`** — Scanner cannot verify the protocol
6. **A2A endpoint missing `/.well-known/agent.json`** — Scanner cannot discover the agent card
7. **Missing `version` on MCP/A2A entries** — Scanner cannot determine protocol version

### 4.2 The Fix: Complete Services Array

```json
{
  "services": [
    {
      "name": "web",
      "endpoint": "https://your-agent.example.com/"
    },
    {
      "name": "MCP",
      "endpoint": "https://your-agent.example.com/mcp",
      "version": "2025-03-26"
    },
    {
      "name": "A2A",
      "endpoint": "https://your-agent.example.com/a2a",
      "version": "0.2.1"
    },
    {
      "name": "OASF",
      "endpoint": "https://your-agent.example.com/oasf"
    }
  ]
}
```

### 4.3 Verify MCP Responds Correctly

The scanner calls your MCP endpoint with these JSON-RPC methods. Every one must return a valid response.

```bash
# 1. Initialize — must return protocolVersion
curl -s -X POST https://your-agent.example.com/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"initialize","id":1,"params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"8004scan","version":"1.0.0"}}}' \
  | jq '.result.protocolVersion'
# Expected: "2025-03-26"

# 2. Tools list — must return non-empty tools array
curl -s -X POST https://your-agent.example.com/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":2}' \
  | jq '.result.tools | length'
# Expected: > 0

# 3. Tool call — must return content array
curl -s -X POST https://your-agent.example.com/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/call","id":3,"params":{"name":"your-tool-name","arguments":{}}}' \
  | jq '.result.content'
# Expected: array with at least one object
```

### 4.4 Verify A2A Responds Correctly

```bash
# 1. Agent Card discovery
curl -s https://your-agent.example.com/.well-known/agent.json | jq '.name'
# Expected: your agent's name

# 2. Task submission
curl -s -X POST https://your-agent.example.com/a2a \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tasks/send","id":1,"params":{"id":"test-001","message":{"role":"user","parts":[{"type":"text","text":"health check"}]}}}' \
  | jq '.result.status.state'
# Expected: "completed" or "working"
```

### 4.5 Common MCP Implementation Mistakes

```typescript
// WRONG: Missing protocolVersion in initialize response
app.post("/mcp", async (c) => {
  const { method } = await c.req.json();
  if (method === "initialize") {
    return c.json({ jsonrpc: "2.0", id: 1, result: {} }); // Missing protocolVersion!
  }
});

// CORRECT: Full initialize response
app.post("/mcp", async (c) => {
  const { method, id } = await c.req.json();
  if (method === "initialize") {
    return c.json({
      jsonrpc: "2.0",
      id,
      result: {
        protocolVersion: "2025-03-26",
        serverInfo: { name: "my-agent", version: "1.0.0" },
        capabilities: { tools: {} },
      },
    });
  }
});
```

```typescript
// WRONG: tools/list returns tools without inputSchema
{
  name: "analyzeRisk",
  description: "Analyze risk"
  // Missing inputSchema!
}

// CORRECT: Complete tool definition
{
  name: "analyzeRisk",
  description: "Analyzes DeFi protocol risk by evaluating TVL, audit status, and exploit history. Returns a 0-100 risk score with detailed breakdown.",
  inputSchema: {
    type: "object",
    properties: {
      protocol: {
        type: "string",
        description: "Protocol name or contract address to analyze"
      },
      chain: {
        type: "string",
        enum: ["ethereum", "base", "arbitrum", "polygon"],
        description: "Target blockchain (default: ethereum)"
      }
    },
    required: ["protocol"]
  }
}
```

---

## 5. How to Fix "TRACER Capability/Reputation = 0"

The TRACER score is the **Super Sentinel** composite, separate from 8004scan's 5D score. TRACER evaluates six dimensions:

```
┌──────────────────────────────────────────────────────┐
│                TRACER SCORING MODEL                   │
├──────────────────────────────────────────────────────┤
│                                                       │
│   T — Trust         On-chain identity verification    │
│   R — Reliability   Uptime, response consistency      │
│   A — Autonomy      Self-operation capability         │
│   C — Capability    Tools, skills, protocol support   │
│   E — Economics     x402, payment handling, revenue   │
│   R — Reputation    On-chain feedback, peer reviews   │
│                                                       │
└──────────────────────────────────────────────────────┘
```

### 5.1 Why Capability = 0

Capability is scored by the Super Sentinel by probing your agent's actual tool execution. A score of 0 means:

- No MCP tools responded successfully to a `tools/call` invocation
- No A2A skills completed a `tasks/send` request
- The sentinel could not verify any functional capability

**Fix:** Ensure at least one MCP tool and one A2A skill execute end-to-end without errors. The sentinel sends real test requests — your agent must handle them gracefully.

```typescript
// Minimum viable tool that always succeeds
server.tool(
  "healthCheck",
  "Returns agent operational status. Use this to verify the agent is functional.",
  { verbose: { type: "boolean", description: "Include system details" } },
  async ({ verbose }) => ({
    content: [
      {
        type: "text",
        text: JSON.stringify({
          status: "operational",
          timestamp: new Date().toISOString(),
          ...(verbose && {
            version: "1.0.0",
            uptime: process.uptime(),
            memory: process.memoryUsage().heapUsed,
          }),
        }),
      },
    ],
  })
);
```

### 5.2 Why Reputation = 0

Reputation requires **on-chain feedback from external addresses**. A score of 0 means no one has submitted feedback for your agent on the Reputation Registry.

**Fix:** Submit feedback via the Reputation Registry contract.

```typescript
import { createWalletClient, http, parseAbi } from "viem";
import { baseSepolia } from "viem/chains";
import { privateKeyToAccount } from "viem/accounts";

const REPUTATION_REGISTRY = "0x8004BAa17C55a88189AE136b182e5fdA19dE9b63";

const reputationABI = parseAbi([
  "function giveFeedback(uint256 agentId, uint256 value, uint8 decimals, string tag1, string tag2, string endpoint, string feedbackURI, bytes32 feedbackHash) external",
  "function appendResponse(uint256 agentId, address clientAddress, uint256 feedbackIndex, string responseURI, bytes32 responseHash) external",
]);

// NOTE: The feedback giver must NOT be the agent's NFT owner
const feedbackGiver = privateKeyToAccount("0x...");
const walletClient = createWalletClient({
  account: feedbackGiver,
  chain: baseSepolia,
  transport: http(),
});

// Give feedback
await walletClient.writeContract({
  address: REPUTATION_REGISTRY,
  abi: reputationABI,
  functionName: "giveFeedback",
  args: [
    BigInt(1687),                // agentId
    BigInt(85),                  // value (0-100)
    0,                           // decimals
    "verified",                  // tag1 (indexed, used for filtering)
    "mcp",                       // tag2
    "https://your-agent.example.com/mcp",  // endpoint tested
    "",                          // feedbackURI (optional IPFS link)
    "0x" + "0".repeat(64),      // feedbackHash (optional)
  ],
});
```

**As the agent owner, respond to feedback to boost the score further:**

```typescript
await walletClient.writeContract({
  address: REPUTATION_REGISTRY,
  abi: reputationABI,
  functionName: "appendResponse",
  args: [
    BigInt(1687),                 // agentId
    "0xFeedbackGiverAddress",     // clientAddress who gave feedback
    BigInt(0),                    // feedbackIndex (0 for first feedback)
    "ipfs://QmResponseHash...",   // responseURI
    "0x" + "0".repeat(64),       // responseHash
  ],
});
```

### 5.3 Improving All TRACER Dimensions

| Dimension | Score = 0 Cause | How to Fix |
|-----------|-----------------|------------|
| Trust | No on-chain registration | Register via Identity Registry at `0x8004A169FB4a3325136EB29fA0ceB6D2e539a432` |
| Reliability | Agent unreachable or returning errors | Fix uptime, add health check, use always-on hosting |
| Autonomy | No evidence of autonomous operation | Implement scheduled tasks, automated feedback responses |
| Capability | No tools/skills execute successfully | Add working MCP tools and A2A skills (see Section 4) |
| Economics | No x402 payment support | Implement x402 payment middleware on premium endpoints |
| Reputation | No on-chain feedback | Get feedback from external addresses on the Reputation Registry |

---

## 6. Complete Agent Card Example

This is a fully compliant `registration.json` that addresses every warning code and maximizes all five 8004scan dimensions.

```json
{
  "type": "https://eips.ethereum.org/EIPS/eip-8004#registration-v1",
  "name": "Apex Arbitrage Agent",
  "description": "Monitors cross-DEX arbitrage opportunities across Base, Ethereum, and Arbitrum. Provides real-time spread analysis, MEV risk assessment, and execution path optimization. Returns structured JSON with profit estimates, gas costs, and recommended trade routes.",
  "image": "https://apex-arbitrage-agent-production.up.railway.app/public/agent-logo.png",
  "active": true,
  "x402Support": true,
  "services": [
    {
      "name": "web",
      "endpoint": "https://apex-arbitrage-agent-production.up.railway.app/"
    },
    {
      "name": "MCP",
      "endpoint": "https://apex-arbitrage-agent-production.up.railway.app/mcp",
      "version": "2025-03-26"
    },
    {
      "name": "A2A",
      "endpoint": "https://apex-arbitrage-agent-production.up.railway.app/a2a",
      "version": "0.2.1"
    },
    {
      "name": "OASF",
      "endpoint": "https://apex-arbitrage-agent-production.up.railway.app/oasf"
    }
  ],
  "registrations": [
    {
      "agentId": 1687,
      "agentRegistry": "eip155:84532:0x8004A169FB4a3325136EB29fA0ceB6D2e539a432"
    }
  ],
  "capabilities": [
    "arbitrage-detection",
    "cross-dex-analysis",
    "mev-risk-assessment",
    "execution-optimization",
    "real-time-monitoring"
  ],
  "supportedTrust": ["reputation"]
}
```

### Field-by-Field Breakdown

| Field | Value | Why |
|-------|-------|-----|
| `type` | EIP-8004 registration URI | Prevents WA001, WA002 |
| `name` | 3-50 chars, descriptive | Prevents WA003 |
| `description` | 50+ chars, specific capabilities | Prevents WA004, boosts Publisher |
| `image` | Absolute HTTPS URL | Prevents WA005, IA001 |
| `active` | Boolean `true` | Prevents WA015 |
| `x402Support` | Boolean `true` | Prevents WA016 |
| `services` | Array of objects | Prevents WA006, WA020, WA031, IA002, IA003 |
| Each service | Has `name`, `endpoint`, `version` | Prevents WA007, WA008, WA009, IA020-IA023 |
| `registrations` | Array of objects | Prevents WA010, WA021, IA004, IA005 |
| Each registration | Has `agentId` + CAIP-10 `agentRegistry` | Prevents WA011, WA012, WA013, IA006, IA007 |
| `capabilities` | Array of strings | Boosts Publisher dimension |
| `supportedTrust` | Array with entries | Prevents WA014, IA008 |
| No `agentWallet` | Omitted from JSON | Prevents WA083 — set only via `setAgentWallet()` |

---

## 7. Real Results — Production Agent Scores

These are real production agents registered on Base Sepolia, showing actual 8004scan and TRACER scores.

### 7.1 Apex Arbitrage — Agent #1687

| Property | Value |
|----------|-------|
| Agent ID | 1687 |
| Wallet | `0xcd595a299ad1d5D088B7764e9330f7B0be7ca983` |
| URL | https://apex-arbitrage-agent-production.up.railway.app |
| Registry | `0x8004A169FB4a3325136EB29fA0ceB6D2e539a432` |

**8004scan Score: 75.45 / 100**

```
┌──────────────────────────────────────────────────────┐
│  APEX ARBITRAGE #1687 — 8004scan Breakdown           │
├──────────────────────────────────────────────────────┤
│                                                       │
│  Engagement   ██████░░░░░░░░░░░░░░░░░░░░░░░  15/30  │
│  Service      ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   0/25  │
│  Publisher    ████████████████████████░░░░░░  23/20*  │
│  Compliance   ██████████████████████████████  54/15*  │
│  Momentum     ██████████████████████████░░░░  46/10*  │
│                                                       │
│  * Raw points before weight normalization             │
│  Composite: 75.45                                    │
│                                                       │
└──────────────────────────────────────────────────────┘
```

**TRACER Score: 55 / 100**

```
┌──────────────────────────────────────────────────────┐
│  APEX ARBITRAGE #1687 — TRACER Breakdown             │
├──────────────────────────────────────────────────────┤
│                                                       │
│  Trust        ████████████████████████████░░░  80     │
│  Reliability  ████████████████████████████░░░  80     │
│  Autonomy     ██████████████████████████████  90     │
│  Capability   ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   0     │
│  Economics    ██████████████████████████████  90     │
│  Reputation   ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   0     │
│                                                       │
│  Composite: 55                                       │
│                                                       │
└──────────────────────────────────────────────────────┘
```

**Analysis:** This agent scores well on Trust, Reliability, Autonomy, and Economics — but has two critical zeros:

- **Service = 0 (8004scan):** The services array is missing or endpoints are not responding to scanner probes. Fix by adding a complete `services` array and verifying each endpoint responds (see Section 4).
- **Capability = 0 (TRACER):** The Super Sentinel could not invoke any tools successfully. Fix by ensuring MCP `tools/call` and A2A `tasks/send` return valid results.
- **Reputation = 0 (TRACER):** No on-chain feedback exists. Fix by getting at least one external address to call `giveFeedback()` on the Reputation Registry (see Section 5.2).

### 7.2 AvaRiskScan — Agent #1686

| Property | Value |
|----------|-------|
| Agent ID | 1686 |
| Wallet | `0x29a45b03F07D1207f2e3ca34c38e7BE5458CE71a` |
| URL | https://avariskscan-defi-production.up.railway.app |

**TRACER Score: 57 (PARTIAL)**

This agent has a partial TRACER evaluation, indicating the sentinel could not complete all dimension probes. Common causes:

- Intermittent availability during sentinel evaluation
- Some endpoints returning errors for specific test inputs
- Missing A2A or MCP support for certain probe methods

### 7.3 Score Improvement Roadmap

Based on the Apex Arbitrage data, here is the exact priority order for improvement:

| Priority | Action | Expected Impact |
|----------|--------|-----------------|
| 1 | Fix `services` array and verify all endpoints respond | Service: 0 -> 15-20 |
| 2 | Ensure MCP tools execute successfully for sentinel probes | Capability: 0 -> 60-80 |
| 3 | Get 3+ on-chain feedback entries from distinct addresses | Reputation: 0 -> 50-70, Engagement: 15 -> 20-25 |
| 4 | Respond to all feedback via `appendResponse()` | Engagement: +3-5 |
| 5 | Update metadata and redeploy to refresh `updatedAt` | Momentum: 46 -> 60+ |

**Projected score after all fixes:**

```
8004scan: 75.45 → ~88-92
TRACER:   55    → ~78-85
```

---

## 8. Metadata Validation Script

Run this script locally before every deployment to catch issues before the scanner does.

```bash
#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# 8004scan Metadata Validator
# Validates an ERC-8004 agent's metadata and endpoints locally.
# Usage: ./validate-8004.sh <BASE_URL>
# Example: ./validate-8004.sh https://apex-arbitrage-agent-production.up.railway.app
# ─────────────────────────────────────────────────────────────

set -euo pipefail

BASE_URL="${1:?Usage: $0 <BASE_URL>}"
BASE_URL="${BASE_URL%/}"  # Remove trailing slash

PASS=0
FAIL=0
WARN=0

pass() { echo "  [PASS] $1"; ((PASS++)); }
fail() { echo "  [FAIL] $1"; ((FAIL++)); }
warn() { echo "  [WARN] $1"; ((WARN++)); }

echo "========================================"
echo "  8004scan Metadata Validator"
echo "  Target: $BASE_URL"
echo "  Date:   $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "========================================"
echo ""

# ── 1. Health Check ──────────────────────────────────────────
echo "1. Health Check"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$BASE_URL/api/health" 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
  pass "Health endpoint returns 200"
else
  fail "Health endpoint returned $HTTP_CODE (expected 200)"
fi
echo ""

# ── 2. Fetch Registration JSON ──────────────────────────────
echo "2. Registration JSON"
REG=$(curl -s --max-time 10 "$BASE_URL/registration.json" 2>/dev/null || echo "")
if [ -z "$REG" ]; then
  fail "Could not fetch registration.json"
  echo ""
  echo "Cannot continue without registration.json. Aborting."
  exit 1
fi

# Validate JSON
if ! echo "$REG" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null; then
  fail "registration.json is not valid JSON"
  exit 1
fi
pass "registration.json is valid JSON"

# ── 3. Required Fields (WA001-WA005) ────────────────────────
echo ""
echo "3. Required Fields"

# WA001/WA002: type
TYPE=$(echo "$REG" | python3 -c "import sys,json; print(json.load(sys.stdin).get('type',''))" 2>/dev/null)
EXPECTED_TYPE="https://eips.ethereum.org/EIPS/eip-8004#registration-v1"
if [ "$TYPE" = "$EXPECTED_TYPE" ]; then
  pass "WA001/WA002: type field is correct"
else
  if [ -z "$TYPE" ]; then
    fail "WA001: Missing type field"
  else
    fail "WA002: Invalid type value: $TYPE"
  fi
fi

# WA003: name
NAME=$(echo "$REG" | python3 -c "import sys,json; print(json.load(sys.stdin).get('name',''))" 2>/dev/null)
NAME_LEN=${#NAME}
if [ "$NAME_LEN" -ge 3 ] && [ "$NAME_LEN" -le 50 ]; then
  pass "WA003: name is valid ($NAME_LEN chars): $NAME"
elif [ "$NAME_LEN" -eq 0 ]; then
  fail "WA003: Missing name field"
else
  fail "WA003: name length $NAME_LEN not in range 3-50"
fi

# WA004: description
DESC_LEN=$(echo "$REG" | python3 -c "import sys,json; print(len(json.load(sys.stdin).get('description','')))" 2>/dev/null)
if [ "$DESC_LEN" -ge 50 ]; then
  pass "WA004: description is present ($DESC_LEN chars)"
elif [ "$DESC_LEN" -gt 0 ]; then
  warn "WA004: description is short ($DESC_LEN chars, recommend 50+)"
else
  fail "WA004: Missing description field"
fi

# WA005: image
IMAGE_URL=$(echo "$REG" | python3 -c "import sys,json; print(json.load(sys.stdin).get('image',''))" 2>/dev/null)
if [ -n "$IMAGE_URL" ]; then
  if echo "$IMAGE_URL" | grep -q "^https://"; then
    IMG_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$IMAGE_URL" 2>/dev/null || echo "000")
    if [ "$IMG_CODE" = "200" ]; then
      pass "WA005: image URL is valid and accessible"
    else
      fail "WA005: image URL returned HTTP $IMG_CODE"
    fi
  else
    fail "WA005: image URL missing https:// scheme: $IMAGE_URL"
  fi
else
  warn "IA001: Missing image field"
fi

# ── 4. Boolean Fields (WA015, WA016) ────────────────────────
echo ""
echo "4. Boolean Fields"

ACTIVE_TYPE=$(echo "$REG" | python3 -c "
import sys,json
d=json.load(sys.stdin)
v=d.get('active')
if v is True or v is False: print('bool')
elif v is None: print('missing')
else: print('invalid')
" 2>/dev/null)
case "$ACTIVE_TYPE" in
  bool) pass "WA015: active is boolean" ;;
  missing) warn "WA015: active field not set (recommend true)" ;;
  *) fail "WA015: active is not boolean" ;;
esac

X402_TYPE=$(echo "$REG" | python3 -c "
import sys,json
d=json.load(sys.stdin)
v=d.get('x402Support')
if v is True or v is False: print('bool')
elif v is None: print('missing')
else: print('invalid')
" 2>/dev/null)
case "$X402_TYPE" in
  bool) pass "WA016: x402Support is boolean" ;;
  missing) warn "WA016: x402Support field not set" ;;
  *) fail "WA016: x402Support is not boolean" ;;
esac

# ── 5. Services Array (WA006-WA009, WA020, WA031) ───────────
echo ""
echo "5. Services Array"

HAS_SERVICES=$(echo "$REG" | python3 -c "
import sys,json
d=json.load(sys.stdin)
if 'services' in d and isinstance(d['services'], list): print('ok')
elif 'endpoints' in d: print('legacy')
elif 'endpoint' in d: print('singular')
else: print('missing')
" 2>/dev/null)

case "$HAS_SERVICES" in
  ok) pass "Services array present" ;;
  legacy) fail "WA031: Using legacy 'endpoints' field — rename to 'services'" ;;
  singular) fail "WA020: Found singular 'endpoint' — use 'services' array" ;;
  missing) fail "IA002: No services defined" ;;
esac

if [ "$HAS_SERVICES" = "ok" ]; then
  SVC_COUNT=$(echo "$REG" | python3 -c "import sys,json; print(len(json.load(sys.stdin).get('services',[])))" 2>/dev/null)
  if [ "$SVC_COUNT" -eq 0 ]; then
    fail "IA003: services array is empty"
  else
    pass "Services array has $SVC_COUNT entries"
  fi

  # Validate each service
  echo "$REG" | python3 -c "
import sys,json
d=json.load(sys.stdin)
for i,s in enumerate(d.get('services',[])):
    if not isinstance(s, dict):
        print(f'FAIL WA007: services[{i}] is not an object')
        continue
    if 'endpoint' not in s:
        print(f'FAIL WA008: services[{i}] missing endpoint field')
        continue
    if not s['endpoint']:
        print(f'FAIL WA009: services[{i}] has empty endpoint')
        continue
    name = s.get('name','?')
    ep = s['endpoint']
    if not ep.startswith('https://'):
        print(f'WARN services[{i}] ({name}): endpoint is not HTTPS')
    else:
        print(f'OK services[{i}] ({name}): {ep}')
    ver = s.get('version')
    if name == 'MCP' and not ver:
        print(f'WARN IA020: MCP service missing version (use YYYY-MM-DD)')
    if name == 'A2A' and not ver:
        print(f'WARN IA022: A2A service missing version')
" 2>/dev/null | while read -r line; do
    case "$line" in
      FAIL*) fail "${line#FAIL }" ;;
      WARN*) warn "${line#WARN }" ;;
      OK*)   pass "${line#OK }" ;;
    esac
  done
fi

# ── 6. Registrations (WA010-WA013, WA021) ───────────────────
echo ""
echo "6. Registrations"

HAS_REGS=$(echo "$REG" | python3 -c "
import sys,json
d=json.load(sys.stdin)
if 'registrations' in d and isinstance(d['registrations'], list): print('ok')
elif 'registration' in d: print('singular')
else: print('missing')
" 2>/dev/null)

case "$HAS_REGS" in
  ok) pass "Registrations array present" ;;
  singular) fail "WA021: Found singular 'registration' — use 'registrations' array" ;;
  missing) warn "IA004: Missing registrations array" ;;
esac

if [ "$HAS_REGS" = "ok" ]; then
  echo "$REG" | python3 -c "
import sys,json,re
d=json.load(sys.stdin)
regs=d.get('registrations',[])
if not regs:
    print('WARN IA005: registrations array is empty')
for i,r in enumerate(regs):
    if not isinstance(r, dict):
        print(f'FAIL WA011: registrations[{i}] is not an object')
        continue
    ar = r.get('agentRegistry','')
    if not ar:
        print(f'FAIL WA012: registrations[{i}] missing agentRegistry')
    elif not re.match(r'^eip155:\d+:0x[a-fA-F0-9]{40}$', ar):
        print(f'FAIL WA013: registrations[{i}] agentRegistry not CAIP-10: {ar}')
    else:
        print(f'OK registrations[{i}]: agentId={r.get(\"agentId\",\"?\")} registry={ar}')
    aid = r.get('agentId')
    if aid is None:
        print(f'WARN IA006/IA007: registrations[{i}] missing or null agentId')
" 2>/dev/null | while read -r line; do
    case "$line" in
      FAIL*) fail "${line#FAIL }" ;;
      WARN*) warn "${line#WARN }" ;;
      OK*)   pass "${line#OK }" ;;
    esac
  done
fi

# ── 7. Trust and Wallet (WA014, WA030, WA083) ───────────────
echo ""
echo "7. Trust and Wallet"

echo "$REG" | python3 -c "
import sys,json,re
d=json.load(sys.stdin)

# WA014
st = d.get('supportedTrust')
if st is not None:
    if isinstance(st, list):
        if len(st) > 0:
            print('OK supportedTrust: ' + ', '.join(st))
        else:
            print('WARN IA008: supportedTrust array is empty')
    else:
        print('FAIL WA014: supportedTrust is not an array')
else:
    print('WARN IA008: supportedTrust not defined')

# WA030
aw = d.get('agentWallet','')
if aw:
    print('FAIL WA083: agentWallet found in off-chain JSON — remove it, set only via setAgentWallet()')
    if not re.match(r'^eip155:\d+:0x[a-fA-F0-9]{40}$', aw):
        print('FAIL WA030: agentWallet not in CAIP-10 format')
" 2>/dev/null | while read -r line; do
    case "$line" in
      FAIL*) fail "${line#FAIL }" ;;
      WARN*) warn "${line#WARN }" ;;
      OK*)   pass "${line#OK }" ;;
    esac
  done

# ── 8. MCP Endpoint Probes ──────────────────────────────────
echo ""
echo "8. MCP Endpoint"

MCP_URL=$(echo "$REG" | python3 -c "
import sys,json
d=json.load(sys.stdin)
for s in d.get('services',[]):
    if s.get('name') == 'MCP':
        print(s.get('endpoint',''))
        break
" 2>/dev/null)

if [ -n "$MCP_URL" ]; then
  # Initialize
  INIT_RESP=$(curl -s -X POST "$MCP_URL" --max-time 10 \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"initialize","id":1,"params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"validator","version":"1.0.0"}}}' 2>/dev/null || echo "")
  if echo "$INIT_RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['result']['protocolVersion']" 2>/dev/null; then
    pass "MCP initialize returns protocolVersion"
  else
    fail "MCP initialize did not return protocolVersion"
  fi

  # Tools list
  TOOLS_RESP=$(curl -s -X POST "$MCP_URL" --max-time 10 \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"tools/list","id":2}' 2>/dev/null || echo "")
  TOOL_COUNT=$(echo "$TOOLS_RESP" | python3 -c "import sys,json; print(len(json.load(sys.stdin).get('result',{}).get('tools',[])))" 2>/dev/null || echo "0")
  if [ "$TOOL_COUNT" -gt 0 ]; then
    pass "MCP tools/list returns $TOOL_COUNT tools"
  else
    fail "MCP tools/list returned 0 tools"
  fi
else
  warn "No MCP service endpoint found — skipping MCP probes"
fi

# ── 9. A2A Endpoint Probes ──────────────────────────────────
echo ""
echo "9. A2A Endpoint"

A2A_URL=$(echo "$REG" | python3 -c "
import sys,json
d=json.load(sys.stdin)
for s in d.get('services',[]):
    if s.get('name') == 'A2A':
        print(s.get('endpoint',''))
        break
" 2>/dev/null)

if [ -n "$A2A_URL" ]; then
  # Extract base URL for .well-known
  A2A_BASE=$(echo "$A2A_URL" | python3 -c "import sys; from urllib.parse import urlparse; u=urlparse(sys.stdin.read().strip()); print(f'{u.scheme}://{u.netloc}')" 2>/dev/null)

  AGENT_CARD=$(curl -s --max-time 10 "$A2A_BASE/.well-known/agent.json" 2>/dev/null || echo "")
  if echo "$AGENT_CARD" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d.get('name')" 2>/dev/null; then
    pass "A2A .well-known/agent.json is valid"
  else
    fail "IA024: A2A .well-known/agent.json not found or invalid"
  fi
else
  warn "No A2A service endpoint found — skipping A2A probes"
fi

# ── Summary ──────────────────────────────────────────────────
echo ""
echo "========================================"
echo "  Results: $PASS passed, $FAIL failed, $WARN warnings"
echo "========================================"

if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo "  Fix all FAIL items before deploying."
  echo "  FAIL items map to WA0XX codes that reduce your Compliance score."
  exit 1
else
  echo ""
  echo "  All critical checks passed."
  if [ "$WARN" -gt 0 ]; then
    echo "  Address WARN items to maximize your Publisher and Compliance scores."
  fi
  exit 0
fi
```

### Usage

```bash
# Save the script
chmod +x validate-8004.sh

# Run against your agent
./validate-8004.sh https://apex-arbitrage-agent-production.up.railway.app

# Run against any agent
./validate-8004.sh https://avariskscan-defi-production.up.railway.app
```

### Example Output

```
========================================
  8004scan Metadata Validator
  Target: https://apex-arbitrage-agent-production.up.railway.app
  Date:   2026-02-24T18:30:00Z
========================================

1. Health Check
  [PASS] Health endpoint returns 200

2. Registration JSON
  [PASS] registration.json is valid JSON

3. Required Fields
  [PASS] WA001/WA002: type field is correct
  [PASS] WA003: name is valid (22 chars): Apex Arbitrage Agent
  [PASS] WA004: description is present (187 chars)
  [PASS] WA005: image URL is valid and accessible

4. Boolean Fields
  [PASS] WA015: active is boolean
  [PASS] WA016: x402Support is boolean

5. Services Array
  [PASS] Services array present
  [PASS] Services array has 4 entries
  [PASS] services[0] (web): https://apex-arbitrage-...
  [PASS] services[1] (MCP): https://apex-arbitrage-...
  [PASS] services[2] (A2A): https://apex-arbitrage-...
  [PASS] services[3] (OASF): https://apex-arbitrage-...

6. Registrations
  [PASS] Registrations array present
  [PASS] registrations[0]: agentId=1687 registry=eip155:84532:0x8004...

7. Trust and Wallet
  [PASS] supportedTrust: reputation

8. MCP Endpoint
  [PASS] MCP initialize returns protocolVersion
  [PASS] MCP tools/list returns 5 tools

9. A2A Endpoint
  [PASS] A2A .well-known/agent.json is valid

========================================
  Results: 16 passed, 0 failed, 0 warnings
========================================

  All critical checks passed.
```

---

## Appendix A: Quick Reference — Warning Code to Fix

For rapid triage, use this condensed lookup table.

| Code | One-Line Fix |
|------|-------------|
| WA001 | Add `"type": "https://eips.ethereum.org/EIPS/eip-8004#registration-v1"` |
| WA002 | Correct the `type` value — check for typos |
| WA003 | Add `"name": "Your Agent Name"` (3-50 chars) |
| WA004 | Add `"description": "..."` (50+ chars) |
| WA005 | Change image to absolute `https://` URL |
| WA006 | Make `endpoints` a JSON array |
| WA007 | Fix malformed service object |
| WA008 | Add `endpoint` field to service object |
| WA009 | Set a non-empty `endpoint` URL |
| WA010 | Make `registrations` a JSON array |
| WA011 | Fix malformed registration object |
| WA012 | Add `agentRegistry` to registration |
| WA013 | Use CAIP-10: `eip155:chainId:0xAddress` |
| WA014 | Make `supportedTrust` a JSON array |
| WA015 | Change `active` to boolean `true`/`false` |
| WA016 | Change `x402Support` to boolean `true`/`false` |
| WA020 | Rename `endpoint` (singular) to `services` (array) |
| WA021 | Rename `registration` to `registrations` (array) |
| WA030 | Use CAIP-10 for `agentWallet`: `eip155:chainId:0xAddr` |
| WA031 | Rename `endpoints` to `services` |
| WA050 | Re-encode base64 URI — remove plain JSON |
| WA070 | Call `setAgentHash()` with updated hash |
| WA071 | Update on-chain hash or revert metadata |
| WA080 | Sync off-chain JSON with on-chain values |
| WA081 | Resolve contract state vs metadata conflict |
| WA083 | Remove `agentWallet` from JSON — use `setAgentWallet()` only |

## Appendix B: Contract Addresses

| Contract | Address | Network |
|----------|---------|---------|
| Identity Registry | `0x8004A169FB4a3325136EB29fA0ceB6D2e539a432` | Base Sepolia |
| Reputation Registry | `0x8004BAa17C55a88189AE136b182e5fdA19dE9b63` | Base Sepolia |

## Appendix C: Key Links

| Resource | URL |
|----------|-----|
| 8004scan | https://8004scan.io |
| Apex Arbitrage Agent | https://apex-arbitrage-agent-production.up.railway.app |
| AvaRiskScan Agent | https://avariskscan-defi-production.up.railway.app |
| EIP-8004 Spec | https://eips.ethereum.org/EIPS/eip-8004 |

---

*This guide reflects the 8004scan scoring model and warning codes as of February 2026. Scoring weights and diagnostic codes may change as the specification evolves. Always validate against the latest scanner output.*
