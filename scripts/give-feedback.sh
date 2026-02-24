#!/usr/bin/env bash
set -euo pipefail

# ERC-8004 Give Feedback — Multi-Chain
# Usage:
#   CHAIN=base ./scripts/give-feedback.sh <agent-id> <value> [tag1] [tag2]

CHAIN="${CHAIN:-base}"

declare -A CHAINS
CHAINS[ethereum]="1|https://eth.llamarpc.com|0x8004BAa17C55a88189AE136b182e5fdA19dE9b63|https://etherscan.io"
CHAINS[base]="8453|https://mainnet.base.org|0x8004BAa17C55a88189AE136b182e5fdA19dE9b63|https://basescan.org"
CHAINS[arbitrum]="42161|https://arb1.arbitrum.io/rpc|0x8004BAa17C55a88189AE136b182e5fdA19dE9b63|https://arbiscan.io"
CHAINS[avalanche]="43114|https://api.avax.network/ext/bc/C/rpc|0x8004BAa17C55a88189AE136b182e5fdA19dE9b63|https://snowtrace.io"
CHAINS[sepolia]="11155111|https://rpc.sepolia.org|0x8004B663056A597Dffe9eCcC1965A193B7388713|https://sepolia.etherscan.io"
CHAINS[base-sepolia]="84532|https://sepolia.base.org|0x8004B663056A597Dffe9eCcC1965A193B7388713|https://sepolia.basescan.org"
CHAINS[avalanche-fuji]="43113|https://api.avax-test.network/ext/bc/C/rpc|0x8004B663056A597Dffe9eCcC1965A193B7388713|https://testnet.snowtrace.io"

if [ -z "${CHAINS[$CHAIN]+x}" ]; then
  echo "Error: Unknown chain '$CHAIN'."
  exit 1
fi

IFS='|' read -r CHAIN_ID RPC_URL REPUTATION_REGISTRY EXPLORER <<< "${CHAINS[$CHAIN]}"

if [ -z "${PRIVATE_KEY:-}" ]; then
  echo "Error: PRIVATE_KEY environment variable is required"
  exit 1
fi

AGENT_ID="${1:-}"
VALUE="${2:-}"
TAG1="${3:-}"
TAG2="${4:-}"
VALUE_DECIMALS="${VALUE_DECIMALS:-0}"

if [ -z "$AGENT_ID" ] || [ -z "$VALUE" ]; then
  echo "Usage: CHAIN=<chain> ./scripts/give-feedback.sh <agent-id> <value> [tag1] [tag2]"
  echo ""
  echo "Examples:"
  echo "  CHAIN=base ./scripts/give-feedback.sh 1 85 starred"
  echo "  CHAIN=avalanche ./scripts/give-feedback.sh 1686 90 starred quality"
  echo ""
  echo "Common tags: starred (0-100), reachable (0/1), uptime, successRate, responseTime"
  exit 1
fi

if ! command -v cast &> /dev/null; then
  echo "Error: 'cast' (Foundry) is required."
  exit 1
fi

EMPTY_HASH="0x0000000000000000000000000000000000000000000000000000000000000000"

echo "=== ERC-8004 Give Feedback ==="
echo "Chain: $CHAIN (Chain ID: $CHAIN_ID)"
echo "Agent ID: $AGENT_ID"
echo "Value: $VALUE (decimals: $VALUE_DECIMALS)"
echo "Tag1: ${TAG1:-<empty>}  Tag2: ${TAG2:-<empty>}"
echo ""
echo "Sending feedback..."

TX_HASH=$(cast send "$REPUTATION_REGISTRY" \
  "giveFeedback(uint256,int128,uint8,string,string,string,string,bytes32)" \
  "$AGENT_ID" "$VALUE" "$VALUE_DECIMALS" "$TAG1" "$TAG2" "" "" "$EMPTY_HASH" \
  --rpc-url "$RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  --json | grep -o '"transactionHash":"[^"]*"' | cut -d'"' -f4)

echo "Transaction sent: $TX_HASH"
echo "Explorer: $EXPLORER/tx/$TX_HASH"
echo ""
echo "Feedback submitted successfully!"
