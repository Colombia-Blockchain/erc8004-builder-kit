# 11 — Validation Registry Guide

Validation answers a simple question: **"Did this agent actually do what it claims?"**

Any agent can register on ERC-8004 and claim to be a DeFi oracle. Validation is how the network verifies those claims. It is the difference between "trust me" and "verify me."

---

## What is Validation?

Validation is an on-chain mechanism where one agent (or a specialized validator) verifies the output of another agent. The result is stored in the ERC-8004 Validation Registry, creating a permanent, queryable record of verified (or failed) validations.

```
Agent A produces output → Validator checks output → Result stored on-chain
```

The Validation Registry is a separate contract (or module within ERC-8004) that tracks:

- **requestId**: Unique identifier for the validation request
- **agentId**: The agent being validated
- **validatorId**: The agent or entity performing validation
- **method**: Which validation method was used
- **status**: pending, passed, failed, expired
- **evidence**: Hash of the validation proof
- **timestamp**: When the validation occurred

---

## The 4 Validation Methods

### 1. Re-Execution Validation

The simplest method. A validator re-runs the same task and compares outputs.

```
Original:  "What is AVAX price?" → Agent A → "$35.42"
Validator: "What is AVAX price?" → Agent B → "$35.41"
Result:    Outputs match within tolerance → PASSED
```

**Pros:** Easy to implement, no special infrastructure.
**Cons:** Non-deterministic outputs (LLM responses) may differ. Works best for factual queries.

**When to use:** Price feeds, factual lookups, deterministic computations.

### 2. Stake-Secured Validation

The validator stakes tokens as collateral. If their validation is later proven wrong, they lose their stake.

```
Validator stakes 100 USDC → Validates Agent A → If challenged and wrong → loses stake
```

**Pros:** Economic incentive for honest validation.
**Cons:** Requires staking infrastructure and dispute resolution.

**When to use:** High-value transactions, financial data, anything where accuracy has monetary consequences.

### 3. zkML Validation (Zero-Knowledge Machine Learning)

The agent produces a zero-knowledge proof that its ML model ran correctly on the given input. The validator verifies the proof without re-running the model.

```
Agent runs model → produces output + zk proof
Validator verifies proof → PASSED (without seeing model weights)
```

**Pros:** Cryptographically verifiable. Model privacy preserved.
**Cons:** Requires zkML tooling (e.g., EZKL, Modulus). Computationally expensive to generate proofs.

**When to use:** When model integrity matters, regulated environments, privacy-sensitive applications.

### 4. TEE Attestation (Trusted Execution Environment)

The agent runs inside a TEE (e.g., Intel SGX, AWS Nitro Enclaves). The TEE produces an attestation that the code ran unmodified in a secure environment.

```
Agent runs in TEE → TEE produces attestation
Validator verifies attestation signature → PASSED
```

**Pros:** Hardware-level security guarantee.
**Cons:** Requires TEE infrastructure. Limited to supported hardware.

**When to use:** High-security applications, financial compliance, when code integrity must be proven.

---

## Requesting Validation

### TypeScript: Request Validation

```typescript
import { createWalletClient, http, stringToHex } from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { avalancheFuji } from "viem/chains";

const VALIDATION_REGISTRY = "0xValidationRegistryAddress" as `0x${string}`;

const account = privateKeyToAccount(
  process.env.PRIVATE_KEY as `0x${string}`
);

const walletClient = createWalletClient({
  account,
  chain: avalancheFuji,
  transport: http("https://api.avax-test.network/ext/bc/C/rpc"),
});

// Validation method constants
const METHODS = {
  RE_EXECUTION: 0,
  STAKE_SECURED: 1,
  ZKML: 2,
  TEE_ATTESTATION: 3,
} as const;

async function requestValidation(
  agentId: bigint,
  method: number,
  taskData: string,
  expectedOutput: string
) {
  const taskHash = stringToHex(taskData, { size: 32 });
  const outputHash = stringToHex(expectedOutput, { size: 32 });

  const tx = await walletClient.writeContract({
    address: VALIDATION_REGISTRY,
    abi: VALIDATION_ABI,
    functionName: "requestValidation",
    args: [agentId, method, taskHash, outputHash],
  });

  console.log(`Validation request TX: ${tx}`);
  return tx;
}

// Example: Request re-execution validation for Agent #1687
await requestValidation(
  1687n,
  METHODS.RE_EXECUTION,
  "What is the current AVAX/USD price?",
  "35.42"
);
```

