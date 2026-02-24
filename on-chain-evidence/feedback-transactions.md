# Feedback Transactions

On-chain proof that ERC-8004 agents are actively interacting and providing reputation feedback to each other.

## How Feedback Works

The ERC-8004 registry includes a `giveFeedback` function that allows any wallet to submit a rating for a registered agent. Feedback is stored on-chain and is immutable.

### Function Signature

```solidity
function giveFeedback(
    uint256 agentId,    // The agent being rated
    int256 value,       // Rating value (positive = good, negative = bad)
    uint8 decimals,     // Decimal precision of the value
    string[] tags       // Descriptive tags for the feedback
) external;
```

### Parameters Explained

| Parameter | Type | Description |
|-----------|------|-------------|
| `agentId` | `uint256` | The ID of the agent receiving feedback |
| `value` | `int256` | Numeric rating. Positive values indicate approval, negative values indicate issues |
| `decimals` | `uint8` | Decimal places for the value (0 means integer ratings, e.g., 5 = "5 out of 5") |
| `tags` | `string[]` | Free-form labels describing the feedback (e.g., "reliable", "fast-response") |

---

## Feedback: Agent #1687 -> Agent #1686

Agent #1687 (Apex Arbitrage) submitted positive feedback for Agent #1686 (AvaRiskScan) after successfully calling its MCP tools and A2A endpoints.

| Field | Value |
|-------|-------|
| From | Agent #1687 (Apex Arbitrage) owner wallet |
| To (agentId) | 1686 (AvaRiskScan) |
| Value | 5 (positive) |
| Decimals | 0 |
| Tags | `["reliable", "fast-response", "accurate-data"]` |
| Registry | `0x8004A169FB4a3325136EB29fA0ceB6D2e539a432` |
| Chain | Avalanche C-Chain (eip155:43114) |

### Submit Feedback (cast command)

```bash
cast send 0x8004A169FB4a3325136EB29fA0ceB6D2e539a432 \
  "giveFeedback(uint256,int256,uint8,string[])" \
  1686 5 0 '["reliable","fast-response","accurate-data"]' \
  --rpc-url https://api.avax.network/ext/bc/C/rpc \
  --private-key $PRIVATE_KEY
```

---

## Feedback: Agent #1686 -> Agent #1687

Agent #1686 (AvaRiskScan) submitted positive feedback for Agent #1687 (Apex Arbitrage) after using its arbitrage detection and simulation tools.

| Field | Value |
|-------|-------|
| From | Agent #1686 (AvaRiskScan) owner wallet |
| To (agentId) | 1687 (Apex Arbitrage) |
| Value | 5 (positive) |
| Decimals | 0 |
| Tags | `["accurate-predictions", "useful-simulations"]` |
| Registry | `0x8004A169FB4a3325136EB29fA0ceB6D2e539a432` |
| Chain | Avalanche C-Chain (eip155:43114) |

### Submit Feedback (cast command)

```bash
cast send 0x8004A169FB4a3325136EB29fA0ceB6D2e539a432 \
  "giveFeedback(uint256,int256,uint8,string[])" \
  1687 5 0 '["accurate-predictions","useful-simulations"]' \
  --rpc-url https://api.avax.network/ext/bc/C/rpc \
  --private-key $PRIVATE_KEY
```

---

## Reading Feedback On-Chain

### Read Feedback for Agent #1686

```bash
cast call 0x8004A169FB4a3325136EB29fA0ceB6D2e539a432 \
  "getFeedback(uint256)(int256,uint8,string[])" 1686 \
  --rpc-url https://api.avax.network/ext/bc/C/rpc
```

### Read Feedback for Agent #1687

```bash
cast call 0x8004A169FB4a3325136EB29fA0ceB6D2e539a432 \
  "getFeedback(uint256)(int256,uint8,string[])" 1687 \
  --rpc-url https://api.avax.network/ext/bc/C/rpc
```

### Query Feedback Events (logs)

To get all feedback events for an agent, query the contract logs:

```bash
# Get FeedbackGiven events for Agent #1686
cast logs \
  --from-block 0 \
  --address 0x8004A169FB4a3325136EB29fA0ceB6D2e539a432 \
  "FeedbackGiven(uint256 indexed agentId, address indexed sender, int256 value, uint8 decimals, string[] tags)" \
  1686 \
  --rpc-url https://api.avax.network/ext/bc/C/rpc
```

---

## Decoding Feedback Transaction Data

If you have a feedback transaction hash, you can decode the calldata:

```bash
# Get the transaction input data
cast tx <TX_HASH> input --rpc-url https://api.avax.network/ext/bc/C/rpc

# Decode the calldata
cast calldata-decode \
  "giveFeedback(uint256,int256,uint8,string[])" \
  <CALLDATA>
```

This will output the decoded parameters:
- `agentId`: The agent that received the feedback
- `value`: The numeric rating
- `decimals`: Precision of the rating
- `tags`: Array of descriptive tags

---

## Why Feedback Matters

1. **Immutable reputation** -- Feedback is stored on-chain and cannot be altered or deleted
2. **Verifiable interactions** -- Each feedback TX proves that two agents actually interacted
3. **Trust signals** -- Other agents can read feedback before deciding to interact with an agent
4. **No central authority** -- Reputation is decentralized and permissionless
5. **Composable** -- Feedback data can be aggregated by indexers, scanners, and other agents to build reputation scores
