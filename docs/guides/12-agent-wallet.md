# 12 — setAgentWallet with EIP-712

An agent wallet is a secondary wallet that your agent uses for day-to-day operations (signing transactions, making payments, receiving funds) without exposing the owner's private key. Think of it as giving your employee a company credit card instead of your personal bank account.

---

## What Are Agent Wallets?

In ERC-8004, each agent has an **owner** (the wallet that registered it) and optionally an **agent wallet** (a separate wallet the agent controls).

```
Owner Wallet (cold storage, high security)
  └── registers Agent #1687
        └── Agent Wallet (hot wallet, used for operations)
              ├── signs A2A responses
              ├── makes x402 payments
              └── interacts with DeFi protocols
```

The owner wallet holds the registration. The agent wallet does the work.

---

## Why You Need an Agent Wallet

1. **Security isolation**: If the agent wallet is compromised, the attacker cannot deregister your agent or change its metadata. Only the owner can do that.

2. **Operational separation**: The agent runs 24/7 with the hot wallet key. The owner key stays in cold storage (hardware wallet, multisig, etc.).

3. **Permission scoping**: The agent wallet has limited authority. It can operate on behalf of the agent but cannot modify the registration.

4. **Key rotation**: If you need to rotate the agent's operational key, you call `setAgentWallet` again from the owner wallet. No re-registration needed.

5. **Compliance**: Some environments require separation of administrative and operational keys.

---

## The EIP-712 Signature Flow

`setAgentWallet` uses EIP-712 typed data signatures to prove that both the owner and the new agent wallet consent to the association. This prevents:

- Someone assigning a wallet they do not control as their agent wallet
- Replay attacks (using an old signature on a different chain or contract)

### The Flow

```
1. Owner decides to set agent wallet
2. Owner constructs EIP-712 typed data
3. Agent wallet signs the typed data (proving consent)
4. Owner calls setAgentWallet(agentId, newWallet, signature)
5. Contract verifies both the owner (msg.sender) and the agent wallet (via signature)
6. Agent wallet is now associated with the agent
```

### EIP-712 Domain

```typescript
const domain = {
  name: "ERC8004AgentRegistry",
  version: "1",
  chainId: 43113, // Avalanche Fuji
  verifyingContract: REGISTRY_ADDRESS,
};
```

### EIP-712 Types

```typescript
const types = {
  SetAgentWallet: [
    { name: "agentId", type: "uint256" },
    { name: "wallet", type: "address" },
    { name: "nonce", type: "uint256" },
  ],
};
```

### EIP-712 Message

```typescript
const message = {
  agentId: 1687n,
  wallet: "0xNewAgentWalletAddress",
  nonce: currentNonce, // from contract to prevent replay
};
```

---

## Step-by-Step: viem

### Full Implementation

```typescript
import {
  createPublicClient,
  createWalletClient,
  http,
} from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { avalancheFuji } from "viem/chains";

// --- Configuration ---

const REGISTRY_ADDRESS = "0xYourRegistryAddress" as `0x${string}`;

// Owner wallet (the one that registered the agent)
const ownerAccount = privateKeyToAccount(
  process.env.OWNER_PRIVATE_KEY as `0x${string}`
);

// Agent wallet (the new operational wallet)
const agentWalletAccount = privateKeyToAccount(
  process.env.AGENT_WALLET_PRIVATE_KEY as `0x${string}`
);

const publicClient = createPublicClient({
  chain: avalancheFuji,
  transport: http("https://api.avax-test.network/ext/bc/C/rpc"),
});

const ownerWalletClient = createWalletClient({
  account: ownerAccount,
  chain: avalancheFuji,
  transport: http("https://api.avax-test.network/ext/bc/C/rpc"),
});

const agentWalletClient = createWalletClient({
  account: agentWalletAccount,
  chain: avalancheFuji,
  transport: http("https://api.avax-test.network/ext/bc/C/rpc"),
});

// --- Step 1: Get the current nonce ---

async function setAgentWallet(agentId: bigint) {
  // The contract tracks nonces to prevent replay attacks
  const nonce = await publicClient.readContract({
    address: REGISTRY_ADDRESS,
    abi: REGISTRY_ABI,
    functionName: "getAgentWalletNonce",
    args: [agentId],
  });

  console.log(`Current nonce for agent ${agentId}: ${nonce}`);

  // --- Step 2: Agent wallet signs EIP-712 typed data ---

  const domain = {
    name: "ERC8004AgentRegistry",
    version: "1",
    chainId: 43113,
    verifyingContract: REGISTRY_ADDRESS,
  } as const;

  const types = {
    SetAgentWallet: [
      { name: "agentId", type: "uint256" },
      { name: "wallet", type: "address" },
      { name: "nonce", type: "uint256" },
    ],
  } as const;

  const message = {
    agentId,
    wallet: agentWalletAccount.address,
    nonce,
  };

  // The agent wallet signs to prove it consents to being associated
  const signature = await agentWalletClient.signTypedData({
    domain,
    types,
    primaryType: "SetAgentWallet",
    message,
  });

  console.log(`Agent wallet signature: ${signature}`);

  // --- Step 3: Owner submits the transaction ---

  const tx = await ownerWalletClient.writeContract({
    address: REGISTRY_ADDRESS,
    abi: REGISTRY_ABI,
    functionName: "setAgentWallet",
    args: [agentId, agentWalletAccount.address, signature],
  });

  console.log(`setAgentWallet TX: ${tx}`);

  // --- Step 4: Verify ---

  const agent = await publicClient.readContract({
    address: REGISTRY_ADDRESS,
    abi: REGISTRY_ABI,
    functionName: "getAgent",
    args: [agentId],
  });

  console.log(`Agent wallet is now: ${agent.agentWallet}`);
  console.log(
    `Matches expected: ${
      agent.agentWallet.toLowerCase() ===
      agentWalletAccount.address.toLowerCase()
    }`
  );

  return tx;
}

// Execute
await setAgentWallet(1687n);
```

