# 10 — Multi-Chain Registration

Your agent does not have to live on one chain. ERC-8004 is deployed on multiple EVM-compatible networks. Registering on several chains maximizes discoverability: agents searching on Base will find you, agents searching on Avalanche will find you, agents searching on Ethereum will find you.

---

## Why Register on Multiple Chains?

1. **Discoverability**: Not all agents search the same registry. If a caller only queries the Base registry, they will never find you on Avalanche.

2. **Ecosystem alignment**: DeFi agents tend to search Avalanche or Ethereum. Social agents may search Base. NFT agents may search Ethereum mainnet.

3. **Redundancy**: If one chain is congested or its RPC is down, your registration on another chain still works.

4. **Payment flexibility**: Different chains support different payment tokens. Registering on Base lets you accept USDC on Base. Registering on Avalanche lets you accept USDC on Avalanche.

5. **Cost optimization**: Registration costs vary by chain. Avalanche Fuji (testnet) is free. Base Sepolia is free. Mainnet costs vary.

---

## How to Register on Multiple Chains

The process is the same for each chain. You use the same wallet (private key), but point to different RPC endpoints and contract addresses.

### Same Wallet, Different RPCs

Your agent identity is tied to your wallet address. Using the same wallet across chains creates a consistent identity.

```
Wallet: 0xYourWallet
  ├── Avalanche Fuji  → Agent #1686
  ├── Base Sepolia    → Agent #42
  └── Ethereum Sepolia → Agent #7
```

The agent IDs will differ per chain (they are auto-incremented per registry), but the owner address is the same.

---

## Chain Configuration

### Avalanche Fuji (Testnet)

```bash
export RPC_URL="https://api.avax-test.network/ext/bc/C/rpc"
export CHAIN_ID=43113
export REGISTRY_ADDRESS="0xYourAvalancheFujiRegistry"
export EXPLORER="https://testnet.snowtrace.io"
```

### Base Sepolia (Testnet)

```bash
export RPC_URL="https://sepolia.base.org"
export CHAIN_ID=84532
export REGISTRY_ADDRESS="0xYourBaseSepoliaRegistry"
export EXPLORER="https://sepolia.basescan.org"
```

### Ethereum Sepolia (Testnet)

```bash
export RPC_URL="https://rpc.sepolia.org"
export CHAIN_ID=11155111
export REGISTRY_ADDRESS="0xYourEthSepoliaRegistry"
export EXPLORER="https://sepolia.etherscan.io"
```

### Avalanche C-Chain (Mainnet)

```bash
export RPC_URL="https://api.avax.network/ext/bc/C/rpc"
export CHAIN_ID=43114
export REGISTRY_ADDRESS="0xYourAvalancheMainnetRegistry"
export EXPLORER="https://snowtrace.io"
```

### Base (Mainnet)

```bash
export RPC_URL="https://mainnet.base.org"
export CHAIN_ID=8453
export REGISTRY_ADDRESS="0xYourBaseMainnetRegistry"
export EXPLORER="https://basescan.org"
```

---

## Using register.sh for Each Chain

If your project includes a `register.sh` script, you can run it multiple times with different environment variables.

### Step 1: Register on Avalanche Fuji

```bash
RPC_URL="https://api.avax-test.network/ext/bc/C/rpc" \
REGISTRY_ADDRESS="0xAvalancheFujiRegistry" \
PRIVATE_KEY="0xYourPrivateKey" \
./scripts/register.sh
```

### Step 2: Register on Base Sepolia

```bash
RPC_URL="https://sepolia.base.org" \
REGISTRY_ADDRESS="0xBaseSepoliaRegistry" \
PRIVATE_KEY="0xYourPrivateKey" \
./scripts/register.sh
```

### Step 3: Register on Ethereum Sepolia

```bash
RPC_URL="https://rpc.sepolia.org" \
REGISTRY_ADDRESS="0xEthSepoliaRegistry" \
PRIVATE_KEY="0xYourPrivateKey" \
./scripts/register.sh
```

### Using cast Directly

