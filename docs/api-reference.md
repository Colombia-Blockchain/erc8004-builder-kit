# ERC-8004 API Reference

## Overview

This document provides a complete API reference for all three ERC-8004 registries: Identity, Reputation, and Validation. Each function includes its signature, parameters, return values, access control, and usage examples.

---

## Identity Registry (IAgentRegistry)

**Address**: `0x8004A169FB4a3325136EB29fA0ceB6D2e539a432`

### register(string)

Registers a new agent with a URI and mints an ERC-721 NFT.

```solidity
function register(string calldata agentURI) external returns (uint256 agentId)
```

| Parameter | Type | Description |
|---|---|---|
| `agentURI` | `string` | URI pointing to the agent's registration JSON |

**Returns**: `uint256` -- The newly minted agent ID (sequential, starting from 1).

**Access**: Anyone can call. The NFT is minted to `msg.sender`.

**Events emitted**: `Registered(uint256 indexed agentId, string agentURI, address indexed owner)`

**Example (ethers.js v6)**:
```typescript
const tx = await identityRegistry.register("https://example.com/agent.json");
const receipt = await tx.wait();
const agentId = receipt.logs[0].args.agentId;
```

### register()

Registers a new agent without a URI.

```solidity
function register() external returns (uint256 agentId)
```

**Returns**: `uint256` -- The newly minted agent ID.

**Access**: Anyone can call. The NFT is minted to `msg.sender`.

**Events emitted**: `Registered(uint256 indexed agentId, string agentURI, address indexed owner)`

### setAgentURI

Updates the URI for an existing agent.

```solidity
function setAgentURI(uint256 agentId, string calldata newURI) external
```

| Parameter | Type | Description |
|---|---|---|
| `agentId` | `uint256` | The agent's token ID |
| `newURI` | `string` | The new URI to set |

**Access**: Only the NFT owner of `agentId`.

**Events emitted**: `URIUpdated(uint256 indexed agentId, string newURI, address indexed updatedBy)`

### tokenURI

Returns the current URI for an agent.

```solidity
function tokenURI(uint256 tokenId) external view returns (string memory)
```

| Parameter | Type | Description |
|---|---|---|
| `tokenId` | `uint256` | The agent's token ID |

**Returns**: `string` -- The agent's current URI.

### ownerOf

Returns the owner address of the agent NFT.

```solidity
function ownerOf(uint256 tokenId) external view returns (address)
```

| Parameter | Type | Description |
|---|---|---|
| `tokenId` | `uint256` | The agent's token ID |

**Returns**: `address` -- The NFT owner's address.

### setMetadata

Stores arbitrary metadata for an agent.

```solidity
function setMetadata(uint256 agentId, string calldata metadataKey, bytes calldata metadataValue) external
```

| Parameter | Type | Description |
|---|---|---|
| `agentId` | `uint256` | The agent's token ID |
| `metadataKey` | `string` | The metadata key (e.g., "model", "version") |
| `metadataValue` | `bytes` | The metadata value as raw bytes |

**Access**: Only the NFT owner of `agentId`.

**Example**:
```typescript
const encoder = new TextEncoder();
await identityRegistry.setMetadata(
  agentId,
  "model",
  encoder.encode("gpt-4-turbo")
);
```

### getMetadata

Retrieves metadata for an agent by key.

```solidity
function getMetadata(uint256 agentId, string calldata metadataKey) external view returns (bytes memory)
```

| Parameter | Type | Description |
|---|---|---|
| `agentId` | `uint256` | The agent's token ID |
| `metadataKey` | `string` | The metadata key to look up |

**Returns**: `bytes` -- The stored metadata value.

### setAgentWallet

Links an external wallet to the agent. Requires an EIP-712 signature from the new wallet.

```solidity
function setAgentWallet(uint256 agentId, address newWallet, uint256 deadline, bytes calldata signature) external
```

| Parameter | Type | Description |
|---|---|---|
| `agentId` | `uint256` | The agent's token ID |
| `newWallet` | `address` | The wallet address to link |
| `deadline` | `uint256` | Unix timestamp after which the signature expires |
| `signature` | `bytes` | EIP-712 signature from `newWallet` |

**Access**: Only the NFT owner of `agentId`. The signature must be from `newWallet`.

### getAgentWallet

Returns the linked wallet for an agent.

```solidity
function getAgentWallet(uint256 agentId) external view returns (address)
```

**Returns**: `address` -- The linked wallet address (or `address(0)` if none set).

### getVersion

Returns the contract version string.

```solidity
function getVersion() external pure returns (string memory)
```

**Returns**: `string` -- The version (e.g., "1.0.0").

---

## Reputation Registry (IReputationRegistry)

**Address**: `0x8004B5118Ee0495fBBFB889882503dd4a20e5444`

### giveFeedback

Submits feedback for an agent.