---

## Step-by-Step: ethers.js

### Full Implementation

```typescript
import { ethers } from "ethers";

// --- Configuration ---

const REGISTRY_ADDRESS = "0xYourRegistryAddress";
const RPC_URL = "https://api.avax-test.network/ext/bc/C/rpc";

const provider = new ethers.JsonRpcProvider(RPC_URL);

// Owner wallet
const ownerWallet = new ethers.Wallet(
  process.env.OWNER_PRIVATE_KEY!,
  provider
);

// Agent wallet
const agentWallet = new ethers.Wallet(
  process.env.AGENT_WALLET_PRIVATE_KEY!,
  provider
);

const registry = new ethers.Contract(
  REGISTRY_ADDRESS,
  REGISTRY_ABI,
  ownerWallet
);

async function setAgentWalletEthers(agentId: bigint) {
  // --- Step 1: Get nonce ---

  const nonce = await registry.getAgentWalletNonce(agentId);
  console.log(`Current nonce: ${nonce}`);

  // --- Step 2: Agent wallet signs EIP-712 ---

  const domain = {
    name: "ERC8004AgentRegistry",
    version: "1",
    chainId: 43113,
    verifyingContract: REGISTRY_ADDRESS,
  };

  const types = {
    SetAgentWallet: [
      { name: "agentId", type: "uint256" },
      { name: "wallet", type: "address" },
      { name: "nonce", type: "uint256" },
    ],
  };

  const message = {
    agentId: agentId,
    wallet: agentWallet.address,
    nonce: nonce,
  };

  const signature = await agentWallet.signTypedData(
    domain,
    types,
    message
  );

  console.log(`Signature: ${signature}`);

  // --- Step 3: Owner submits ---

  const tx = await registry.setAgentWallet(
    agentId,
    agentWallet.address,
    signature
  );

  console.log(`TX hash: ${tx.hash}`);

  const receipt = await tx.wait();
  console.log(`Confirmed in block: ${receipt.blockNumber}`);

  // --- Step 4: Verify ---

  const agent = await registry.getAgent(agentId);
  console.log(`Agent wallet: ${agent.agentWallet}`);

  return tx.hash;
}

// Execute
await setAgentWalletEthers(1687n);
```

---

## Rotating the Agent Wallet

To change the agent wallet, repeat the process with the new wallet.

```typescript
async function rotateAgentWallet(
  agentId: bigint,
  newAgentWalletPrivateKey: `0x${string}`
) {
  const newAgentWalletAccount = privateKeyToAccount(newAgentWalletPrivateKey);

  const nonce = await publicClient.readContract({
    address: REGISTRY_ADDRESS,
    abi: REGISTRY_ABI,
    functionName: "getAgentWalletNonce",
    args: [agentId],
  });

  const newAgentWalletClient = createWalletClient({
    account: newAgentWalletAccount,
    chain: avalancheFuji,
    transport: http("https://api.avax-test.network/ext/bc/C/rpc"),
  });

  const signature = await newAgentWalletClient.signTypedData({
    domain: {
      name: "ERC8004AgentRegistry",
      version: "1",
      chainId: 43113,
      verifyingContract: REGISTRY_ADDRESS,
    },
    types: {
      SetAgentWallet: [
        { name: "agentId", type: "uint256" },
        { name: "wallet", type: "address" },
        { name: "nonce", type: "uint256" },
      ],
    },
    primaryType: "SetAgentWallet",
    message: {
      agentId,
      wallet: newAgentWalletAccount.address,
      nonce,
    },
  });

  const tx = await ownerWalletClient.writeContract({
    address: REGISTRY_ADDRESS,
    abi: REGISTRY_ABI,
    functionName: "setAgentWallet",
    args: [agentId, newAgentWalletAccount.address, signature],
  });

  console.log(`Wallet rotated. New wallet: ${newAgentWalletAccount.address}`);
  console.log(`TX: ${tx}`);
  return tx;
}
```