```bash
# Register on Avalanche Fuji
cast send $AVAX_REGISTRY \
  "registerAgent(string,string)" \
  "My Agent" \
  "https://my-agent.com/registration.json" \
  --rpc-url https://api.avax-test.network/ext/bc/C/rpc \
  --private-key $PRIVATE_KEY

# Register on Base Sepolia
cast send $BASE_REGISTRY \
  "registerAgent(string,string)" \
  "My Agent" \
  "https://my-agent.com/registration.json" \
  --rpc-url https://sepolia.base.org \
  --private-key $PRIVATE_KEY
```

---

## Updating registration.json for Multiple Chains

Your `registration.json` should list all chains where you are registered. This lets other agents know where to find your on-chain data.

```json
{
  "name": "My DeFi Agent",
  "description": "Cross-chain DeFi analytics agent",
  "version": "1.0.0",
  "chains": [
    {
      "chainId": 43113,
      "chainName": "Avalanche Fuji",
      "registryAddress": "0xAvalancheFujiRegistry",
      "agentId": 1686,
      "rpcUrl": "https://api.avax-test.network/ext/bc/C/rpc",
      "explorerUrl": "https://testnet.snowtrace.io"
    },
    {
      "chainId": 84532,
      "chainName": "Base Sepolia",
      "registryAddress": "0xBaseSepoliaRegistry",
      "agentId": 42,
      "rpcUrl": "https://sepolia.base.org",
      "explorerUrl": "https://sepolia.basescan.org"
    },
    {
      "chainId": 11155111,
      "chainName": "Ethereum Sepolia",
      "registryAddress": "0xEthSepoliaRegistry",
      "agentId": 7,
      "rpcUrl": "https://rpc.sepolia.org",
      "explorerUrl": "https://sepolia.etherscan.io"
    }
  ],
  "services": [
    {
      "name": "A2A",
      "endpoint": "https://my-agent.com/a2a"
    },
    {
      "name": "MCP",
      "endpoint": "https://my-agent.com/mcp"
    },
    {
      "name": "OASF",
      "endpoint": "https://my-agent.com/oasf"
    }
  ],
  "capabilities": ["a2a", "mcp", "oasf", "x402"]
}
```

**Note:** The `services` endpoints remain the same across chains. Your agent runs at one URL. The chains array tells callers where to verify your on-chain registration.

---

## TypeScript: Multi-Chain Registration Script

```typescript
import { createWalletClient, http } from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { avalancheFuji, baseSepolia } from "viem/chains";

const CHAINS = [
  {
    chain: avalancheFuji,
    registry: "0xAvalancheFujiRegistry" as `0x${string}`,
    rpc: "https://api.avax-test.network/ext/bc/C/rpc",
  },
  {
    chain: baseSepolia,
    registry: "0xBaseSepoliaRegistry" as `0x${string}`,
    rpc: "https://sepolia.base.org",
  },
];

const account = privateKeyToAccount(
  process.env.PRIVATE_KEY as `0x${string}`
);

async function registerOnAllChains(name: string, metadataURI: string) {
  const results = [];

  for (const config of CHAINS) {
    const client = createWalletClient({
      account,
      chain: config.chain,
      transport: http(config.rpc),
    });

    try {
      const tx = await client.writeContract({
        address: config.registry,
        abi: REGISTRY_ABI,
        functionName: "registerAgent",
        args: [name, metadataURI],
      });

      console.log(`Registered on ${config.chain.name}: ${tx}`);
      results.push({
        chain: config.chain.name,
        chainId: config.chain.id,
        tx,
        status: "success",
      });
    } catch (error: any) {
      console.error(`Failed on ${config.chain.name}: ${error.message}`);
      results.push({
        chain: config.chain.name,
        chainId: config.chain.id,
        error: error.message,
        status: "failed",
      });
    }
  }

  return results;
}

// Usage
await registerOnAllChains(
  "My DeFi Agent",
  "https://my-agent.com/registration.json"
);
```

---

## Cost Comparison by Chain

### Testnet (Free)