### cast: Request Validation

```bash
cast send $VALIDATION_REGISTRY \
  "requestValidation(uint256,uint8,bytes32,bytes32)" \
  1687 \
  0 \
  $(cast --format-bytes32-string "avax-price-query") \
  $(cast --format-bytes32-string "35.42") \
  --rpc-url https://api.avax-test.network/ext/bc/C/rpc \
  --private-key $PRIVATE_KEY
```

---

## Responding to Validation Requests

If your agent is asked to serve as a validator, you respond with your findings.

### TypeScript: Submit Validation Response

```typescript
async function submitValidation(
  requestId: bigint,
  passed: boolean,
  evidence: `0x${string}`,
  comment: string
) {
  const tx = await walletClient.writeContract({
    address: VALIDATION_REGISTRY,
    abi: VALIDATION_ABI,
    functionName: "submitValidation",
    args: [requestId, passed, evidence, comment],
  });

  console.log(`Validation response TX: ${tx}`);
  return tx;
}

// Validator confirms the output is correct
await submitValidation(
  1n, // requestId
  true, // passed
  "0xEvidenceHashHere..." as `0x${string}`,
  "Re-executed query. Output matches within 0.1% tolerance."
);
```

### cast: Submit Validation Response

```bash
cast send $VALIDATION_REGISTRY \
  "submitValidation(uint256,bool,bytes32,string)" \
  1 \
  true \
  0x0000000000000000000000000000000000000000000000000000000000000001 \
  "Output verified via re-execution" \
  --rpc-url https://api.avax-test.network/ext/bc/C/rpc \
  --private-key $PRIVATE_KEY
```

---

## Implementing a Re-Execution Validator

A complete example of a validator agent that re-executes tasks to verify outputs.

```typescript
import { createPublicClient, createWalletClient, http } from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { avalancheFuji } from "viem/chains";

const account = privateKeyToAccount(
  process.env.PRIVATE_KEY as `0x${string}`
);

const publicClient = createPublicClient({
  chain: avalancheFuji,
  transport: http(),
});

const walletClient = createWalletClient({
  account,
  chain: avalancheFuji,
  transport: http(),
});

async function reExecutionValidator(requestId: bigint) {
  // 1. Read the validation request
  const request = await publicClient.readContract({
    address: VALIDATION_REGISTRY,
    abi: VALIDATION_ABI,
    functionName: "getValidationRequest",
    args: [requestId],
  });

  const { agentId, taskHash, outputHash } = request;

  // 2. Get the agent's endpoint
  const agent = await publicClient.readContract({
    address: REGISTRY_ADDRESS,
    abi: REGISTRY_ABI,
    functionName: "getAgent",
    args: [agentId],
  });

  const reg = await (await fetch(agent.metadataURI)).json();
  const a2aEndpoint = reg.services.find(
    (s: any) => s.name === "A2A"
  )?.endpoint;

  // 3. Re-execute the same task
  const result = await fetch(a2aEndpoint, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      jsonrpc: "2.0",
      method: "tasks/send",
      params: {
        id: crypto.randomUUID(),
        message: {
          role: "user",
          parts: [{ type: "text", text: "What is the current AVAX/USD price?" }],
        },
      },
    }),
  });

  const response = await result.json();
  const agentOutput = response.result?.history?.[0]?.parts?.[0]?.text ?? "";

  // 4. Compare outputs (with tolerance for numeric values)
  const originalValue = parseFloat(outputHash.toString());
  const newValue = parseFloat(agentOutput);
  const tolerance = 0.01; // 1% tolerance

  const passed =
    Math.abs(originalValue - newValue) / originalValue <= tolerance;

  // 5. Submit validation result
  const evidence = stringToHex(
    JSON.stringify({
      method: "re-execution",
      originalOutput: outputHash,
      newOutput: agentOutput,
      tolerance,
      timestamp: new Date().toISOString(),
    }),
    { size: 32 }
  );

  await submitValidation(
    requestId,
    passed,
    evidence,
    passed
      ? `Re-execution matched within ${tolerance * 100}% tolerance`
      : `Re-execution mismatch: expected ~${originalValue}, got ${newValue}`
  );
}
```

---

## Implementing a Stake-Secured Validator

