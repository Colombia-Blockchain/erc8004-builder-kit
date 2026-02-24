# Case Study: Apex Arbitrage Agent #1687

## Overview

| Field | Value |
|-------|-------|
| Agent ID | #1687 (Avalanche Mainnet) |
| Registry | `eip155:43114:0x8004A169FB4a3325136EB29fA0ceB6D2e539a432` |
| Stack | Python 3.12 / FastAPI |
| Deployment | Railway |
| Live URL | Production on Railway |
| Repo | `Colombia-Blockchain/apex-arbitrage-agent` |

## What It Does

Apex is a DeFi arbitrage detection agent for Avalanche. It:

- Monitors DEX pools for price discrepancies across Trader Joe, Pangolin, GMX, and other Avalanche DEXs
- Simulates flash loan arbitrage paths using Monte Carlo methods
- Uses a trained ML model (scikit-learn) for arbitrage prediction
- Provides real-time alerts for profitable opportunities
- Exposes 10+ MCP tools for programmatic access
- Accepts A2A queries for natural language DeFi questions

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                APEX ARBITRAGE AGENT                       │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  FastAPI Server (server.py)                               │
│  ├─ GET  /                  Dashboard                    │
│  ├─ GET  /api/health        Health check                 │
│  ├─ GET  /registration.json ERC-8004 metadata            │
│  ├─ POST /mcp               MCP server                   │
│  ├─ POST /a2a/guide         A2A natural language          │
│  └─ POST /a2a/analytics     A2A structured data           │
│                                                           │
│  Data Layer                                               │
│  ├─ data/pool_fetcher.py    Pool data from DEXs          │
│  ├─ data/price_calculator.py Price calculations           │
│  ├─ data/defillama.py       DeFiLlama integration        │
│  ├─ data/dexscreener.py     DEX Screener integration     │
│  └─ data/flash_loan_simulator.py Simulation engine        │
│                                                           │
│  ML/RL Layer                                              │
│  ├─ models/predictor.py     Trained arbitrage predictor   │
│  ├─ rl/agent.py             Reinforcement learning        │
│  └─ simulator/monte_carlo.py Monte Carlo simulations      │
│                                                           │
│  Agent Identity                                           │
│  ├─ agent_identity/erc8004_register.py On-chain reg      │
│  └─ agent_identity/metadata.json     Agent metadata       │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

## Tech Stack

| Component | Technology | Why |
|-----------|-----------|-----|
| Server | FastAPI | Async Python, great for compute-heavy tasks |
| ML | scikit-learn, joblib | Lightweight ML for arbitrage prediction |
| RL | Custom environment | Reinforcement learning for strategy optimization |
| Simulation | Monte Carlo | Flash loan path simulation |
| Data | DeFiLlama, DEX Screener, CoinGecko | Real-time DeFi data |
| Deployment | Railway + Docker | Auto-deploy from GitHub |
| Identity | ERC-8004 on Avalanche | On-chain agent registration |

## ERC-8004 Implementation

### Registration

Registered on Avalanche mainnet with agent ID #1687 using:

```bash
CHAIN=avalanche PRIVATE_KEY=$KEY \
  ./scripts/register.sh "https://apex-production.up.railway.app/registration.json"
```

### Services Declared

- **web**: Dashboard
- **A2A v0.3.0**: Natural language DeFi queries
- **MCP v2025-11-25**: 10+ tools for arbitrage detection, simulation, and alerts

### MCP Tools

| Tool | Description |
|------|-------------|
| `get_arbitrage_opportunities` | Find current arbitrage paths |
| `simulate_flash_loan` | Simulate a flash loan path |
| `get_pool_data` | Get DEX pool reserves and prices |
| `get_price` | Get token price from multiple sources |
| `get_top_pairs` | Top trading pairs by volume |
| `predict_arbitrage` | ML-based opportunity prediction |
| `get_alerts` | Real-time profitable opportunity alerts |

## Lessons Learned

1. **Python is great for compute-heavy agents** — ML model inference, Monte Carlo simulations, and numerical analysis are natural in Python
2. **FastAPI's async model works well** — Parallel API calls with `asyncio.gather` instead of sequential fetching
3. **Cache everything** — DeFi data changes every block, but 2-minute caches are fine for most use cases
4. **Start on testnet** — Registered on Fuji first, caught metadata issues before mainnet
5. **Honest descriptions matter** — Clearly stated "detection" not "execution" for arbitrage capabilities

## Timeline

| Date | Milestone |
|------|-----------|
| Week 1 | Core server + DeFi data integrations |
| Week 2 | ML model training + flash loan simulator |
| Week 3 | ERC-8004 registration + MCP implementation |
| Week 4 | A2A endpoints + scanner optimization |

---

*Built by Colombia-Blockchain / Enigma team.*
