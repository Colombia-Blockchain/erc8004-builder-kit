#!/usr/bin/env bash
set -euo pipefail

# ERC-8004 Agent URI Update — Multi-Chain
# Usage:
#   CHAIN=base ./scripts/update-uri.sh <agent-id> <new-uri>

CHAIN="${CHAIN:-base}"

declare -A CHAINS
CHAINS[ethereum]="1|https://eth.llamarpc.com|0x8004A169FB4a3325136EB29fA0ceB6D2e539a432|https://etherscan.io"
CHAINS[base]="8453|https://mainnet.base.org|0x8004A169FB4a3325136EB29fA0ceB6D2e539a432|https://basescan.org"
CHAINS[arbitrum]="42161|https://arb1.arbitrum.io/rpc|0x8004A169FB4a3325136EB29fA0ceB6D2e539a432|https://arbiscan.io"
CHAINS[avalanche]="43114|https://api.avax.network/ext/bc/C/rpc|0x8004A169FB4a3325136EB29fA0ceB6D2e539a432|https://snowtrace.io"
CHAINS[sepolia]="11155111|https://rpc.sepolia.org|0x8004A818BFB912233c491871b3d84c89A494BD9e|https://sepolia.etherscan.io"
CHAINS[base-sepolia]="84532|https://sepolia.base.org|0x8004A818BFB912233c491871b3d84c89A494BD9e|https://sepolia.basescan.org"
CHAINS[avalanche-fuji]="43113|https://api.avax-test.network/ext/bc/C/rpc|0x8004A818BFB912233c491871b3d84c89A494BD9e|https://testnet.snowtrace.io"

if [ -z "${CHAINS[$CHAIN]+x}" ]; then
  echo "Error: Unknown chain '$CHAIN'."
  exit 1
fi

IFS='|' read -r CHAIN_ID RPC_URL IDENTITY_REGISTRY EXPLORER <<< "${CHAINS[$CHAIN]}"

if [ -z "${PRIVATE_KEY:-}" ]; then
  echo "Error: PRIVATE_KEY environment variable is required"
  exit 1
fi

AGENT_ID="${1:-}"
NEW_URI="${2:-}"

if [ -z "$AGENT_ID" ] || [ -z "$NEW_URI" ]; then
  echo "Usage: CHAIN=<chain> ./scripts/update-uri.sh <agent-id> <new-uri>"
  echo ""
  echo "Examples:"
  echo "  CHAIN=base ./scripts/update-uri.sh 42 \"https://myagent.com/registration.json\""
  echo "  CHAIN=avalanche-fuji ./scripts/update-uri.sh 15 \"https://myagent.com/registration.json\""
  exit 1
fi

if ! command -v cast &> /dev/null; then
  echo "Error: 'cast' (Foundry) is required."
  exit 1
fi

echo ""
echo "=== ERC-8004 Agent URI Update ==="
echo "Chain:     $CHAIN (Chain ID: $CHAIN_ID)"
echo "Registry:  $IDENTITY_REGISTRY"
echo "Agent ID:  $AGENT_ID"
echo "New URI:   $NEW_URI"
echo ""

WALLET_ADDRESS=$(cast wallet address --private-key "$PRIVATE_KEY")
OWNER=$(cast call "$IDENTITY_REGISTRY" "ownerOf(uint256)(address)" "$AGENT_ID" --rpc-url "$RPC_URL" 2>/dev/null || echo "")

if [ -z "$OWNER" ]; then
  echo "Error: Agent #$AGENT_ID not found"
  exit 1
fi

if [ "$(echo "$OWNER" | tr '[:upper:]' '[:lower:]')" != "$(echo "$WALLET_ADDRESS" | tr '[:upper:]' '[:lower:]')" ]; then
  echo "Error: You are not the owner of Agent #$AGENT_ID"
  echo "  Your wallet: $WALLET_ADDRESS"
  echo "  Agent owner: $OWNER"
  exit 1
fi

echo "Owner verified: $WALLET_ADDRESS"
echo "Updating agent URI on-chain..."

TX_HASH=$(cast send "$IDENTITY_REGISTRY" \
  "setAgentURI(uint256,string)" "$AGENT_ID" "$NEW_URI" \
  --rpc-url "$RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  --json | grep -o '"transactionHash":"[^"]*"' | cut -d'"' -f4)

echo "Transaction sent: $TX_HASH"
echo "Explorer: $EXPLORER/tx/$TX_HASH"
echo ""
echo "URI updated. Scanners will refresh within 5-10 minutes."
