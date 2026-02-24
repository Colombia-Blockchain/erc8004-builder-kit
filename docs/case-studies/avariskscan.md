# Case Study: AvaRiskScan Agent #1686

## Overview

| Field | Value |
|-------|-------|
| Agent ID | #1686 (Avalanche Mainnet), #15 (Avalanche Fuji Testnet) |
| Registry (Mainnet) | `eip155:43114:0x8004A169FB4a3325136EB29fA0ceB6D2e539a432` |
| Registry (Fuji) | `eip155:43113:0x8004A818C2B4fF20386a0e25Ca0d69e418e9cE77` |
| Stack | TypeScript / Hono |
| Deployment | Railway |
| Live URL | Production on Railway |
| Repo | `Colombia-Blockchain/avariskscan-agent` |
| Scanner | [erc-8004scan.xyz](https://erc-8004scan.xyz) |

## What It Does

AvaRiskScan is a comprehensive DeFi analytics and Avalanche ecosystem guide agent. It:

- Provides DeFi analytics across protocols using DeFiLlama, CoinGecko, DEX Screener, and the Glacier API
- Serves as an Avalanche ecosystem guide backed by 128K+ lines of curated documentation
- Exposes 27 MCP tools for programmatic access to DeFi data and ecosystem knowledge
- Implements x402 payment protocol for premium tool access
- Publishes an OASF (Open Agent Service Format) agent card at zero cost
- Powers the Enigma scanner at [erc-8004scan.xyz](https://erc-8004scan.xyz) for browsing registered agents

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│                  AVARISKSCAN AGENT                         │
├──────────────────────────────────────────────────────────┤
│                                                            │
│  Hono Server (src/index.ts)                                │
│  ├─ GET  /                       Dashboard                │
│  ├─ GET  /health                 Health check              │
│  ├─ GET  /registration.json      ERC-8004 metadata         │
│  ├─ GET  /.well-known/agent.json OASF agent card           │
│  ├─ POST /mcp                    MCP server (27 tools)     │
│  ├─ POST /a2a                    A2A endpoint               │
│  └─ POST /x402/*                 x402 paid endpoints        │
│                                                            │
│  Data Providers                                            │
│  ├─ providers/defillama.ts       TVL, yields, protocol data│
│  ├─ providers/coingecko.ts       Token prices & market data│
│  ├─ providers/dexscreener.ts     DEX pair analytics         │
│  ├─ providers/glacier.ts         Avalanche Glacier API      │
│  └─ providers/docs-search.ts     128K+ lines docs search    │
│                                                            │
│  Payment Layer                                             │
│  ├─ x402/middleware.ts           x402 payment verification  │
│  └─ x402/pricing.ts             Tool pricing configuration  │
│                                                            │
│  Agent Identity                                            │
│  ├─ identity/register.ts         On-chain registration      │
│  ├─ identity/metadata.json       Agent metadata             │
│  └─ identity/oasf.ts            OASF card generation        │
│                                                            │
└──────────────────────────────────────────────────────────┘
```

## Tech Stack

| Component | Technology | Why |
|-----------|-----------|-----|
| Server | Hono | Ultra-lightweight (14KB), fast, edge-ready |
| Runtime | Node.js 20 / TypeScript | Type safety, broad ecosystem |
| Data | DeFiLlama, CoinGecko, DEX Screener, Glacier | Comprehensive DeFi coverage |
| Docs | 128K+ lines of Avalanche docs | Deep ecosystem knowledge |
| Payments | x402 protocol | Agent-to-agent micropayments |
| Agent Card | OASF | Zero-cost self-description format |
| Deployment | Railway + Docker | Auto-deploy from GitHub |
| Identity | ERC-8004 on Avalanche | On-chain agent registration |

## ERC-8004 Implementation

### Registration

Registered on both Fuji testnet (Agent #15) and Avalanche mainnet (Agent #1686):

```bash
# Fuji testnet registration
CHAIN=fuji PRIVATE_KEY=$KEY \
  ./scripts/register.sh "https://avariskscan-production.up.railway.app/registration.json"

# Avalanche mainnet registration
CHAIN=avalanche PRIVATE_KEY=$KEY \
  ./scripts/register.sh "https://avariskscan-production.up.railway.app/registration.json"
```

### Services Declared

- **web**: Dashboard and scanner UI
- **A2A v0.3.0**: Natural language DeFi and ecosystem queries
- **MCP v2025-11-25**: 27 tools for analytics, docs search, and payments
- **OASF**: Agent card at `/.well-known/agent.json`
- **x402**: Paid premium endpoints

### MCP Tools (27 Total)

| Category | Tool | Description |
|----------|------|-------------|
| **DeFi Analytics** | `get_protocol_tvl` | Get protocol TVL from DeFiLlama |
| | `get_yield_pools` | Find highest-yield pools |
| | `get_token_price` | Token price from CoinGecko |
| | `get_market_data` | Market cap, volume, supply |
| | `get_trending_tokens` | Currently trending tokens |
| | `get_dex_pairs` | DEX pair data from DEX Screener |
| | `get_top_gainers` | Top gaining tokens |
| | `get_top_losers` | Top losing tokens |
| | `get_chain_tvl` | TVL by chain |
| | `get_protocol_fees` | Protocol fee revenue |
| **Avalanche** | `search_avalanche_docs` | Search 128K+ lines of docs |
| | `get_subnet_info` | Avalanche subnet information |
| | `get_validator_info` | Validator data via Glacier |
| | `get_c_chain_stats` | C-Chain statistics |
| | `get_x_chain_assets` | X-Chain asset information |
| | `get_p_chain_validators` | P-Chain validator set |
| **Risk** | `assess_token_risk` | Token risk scoring |
| | `assess_protocol_risk` | Protocol risk assessment |
| | `get_audit_status` | Protocol audit information |
| **Ecosystem** | `get_ecosystem_overview` | Avalanche ecosystem summary |
| | `get_bridge_info` | Cross-chain bridge data |
| | `get_staking_info` | AVAX staking information |
| **Utility** | `convert_units` | Unit conversion (wei, gwei, etc.) |
| | `get_gas_prices` | Current gas prices |
| | `get_block_info` | Block information via Glacier |
| | `get_transaction_info` | Transaction details |
| | `get_address_balance` | Address balance lookup |

## x402 Payment Integration

AvaRiskScan implements the x402 payment protocol, allowing other agents to pay for premium tool access:

```typescript
// x402 middleware checks payment headers
app.use('/x402/*', x402Middleware({
  receiver: '0x...', // Agent's payment address
  pricing: {
    '/x402/premium-analytics': { amount: '0.001', token: 'USDC' },
    '/x402/deep-risk-scan':    { amount: '0.005', token: 'USDC' },
  }
}));
```

This enables a sustainable model where agents pay each other for services without human intervention.

## OASF Implementation

The Open Agent Service Format (OASF) agent card is served at `/.well-known/agent.json` at zero infrastructure cost -- it is simply a JSON file served by the existing Hono server:

```json
{
  "name": "AvaRiskScan",
  "description": "DeFi analytics and Avalanche ecosystem guide",
  "version": "1.0.0",
  "capabilities": ["mcp", "a2a", "x402"],
  "endpoints": {
    "mcp": "/mcp",
    "a2a": "/a2a",
    "registration": "/registration.json"
  }
}
```

## Lessons Learned

1. **Hono is extremely lightweight** — At 14KB, Hono adds virtually no overhead compared to Express. Perfect for agents that need to be fast and resource-efficient
2. **x402 integration is straightforward** — Adding payment middleware took less than a day. The hardest part was deciding pricing, not implementation
3. **OASF costs $0** — Serving an agent card is just a static JSON endpoint. No additional infrastructure needed
4. **27 tools is manageable** — With good naming conventions and categories, a large tool surface is navigable by other agents
5. **Testnet first saved us** — Agent #15 on Fuji caught several metadata formatting issues before mainnet registration as #1686
6. **Glacier API is underrated** — Direct access to Avalanche's indexed chain data eliminates the need for running your own indexer

## Timeline

| Date | Milestone |
|------|-----------|
| Week 1 | Core Hono server + DeFiLlama/CoinGecko integrations |
| Week 2 | Glacier API integration + Avalanche docs ingestion (128K+ lines) |
| Week 3 | ERC-8004 registration (Fuji #15, then mainnet #1686) + MCP tools |
| Week 4 | x402 payment layer + OASF card + scanner (erc-8004scan.xyz) |

---

*Built by Colombia-Blockchain / Enigma team.*
