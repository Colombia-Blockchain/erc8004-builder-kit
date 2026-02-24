# Case Study: Dual-Agent Interaction

## Overview

This case study documents how two ERC-8004 registered agents -- Apex Arbitrage (#1687) and AvaRiskScan (#1686) -- discover each other, communicate, pay for services via x402, and provide on-chain feedback, all without human intervention.

Both agents are registered on Avalanche mainnet under the same Identity Registry (`0x8004A169FB4a3325136EB29fA0ceB6D2e539a432`), making them discoverable to any agent or client that queries the contract. On-chain feedback is submitted to the Reputation Registry (`0x8004BAa17C55a88189AE136b182e5fdA19dE9b63`).

**Super Sentinel** acts as the scanner and orchestrator, continuously evaluating agents using the TRACER framework and coordinating cross-agent interactions.

### Production Endpoints

| Agent | Live URL |
|-------|----------|
| AvaRiskScan #1686 | [avariskscan-defi-production.up.railway.app](https://avariskscan-defi-production.up.railway.app) |
| Apex Arbitrage #1687 | [apex-arbitrage-agent-production.up.railway.app](https://apex-arbitrage-agent-production.up.railway.app) |

## Interaction Flow

```
┌─────────────────┐                              ┌─────────────────┐
│  Apex Arbitrage  │                              │   AvaRiskScan   │
│    Agent #1687   │                              │   Agent #1686   │
└────────┬────────┘                              └────────┬────────┘
         │                                                 │
         │  1. Query Identity Registry                     │
         │     tokenURI(1686)                              │
         │────────────────────────────────────────────────>│
         │                                                 │
         │  2. Fetch registration.json                     │
         │     GET /registration.json                      │
         │────────────────────────────────────────────────>│
         │                                                 │
         │  3. Read agent card (capabilities, tools)       │
         │<────────────────────────────────────────────────│
         │                                                 │
         │  4. Call MCP tool: get_avax_price()              │
         │     POST /mcp                                   │
         │────────────────────────────────────────────────>│
         │                                                 │
         │  5. Receive price data                          │
         │<────────────────────────────────────────────────│
         │                                                 │
         │  6. Pay via x402 for premium analytics          │
         │     POST /x402/premium-analytics                │
         │     (x-402-payment header with USDC)            │
         │────────────────────────────────────────────────>│
         │                                                 │
         │  7. Receive premium data                        │
         │<────────────────────────────────────────────────│
         │                                                 │
         │  8. Call A2A: "What is the risk of pool X?"     │
         │     POST /a2a                                   │
         │────────────────────────────────────────────────>│
         │                                                 │
         │  9. Receive risk assessment                     │
         │<────────────────────────────────────────────────│
         │                                                 │
         │  10. Submit on-chain feedback                   │
         │      giveFeedback(...) on Reputation Registry   │
         │────────────────────────────────────────────────>│
         │                                          (on-chain TX)
         │                                                 │
```

## Step-by-Step Walkthrough

### Step 1: Discover Agent via Registry

Agent #1687 queries the ERC-8004 Identity Registry to find other agents. It reads the `tokenURI` for agent #1686:

```solidity
// On-chain call to Identity Registry
string memory uri = registry.tokenURI(1686);
// Returns: "https://avariskscan-defi-production.up.railway.app/registration.json"
```

Using `cast`:

```bash
cast call 0x8004A169FB4a3325136EB29fA0ceB6D2e539a432 \
  "tokenURI(uint256)(string)" 1686 \
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
    "https://avariskscan-defi-production.up.railway.app/registration.json"
)
print(card["name"])        # "AvaRiskScan"
print(card["services"])    # Array of service objects
```

### Step 3: Parse Capabilities

The registration JSON contains the full service manifest using the v2 format with a services array:

```json
{
  "type": "https://eips.ethereum.org/EIPS/eip-8004#registration-v1",
  "name": "AvaRiskScan",
  "description": "DeFi analytics and Avalanche ecosystem guide",
  "version": "1.0.0",
  "agentWallet": "eip155:43114:0x29a45b03F07D1207f2e3ca34c38e7BE5458CE71a",
  "services": [
    {
      "type": "MCP",
      "version": "2025-11-25",
      "endpoint": "/mcp",
      "tools_count": 21
    },
    {
      "type": "A2A",
      "version": "0.3.0",
      "endpoint": "/a2a"
    },
    {
      "type": "x402",
      "endpoint": "/x402",
      "payment_token": "USDC"
    },
    {
      "type": "web"
    }
  ],
  "registrations": [
    {
      "agentId": 1686,
      "registry": "eip155:43114:0x8004A169FB4a3325136EB29fA0ceB6D2e539a432"
    }
  ]
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
    "https://avariskscan-defi-production.up.railway.app/mcp",
    "get_avax_price",
    {}
)

# Get Avalanche DeFi analytics
defi_data = await call_mcp_tool(
    "https://avariskscan-defi-production.up.railway.app/mcp",
    "get_avalanche_defi",
    {}
)

# Simulate a swap
swap_data = await call_mcp_tool(
    "https://avariskscan-defi-production.up.railway.app/mcp",
    "simulate_swap",
    {"from_token": "AVAX", "to_token": "USDC", "amount": "100"}
)
```

### Step 5: Pay via x402

For premium analytics, Agent #1687 makes an x402 payment in USDC:

```python
async def call_x402_endpoint(endpoint: str, payment_header: str) -> dict:
    """Call a paid x402 endpoint with USDC payment."""
    async with httpx.AsyncClient() as client:
        response = await client.post(
            endpoint,
            headers={"x-402-payment": payment_header},
            json={"query": "deep analytics on AVAX/USDC pools"}
        )
        return response.json()
```

**Real x402 payment transaction on Avalanche mainnet:**

| Field | Value |
|-------|-------|
| TxHash | `0xbd4791789f59c87656517cf8f291db50fe5955a1cb9d8287e71c5968215b504b` |
| Snowtrace | [View on Snowtrace](https://snowtrace.io/tx/0xbd4791789f59c87656517cf8f291db50fe5955a1cb9d8287e71c5968215b504b) |
| Network | Avalanche C-Chain |

### Step 6: Call A2A Endpoints

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
    "https://avariskscan-defi-production.up.railway.app/a2a",
    "What is the risk level of the AVAX/USDC pool on Trader Joe? "
    "Consider TVL, volume trends, and smart contract audit status."
)
```

### Step 7: Submit On-Chain Feedback

After successfully interacting with Agent #1686, Agent #1687 submits on-chain feedback to the **Reputation Registry** (not the Identity Registry):

```python
from web3 import Web3

# Reputation Registry contract address
REPUTATION_REGISTRY = "0x8004BAa17C55a88189AE136b182e5fdA19dE9b63"

def give_feedback(
    agent_id: int,
    score: int,
    score_type: int,
    comment: str,
    category: str,
    evidence_uri: str,
    metadata: str,
    interaction_hash: bytes,
    private_key: str
):
    """Submit on-chain feedback for an agent via Reputation Registry.

    giveFeedback signature (v2):
      giveFeedback(uint256, int128, uint8, string, string, string, string, bytes32)
    """
    w3 = Web3(Web3.HTTPProvider("https://api.avax.network/ext/bc/C/rpc"))

    registry = w3.eth.contract(
        address=REPUTATION_REGISTRY,
        abi=REPUTATION_REGISTRY_ABI
    )

    tx = registry.functions.giveFeedback(
        agent_id,          # agentId: 1686
        score,             # score: 88 (int128)
        score_type,        # scoreType: 1 (uint8, e.g. 1 = quality)
        comment,           # comment: "Reliable DeFi data, fast responses"
        category,          # category: "defi-analytics"
        evidence_uri,      # evidenceURI: link to interaction proof
        metadata,          # metadata: additional context
        interaction_hash   # interactionHash: keccak256 of the interaction
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
    agent_id=1686,
    score=88,
    score_type=1,
    comment="Reliable DeFi data, fast responses, accurate pricing",
    category="defi-analytics",
    evidence_uri="https://apex-arbitrage-agent-production.up.railway.app/interactions/1686",
    metadata="",
    interaction_hash=b'\x00' * 32,  # Replace with actual interaction hash
    private_key=AGENT_1687_PRIVATE_KEY
)
```

Using `cast`:

```bash
cast send 0x8004BAa17C55a88189AE136b182e5fdA19dE9b63 \
  "giveFeedback(uint256,int128,uint8,string,string,string,string,bytes32)" \
  1686 88 1 \
  "Reliable DeFi data, fast responses" \
  "defi-analytics" \
  "" "" \
  0x0000000000000000000000000000000000000000000000000000000000000000 \
  --rpc-url https://api.avax.network/ext/bc/C/rpc \
  --private-key $PRIVATE_KEY
```

**Real feedback transaction on Avalanche mainnet:**

| Field | Value |
|-------|-------|
| TxHash | `0xed60cbdd3fdb642af4f3c4baab958e285c9745b8368c57cc5ec8781c7cd6186b` |
| Snowtrace | [View on Snowtrace](https://snowtrace.io/tx/0xed60cbdd3fdb642af4f3c4baab958e285c9745b8368c57cc5ec8781c7cd6186b) |
| Score | 88 |
| Registry | Reputation Registry `0x8004BAa17C55a88189AE136b182e5fdA19dE9b63` |

## What This Proves

1. **On-chain discovery works** -- Agent #1687 found Agent #1686 purely through the ERC-8004 Identity Registry contract, no off-chain directory needed
2. **Interoperability across stacks** -- Python/FastAPI agent successfully calls TypeScript/Hono agent via standardized MCP and A2A protocols
3. **Multi-protocol communication** -- The same pair of agents use MCP (structured tool calls), A2A (natural language), x402 (payments), and on-chain feedback (reputation)
4. **x402 enables agent-to-agent payments** -- Verifiable on-chain USDC micropayments between agents without human intervention
5. **Feedback creates reputation** -- On-chain feedback transactions via the Reputation Registry are immutable and publicly verifiable, building a trust layer for autonomous agents
6. **Super Sentinel orchestrates evaluation** -- The scanner continuously evaluates both agents using the TRACER framework, providing objective quality scores
7. **No human in the loop** -- The entire discovery-to-payment-to-feedback flow runs autonomously

## On-Chain Verification

All transactions can be verified independently on Snowtrace:

### Identity Registry (Agent Discovery)

```bash
# Read tokenURI for Agent #1686
cast call 0x8004A169FB4a3325136EB29fA0ceB6D2e539a432 \
  "tokenURI(uint256)(string)" 1686 \
  --rpc-url https://api.avax.network/ext/bc/C/rpc

# Read tokenURI for Agent #1687
cast call 0x8004A169FB4a3325136EB29fA0ceB6D2e539a432 \
  "tokenURI(uint256)(string)" 1687 \
  --rpc-url https://api.avax.network/ext/bc/C/rpc
```

### Reputation Registry (Feedback)

```bash
# Read feedback for Agent #1686 from Reputation Registry
cast call 0x8004BAa17C55a88189AE136b182e5fdA19dE9b63 \
  "getFeedback(uint256)" 1686 \
  --rpc-url https://api.avax.network/ext/bc/C/rpc
```

### Transaction Verification

| Transaction | TxHash | Snowtrace |
|-------------|--------|-----------|
| x402 Payment | `0xbd4791...504b` | [View](https://snowtrace.io/tx/0xbd4791789f59c87656517cf8f291db50fe5955a1cb9d8287e71c5968215b504b) |
| Feedback | `0xed60cb...186b` | [View](https://snowtrace.io/tx/0xed60cbdd3fdb642af4f3c4baab958e285c9745b8368c57cc5ec8781c7cd6186b) |

Browse registered agents and their feedback on the Enigma scanner: [erc-8004scan.xyz](https://erc-8004scan.xyz)

## Reverse Direction

The interaction also works in reverse -- AvaRiskScan (#1686) can discover Apex (#1687) and call its arbitrage detection tools:

```bash
# Discover Apex agent
cast call 0x8004A169FB4a3325136EB29fA0ceB6D2e539a432 \
  "tokenURI(uint256)(string)" 1687 \
  --rpc-url https://api.avax.network/ext/bc/C/rpc

# Returns: "https://apex-arbitrage-agent-production.up.railway.app/registration.json"
```

This bidirectional capability demonstrates the true power of ERC-8004: any registered agent can discover and interact with any other registered agent using standardized protocols.

## Contract Addresses

| Contract | Address | Purpose |
|----------|---------|---------|
| Identity Registry | `0x8004A169FB4a3325136EB29fA0ceB6D2e539a432` | Agent registration and discovery via `tokenURI` |
| Reputation Registry | `0x8004BAa17C55a88189AE136b182e5fdA19dE9b63` | On-chain feedback via `giveFeedback` (v2) |

---

*Built by Colombia-Blockchain / Enigma team.*
