#!/usr/bin/env bash
set -euo pipefail

# ERC-8004 Agent Checker — Multi-Chain
# Usage:
#   CHAIN=base ./scripts/check-agent.sh <agent-id>
#   CHAIN=avalanche ./scripts/check-agent.sh 1686

CHAIN="${CHAIN:-base}"

declare -A CHAINS
CHAINS[ethereum]="1|https://eth.llamarpc.com|0x8004A169FB4a3325136EB29fA0ceB6D2e539a432|0x8004BAa17C55a88189AE136b182e5fdA19dE9b63|https://etherscan.io"
CHAINS[base]="8453|https://mainnet.base.org|0x8004A169FB4a3325136EB29fA0ceB6D2e539a432|0x8004BAa17C55a88189AE136b182e5fdA19dE9b63|https://basescan.org"
CHAINS[arbitrum]="42161|https://arb1.arbitrum.io/rpc|0x8004A169FB4a3325136EB29fA0ceB6D2e539a432|0x8004BAa17C55a88189AE136b182e5fdA19dE9b63|https://arbiscan.io"
CHAINS[avalanche]="43114|https://api.avax.network/ext/bc/C/rpc|0x8004A169FB4a3325136EB29fA0ceB6D2e539a432|0x8004BAa17C55a88189AE136b182e5fdA19dE9b63|https://snowtrace.io"
CHAINS[sepolia]="11155111|https://rpc.sepolia.org|0x8004A818BFB912233c491871b3d84c89A494BD9e|0x8004B663056A597Dffe9eCcC1965A193B7388713|https://sepolia.etherscan.io"
CHAINS[base-sepolia]="84532|https://sepolia.base.org|0x8004A818BFB912233c491871b3d84c89A494BD9e|0x8004B663056A597Dffe9eCcC1965A193B7388713|https://sepolia.basescan.org"
CHAINS[avalanche-fuji]="43113|https://api.avax-test.network/ext/bc/C/rpc|0x8004A818BFB912233c491871b3d84c89A494BD9e|0x8004B663056A597Dffe9eCcC1965A193B7388713|https://testnet.snowtrace.io"

if [ -z "${CHAINS[$CHAIN]+x}" ]; then
  echo "Error: Unknown chain '$CHAIN'. Use: ethereum, base, arbitrum, avalanche, sepolia, base-sepolia, avalanche-fuji"
  exit 1
fi

IFS='|' read -r CHAIN_ID RPC_URL IDENTITY_REGISTRY REPUTATION_REGISTRY EXPLORER <<< "${CHAINS[$CHAIN]}"

AGENT_ID="${1:-}"
if [ -z "$AGENT_ID" ]; then
  echo "Usage: CHAIN=<chain> ./scripts/check-agent.sh <agent-id>"
  exit 1
fi

if ! command -v cast &> /dev/null; then
  echo "Error: 'cast' (Foundry) is required."
  exit 1
fi

echo "=== ERC-8004 Agent Info ==="
echo "Chain: $CHAIN (Chain ID: $CHAIN_ID)"
echo "Agent ID: $AGENT_ID"
echo ""

OWNER=$(cast call "$IDENTITY_REGISTRY" "ownerOf(uint256)(address)" "$AGENT_ID" --rpc-url "$RPC_URL" 2>/dev/null || echo "NOT_FOUND")

if [ "$OWNER" = "NOT_FOUND" ] || [ -z "$OWNER" ]; then
  echo "Agent #$AGENT_ID is not registered on $CHAIN."
  exit 0
fi

echo "Owner: $OWNER"

TOKEN_URI=$(cast call "$IDENTITY_REGISTRY" "tokenURI(uint256)(string)" "$AGENT_ID" --rpc-url "$RPC_URL" 2>/dev/null || echo "")
echo "Agent URI: $TOKEN_URI"

AGENT_WALLET=$(cast call "$IDENTITY_REGISTRY" "getAgentWallet(uint256)(address)" "$AGENT_ID" --rpc-url "$RPC_URL" 2>/dev/null || echo "0x0000000000000000000000000000000000000000")
echo "Agent Wallet: $AGENT_WALLET"

CLIENTS=$(cast call "$REPUTATION_REGISTRY" "getClients(uint256)(address[])" "$AGENT_ID" --rpc-url "$RPC_URL" 2>/dev/null || echo "[]")
echo ""
echo "Reputation Clients: $CLIENTS"

echo ""
echo "Registry ID: eip155:${CHAIN_ID}:${IDENTITY_REGISTRY}"
echo "Explorer: $EXPLORER/address/$IDENTITY_REGISTRY"
