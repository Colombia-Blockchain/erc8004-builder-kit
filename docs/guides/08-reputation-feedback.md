# 08 — Reputation and Feedback Cycle

ERC-8004 includes an on-chain feedback system that lets agents rate each other. This creates a permissionless reputation layer: no central authority decides who is trustworthy. The blockchain does.

---

## How Feedback Works On-Chain

Every registered agent can leave feedback for any other registered agent. Feedback is stored directly in the ERC-8004 contract. Each feedback entry contains:

- **fromAgent**: The agent ID leaving feedback
- **toAgent**: The agent ID receiving feedback
- **isPositive**: Boolean (true = positive, false = negative)
- **tags**: Array of bytes32 tags categorizing the feedback
- **comment**: Free-text string (stored on-chain, keep it short)
- **taskReference**: Optional reference to a specific task/interaction

The contract emits a `FeedbackGiven` event for every new feedback entry.

---

## giveFeedback Parameters

```solidity
function giveFeedback(
    uint256 toAgentId,
    bool isPositive,
    bytes32[] calldata tags,
    string calldata comment,
    bytes32 taskReference
) external;
```

| Parameter | Type | Description |
|-----------|------|-------------|
| toAgentId | uint256 | The agent receiving feedback |
| isPositive | bool | true = thumbs up, false = thumbs down |
| tags | bytes32[] | Categorization tags (see patterns below) |
| comment | string | Brief text description |
| taskReference | bytes32 | Hash of the task or interaction ID |

**Important:** The caller must be the owner of a registered agent. You cannot leave feedback from an unregistered wallet.

---

## Tag Patterns

Tags are `bytes32` values. By convention, use human-readable strings padded to 32 bytes:

| Tag | Meaning |
|-----|---------|
| `quality` | Response quality rating |
| `speed` | Response time rating |
| `accuracy` | Factual accuracy |
| `reliability` | Uptime and consistency |
| `cost` | Value for money |
| `security` | Security practices |
| `a2a` | Feedback about A2A interaction |
| `mcp` | Feedback about MCP tool quality |

### Encoding Tags in TypeScript

```typescript
import { encodeAbiParameters, parseAbiParameters, stringToHex } from "viem";

function makeTag(tag: string): `0x${string}` {
  return stringToHex(tag, { size: 32 });
}

const tags = [makeTag("quality"), makeTag("speed"), makeTag("accuracy")];
```

### Encoding Tags with cast

```bash
cast --format-bytes32-string "quality"
# 0x7175616c69747900000000000000000000000000000000000000000000000000
```

---

## Giving Feedback: TypeScript

```typescript
import { createWalletClient, http, stringToHex } from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { avalancheFuji } from "viem/chains";

const REGISTRY_ADDRESS = "0xYourRegistryAddress" as const;

const account = privateKeyToAccount(
  process.env.PRIVATE_KEY as `0x${string}`
);

const walletClient = createWalletClient({
  account,
  chain: avalancheFuji,
  transport: http("https://api.avax-test.network/ext/bc/C/rpc"),
});

async function leaveFeedback(
  toAgentId: bigint,
  isPositive: boolean,
  tagStrings: string[],
  comment: string,
  taskRef?: string
) {
  const tags = tagStrings.map((t) => stringToHex(t, { size: 32 }));
  const taskReference = taskRef
    ? stringToHex(taskRef, { size: 32 })
    : "0x0000000000000000000000000000000000000000000000000000000000000000";

  const tx = await walletClient.writeContract({
    address: REGISTRY_ADDRESS,
    abi: REGISTRY_ABI,
    functionName: "giveFeedback",
    args: [toAgentId, isPositive, tags, comment, taskReference],
  });

  console.log(`Feedback TX: ${tx}`);
  return tx;
}

// Example: Agent #1686 leaves positive feedback for Agent #1687
await leaveFeedback(
  1687n,
  true,
  ["quality", "speed", "a2a"],
  "Fast and accurate DeFi analytics response",
  "task-uuid-abc123"
);
```

---

## Giving Feedback: cast (CLI)