```typescript
async function stakeSecuredValidation(
  requestId: bigint,
  stakeAmount: bigint
) {
  // 1. Approve stake token
  const approveTx = await walletClient.writeContract({
    address: USDC_ADDRESS,
    abi: ERC20_ABI,
    functionName: "approve",
    args: [VALIDATION_REGISTRY, stakeAmount],
  });
  console.log(`Stake approved: ${approveTx}`);

  // 2. Submit validation with stake
  const tx = await walletClient.writeContract({
    address: VALIDATION_REGISTRY,
    abi: VALIDATION_ABI,
    functionName: "submitStakedValidation",
    args: [
      requestId,
      true, // passed
      stakeAmount,
      "0x..." as `0x${string}`, // evidence
      "Validated with 100 USDC stake",
    ],
  });

  console.log(`Staked validation TX: ${tx}`);
  return tx;
}
```

---

## Checking Validation Status

### TypeScript

```typescript
async function checkValidationStatus(requestId: bigint) {
  const status = await publicClient.readContract({
    address: VALIDATION_REGISTRY,
    abi: VALIDATION_ABI,
    functionName: "getValidationRequest",
    args: [requestId],
  });

  const STATUS_LABELS: Record<number, string> = {
    0: "pending",
    1: "passed",
    2: "failed",
    3: "expired",
    4: "disputed",
  };

  return {
    requestId: Number(requestId),
    agentId: Number(status.agentId),
    validatorId: Number(status.validatorId),
    method: status.method,
    status: STATUS_LABELS[status.status] ?? "unknown",
    evidence: status.evidence,
    timestamp: new Date(Number(status.timestamp) * 1000).toISOString(),
  };
}

// Check status
const result = await checkValidationStatus(1n);
console.log(result);
// {
//   requestId: 1,
//   agentId: 1687,
//   validatorId: 1686,
//   method: 0,
//   status: "passed",
//   evidence: "0x...",
//   timestamp: "2025-12-01T12:00:00.000Z"
// }
```

### cast

```bash
cast call $VALIDATION_REGISTRY \
  "getValidationRequest(uint256)" \
  1 \
  --rpc-url https://api.avax-test.network/ext/bc/C/rpc
```

---

## Querying Validation History for an Agent

```typescript
async function getValidationHistory(agentId: bigint) {
  const count = await publicClient.readContract({
    address: VALIDATION_REGISTRY,
    abi: VALIDATION_ABI,
    functionName: "getValidationCount",
    args: [agentId],
  });

  const validations = [];
  for (let i = 0n; i < count; i++) {
    const v = await publicClient.readContract({
      address: VALIDATION_REGISTRY,
      abi: VALIDATION_ABI,
      functionName: "getAgentValidation",
      args: [agentId, i],
    });
    validations.push(v);
  }

  const passed = validations.filter((v) => v.status === 1).length;
  const failed = validations.filter((v) => v.status === 2).length;

  return {
    agentId: Number(agentId),
    totalValidations: validations.length,
    passed,
    failed,
    passRate: validations.length > 0 ? passed / validations.length : 0,
    validations,
  };
}
```

---

## Validation in registration.json

Declare that your agent supports validation:

```json
{
  "capabilities": ["a2a", "mcp", "oasf", "validation"],
  "validation": {
    "methods": ["re-execution", "tee-attestation"],
    "autoRespond": true,
    "maxStake": "1000000000",
    "teeProvider": "aws-nitro"
  }
}
```

---

## Validation Method Comparison

| Method | Cost | Speed | Trust Level | Infrastructure |
|--------|------|-------|-------------|---------------|
| Re-Execution | Low (gas + agent call) | Fast (~seconds) | Medium | None extra |
| Stake-Secured | Medium (stake + gas) | Fast | High | Token staking |
| zkML | High (proof generation) | Slow (~minutes) | Very High | zkML toolchain |
| TEE Attestation | Medium (TEE runtime) | Fast | Very High | TEE hardware |

---

## Best Practices

1. **Start with re-execution** for development and testing.
2. **Move to stake-secured** for production financial applications.
3. **Use zkML** when you need cryptographic proof of model integrity.
4. **Use TEE** when you need proof that specific code ran unmodified.
5. **Combine methods**: Use re-execution for routine checks and stake-secured for high-value operations.
6. **Set expiration times** on validation requests to avoid stale pending requests.
7. **Monitor validation pass rates** as a signal of agent reliability (complement to feedback reputation).

---

*Validation transforms "I did the work" into "here is proof I did the work." It is the foundation of verifiable AI.*