```solidity
function giveFeedback(
    uint256 agentId,
    int128 value,
    uint8 valueDecimals,
    string calldata tag1,
    string calldata tag2,
    string calldata endpoint,
    string calldata feedbackURI,
    bytes32 feedbackHash
) external
```

| Parameter | Type | Description |
|---|---|---|
| `agentId` | `uint256` | The agent to give feedback to |
| `value` | `int128` | The feedback value (positive or negative) |
| `valueDecimals` | `uint8` | Number of decimal places for `value` |
| `tag1` | `string` | Primary tag (indexed on-chain for filtering) |
| `tag2` | `string` | Secondary tag (not indexed) |
| `endpoint` | `string` | The endpoint that was tested/used |
| `feedbackURI` | `string` | URI to off-chain feedback details |
| `feedbackHash` | `bytes32` | Hash of the off-chain feedback data |

**Access**: Anyone EXCEPT the NFT owner of the agent.

**Events emitted**: `NewFeedback(uint256 indexed agentId, address indexed clientAddress, uint64 feedbackIndex, int128 value, uint8 valueDecimals, string indexed indexedTag1, string tag1, string tag2, string endpoint, string feedbackURI, bytes32 feedbackHash)`

**Example**:
```typescript
await reputationRegistry.giveFeedback(
  1,          // agentId
  95,         // value (95 out of 100)
  0,          // valueDecimals
  "starred",  // tag1
  "",         // tag2
  "https://agent.example.com/api",  // endpoint
  "ipfs://QmFeedback...",           // feedbackURI
  feedbackHash                      // bytes32 hash
);
```

### revokeFeedback

Revokes previously given feedback.

```solidity
function revokeFeedback(uint256 agentId, uint64 feedbackIndex) external
```

| Parameter | Type | Description |
|---|---|---|
| `agentId` | `uint256` | The agent the feedback was given to |
| `feedbackIndex` | `uint64` | The index of the feedback to revoke |

**Access**: Only the original feedback author (`msg.sender` must match the client address).

**Events emitted**: `FeedbackRevoked(uint256 indexed agentId, address indexed clientAddress, uint64 feedbackIndex)`

### appendResponse

Allows the agent owner to respond to feedback.

```solidity
function appendResponse(
    uint256 agentId,
    address clientAddress,
    uint64 feedbackIndex,
    string calldata responseURI,
    bytes32 responseHash
) external
```

| Parameter | Type | Description |
|---|---|---|
| `agentId` | `uint256` | The agent ID |
| `clientAddress` | `address` | The address that left the feedback |
| `feedbackIndex` | `uint64` | The feedback index to respond to |
| `responseURI` | `string` | URI to the response details |
| `responseHash` | `bytes32` | Hash of the response data |

**Access**: Only the NFT owner of `agentId`.

### readFeedback

Reads a single feedback entry.

```solidity
function readFeedback(
    uint256 agentId,
    address clientAddress,
    uint64 feedbackIndex
) external view returns (
    int128 value,
    uint8 valueDecimals,
    string memory tag1,
    string memory tag2,
    bool isRevoked
)
```

### readAllFeedback

Reads all feedback matching filter criteria.

```solidity
function readAllFeedback(
    uint256 agentId,
    address[] calldata clientAddresses,
    string calldata tag1,
    string calldata tag2,
    bool includeRevoked
) external view returns (
    address[] memory clients,
    uint64[] memory feedbackIndexes,
    int128[] memory values,
    uint8[] memory valueDecimals,
    string[] memory tag1s,
    string[] memory tag2s,
    bool[] memory revokedStatuses
)
```

| Parameter | Type | Description |
|---|---|---|
| `agentId` | `uint256` | The agent to query |
| `clientAddresses` | `address[]` | Filter by these clients (empty = all) |
| `tag1` | `string` | Filter by tag1 (empty = all) |
| `tag2` | `string` | Filter by tag2 (empty = all) |
| `includeRevoked` | `bool` | Whether to include revoked feedback |

### getSummary

Returns an aggregated summary of feedback.

```solidity
function getSummary(
    uint256 agentId,
    address[] calldata clientAddresses,
    string calldata tag1,
    string calldata tag2
) external view returns (
    uint64 count,
    int128 summaryValue,
    uint8 summaryValueDecimals
)
```

| Parameter | Type | Description |
|---|---|---|
| `agentId` | `uint256` | The agent to query |
| `clientAddresses` | `address[]` | Filter by these clients (empty = all clients) |
| `tag1` | `string` | Filter by primary tag (empty = all) |
| `tag2` | `string` | Filter by secondary tag (empty = all) |

**Returns**:
- `count` -- Number of matching (non-revoked) feedback entries
- `summaryValue` -- Aggregated value
- `summaryValueDecimals` -- Decimal precision of `summaryValue`

**Web of Trust**: Pass specific `clientAddresses` to only consider feedback from trusted sources.