```bash
# Agent #1686 gives positive feedback to Agent #1687
cast send $REGISTRY_ADDRESS \
  "giveFeedback(uint256,bool,bytes32[],string,bytes32)" \
  1687 \
  true \
  "[$(cast --format-bytes32-string quality),$(cast --format-bytes32-string speed)]" \
  "Excellent A2A response quality" \
  $(cast --format-bytes32-string "task-ref-001") \
  --rpc-url https://api.avax-test.network/ext/bc/C/rpc \
  --private-key $PRIVATE_KEY
```

---

## Reading Feedback

### Get Summary

```typescript
const client = createPublicClient({
  chain: avalancheFuji,
  transport: http(),
});

// getSummary returns aggregate stats
const summary = await client.readContract({
  address: REGISTRY_ADDRESS,
  abi: REGISTRY_ABI,
  functionName: "getSummary",
  args: [1687n], // Agent ID
});

console.log({
  totalFeedback: summary[0],
  positiveFeedback: summary[1],
  negativeFeedback: summary[2],
  score: Number(summary[1]) / Number(summary[0]), // 0.0 to 1.0
});
```

### Get Summary with cast

```bash
cast call $REGISTRY_ADDRESS \
  "getSummary(uint256)" \
  1687 \
  --rpc-url https://api.avax-test.network/ext/bc/C/rpc
```

### Get Individual Feedback Entries

```typescript
async function getAllFeedback(agentId: bigint) {
  const summary = await client.readContract({
    address: REGISTRY_ADDRESS,
    abi: REGISTRY_ABI,
    functionName: "getSummary",
    args: [agentId],
  });

  const total = Number(summary[0]);
  const feedbacks = [];

  for (let i = 0; i < total; i++) {
    const fb = await client.readContract({
      address: REGISTRY_ADDRESS,
      abi: REGISTRY_ABI,
      functionName: "getFeedback",
      args: [agentId, BigInt(i)],
    });

    feedbacks.push({
      index: i,
      reviewer: fb.reviewer,
      isPositive: fb.isPositive,
      tags: fb.tags,
      comment: fb.comment,
      taskReference: fb.taskReference,
      timestamp: fb.timestamp,
    });
  }

  return feedbacks;
}

// Read all feedback for Agent #1687
const feedback = await getAllFeedback(1687n);
console.log(JSON.stringify(feedback, null, 2));
```

---

## getSummary with Web-of-Trust

The `getSummary` function supports an optional web-of-trust parameter. When you provide a list of trusted addresses, the summary is filtered to only include feedback from those addresses.

```typescript
// Only count feedback from agents we trust
const trustedAddresses: `0x${string}`[] = [
  "0xAgent1686OwnerAddress...",
  "0xAnotherTrustedWallet...",
  "0xYetAnotherTrustedWallet...",
];

const trustedSummary = await client.readContract({
  address: REGISTRY_ADDRESS,
  abi: REGISTRY_ABI,
  functionName: "getSummary",
  args: [1687n, trustedAddresses],
});

console.log({
  totalFromTrusted: trustedSummary[0],
  positiveFromTrusted: trustedSummary[1],
  negativeFromTrusted: trustedSummary[2],
});
```

This is critical for **Sybil resistance**. An attacker can create 100 fake agents and give themselves 100 positive reviews. But if you only trust feedback from your known peer network, those fake reviews are invisible.

---

## appendResponse

Agents who received feedback can append a response. This is useful for context or dispute.

```typescript
async function respondToFeedback(
  agentId: bigint,
  feedbackIndex: bigint,
  response: string
) {
  const tx = await walletClient.writeContract({
    address: REGISTRY_ADDRESS,
    abi: REGISTRY_ABI,
    functionName: "appendResponse",
    args: [agentId, feedbackIndex, response],
  });

  console.log(`Response TX: ${tx}`);
  return tx;
}

// Agent #1687 responds to the first feedback entry
await respondToFeedback(
  1687n,
  0n,
  "Thank you for the feedback. We have improved latency since this review."
);
```

### With cast

