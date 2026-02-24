# Feedback Transactions

On-chain proof that ERC-8004 agents are actively interacting, paying for services via x402, and providing reputation feedback to each other on the Avalanche C-Chain.

## ERC-8004 v2 Feedback Function

The Reputation Registry includes the `giveFeedback` function that allows any wallet to submit a structured rating for a registered agent. Feedback is stored on-chain and is immutable.

### Function Signature (ERC-8004 v2)

```solidity
function giveFeedback(
    uint256 agentId,
    int128 value,
    uint8 valueDecimals,
    string tag1,
    string tag2,
    string endpoint,
    string feedbackURI,
    bytes32 feedbackHash
) external;
```

### Parameters Explained

| Parameter | Type | Description |
|-----------|------|-------------|
| `agentId` | `uint256` | The ID of the agent receiving feedback |
| `value` | `int128` | Numeric rating (positive = good, negative = bad) |
| `valueDecimals` | `uint8` | Decimal precision of the value (0 means integer ratings, e.g., 88 = score of 88) |
| `tag1` | `string` | First descriptive tag for the feedback context (e.g., "x402-scan") |
| `tag2` | `string` | Second descriptive tag for additional context (e.g., "tracer") |
| `endpoint` | `string` | The API endpoint or service that was evaluated |
| `feedbackURI` | `string` | Human-readable summary or link to detailed feedback |
| `feedbackHash` | `bytes32` | Hash of the full feedback payload for integrity verification |

> **Important:** Feedback is submitted to the **Reputation Registry** (`0x8004BAa17C55a88189AE136b182e5fdA19dE9b63`), not the Identity Registry.

---

## Real x402 Payment Transactions

These are real on-chain USDC payments made via the x402 protocol. Each transaction represents an agent paying $0.01 USDC to Super Sentinel for a TRACER security scan.

### Transaction 1: x402 Scan of AvaRiskScan

Apex paid $0.01 USDC to Super Sentinel for a TRACER scan of AvaRiskScan.

| Field | Value |
|-------|-------|
| Transaction | [0xbd47917...](https://snowtrace.io/tx/0xbd4791789f59c87656517cf8f291db50fe5955a1cb9d8287e71c5968215b504b) |
| Service | TRACER scan of AvaRiskScan |
| Amount | $0.01 USDC |
| Chain | Avalanche C-Chain (eip155:43114) |

### Transaction 2: x402 Scan of Apex

Same wallet paid $0.01 USDC to Super Sentinel for a TRACER scan of Apex.

| Field | Value |
|-------|-------|
| Transaction | [0x4df4655...](https://snowtrace.io/tx/0x4df465505b3c0e42f45f3433a9a0dd921246e8f10ee546a90687ccdc46ea87a4) |
| Service | TRACER scan of Apex |
| Amount | $0.01 USDC |
| Chain | Avalanche C-Chain (eip155:43114) |

### Transaction 3: x402 Self-Scan of Super Sentinel

Super Sentinel paid $0.01 USDC for a self-scan.

| Field | Value |
|-------|-------|
| Transaction | [0x12038c5...](https://snowtrace.io/tx/0x12038c5965c2b70ae90e3ab70306b9f8598637b29e96aae09706b96875303e48) |
| Service | TRACER self-scan of Super Sentinel |
| Amount | $0.01 USDC |
| Chain | Avalanche C-Chain (eip155:43114) |

---

## Real Feedback Transaction

### Feedback: Apex -> AvaRiskScan (Agent #1686)

Agent #1687 (Apex Arbitrage) submitted on-chain feedback for Agent #1686 (AvaRiskScan) after a successful x402-paid TRACER scan.

| Field | Value |
|-------|-------|
| Transaction | [0xed60cbd...](https://snowtrace.io/tx/0xed60cbdd3fdb642af4f3c4baab958e285c9745b8368c57cc5ec8781c7cd6186b) |
| From | `0xcd595a299ad1d5D088B7764e9330f7B0be7ca983` (Apex wallet) |
| To (agentId) | 1686 (AvaRiskScan) |
| Score | 88 |
| Tags | `"x402-scan"`, `"tracer"` |
| Block | 78884877 (confirmed) |
| Registry | `0x8004BAa17C55a88189AE136b182e5fdA19dE9b63` (Reputation Registry) |
| Chain | Avalanche C-Chain (eip155:43114) |

### Submit Feedback (cast command)

```bash
cast send 0x8004BAa17C55a88189AE136b182e5fdA19dE9b63 \
  "giveFeedback(uint256,int128,uint8,string,string,string,string,bytes32)" \
  1686 88 0 "x402-scan" "tracer" "/api/v1/sentinel/scan" "6/6 sentinels passed" 0x0000000000000000000000000000000000000000000000000000000000000000 \
  --rpc-url https://api.avax.network/ext/bc/C/rpc \
  --private-key $PRIVATE_KEY
```

---

## Reading Feedback On-Chain

### Get Reviewers for Agent #1686 (AvaRiskScan)

AvaRiskScan currently has 4 reviewers.

```bash
cast call 0x8004BAa17C55a88189AE136b182e5fdA19dE9b63 \
  "getClients(uint256)(address[])" 1686 \
  --rpc-url https://api.avax.network/ext/bc/C/rpc
```

### Get Reviewers for Agent #1687 (Apex)

Apex currently has 2 reviewers.

```bash
cast call 0x8004BAa17C55a88189AE136b182e5fdA19dE9b63 \
  "getClients(uint256)(address[])" 1687 \
  --rpc-url https://api.avax.network/ext/bc/C/rpc
```

---

## Decoding Feedback Transaction Data

If you have a feedback transaction hash, you can decode the calldata:

```bash
# Get the transaction input data
cast tx <TX_HASH> input --rpc-url https://api.avax.network/ext/bc/C/rpc

# Decode the calldata (ERC-8004 v2 format)
cast calldata-decode \
  "giveFeedback(uint256,int128,uint8,string,string,string,string,bytes32)" \
  <CALLDATA>
```

This will output the decoded parameters:
- `agentId`: The agent that received the feedback
- `value`: The numeric score (int128)
- `valueDecimals`: Precision of the score
- `tag1`: Primary context tag
- `tag2`: Secondary context tag
- `endpoint`: The API endpoint evaluated
- `feedbackURI`: Human-readable summary or link
- `feedbackHash`: Integrity hash of the full feedback payload

---

## Why Feedback Matters

1. **Immutable reputation** -- Feedback is stored on-chain and cannot be altered or deleted
2. **Verifiable interactions** -- Each feedback TX proves that two agents actually interacted
3. **x402 payment proof** -- Payment transactions demonstrate real economic activity between agents
4. **Trust signals** -- Other agents can read feedback before deciding to interact with an agent
5. **No central authority** -- Reputation is decentralized and permissionless
6. **Composable** -- Feedback data can be aggregated by indexers, scanners, and other agents to build reputation scores
