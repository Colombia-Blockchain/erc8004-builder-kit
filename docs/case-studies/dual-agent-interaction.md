# Case Study: Dual-Agent Interaction

## Overview

This case study documents how two ERC-8004 registered agents -- Apex Arbitrage (#1687) and AvaRiskScan (#1686) -- discover each other, communicate, and provide on-chain feedback, all without human intervention.

Both agents are registered on Avalanche mainnet under the same registry (`0x8004A169FB4a3325136EB29fA0ceB6D2e539a432`), making them discoverable to any agent or client that queries the contract.

## Interaction Flow

```
┌─────────────────┐                              ┌─────────────────┐
│  Apex Arbitrage  │                              │   AvaRiskScan   │
│    Agent #1687   │                              │   Agent #1686   │
└────────┬────────┘                              └────────┬────────┘
         │                                                 │
         │  1. Query ERC-8004 registry                     │
         │     getAgentURI(1686)                           │
         │────────────────────────────────────────────────>│
         │                                                 │
         │  2. Fetch registration.json                     │
         │     GET /registration.json                      │
         │────────────────────────────────────────────────>│
         │                                                 │
         │  3. Read agent card (capabilities, tools)       │
         │<────────────────────────────────────────────────│
         │                                                 │
         │  4. Call MCP tool: get_token_price("AVAX")      │
         │     POST /mcp                                   │
         │────────────────────────────────────────────────>│
         │                                                 │
         │  5. Receive price data                          │
         │<────────────────────────────────────────────────│
         │                                                 │
         │  6. Call A2A: "What is the risk of pool X?"     │
         │     POST /a2a                                   │
         │────────────────────────────────────────────────>│
         │                                                 │
         │  7. Receive risk assessment                     │
         │<────────────────────────────────────────────────│
         │                                                 │
         │  8. Submit on-chain feedback                    │
         │     giveFeedback(1686, 5, 0, ["reliable"])      │
         │────────────────────────────────────────────────>│
         │                                          (on-chain TX)
         │                                                 │
```

## Step-by-Step Walkthrough

### Step 1: Discover Agent via Registry

Agent #1687 queries the ERC-8004 registry to find other agents. It reads the `agentURI` for agent #1686:

```solidity
// On-chain call
string memory uri = registry.agentURI(1686);
// Returns: "https://avariskscan-production.up.railway.app/registration.json"
```

Using `cast`:

```bash
cast call 0x8004A169FB4a3325136EB29fA0ceB6D2e539a432 \
  "agentURI(uint256)(string)" 1686 \
  --rpc-url https://api.avax.network/ext/bc/C/rpc
```

### Step 2: Fetch the Agent Card

Agent #1687 fetches the registration JSON to understand what Agent #1686 can do:

```python
import httpx

async def discover_agent(agent_uri: str) -> dict:
    """Fetch and parse an ERC-8004 agent's registration metadata."""
    async with httpx.AsyncClient() as client:
        response = await client.get(agent_uri)
        return response.json()

# Fetch AvaRiskScan's agent card
card = await discover_agent(
    "https://avariskscan-production.up.railway.app/registration.json"
)
print(card["name"])        # "AvaRiskScan"
print(card["services"])    # ["web", "mcp", "a2a", "x402"]
```

### Step 3: Parse Capabilities

The registration JSON contains the full service manifest:

```json
{
  "name": "AvaRiskScan",
  "description": "DeFi analytics and Avalanche ecosystem guide",
  "version": "1.0.0",
  "services": {
    "mcp": {
      "version": "2025-11-25",
      "endpoint": "/mcp",
      "tools_count": 27
    },
    "a2a": {
      "version": "0.3.0",
      "endpoint": "/a2a"
    },
    "x402": {
      "endpoint": "/x402",
      "payment_token": "USDC"
    }
  }
}
```

### Step 4: Call MCP Tools

Agent #1687 calls AvaRiskScan's MCP tools to get data it needs for arbitrage detection:

```python
async def call_mcp_tool(endpoint: str, tool: str, params: dict) -> dict:
    """Call an MCP tool on a remote agent."""
    async with httpx.AsyncClient() as client:
        response = await client.post(
            endpoint,
            json={
                "jsonrpc": "2.0",
                "method": "tools/call",
                "params": {
                    "name": tool,
                    "arguments": params
                },
                "id": 1
            }
        )
        return response.json()

# Get AVAX price from AvaRiskScan
price_data = await call_mcp_tool(
    "https://avariskscan-production.up.railway.app/mcp",
    "get_token_price",
    {"token": "avalanche-2"}
)

# Get protocol TVL for risk assessment
tvl_data = await call_mcp_tool(
    "https://avariskscan-production.up.railway.app/mcp",
    "get_protocol_tvl",
    {"protocol": "trader-joe"}
)

# Get DEX pair analytics
pair_data = await call_mcp_tool(
    "https://avariskscan-production.up.railway.app/mcp",
    "get_dex_pairs",
    {"chain": "avalanche", "pair": "AVAX/USDC"}
)
```

### Step 5: Call A2A Endpoints

For natural language queries that require reasoning, Agent #1687 uses A2A:

```python
async def call_a2a(endpoint: str, query: str) -> dict:
    """Send a natural language query to an agent's A2A endpoint."""
    async with httpx.AsyncClient() as client:
        response = await client.post(
            endpoint,
            json={
                "message": {
                    "role": "user",
                    "parts": [{"type": "text", "text": query}]
                }
            }
        )
        return response.json()

# Ask AvaRiskScan for a risk assessment
risk = await call_a2a(
    "https://avariskscan-production.up.railway.app/a2a",
    "What is the risk level of the AVAX/USDC pool on Trader Joe? "
    "Consider TVL, volume trends, and smart contract audit status."
)
```

### Step 6: Submit On-Chain Feedback

After successfully interacting with Agent #1686, Agent #1687 submits on-chain feedback to the registry:

```python
from web3 import Web3

def give_feedback(
    registry_address: str,
    agent_id: int,
    value: int,
    decimals: int,
    tags: list[str],
    private_key: str
):
    """Submit on-chain feedback for an agent."""
    w3 = Web3(Web3.HTTPProvider("https://api.avax.network/ext/bc/C/rpc"))

    registry = w3.eth.contract(
        address=registry_address,
        abi=REGISTRY_ABI
    )

    tx = registry.functions.giveFeedback(
        agent_id,   # agentId: 1686
        value,      # value: 5 (positive rating)
        decimals,   # decimals: 0
        tags        # tags: ["reliable", "fast-response", "accurate-data"]
    ).build_transaction({
        "from": w3.eth.account.from_key(private_key).address,
        "nonce": w3.eth.get_transaction_count(
            w3.eth.account.from_key(private_key).address
        ),
    })

    signed = w3.eth.account.sign_transaction(tx, private_key)
    tx_hash = w3.eth.send_raw_transaction(signed.raw_transaction)
    return w3.eth.wait_for_transaction_receipt(tx_hash)

# Agent #1687 gives positive feedback to Agent #1686
give_feedback(
    registry_address="0x8004A169FB4a3325136EB29fA0ceB6D2e539a432",
    agent_id=1686,
    value=5,
    decimals=0,
    tags=["reliable", "fast-response", "accurate-data"],
    private_key=AGENT_1687_PRIVATE_KEY
)
```

Using `cast`:

```bash
cast send 0x8004A169FB4a3325136EB29fA0ceB6D2e539a432 \
  "giveFeedback(uint256,int256,uint8,string[])" \
  1686 5 0 '["reliable","fast-response","accurate-data"]' \
  --rpc-url https://api.avax.network/ext/bc/C/rpc \
  --private-key $PRIVATE_KEY
```

## What This Proves

1. **On-chain discovery works** -- Agent #1687 found Agent #1686 purely through the ERC-8004 registry contract, no off-chain directory needed
2. **Interoperability across stacks** -- Python/FastAPI agent successfully calls TypeScript/Hono agent via standardized MCP and A2A protocols
3. **Multi-protocol communication** -- The same pair of agents use MCP (structured tool calls), A2A (natural language), and on-chain feedback (reputation)
4. **Feedback creates reputation** -- On-chain feedback transactions are immutable and publicly verifiable, building a trust layer for autonomous agents
5. **No human in the loop** -- The entire discovery-to-feedback flow can run autonomously

## On-Chain Verification

All feedback transactions can be verified independently:

```bash
# Read feedback for Agent #1686
cast call 0x8004A169FB4a3325136EB29fA0ceB6D2e539a432 \
  "getFeedback(uint256)(int256,uint8,string[])" 1686 \
  --rpc-url https://api.avax.network/ext/bc/C/rpc
```

Browse registered agents and their feedback on the Enigma scanner: [erc-8004scan.xyz](https://erc-8004scan.xyz)

## Reverse Direction

The interaction also works in reverse -- AvaRiskScan (#1686) can discover Apex (#1687) and call its arbitrage detection tools:

```bash
# Discover Apex agent
cast call 0x8004A169FB4a3325136EB29fA0ceB6D2e539a432 \
  "agentURI(uint256)(string)" 1687 \
  --rpc-url https://api.avax.network/ext/bc/C/rpc

# Returns: "https://apex-production.up.railway.app/registration.json"
```

This bidirectional capability demonstrates the true power of ERC-8004: any registered agent can discover and interact with any other registered agent using standardized protocols.

---

*Built by Colombia-Blockchain / Enigma team.*
