# ERC-8004: Trustless Agent Services — Complete Specification

## Overview

ERC-8004 defines a standard for registering, discovering, and evaluating AI agents on any EVM-compatible blockchain. It consists of three on-chain registries deployed with deterministic vanity addresses.

- **EIP**: [EIP-8004](https://eips.ethereum.org/EIPS/eip-8004)
- **Status**: Draft
- **Type**: Standards Track (ERC)
- **Category**: ERC
- **Authors**: Agent0 Labs

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   ERC-8004 ON-CHAIN LAYER                    │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Identity Registry (0x8004A...)                              │
│  ├─ ERC-721 NFT for each agent                             │
│  ├─ register(agentURI) → agentId                           │
│  ├─ setAgentURI(agentId, newURI)                           │
│  ├─ setMetadata(agentId, key, value)                       │
│  ├─ setAgentWallet(agentId, wallet, deadline, sig)         │
│  └─ Events: Registered, URIUpdated                         │
│                                                              │
│  Reputation Registry (0x8004B...)                            │
│  ├─ giveFeedback(agentId, value, decimals, tags...)        │
│  ├─ revokeFeedback(agentId, feedbackIndex)                 │
│  ├─ appendResponse(agentId, client, index, uri, hash)      │
│  ├─ getSummary(agentId, clients, tag1, tag2)               │
│  └─ Events: NewFeedback, FeedbackRevoked                   │
│                                                              │
│  Validation Registry (0x8004C...)                            │
│  ├─ validationRequest(validator, agentId, uri, hash)       │
│  ├─ validationResponse(hash, response, uri, hash, tag)     │
│  ├─ getValidationStatus(requestHash)                       │
│  └─ Events: ValidationRequested, ValidationResponded       │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## 1. Identity Registry

### Interface

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IAgentRegistry {
    function register(string calldata agentURI) external returns (uint256 agentId);
    function register() external returns (uint256 agentId);
    function setAgentURI(uint256 agentId, string calldata newURI) external;
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function ownerOf(uint256 tokenId) external view returns (address);
    function setMetadata(uint256 agentId, string calldata metadataKey, bytes calldata metadataValue) external;
    function getMetadata(uint256 agentId, string calldata metadataKey) external view returns (bytes memory);
    function setAgentWallet(uint256 agentId, address newWallet, uint256 deadline, bytes calldata signature) external;
    function getAgentWallet(uint256 agentId) external view returns (address);
    function getVersion() external pure returns (string memory);

    event Registered(uint256 indexed agentId, string agentURI, address indexed owner);
    event URIUpdated(uint256 indexed agentId, string newURI, address indexed updatedBy);
}
```

### Key Behaviors

- `register(string)` mints a new ERC-721 NFT to `msg.sender` with the given URI
- `register()` mints without a URI (can be set later via `setAgentURI`)
- `setAgentURI` can only be called by the NFT owner
- `setMetadata` stores arbitrary bytes indexed by string key, owner-only
- `setAgentWallet` requires an EIP-712 signature from the new wallet proving consent
- Agent IDs are sequential starting from 1
- The contract is non-upgradeable by design

## 2. Reputation Registry

### Interface

```solidity
interface IReputationRegistry {
    function giveFeedback(
        uint256 agentId, int128 value, uint8 valueDecimals,
        string calldata tag1, string calldata tag2, string calldata endpoint,
        string calldata feedbackURI, bytes32 feedbackHash
    ) external;
    function revokeFeedback(uint256 agentId, uint64 feedbackIndex) external;
    function appendResponse(uint256 agentId, address clientAddress, uint64 feedbackIndex, string calldata responseURI, bytes32 responseHash) external;
    function readFeedback(uint256 agentId, address clientAddress, uint64 feedbackIndex) external view returns (int128 value, uint8 valueDecimals, string memory tag1, string memory tag2, bool isRevoked);
    function readAllFeedback(uint256 agentId, address[] calldata clientAddresses, string calldata tag1, string calldata tag2, bool includeRevoked) external view returns (address[] memory clients, uint64[] memory feedbackIndexes, int128[] memory values, uint8[] memory valueDecimals, string[] memory tag1s, string[] memory tag2s, bool[] memory revokedStatuses);
    function getSummary(uint256 agentId, address[] calldata clientAddresses, string calldata tag1, string calldata tag2) external view returns (uint64 count, int128 summaryValue, uint8 summaryValueDecimals);
    function getClients(uint256 agentId) external view returns (address[] memory);
    function getLastIndex(uint256 agentId, address clientAddress) external view returns (uint64);

    event NewFeedback(uint256 indexed agentId, address indexed clientAddress, uint64 feedbackIndex, int128 value, uint8 valueDecimals, string indexed indexedTag1, string tag1, string tag2, string endpoint, string feedbackURI, bytes32 feedbackHash);
    event FeedbackRevoked(uint256 indexed agentId, address indexed clientAddress, uint64 feedbackIndex);
}
```

### Key Behaviors

- Anyone can give feedback EXCEPT the agent's own NFT owner
- Feedback is indexed by `(agentId, clientAddress, feedbackIndex)`
- `value` is `int128` — supports positive AND negative feedback
- `valueDecimals` allows precision (e.g., 9950 with decimals=2 = 99.50%)
- `tag1` is indexed on-chain for efficient filtering
- `getSummary` with empty `clientAddresses[]` aggregates ALL feedback
- `getSummary` with specific addresses creates a "web of trust" filter
- Revoked feedback is excluded from summaries by default
- Agent owners can respond to feedback via `appendResponse`

### Common Tag Patterns

| Tag1 | Value Range | Decimals | Meaning |
|---|---|---|---|
| `starred` | 0-100 | 0 | Quality rating |
| `reachable` | 0 or 1 | 0 | Endpoint reachability |
| `uptime` | 0-10000 | 2 | Uptime percentage (99.50% = 9950) |
| `successRate` | 0-10000 | 2 | Success rate percentage |
| `responseTime` | milliseconds | 0 | Response time |

## 3. Validation Registry

### Interface

```solidity
interface IValidationRegistry {
    function validationRequest(address validatorAddress, uint256 agentId, string calldata requestURI, bytes32 requestHash) external;
    function validationResponse(bytes32 requestHash, uint8 response, string calldata responseURI, bytes32 responseHash, string calldata tag) external;
    function getValidationStatus(bytes32 requestHash) external view returns (address validatorAddress, uint256 agentId, uint8 response, bytes32 responseHash, string memory tag, uint256 lastUpdate);
    function getSummary(uint256 agentId, address[] calldata validatorAddresses, string calldata tag) external view returns (uint64 count, uint8 avgResponse);
    function getAgentValidations(uint256 agentId) external view returns (bytes32[] memory);
    function getValidatorRequests(address validatorAddress) external view returns (bytes32[] memory);
}
```

### Validation Methods

| Method | Description |
|---|---|
| **Re-execution** | Validator re-runs the agent's task and compares output |
| **Stake-secured** | Validator stakes tokens as collateral for honest evaluation |
| **zkML** | Zero-knowledge proof that the agent's model produced the output |
| **TEE Attestation** | Trusted Execution Environment proves code integrity |

## Agent Registry Identifier Format

Agents are globally identified using the CAIP-10 format:

```
eip155:<chainId>:<registryAddress>
```

Examples:
- Ethereum: `eip155:1:0x8004A169FB4a3325136EB29fA0ceB6D2e539a432`
- Base: `eip155:8453:0x8004A169FB4a3325136EB29fA0ceB6D2e539a432`
- Avalanche: `eip155:43114:0x8004A169FB4a3325136EB29fA0ceB6D2e539a432`

## Registration JSON Schema

The `agentURI` points to a JSON file with this structure:

```json
{
  "type": "https://eips.ethereum.org/EIPS/eip-8004#registration-v1",
  "name": "string (required)",
  "description": "string (required)",
  "image": "string URL (required)",
  "services": [
    {
      "name": "string (web|A2A|MCP|OASF|ENS|DID|email)",
      "endpoint": "string URL",
      "version": "string (optional)"
    }
  ],
  "x402Support": "boolean",
  "active": "boolean",
  "registrations": [
    {
      "agentId": "number",
      "agentRegistry": "string (CAIP-10 format)"
    }
  ],
  "supportedTrust": ["reputation", "crypto-economic", "tee-attestation"],
  "capabilities": ["string[]"]
}
```

## Gas Costs (Approximate)

| Operation | Gas | Cost at 30 gwei |
|---|---|---|
| `register(string)` | ~150,000 | ~$0.15 |
| `setAgentURI` | ~50,000 | ~$0.05 |
| `setMetadata` | ~60,000 | ~$0.06 |
| `giveFeedback` | ~120,000 | ~$0.12 |
| `revokeFeedback` | ~40,000 | ~$0.04 |
| `validationRequest` | ~100,000 | ~$0.10 |

Gas costs vary by chain. L2s (Base, Arbitrum, Optimism) are significantly cheaper than Ethereum mainnet.

## Security Considerations

- **No admin keys**: Contracts are non-upgradeable with no owner/admin
- **NFT ownership**: Only the NFT owner can modify agent metadata
- **Signature verification**: `setAgentWallet` requires EIP-712 signature
- **Self-feedback prevention**: Agents cannot give feedback to themselves
- **Immutable history**: Feedback history is permanent (revocation marks, doesn't delete)

---

*Based on [EIP-8004](https://eips.ethereum.org/EIPS/eip-8004) by Agent0 Labs.*
