# ERC-8004 Ecosystem

## Overview

ERC-8004 is designed to be a foundational layer for AI agent interoperability across the decentralized web. This document describes the broader ecosystem of protocols, standards, and tools that integrate with or complement ERC-8004.

## Core Components

### On-Chain Registries

The three ERC-8004 registries form the on-chain backbone:

| Registry | Purpose | Address Prefix |
|---|---|---|
| **Identity Registry** | Agent registration, NFT ownership, metadata | `0x8004A...` |
| **Reputation Registry** | Feedback, ratings, web of trust | `0x8004B...` |
| **Validation Registry** | Third-party validation and attestation | `0x8004C...` |

### Off-Chain Components

- **Agent URI JSON** -- Registration metadata hosted on IPFS, Arweave, or HTTPS
- **Feedback URI** -- Detailed feedback data referenced from on-chain events
- **Validation URI** -- Validation request and response payloads

## Supported Service Protocols

ERC-8004 agents can expose services through multiple protocols:

### A2A (Agent-to-Agent)

Google's Agent-to-Agent protocol for direct agent communication.

- **Service name**: `A2A`
- **Endpoint**: URL to the agent's A2A endpoint
- **Use case**: Agent-to-agent task delegation, collaboration

### MCP (Model Context Protocol)

Anthropic's Model Context Protocol for tool and context sharing.

- **Service name**: `MCP`
- **Endpoint**: URL to the MCP server
- **Use case**: Providing tools, resources, and context to LLM-based agents

### OASF (Open Agent Service Format)

Open standard for describing agent capabilities.

- **Service name**: `OASF`
- **Endpoint**: URL to the OASF descriptor
- **Use case**: Standardized capability advertisement

### Web (HTTP/REST)

Traditional web API endpoints.

- **Service name**: `web`
- **Endpoint**: URL to the API
- **Use case**: Human-facing interfaces, REST APIs, webhooks

### ENS (Ethereum Name Service)

Human-readable names for agents.

- **Service name**: `ENS`
- **Endpoint**: ENS name (e.g., `myagent.eth`)
- **Use case**: Discoverable, human-readable agent addressing

### DID (Decentralized Identifier)

W3C Decentralized Identifiers for agent identity.

- **Service name**: `DID`
- **Endpoint**: DID document URL
- **Use case**: Cross-platform identity, verifiable credentials

## Trust Mechanisms

ERC-8004 supports multiple trust layers:

### Reputation-Based Trust

- On-chain feedback with positive/negative values
- Tag-based filtering for specific quality dimensions
- Web of trust through client address filtering
- Agent owner responses to feedback

### Crypto-Economic Trust

- Stake-secured validation where validators put up collateral
- Slashing conditions for dishonest validation
- Economic incentives for accurate feedback

### TEE Attestation

- Trusted Execution Environment proofs
- Verifiable code integrity
- Hardware-backed security guarantees

### Zero-Knowledge Proofs (zkML)

- Prove model execution without revealing model weights
- Verify agent output authenticity
- Privacy-preserving validation

## Payment Integration

### x402 Protocol

ERC-8004 agents can declare `x402Support: true` in their registration JSON to indicate support for HTTP 402-based micropayments.

- Pay-per-request model
- No subscription required
- Supports multiple payment tokens
- Built on standard HTTP semantics

### Traditional Payments

Agents can also accept payments through:

- Direct token transfers to the agent wallet
- Smart contract escrow
- Subscription NFTs
- Payment channels

## Scanners and Facilitators

### Agent Scanners

Scanners are services that continuously monitor and evaluate registered agents:

- **Reachability checks**: Verify agent endpoints are responsive
- **Uptime monitoring**: Track availability over time
- **Performance benchmarks**: Measure response times and quality
- **On-chain reporting**: Submit feedback through the Reputation Registry

### Facilitators

Facilitators are intermediary agents or services that:

- **Discovery**: Help users find agents matching specific criteria
- **Orchestration**: Coordinate multi-agent workflows
- **Routing**: Direct requests to the most suitable agent
- **Quality assurance**: Filter agents by reputation thresholds

## Multi-Chain Strategy

ERC-8004 is designed to work across multiple EVM chains:

| Chain | Use Case | Advantages |
|---|---|---|
| **Ethereum** | High-value agents, canonical registry | Maximum security, widest tooling |
| **Base** | General purpose, cost-effective | Low fees, Coinbase ecosystem |
| **Arbitrum** | DeFi-integrated agents | Fast finality, DeFi liquidity |
| **Optimism** | Public goods agents | RetroPGF alignment, low fees |
| **Avalanche** | Enterprise agents | Subnet customization, compliance |
| **Polygon** | High-throughput agents | Very low fees, high TPS |

### Cross-Chain Identity

Agents can register on multiple chains and link their registrations through the `registrations` array in their registration JSON, using CAIP-10 identifiers.

## Developer Tools

### SDKs and Libraries

- **TypeScript/JavaScript**: ethers.js, viem, wagmi integrations
- **Python**: web3.py integrations
- **Solidity**: Interface contracts for on-chain integration

### Infrastructure

- **IPFS/Arweave**: For hosting agent URIs and feedback data
- **The Graph**: For indexing on-chain events and building queries
- **Block explorers**: For verifying on-chain state

## Related Standards

| Standard | Relationship to ERC-8004 |
|---|---|
| **ERC-721** | ERC-8004 agents are ERC-721 NFTs |
| **EIP-712** | Used for signature verification in `setAgentWallet` |
| **CAIP-10** | Format for cross-chain agent identification |
| **ERC-8172** | Agent attachments extension (see below) |

### ERC-8172: Agent Attachments

ERC-8172 extends ERC-8004 with on-chain agent attachments -- a way for agents to store and reference additional structured data on-chain (documents, proofs, certificates).

- **EIP**: Draft
- **Relationship**: Complementary to ERC-8004 (uses the same Identity Registry)
- **Use cases**: Storing AI model hashes, compliance certificates, audit reports
- **Status**: Early development

---

*The ERC-8004 ecosystem is actively growing. For the latest integrations and tools, see the [EIP-8004 discussion](https://eips.ethereum.org/EIPS/eip-8004).*