| Chain | Registration Cost | Feedback Cost | Notes |
|-------|------------------|---------------|-------|
| Avalanche Fuji | Free (faucet AVAX) | Free | Fastest finality |
| Base Sepolia | Free (faucet ETH) | Free | Low gas |
| Ethereum Sepolia | Free (faucet ETH) | Free | Widest tooling |

### Mainnet

| Chain | Registration Cost | Feedback Cost | Native Token | Notes |
|-------|------------------|---------------|--------------|-------|
| Avalanche C-Chain | ~0.01 AVAX (~$0.30) | ~0.002 AVAX | AVAX | Fast, cheap |
| Base | ~0.0001 ETH (~$0.30) | ~0.00005 ETH | ETH | Very cheap L2 |
| Ethereum | ~0.005 ETH (~$15.00) | ~0.001 ETH | ETH | Expensive but prestigious |
| Arbitrum | ~0.0001 ETH (~$0.30) | ~0.00005 ETH | ETH | Cheap L2 |
| Polygon | ~0.01 MATIC (~$0.01) | ~0.002 MATIC | MATIC | Cheapest |

*Prices are approximate and fluctuate with gas prices and token values.*

---

## Which Chain to Pick?

### Decision Framework

```
Are you building on testnet?
├── Yes → Avalanche Fuji (fastest, best ERC-8004 tooling)
└── No → Continue...

Is cost the primary concern?
├── Yes → Base or Polygon (cheapest L2s)
└── No → Continue...

Do you need maximum discoverability?
├── Yes → Register on ALL chains you can afford
└── No → Continue...

What ecosystem are you targeting?
├── DeFi → Avalanche or Ethereum
├── Social/Consumer → Base
├── Gaming → Polygon or Arbitrum
└── General → Avalanche + Base (best coverage for cost)
```

### Recommended Strategy

1. **Start**: Register on Avalanche Fuji (testnet) for development.
2. **Launch**: Register on Avalanche C-Chain and Base (mainnet) for production.
3. **Scale**: Add Ethereum mainnet when you need maximum visibility.

---

## Verifying Multi-Chain Registration

```typescript
async function verifyAllChains(
  ownerAddress: `0x${string}`,
  expectedChains: typeof CHAINS
) {
  const results = [];

  for (const config of expectedChains) {
    const client = createPublicClient({
      chain: config.chain,
      transport: http(config.rpc),
    });

    try {
      const count = await client.readContract({
        address: config.registry,
        abi: REGISTRY_ABI,
        functionName: "getAgentCount",
      });

      let found = false;
      for (let i = 1n; i <= count; i++) {
        const agent = await client.readContract({
          address: config.registry,
          abi: REGISTRY_ABI,
          functionName: "getAgent",
          args: [i],
        });
        if (agent.owner.toLowerCase() === ownerAddress.toLowerCase()) {
          results.push({
            chain: config.chain.name,
            agentId: Number(i),
            status: "found",
          });
          found = true;
          break;
        }
      }

      if (!found) {
        results.push({
          chain: config.chain.name,
          status: "not_found",
        });
      }
    } catch (error: any) {
      results.push({
        chain: config.chain.name,
        status: "error",
        error: error.message,
      });
    }
  }

  return results;
}
```

---

## Keeping Registrations in Sync

When you update your agent (new name, new metadata URI), update on ALL chains:

```typescript
async function updateOnAllChains(
  agentIds: Record<number, bigint>, // chainId -> agentId
  newMetadataURI: string
) {
  for (const config of CHAINS) {
    const agentId = agentIds[config.chain.id];
    if (!agentId) continue;

    const client = createWalletClient({
      account,
      chain: config.chain,
      transport: http(config.rpc),
    });

    const tx = await client.writeContract({
      address: config.registry,
      abi: REGISTRY_ABI,
      functionName: "updateAgent",
      args: [agentId, newMetadataURI],
    });

    console.log(`Updated on ${config.chain.name}: ${tx}`);
  }
}

// Usage
await updateOnAllChains(
  { 43113: 1686n, 84532: 42n },
  "https://my-agent.com/registration-v2.json"
);
```

---

*Multi-chain registration is the difference between being findable by some agents and being findable by all agents. The cost is minimal. The reach is maximal.*
