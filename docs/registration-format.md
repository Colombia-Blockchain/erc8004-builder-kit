# ERC-8004 Registration JSON Format

## Overview

When registering an agent via `register(string agentURI)`, the `agentURI` points to a JSON document that describes the agent. This document defines the required schema, optional fields, and enriched metadata sections.

## Base Schema

```json
{
  "type": "https://eips.ethereum.org/EIPS/eip-8004#registration-v1",
  "name": "My Agent",
  "description": "A brief description of what this agent does.",
  "image": "https://example.com/agent-avatar.png",
  "services": [],
  "x402Support": false,
  "active": true,
  "registrations": [],
  "supportedTrust": [],
  "capabilities": []
}
```

## Required Fields

| Field | Type | Description |
|---|---|---|
| `type` | `string` | Must be `"https://eips.ethereum.org/EIPS/eip-8004#registration-v1"` |
| `name` | `string` | Human-readable name for the agent |
| `description` | `string` | Brief description of the agent's purpose and capabilities |
| `image` | `string` | URL to the agent's avatar or logo image |

## Optional Fields

| Field | Type | Default | Description |
|---|---|---|---|
| `services` | `Service[]` | `[]` | List of service endpoints the agent exposes |
| `x402Support` | `boolean` | `false` | Whether the agent supports x402 micropayments |
| `active` | `boolean` | `true` | Whether the agent is currently active |
| `registrations` | `Registration[]` | `[]` | Cross-chain registration references |
| `supportedTrust` | `string[]` | `[]` | Trust mechanisms the agent supports |
| `capabilities` | `string[]` | `[]` | List of capability identifiers |

## Services Array

Each entry in the `services` array describes an endpoint the agent exposes:

```json
{
  "services": [
    {
      "name": "web",
      "endpoint": "https://myagent.example.com",
      "version": "1.0"
    },
    {
      "name": "A2A",
      "endpoint": "https://myagent.example.com/.well-known/agent.json",
      "version": "0.2"
    },
    {
      "name": "MCP",
      "endpoint": "https://myagent.example.com/mcp",
      "version": "1.0"
    }
  ]
}
```

### Supported Service Types

| Name | Protocol | Description |
|---|---|---|
| `web` | HTTP/REST | Traditional web API or human-facing interface |
| `A2A` | Agent-to-Agent | Google's A2A protocol for agent communication |
| `MCP` | Model Context Protocol | Anthropic's protocol for tool/context sharing |
| `OASF` | Open Agent Service Format | Open standard for agent capability description |
| `ENS` | Ethereum Name Service | Human-readable .eth name |
| `DID` | Decentralized Identifier | W3C DID document reference |
| `email` | Email | Contact email for the agent operator |

### Service Object Schema

| Field | Type | Required | Description |
|---|---|---|---|
| `name` | `string` | Yes | One of the supported service types |
| `endpoint` | `string` | Yes | URL or identifier for the service |
| `version` | `string` | No | Version of the protocol being used |

## Registrations Array

The `registrations` array links the agent's identity across multiple chains:

```json
{
  "registrations": [
    {
      "agentId": 42,
      "agentRegistry": "eip155:8453:0x8004A169FB4a3325136EB29fA0ceB6D2e539a432"
    },
    {
      "agentId": 7,
      "agentRegistry": "eip155:1:0x8004A169FB4a3325136EB29fA0ceB6D2e539a432"
    }
  ]
}
```

### Registration Object Schema

| Field | Type | Description |
|---|---|---|
| `agentId` | `number` | The agent's token ID on the specified chain |
| `agentRegistry` | `string` | CAIP-10 identifier for the registry (`eip155:<chainId>:<address>`) |

## Supported Trust Mechanisms

The `supportedTrust` array declares which trust mechanisms the agent supports:

```json
{
  "supportedTrust": ["reputation", "crypto-economic", "tee-attestation"]
}
```

| Value | Description |
|---|---|
| `reputation` | Agent participates in on-chain reputation via the Reputation Registry |
| `crypto-economic` | Agent supports stake-secured validation |
| `tee-attestation` | Agent runs in a Trusted Execution Environment with attestation |
| `zkml` | Agent can provide zero-knowledge proofs of model execution |

## Capabilities Array

Free-form list of capability identifiers:

```json
{
  "capabilities": [
    "text-generation",
    "code-review",
    "smart-contract-audit",
    "image-classification",
    "data-analysis",
    "translation"
  ]
}
```

There is no enforced vocabulary -- capabilities are self-declared by the agent operator. However, common conventions are encouraged for discoverability.

## Enriched Metadata Sections

Beyond the base schema, registration JSON can include enriched metadata for better discoverability and integration.

### Operator Information

```json
{
  "operator": {
    "name": "Agent0 Labs",
    "url": "https://agent0labs.com",
    "contact": "support@agent0labs.com",
    "legal": {
      "jurisdiction": "US",
      "termsOfService": "https://agent0labs.com/tos",
      "privacyPolicy": "https://agent0labs.com/privacy"
    }
  }
}
```

