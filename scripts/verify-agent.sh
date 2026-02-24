#!/usr/bin/env bash
set -euo pipefail

# ERC-8004 Agent Verification — Complete Check
# Verifies on-chain registration, metadata, endpoints, and services
# Usage:
#   CHAIN=base ./scripts/verify-agent.sh <agent-id>

CHAIN="${CHAIN:-base}"

declare -A CHAINS
CHAINS[ethereum]="1|https://eth.llamarpc.com|0x8004A169FB4a3325136EB29fA0ceB6D2e539a432|0x8004BAa17C55a88189AE136b182e5fdA19dE9b63"
CHAINS[base]="8453|https://mainnet.base.org|0x8004A169FB4a3325136EB29fA0ceB6D2e539a432|0x8004BAa17C55a88189AE136b182e5fdA19dE9b63"
CHAINS[arbitrum]="42161|https://arb1.arbitrum.io/rpc|0x8004A169FB4a3325136EB29fA0ceB6D2e539a432|0x8004BAa17C55a88189AE136b182e5fdA19dE9b63"
CHAINS[avalanche]="43114|https://api.avax.network/ext/bc/C/rpc|0x8004A169FB4a3325136EB29fA0ceB6D2e539a432|0x8004BAa17C55a88189AE136b182e5fdA19dE9b63"
CHAINS[sepolia]="11155111|https://rpc.sepolia.org|0x8004A818BFB912233c491871b3d84c89A494BD9e|0x8004B663056A597Dffe9eCcC1965A193B7388713"
CHAINS[base-sepolia]="84532|https://sepolia.base.org|0x8004A818BFB912233c491871b3d84c89A494BD9e|0x8004B663056A597Dffe9eCcC1965A193B7388713"
CHAINS[avalanche-fuji]="43113|https://api.avax-test.network/ext/bc/C/rpc|0x8004A818BFB912233c491871b3d84c89A494BD9e|0x8004B663056A597Dffe9eCcC1965A193B7388713"

if [ -z "${CHAINS[$CHAIN]+x}" ]; then
  echo "Error: Unknown chain '$CHAIN'."
  exit 1
fi

IFS='|' read -r CHAIN_ID RPC_URL IDENTITY_REGISTRY REPUTATION_REGISTRY <<< "${CHAINS[$CHAIN]}"

AGENT_ID="${1:-}"
if [ -z "$AGENT_ID" ]; then
  echo "Usage: CHAIN=<chain> ./scripts/verify-agent.sh <agent-id>"
  exit 1
fi

if ! command -v cast &> /dev/null; then
  echo "Error: 'cast' (Foundry) is required."
  exit 1
fi

PASS=0
FAIL=0
WARN=0