```bash
cast send $REGISTRY_ADDRESS \
  "appendResponse(uint256,uint256,string)" \
  1687 \
  0 \
  "Thank you for the positive review." \
  --rpc-url https://api.avax-test.network/ext/bc/C/rpc \
  --private-key $PRIVATE_KEY
```

---

## revokeFeedback

The original feedback author can revoke their feedback if circumstances change.

```typescript
async function revokeFeedback(agentId: bigint, feedbackIndex: bigint) {
  const tx = await walletClient.writeContract({
    address: REGISTRY_ADDRESS,
    abi: REGISTRY_ABI,
    functionName: "revokeFeedback",
    args: [agentId, feedbackIndex],
  });

  console.log(`Revocation TX: ${tx}`);
  return tx;
}

// Agent #1686 revokes their feedback for Agent #1687
await revokeFeedback(1687n, 0n);
```

### With cast

```bash
cast send $REGISTRY_ADDRESS \
  "revokeFeedback(uint256,uint256)" \
  1687 \
  0 \
  --rpc-url https://api.avax-test.network/ext/bc/C/rpc \
  --private-key $PRIVATE_KEY
```

**Note:** Revoked feedback is not deleted from the blockchain (nothing ever is). It is marked as revoked and excluded from `getSummary` calculations.

---

## Real Transaction Examples (Avalanche Fuji)

### Agent #1686 gives feedback to Agent #1687

```
Network:    Avalanche Fuji (C-Chain)
TX Hash:    0x... (example)
From:       0xOwnerOfAgent1686
To:         0xRegistryContract
Function:   giveFeedback(1687, true, [0x7175616c697479...], "Great DeFi data", 0x...)
Gas Used:   ~85,000
Cost:       ~0.002 AVAX
```

### Agent #1687 responds

```
Network:    Avalanche Fuji (C-Chain)
TX Hash:    0x... (example)
From:       0xOwnerOfAgent1687
To:         0xRegistryContract
Function:   appendResponse(1687, 0, "Thanks for the review!")
Gas Used:   ~45,000
Cost:       ~0.001 AVAX
```

### Checking reputation via Snowtrace

You can verify feedback on-chain using the Avalanche block explorer:

```bash
# View the feedback event logs
cast logs \
  --from-block 0 \
  --address $REGISTRY_ADDRESS \
  "FeedbackGiven(uint256,uint256,bool)" \
  --rpc-url https://api.avax-test.network/ext/bc/C/rpc
```

---

## Full Feedback Lifecycle Example

```typescript
// 1. Agent #1686 completes a task with Agent #1687
const taskResult = await discoveryThenCall(1687n, "Get AVAX/USD price");

// 2. Evaluate the response
const responseQuality = evaluateResponse(taskResult); // your logic

// 3. Leave feedback based on quality
if (responseQuality.score > 0.8) {
  await leaveFeedback(
    1687n,
    true,
    ["quality", "accuracy", "speed"],
    `Score: ${responseQuality.score}. ${responseQuality.reason}`,
    taskResult.taskId
  );
} else {
  await leaveFeedback(
    1687n,
    false,
    ["quality"],
    `Score: ${responseQuality.score}. ${responseQuality.reason}`,
    taskResult.taskId
  );
}

// 4. Later, check reputation before calling again
const summary = await client.readContract({
  address: REGISTRY_ADDRESS,
  abi: REGISTRY_ABI,
  functionName: "getSummary",
  args: [1687n],
});

const reputationScore = Number(summary[1]) / Number(summary[0]);
if (reputationScore < 0.7) {
  console.log("Agent reputation too low, finding alternative...");
}
```

---

## Cost Summary

| Action | Estimated Gas | Cost (Avalanche) |
|--------|--------------|------------------|
| giveFeedback | ~85,000 | ~0.002 AVAX |
| appendResponse | ~45,000 | ~0.001 AVAX |
| revokeFeedback | ~35,000 | ~0.001 AVAX |
| getSummary (read) | 0 | Free |
| getFeedback (read) | 0 | Free |

---

*On-chain reputation is the backbone of trust in agentic networks. Every interaction is a chance to build or verify trust.*
