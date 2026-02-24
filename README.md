# erc8004-builder-kit

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![ERC-8004](https://img.shields.io/badge/ERC--8004-Trustless%20Agent%20Services-blue)](https://eips.ethereum.org/EIPS/eip-8004)
[![Chains](https://img.shields.io/badge/Chains-19%20mainnets-green)](docs/contract-addresses.md)
[![Agents](https://img.shields.io/badge/Registered%20Agents-21%2C000%2B-purple)](https://8004scan.io)

**The definitive builder kit for ERC-8004 agents.** Guides, starter templates, scripts, and real production examples — everything you need to build, deploy, and register AI agents on any EVM chain.

Built by the [Colombia-Blockchain / Enigma](https://github.com/Colombia-Blockchain) team from experience shipping 2 agents to production:
- **Apex Arbitrage Agent** #1687 — Python/FastAPI, DeFi arbitrage detection
- **AvaRiskScan Agent** #1686 — TypeScript/Hono, Avalanche ecosystem guide + DeFi analytics

---

## Quick Start

### 1. Clone

```bash
git clone https://github.com/Colombia-Blockchain/erc8004-builder-kit.git
cd erc8004-builder-kit
```

### 2. Pick Your Stack

**TypeScript/Hono:**
```bash
cp -r examples/typescript-hono my-agent && cd my-agent
npm install && npm run dev
```

**Python/FastAPI:**
```bash
cp -r examples/python-fastapi my-agent && cd my-agent
pip install -r requirements.txt && python server.py
```

### 3. Register On-Chain

```bash
# Install Foundry (cast)
curl -L https://foundry.paradigm.xyz | bash && foundryup

# Register on testnet
CHAIN=base-sepolia PRIVATE_KEY=$KEY \
  ./scripts/register.sh "https://your-agent.up.railway.app/registration.json"
```

### 4. Verify

```bash
CHAIN=base-sepolia ./scripts/verify-agent.sh YOUR_AGENT_ID
```

**Full walkthrough:** [01-quickstart.md](docs/guides/01-quickstart.md)

---

## What's Inside

### Documentation (`docs/`)

| Document | Description |
|----------|-------------|
| [specification.md](docs/specification.md) | Complete Solidity interfaces for all 3 registries |
| [contract-addresses.md](docs/contract-addresses.md) | 19 mainnets + 11 testnets + RPCs |
| [registration-format.md](docs/registration-format.md) | JSON schema + enriched metadata (mcpTools, a2aSkills, OASF) |
| [api-reference.md](docs/api-reference.md) | Code examples: viem, ethers.js, cast |
| [ecosystem.md](docs/ecosystem.md) | Scanners, SDKs, protocols, growth data |
| [glossary.md](docs/glossary.md) | 40+ terms defined |

### Guides (`docs/guides/`)

| # | Guide | What You'll Learn |
|---|-------|-------------------|
| 01 | [Quickstart](docs/guides/01-quickstart.md) | Zero to registered agent in 30 minutes |
| 02 | [A2A](docs/guides/02-a2a-guide.md) | Agent-to-Agent communication (v0.3.0) |
| 03 | [MCP](docs/guides/03-mcp-guide.md) | Model Context Protocol (v2025-11-25) |
| 04 | [x402](docs/guides/04-x402-guide.md) | Micropayments with USDC |
| 05 | [OASF](docs/guides/05-oasf-guide.md) | Open Agentic Schema Framework |
| 06 | [Deployment](docs/guides/06-deployment-guide.md) | Railway, Docker, infrastructure |
| 07 | [Inter-Agent Patterns](docs/guides/07-inter-agent-patterns.md) | 18 communication patterns |
| 08 | [Reputation](docs/guides/08-reputation-feedback.md) | On-chain feedback cycle |
| 09 | [Scanner Optimization](docs/guides/09-scanner-optimization.md) | 5D scoring, enriched metadata |
| 10 | [Multi-Chain](docs/guides/10-multi-chain.md) | Register on 9+ chains |
| 11 | [Validation Registry](docs/guides/11-validation-registry.md) | zkML, TEE, stake-secured |
| 12 | [Agent Wallet](docs/guides/12-agent-wallet.md) | setAgentWallet with EIP-712 |
| 13 | [8004scan Optimization](docs/guides/13-8004scan-optimization.md) | Maximize your score on 8004scan.io |

### Case Studies (`docs/case-studies/`)

| Study | Description |
|-------|-------------|
| [Apex Arbitrage](docs/case-studies/apex-arbitrage.md) | Python/FastAPI agent — ML-powered DeFi arbitrage detection |
| [AvaRiskScan](docs/case-studies/avariskscan.md) | TypeScript/Hono agent — 21 MCP tools, x402 payments |
| [Dual-Agent Interaction](docs/case-studies/dual-agent-interaction.md) | Cross-agent communication with on-chain feedback |

### Starter Templates (`examples/`)

| Template | Stack | Includes |
|----------|-------|----------|
| [typescript-hono](examples/typescript-hono/) | Hono + TypeScript | MCP, A2A, dashboard, x402 middleware, interaction log |
| [python-fastapi](examples/python-fastapi/) | FastAPI + Python | MCP, A2A, OASF, x402 decorator, interaction log |

Both templates are ready for Railway deployment with Dockerfile and `railway.toml`.

### Scripts (`scripts/`)

| Script | Description |
|--------|-------------|
| [register.sh](scripts/register.sh) | Register agent on any of 9+ chains (mainnet + testnet) |
| [verify-agent.sh](scripts/verify-agent.sh) | 30+ verification checks (on-chain, metadata, endpoints) |
| [check-agent.sh](scripts/check-agent.sh) | Query agent info from any chain |
| [update-uri.sh](scripts/update-uri.sh) | Update metadata URI on-chain |
| [give-feedback.sh](scripts/give-feedback.sh) | Submit reputation feedback |

All scripts support multi-chain via `CHAIN=` environment variable.

### Troubleshooting (`troubleshooting/`)

| Document | Description |
|----------|-------------|
| [errors-and-fixes.md](troubleshooting/errors-and-fixes.md) | 40+ real production issues with solutions |
| [scanner-warnings.md](troubleshooting/scanner-warnings.md) | All WA0XX warning codes explained |
| [common-mistakes.md](troubleshooting/common-mistakes.md) | Top 10 mistakes from building 2 agents |

### On-Chain Evidence (`on-chain-evidence/`)

| Document | Description |
|----------|-------------|
| [registration-transactions.md](on-chain-evidence/registration-transactions.md) | TX hashes for agent #1686 and #1687 |
| [feedback-transactions.md](on-chain-evidence/feedback-transactions.md) | Decoded reputation feedback TXs |

---

## ERC-8004 at a Glance

ERC-8004 is the standard for **trustless AI agent services** on EVM chains. Three on-chain registries:

| Registry | Address | Purpose |
|----------|---------|---------|
| **Identity** | `0x8004A169...` | Register agents as ERC-721 NFTs |
| **Reputation** | `0x8004BAa1...` | On-chain feedback and ratings |
| **Validation** | `0x8004C...` | Third-party validation (zkML, TEE, stake) |

**Same addresses on all 19 chains.** Deploy once, register anywhere.

```
Agent → register(agentURI) → Gets NFT (agentId) → Discoverable on 8004scan.io
```

**Key stats (February 2026):**
- 21,000+ registered agents
- 19 mainnet chains (incl. Ethereum, Base, Avalanche, Arbitrum, Optimism, Polygon)
- 15,000+ cumulative feedback entries
- Protocols: A2A v0.3.0, MCP v2025-11-25, x402 V2, OASF v0.8

---

## Architecture: What a Complete Agent Looks Like

```
┌─────────────────────────────────────────────────────────────┐
│                    YOUR ERC-8004 AGENT                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Endpoints                          On-Chain                 │
│  ──────────                         ────────                 │
│  GET  /                 Dashboard   Identity Registry         │
│  GET  /api/health       Monitoring  ├─ NFT (agentId)         │
│  GET  /registration.json Metadata   ├─ tokenURI → your JSON  │
│  GET  /.well-known/     Discovery   └─ setAgentWallet        │
│  POST /mcp              MCP Server                           │
│  POST /a2a/*            A2A         Reputation Registry      │
│  GET  /oasf             OASF        ├─ giveFeedback          │
│  POST /api/premium      x402 Paid   └─ getSummary            │
│                                                              │
│  registration.json                  Validation Registry      │
│  ├─ name, description, image        ├─ validationRequest     │
│  ├─ services (web, A2A, MCP, OASF)  └─ validationResponse   │
│  ├─ registrations (multi-chain)                              │
│  ├─ capabilities                                             │
│  └─ x402Support                                              │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Real Production Results

This kit isn't theoretical. Both agents are live, verified, and transacting on mainnet.

### Agents

| Agent | ID | Stack | URL | Repo |
|-------|-----|-------|-----|------|
| Apex Arbitrage | #1687 | Python/FastAPI | [Production](https://apex-arbitrage-agent-production.up.railway.app) | [Colombia-Blockchain/apex-arbitrage-agent](https://github.com/Colombia-Blockchain/apex-arbitrage-agent) |
| AvaRiskScan | #1686 | TypeScript/Hono | [Production](https://avariskscan-defi-production.up.railway.app) | [Colombia-Blockchain/avariskscan-defi](https://github.com/Colombia-Blockchain/avariskscan-defi) |

### TRACER Scores (via [Super Sentinel](https://github.com/Enigma-Team-org/Enigma))

| Dimension | Apex #1687 | AvaRiskScan #1686 |
|-----------|-----------|-------------------|
| Trust | 80 | 80 |
| Reliability | 80 | 90 |
| Autonomy | 90 | 90 |
| Capability | 0 | 0 |
| Economics | 90 | 90 |
| Reputation | 0 | 0 |
| **Total** | **55** | **57** |

### On-Chain Transactions (Avalanche C-Chain)

| Transaction | TxHash | Amount |
|-------------|--------|--------|
| x402 scan AvaRiskScan | [`0xbd479178...`](https://snowtrace.io/tx/0xbd4791789f59c87656517cf8f291db50fe5955a1cb9d8287e71c5968215b504b) | $0.01 USDC |
| x402 scan Apex | [`0x4df46550...`](https://snowtrace.io/tx/0x4df465505b3c0e42f45f3433a9a0dd921246e8f10ee546a90687ccdc46ea87a4) | $0.01 USDC |
| x402 self-scan | [`0x12038c59...`](https://snowtrace.io/tx/0x12038c5965c2b70ae90e3ab70306b9f8598637b29e96aae09706b96875303e48) | $0.01 USDC |
| Feedback → AvaRiskScan | [`0xed60cbdd...`](https://snowtrace.io/tx/0xed60cbdd3fdb642af4f3c4baab958e285c9745b8368c57cc5ec8781c7cd6186b) | score: 88 |

See [on-chain-evidence/](on-chain-evidence/) for decoded transaction details.

### 8004scan Optimization

New guide: **[13-8004scan-optimization.md](docs/guides/13-8004scan-optimization.md)** — covers all 5 scoring dimensions, every WA0XX/IA0XX warning code, and a metadata validation script. Built from real experience fixing warnings on our production agents.

---

## Resources

| Resource | URL |
|----------|-----|
| ERC-8004 Official | https://www.8004.org |
| EIP Specification | https://eips.ethereum.org/EIPS/eip-8004 |
| Contracts (GitHub) | https://github.com/erc-8004/erc-8004-contracts |
| Agent Scanner | https://8004scan.io |
| Best Practices | https://best-practices.8004scan.io |
| Community Scanner | https://www.erc-8004scan.xyz/scanner |
| x402 Protocol | https://x402.org |
| MCP Registry | https://registry.modelcontextprotocol.io |
| A2A Protocol | https://a2a-protocol.org |
| OASF Framework | https://github.com/agntcy/oasf |

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). We welcome:
- New guides based on real implementation experience
- Additional starter templates (Go, Rust, etc.)
- Script improvements and new chain support
- Bug fixes and corrections

---

## License

[MIT](LICENSE) — Build freely.

---

*Built with real production experience by Colombia-Blockchain / Enigma. Every guide, every code example, every troubleshooting entry comes from shipping real agents to mainnet.*