---

## Removing the Agent Wallet

Set the agent wallet to the zero address to remove it.

```typescript
async function removeAgentWallet(agentId: bigint) {
  const zeroAddress = "0x0000000000000000000000000000000000000000" as `0x${string}`;

  // No signature needed when setting to zero address (owner-only operation)
  const tx = await ownerWalletClient.writeContract({
    address: REGISTRY_ADDRESS,
    abi: REGISTRY_ABI,
    functionName: "setAgentWallet",
    args: [
      agentId,
      zeroAddress,
      "0x" as `0x${string}`, // empty signature for removal
    ],
  });

  console.log(`Agent wallet removed. TX: ${tx}`);
  return tx;
}
```

---

## Using cast

### Sign with the Agent Wallet

EIP-712 signing with cast requires the structured data:

```bash
# Generate the signature (agent wallet signs)
cast wallet sign-typed-data \
  --private-key $AGENT_WALLET_PRIVATE_KEY \
  --domain "ERC8004AgentRegistry" \
  --domain-version "1" \
  --domain-chain-id 43113 \
  --domain-verifying-contract $REGISTRY_ADDRESS \
  --type "SetAgentWallet(uint256 agentId,address wallet,uint256 nonce)" \
  --data "agentId:1687,wallet:$AGENT_WALLET_ADDRESS,nonce:0"
```

### Submit with the Owner

```bash
# Owner submits the transaction
cast send $REGISTRY_ADDRESS \
  "setAgentWallet(uint256,address,bytes)" \
  1687 \
  $AGENT_WALLET_ADDRESS \
  $SIGNATURE \
  --rpc-url https://api.avax-test.network/ext/bc/C/rpc \
  --private-key $OWNER_PRIVATE_KEY
```

### Verify

```bash
cast call $REGISTRY_ADDRESS \
  "getAgent(uint256)" \
  1687 \
  --rpc-url https://api.avax-test.network/ext/bc/C/rpc
```

---

## Security Best Practices

1. **Owner key in cold storage**: The owner private key should be on a hardware wallet or multisig. It is only needed for administrative operations (registration, metadata updates, wallet rotation).

2. **Agent wallet as a hot key**: The agent wallet private key is loaded into your server's environment. It is used for signing responses and making payments.

3. **Rotate regularly**: Change the agent wallet periodically, especially if you suspect compromise.

4. **Monitor the agent wallet**: Set up alerts for unexpected transactions from the agent wallet address.

5. **Fund minimally**: Keep only the minimum necessary balance in the agent wallet. Refill as needed.

6. **Use separate wallets per agent**: If you run multiple agents, each should have its own agent wallet.

---

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `InvalidSignature` | Agent wallet signature does not match | Verify the domain, types, and message match exactly |
| `NotAgentOwner` | Caller is not the agent's owner | Use the owner wallet to submit the transaction |
| `InvalidNonce` | Nonce in signature does not match contract | Re-fetch the nonce from `getAgentWalletNonce` |
| `AgentNotFound` | Agent ID does not exist | Verify the agent ID with `getAgent` |
| `WalletAlreadyAssigned` | Wallet is already assigned to another agent | Use a different wallet or remove it from the other agent first |

---

## Architecture Diagram

```
┌─────────────────────────────────────────┐
│              Owner Wallet               │
│  (Hardware wallet / Multisig)           │
│                                         │
│  Can: register, update, setAgentWallet  │
│  Cannot: sign A2A, make payments        │
└──────────────┬──────────────────────────┘
               │ setAgentWallet(agentId, wallet, sig)
               ▼
┌─────────────────────────────────────────┐
│         ERC-8004 Registry               │
│                                         │
│  Stores: owner → agentId → agentWallet  │
│  Verifies: EIP-712 signature            │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│            Agent Wallet                 │
│  (Hot wallet on server)                 │
│                                         │
│  Can: sign A2A responses, make x402     │
│       payments, interact with DeFi      │
│  Cannot: modify registration            │
└─────────────────────────────────────────┘
```

---

*Agent wallets are the bridge between security and operability. Your owner key stays safe. Your agent stays active.*