### Model Information

```json
{
  "model": {
    "provider": "OpenAI",
    "name": "gpt-4-turbo",
    "version": "2024-04-09",
    "contextWindow": 128000,
    "maxOutputTokens": 4096,
    "modalities": ["text"],
    "fineTuned": false,
    "modelHash": "0xabc123..."
  }
}
```

### Pricing Information

```json
{
  "pricing": {
    "model": "per-request",
    "currency": "USDC",
    "basePrice": "0.01",
    "unit": "request",
    "freeQuota": 100,
    "paymentMethods": ["x402", "direct-transfer"],
    "paymentAddress": "0x1234..."
  }
}
```

### Rate Limits

```json
{
  "rateLimits": {
    "requestsPerMinute": 60,
    "requestsPerDay": 10000,
    "maxConcurrent": 10,
    "maxPayloadSize": "1MB"
  }
}
```

### Availability Information

```json
{
  "availability": {
    "sla": "99.9%",
    "regions": ["us-east-1", "eu-west-1"],
    "maintenanceWindow": "Sunday 02:00-04:00 UTC",
    "statusPage": "https://status.myagent.example.com"
  }
}
```

### Security Information

```json
{
  "security": {
    "authentication": ["api-key", "oauth2", "x402"],
    "encryption": "TLS 1.3",
    "dataRetention": "none",
    "auditLog": true,
    "complianceCertificates": [
      "ipfs://QmCertHash1...",
      "ipfs://QmCertHash2..."
    ]
  }
}
```

## Complete Example

```json
{
  "type": "https://eips.ethereum.org/EIPS/eip-8004#registration-v1",
  "name": "CodeReview Agent",
  "description": "Automated smart contract auditing agent with Solidity expertise. Identifies vulnerabilities, gas optimizations, and best practice violations.",
  "image": "https://storage.example.com/codereview-avatar.png",
  "services": [
    {
      "name": "web",
      "endpoint": "https://codereview.example.com",
      "version": "2.0"
    },
    {
      "name": "A2A",
      "endpoint": "https://codereview.example.com/.well-known/agent.json",
      "version": "0.2"
    },
    {
      "name": "MCP",
      "endpoint": "https://codereview.example.com/mcp",
      "version": "1.0"
    }
  ],
  "x402Support": true,
  "active": true,
  "registrations": [
    {
      "agentId": 42,
      "agentRegistry": "eip155:8453:0x8004A169FB4a3325136EB29fA0ceB6D2e539a432"
    },
    {
      "agentId": 7,
      "agentRegistry": "eip155:1:0x8004A169FB4a3325136EB29fA0ceB6D2e539a432"
    }
  ],
  "supportedTrust": ["reputation", "crypto-economic"],
  "capabilities": [
    "smart-contract-audit",
    "solidity-analysis",
    "gas-optimization",
    "vulnerability-detection",
    "code-review"
  ],
  "operator": {
    "name": "Agent0 Labs",
    "url": "https://agent0labs.com",
    "contact": "security@agent0labs.com"
  },
  "model": {
    "provider": "Anthropic",
    "name": "claude-sonnet-4-20250514",
    "modalities": ["text"],
    "fineTuned": false
  },
  "pricing": {
    "model": "per-request",
    "currency": "USDC",
    "basePrice": "0.05",
    "unit": "audit",
    "paymentMethods": ["x402"]
  },
  "rateLimits": {
    "requestsPerMinute": 10,
    "requestsPerDay": 1000,
    "maxConcurrent": 5,
    "maxPayloadSize": "500KB"
  },
  "availability": {
    "sla": "99.5%",
    "regions": ["us-east-1", "eu-west-1", "ap-southeast-1"]
  }
}
```

## Hosting the Registration JSON

The `agentURI` can point to any accessible URL. Recommended hosting options:

| Method | Pros | Cons |
|---|---|---|
| **IPFS** | Immutable, decentralized, content-addressed | Requires pinning for persistence |
| **Arweave** | Permanent storage, pay once | Higher upfront cost |
| **HTTPS** | Easy to update, fast | Centralized, can go offline |
| **ENS Content Hash** | Decentralized naming + storage | Requires ENS name |

### IPFS Example

```
ipfs://QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG
```

### HTTPS Example

```
https://myagent.example.com/.well-known/agent-registration.json
```

## Validation

When consuming a registration JSON, implementations should:

1. Verify the `type` field matches the expected schema version
2. Ensure all required fields (`name`, `description`, `image`) are present
3. Validate that `services[].name` uses a recognized protocol type
4. Verify `registrations[].agentRegistry` follows CAIP-10 format
5. Check that URLs in `endpoint` fields are well-formed
6. Optionally verify that `image` URL is accessible

---

*For the complete specification, see [specification.md](./specification.md).*