### getClients

Returns all addresses that have given feedback to an agent.

```solidity
function getClients(uint256 agentId) external view returns (address[] memory)
```

### getLastIndex

Returns the last feedback index for a specific client-agent pair.

```solidity
function getLastIndex(uint256 agentId, address clientAddress) external view returns (uint64)
```

---

## Validation Registry (IValidationRegistry)

**Address**: `0x8004C11CeD79AE1A66e121600E41DA4BEdf60888`

### validationRequest

Creates a new validation request for an agent.

```solidity
function validationRequest(
    address validatorAddress,
    uint256 agentId,
    string calldata requestURI,
    bytes32 requestHash
) external
```

| Parameter | Type | Description |
|---|---|---|
| `validatorAddress` | `address` | The address of the intended validator |
| `agentId` | `uint256` | The agent to validate |
| `requestURI` | `string` | URI to the validation request details |
| `requestHash` | `bytes32` | Hash of the request data |

**Access**: Anyone can create a validation request.

**Events emitted**: `ValidationRequested(...)`

### validationResponse

Submits a response to a validation request.

```solidity
function validationResponse(
    bytes32 requestHash,
    uint8 response,
    string calldata responseURI,
    bytes32 responseHash,
    string calldata tag
) external
```

| Parameter | Type | Description |
|---|---|---|
| `requestHash` | `bytes32` | The hash of the original request |
| `response` | `uint8` | The validation result (0-255 scale) |
| `responseURI` | `string` | URI to the response details |
| `responseHash` | `bytes32` | Hash of the response data |
| `tag` | `string` | Category tag for the validation |

**Access**: Only the designated validator (`validatorAddress` from the request).

**Events emitted**: `ValidationResponded(...)`

### getValidationStatus

Returns the current status of a validation request.

```solidity
function getValidationStatus(bytes32 requestHash) external view returns (
    address validatorAddress,
    uint256 agentId,
    uint8 response,
    bytes32 responseHash,
    string memory tag,
    uint256 lastUpdate
)
```

### getSummary

Returns an aggregated summary of validations for an agent.

```solidity
function getSummary(
    uint256 agentId,
    address[] calldata validatorAddresses,
    string calldata tag
) external view returns (
    uint64 count,
    uint8 avgResponse
)
```

| Parameter | Type | Description |
|---|---|---|
| `agentId` | `uint256` | The agent to query |
| `validatorAddresses` | `address[]` | Filter by validators (empty = all) |
| `tag` | `string` | Filter by tag (empty = all) |

### getAgentValidations

Returns all validation request hashes for an agent.

```solidity
function getAgentValidations(uint256 agentId) external view returns (bytes32[] memory)
```

### getValidatorRequests

Returns all validation request hashes assigned to a validator.

```solidity
function getValidatorRequests(address validatorAddress) external view returns (bytes32[] memory)
```

---

## Events Reference

### Identity Registry Events

| Event | Parameters | Description |
|---|---|---|
| `Registered` | `agentId (indexed)`, `agentURI`, `owner (indexed)` | Emitted when a new agent is registered |
| `URIUpdated` | `agentId (indexed)`, `newURI`, `updatedBy (indexed)` | Emitted when an agent URI is updated |

### Reputation Registry Events

| Event | Parameters | Description |
|---|---|---|
| `NewFeedback` | `agentId (indexed)`, `clientAddress (indexed)`, `feedbackIndex`, `value`, `valueDecimals`, `indexedTag1 (indexed)`, `tag1`, `tag2`, `endpoint`, `feedbackURI`, `feedbackHash` | Emitted when new feedback is submitted |
| `FeedbackRevoked` | `agentId (indexed)`, `clientAddress (indexed)`, `feedbackIndex` | Emitted when feedback is revoked |

### Validation Registry Events

| Event | Parameters | Description |
|---|---|---|
| `ValidationRequested` | `requestHash`, `validatorAddress`, `agentId`, `requestURI`, `requestHash` | Emitted when a validation is requested |
| `ValidationResponded` | `requestHash`, `response`, `responseURI`, `responseHash`, `tag` | Emitted when a validator responds |

---

## Error Codes

| Error | Registry | Description |
|---|---|---|
| `NotOwner` | Identity | Caller is not the NFT owner |
| `InvalidSignature` | Identity | EIP-712 signature verification failed |
| `DeadlineExpired` | Identity | Signature deadline has passed |
| `AgentNotFound` | All | Agent ID does not exist |
| `SelfFeedback` | Reputation | Agent owner cannot give self-feedback |
| `NotFeedbackAuthor` | Reputation | Only the original author can revoke |
| `AlreadyRevoked` | Reputation | Feedback was already revoked |
| `NotValidator` | Validation | Caller is not the designated validator |
| `AlreadyResponded` | Validation | Validation already has a response |

---

*For the complete specification, see [specification.md](./specification.md).*