check() {
  local label="$1"
  local status="$2"
  if [ "$status" = "PASS" ]; then
    echo "  [PASS] $label"
    PASS=$((PASS + 1))
  elif [ "$status" = "WARN" ]; then
    echo "  [WARN] $label"
    WARN=$((WARN + 1))
  else
    echo "  [FAIL] $label"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== ERC-8004 Agent Verification ==="
echo "Chain: $CHAIN (Chain ID: $CHAIN_ID)"
echo "Agent ID: $AGENT_ID"
echo ""

# 1. On-chain checks
echo "--- On-Chain ---"

OWNER=$(cast call "$IDENTITY_REGISTRY" "ownerOf(uint256)(address)" "$AGENT_ID" --rpc-url "$RPC_URL" 2>/dev/null || echo "")
if [ -n "$OWNER" ] && [ "$OWNER" != "0x0000000000000000000000000000000000000000" ]; then
  check "Agent registered (owner: $OWNER)" "PASS"
else
  check "Agent not registered" "FAIL"
  echo ""
  echo "Agent #$AGENT_ID is not registered on $CHAIN. Cannot continue."
  exit 1
fi

TOKEN_URI=$(cast call "$IDENTITY_REGISTRY" "tokenURI(uint256)(string)" "$AGENT_ID" --rpc-url "$RPC_URL" 2>/dev/null || echo "")
if [ -n "$TOKEN_URI" ]; then
  check "Token URI set: $TOKEN_URI" "PASS"
else
  check "Token URI not set" "FAIL"
fi

# 2. Metadata checks
echo ""
echo "--- Metadata ---"

if [[ "$TOKEN_URI" == http* ]]; then
  HTTP_STATUS=$(curl -s -o /tmp/agent-reg.json -w "%{http_code}" "$TOKEN_URI" 2>/dev/null || echo "000")
  if [ "$HTTP_STATUS" = "200" ]; then
    check "Metadata accessible (HTTP 200)" "PASS"

    # Validate JSON
    if jq . /tmp/agent-reg.json > /dev/null 2>&1; then
      check "Valid JSON" "PASS"

      NAME=$(jq -r '.name // empty' /tmp/agent-reg.json)
      [ -n "$NAME" ] && check "Name: $NAME" "PASS" || check "Missing name" "FAIL"

      DESC=$(jq -r '.description // empty' /tmp/agent-reg.json)
      [ -n "$DESC" ] && check "Description present (${#DESC} chars)" "PASS" || check "Missing description" "FAIL"

      IMAGE=$(jq -r '.image // empty' /tmp/agent-reg.json)
      if [ -n "$IMAGE" ]; then
        IMG_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$IMAGE" 2>/dev/null || echo "000")
        [ "$IMG_STATUS" = "200" ] && check "Image accessible: $IMAGE" "PASS" || check "Image not accessible (HTTP $IMG_STATUS)" "FAIL"
      else
        check "Missing image" "WARN"
      fi

      TYPE=$(jq -r '.type // empty' /tmp/agent-reg.json)
      [[ "$TYPE" == *"eip-8004"* ]] && check "Type field correct" "PASS" || check "Missing or incorrect type field" "FAIL"

      ACTIVE=$(jq -r '.active // empty' /tmp/agent-reg.json)
      [ "$ACTIVE" = "true" ] && check "Agent active" "PASS" || check "Agent not active" "WARN"

      # Check services
      echo ""
      echo "--- Services ---"
      SERVICES=$(jq -r '.services[]?.name' /tmp/agent-reg.json 2>/dev/null || echo "")
      if [ -n "$SERVICES" ]; then
        while IFS= read -r svc; do
          ENDPOINT=$(jq -r ".services[] | select(.name==\"$svc\") | .endpoint" /tmp/agent-reg.json)
          SVC_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$ENDPOINT" 2>/dev/null || echo "000")
          if [ "$SVC_STATUS" = "200" ] || [ "$SVC_STATUS" = "405" ]; then
            check "Service $svc ($ENDPOINT) reachable" "PASS"
          else
            check "Service $svc ($ENDPOINT) returned HTTP $SVC_STATUS" "FAIL"
          fi
        done <<< "$SERVICES"
      else
        check "No services declared" "WARN"
      fi
    else
      check "Invalid JSON" "FAIL"
    fi
  else
    check "Metadata not accessible (HTTP $HTTP_STATUS)" "FAIL"
  fi
else
  check "Non-HTTP URI (IPFS or other): $TOKEN_URI" "WARN"
fi

# 3. Reputation
echo ""
echo "--- Reputation ---"
CLIENTS=$(cast call "$REPUTATION_REGISTRY" "getClients(uint256)(address[])" "$AGENT_ID" --rpc-url "$RPC_URL" 2>/dev/null || echo "[]")
if [ "$CLIENTS" != "[]" ] && [ -n "$CLIENTS" ]; then
  check "Has reputation feedback" "PASS"
else
  check "No feedback yet" "WARN"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "  Passed: $PASS"
echo "  Warnings: $WARN"
echo "  Failed: $FAIL"

rm -f /tmp/agent-reg.json

if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo "Fix the FAIL items above before your agent is production-ready."
  exit 1
fi
