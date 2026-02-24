# Case Study: AvaRiskScan Agent #1686

## Overview

| Field | Value |
|-------|-------|
| Agent ID | #1686 (Avalanche Mainnet), #15 (Avalanche Fuji Testnet) |
| Registry (Mainnet) | `eip155:43114:0x8004A169FB4a3325136EB29fA0ceB6D2e539a432` |
| Registry (Fuji) | `eip155:43113:0x8004A818C2B4fF20386a0e25Ca0d69e418e9cE77` |
| Wallet | `0x29a45b03F07D1207f2e3ca34c38e7BE5458CE71a` |
| Stack | TypeScript / Hono |
| Deployment | Railway |
| Live URL | [avariskscan-defi-production.up.railway.app](https://avariskscan-defi-production.up.railway.app) |
| Repo | [`Colombia-Blockchain/avariskscan-defi`](https://github.com/Colombia-Blockchain/avariskscan-defi) |
| Scanner | [erc-8004scan.xyz](https://erc-8004scan.xyz) |

## What It Does

AvaRiskScan is a comprehensive DeFi analytics and Avalanche ecosystem guide agent. It:

- Provides DeFi analytics across protocols using DeFiLlama, CoinGecko, DEX Screener, and the Glacier API
- Serves as an Avalanche ecosystem guide backed by 128K+ lines of curated documentation
- Exposes 21 MCP tools for programmatic access to DeFi data and ecosystem knowledge
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
│  ├─ POST /mcp                    MCP server (21 tools)     │
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

## Production Scores

### TRACER Score: 57 (PARTIAL)

| Dimension | Score | Notes |
|-----------|-------|-------|
| **Trust** | 80 | TLS Grade A, TLSv1.3 |
| **Reliability** | 90 | 100% uptime, p50 latency 308ms |
| **Autonomy** | 90 | A2A agent card + 21 MCP tools |
| **Capability** | 0 | No sentinel implemented yet |
| **Economics** | 90 | x402 supported, USDC pricing |
| **Reputation** | 0 | No on-chain feedback read by scanner yet |

## ERC-8004 Implementation

### Registration

Registered on both Fuji testnet (Agent #15) and Avalanche mainnet (Agent #1686):

```bash
# Fuji testnet registration
CHAIN=fuji PRIVATE_KEY=$KEY \
  ./scripts/register.sh "https://avariskscan-defi-production.up.railway.app/registration.json"

# Avalanche mainnet registration
CHAIN=avalanche PRIVATE_KEY=$KEY \
  ./scripts/register.sh "https://avariskscan-defi-production.up.railway.app/registration.json"
```

### Services Declared

- **web**: Dashboard and scanner UI
- **A2A v0.3.0**: Natural language DeFi and ecosystem queries
- **MCP v2025-11-25**: 21 tools for analytics, docs search, and payments
- **OASF**: Agent card at `/.well-known/agent.json`
- **x402**: Paid premium endpoints

### MCP Tools (21 Total)

| Tool | Description |
|------|-------------|
| `get_avax_price` | Current AVAX price and market data |
| `get_avalanche_tvl` | Total value locked across Avalanche protocols |
| `get_avalanche_defi` | DeFi protocol analytics on Avalanche |
| `get_token_info` | Detailed token information and metadata |
| `get_top_pairs` | Top trading pairs by volume |
| `get_avalanche_l1s` | Avalanche L1 subnet information |
| `get_ecosystem_overview` | Avalanche ecosystem summary |
| `get_build_templates` | Developer build templates for Avalanche |
| `get_learning_paths` | Educational learning paths for developers |
| `get_topics` | Browse documentation topics |
| `get_vault_yields` | Best vault yields across protocols |
| `get_gas_prices` | Current gas prices on Avalanche |
| `simulate_swap` | Simulate a token swap with routing |
| `get_portfolio` | Portfolio analytics for a given wallet |
| `get_market_intelligence` | Aggregated market intelligence report |
| `get_wallet_balances` | Token balances for a wallet address |
| `get_transaction` | Transaction details by hash |
| `get_wallet_nfts` | NFT holdings for a wallet address |
| `get_validators` | Avalanche validator set information |
| `get_onchain_prices` | On-chain price data from DEX pools |
| `get_network_status` | Avalanche network health and status |

## x402 Payment Integration

AvaRiskScan implements the x402 payment protocol, allowing other agents to pay for premium tool access:

```typescript
// x402 middleware checks payment headers
app.use('/x402/*', x402Middleware({
  receiver: '0x29a45b03F07D1207f2e3ca34c38e7BE5458CE71a',
  pricing: {
    '/x402/premium-analytics': { amount: '0.001', token: 'USDC' },
    '/x402/deep-risk-scan':    { amount: '0.005', token: 'USDC' },
  }
}));
```

This enables a sustainable model where agents pay each other for services without human intervention.

### First Mainnet x402 Transaction

| Field | Value |
|-------|-------|
| TxHash | `0xbd4791789f59c87656517cf8f291db50fe5955a1cb9d8287e71c5968215b504b` |
| Snowtrace | [View on Snowtrace](https://snowtrace.io/tx/0xbd4791789f59c87656517cf8f291db50fe5955a1cb9d8287e71c5968215b504b) |
| Network | Avalanche C-Chain |

## On-Chain Feedback

AvaRiskScan has received on-chain feedback from 4 unique reviewers via the ReputationRegistry contract.

### Sample Feedback Transaction

| Field | Value |
|-------|-------|
| TxHash | `0xed60cbdd3fdb642af4f3c4baab958e285c9745b8368c57cc5ec8781c7cd6186b` |
| Snowtrace | [View on Snowtrace](https://snowtrace.io/tx/0xed60cbdd3fdb642af4f3c4baab958e285c9745b8368c57cc5ec8781c7cd6186b) |
| Score | 88 |
| Reviewers | 4 unique on-chain reviewers |
| Registry | ReputationRegistry `0x8004BAa17C55a88189AE136b182e5fdA19dE9b63` |

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

1. **Hono is extremely lightweight** -- At 14KB, Hono adds virtually no overhead compared to Express. Perfect for agents that need to be fast and resource-efficient
2. **x402 integration is straightforward** -- Adding payment middleware took less than a day. The hardest part was deciding pricing, not implementation
3. **OASF costs $0** -- Serving an agent card is just a static JSON endpoint. No additional infrastructure needed
4. **21 tools is manageable** -- With good naming conventions and categories, a large tool surface is navigable by other agents
5. **Testnet first saved us** -- Agent #15 on Fuji caught several metadata formatting issues before mainnet registration as #1686
6. **Glacier API is underrated** -- Direct access to Avalanche's indexed chain data eliminates the need for running your own indexer
7. **On-chain feedback builds trust** -- Having 4 independent reviewers submit feedback provides verifiable reputation data

## Timeline

| Date | Milestone |
|------|-----------|
| Week 1 | Core Hono server + DeFiLlama/CoinGecko integrations |
| Week 2 | Glacier API integration + Avalanche docs ingestion (128K+ lines) |
| Week 3 | ERC-8004 registration (Fuji #15, then mainnet #1686) + MCP tools (21) |
| Week 4 | x402 payment layer + OASF card + scanner (erc-8004scan.xyz) |

---

*Built by Colombia-Blockchain / Enigma team.*
