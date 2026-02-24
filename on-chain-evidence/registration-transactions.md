# Registration Transactions

On-chain proof that ERC-8004 agents are registered with real NFTs on the Avalanche network.

## Agent #1686 — AvaRiskScan (Avalanche Mainnet)

| Field | Value |
|-------|-------|
| Chain | Avalanche C-Chain (eip155:43114) |
| Agent ID | 1686 |
| Registry | `0x8004A169FB4a3325136EB29fA0ceB6D2e539a432` |
| Registration URL | `https://avariskscan-production.up.railway.app/registration.json` |

### How to Verify

```bash
# Read the agent's registration URI from the registry
cast call 0x8004A169FB4a3325136EB29fA0ceB6D2e539a432 \
  "agentURI(uint256)(string)" 1686 \
  --rpc-url https://api.avax.network/ext/bc/C/rpc

# Check the owner of the agent NFT
cast call 0x8004A169FB4a3325136EB29fA0ceB6D2e539a432 \
  "ownerOf(uint256)(address)" 1686 \
  --rpc-url https://api.avax.network/ext/bc/C/rpc

# Fetch the registration metadata
curl -s https://avariskscan-production.up.railway.app/registration.json | jq .
```

---

## Agent #1687 — Apex Arbitrage (Avalanche Mainnet)

| Field | Value |
|-------|-------|
| Chain | Avalanche C-Chain (eip155:43114) |
| Agent ID | 1687 |
| Registry | `0x8004A169FB4a3325136EB29fA0ceB6D2e539a432` |
| Registration URL | `https://apex-production.up.railway.app/registration.json` |

### How to Verify

```bash
# Read the agent's registration URI from the registry
cast call 0x8004A169FB4a3325136EB29fA0ceB6D2e539a432 \
  "agentURI(uint256)(string)" 1687 \
  --rpc-url https://api.avax.network/ext/bc/C/rpc

# Check the owner of the agent NFT
cast call 0x8004A169FB4a3325136EB29fA0ceB6D2e539a432 \
  "ownerOf(uint256)(address)" 1687 \
  --rpc-url https://api.avax.network/ext/bc/C/rpc

# Fetch the registration metadata
curl -s https://apex-production.up.railway.app/registration.json | jq .
```

---

## Agent #15 — AvaRiskScan (Avalanche Fuji Testnet)

| Field | Value |
|-------|-------|
| Chain | Avalanche Fuji Testnet (eip155:43113) |
| Agent ID | 15 |
| Registry | `0x8004A818C2B4fF20386a0e25Ca0d69e418e9cE77` |
| Registration URL | `https://avariskscan-production.up.railway.app/registration.json` |

### How to Verify

```bash
# Read the agent's registration URI from the Fuji registry
cast call 0x8004A818C2B4fF20386a0e25Ca0d69e418e9cE77 \
  "agentURI(uint256)(string)" 15 \
  --rpc-url https://api.avax-test.network/ext/bc/C/rpc

# Check the owner of the agent NFT
cast call 0x8004A818C2B4fF20386a0e25Ca0d69e418e9cE77 \
  "ownerOf(uint256)(address)" 15 \
  --rpc-url https://api.avax-test.network/ext/bc/C/rpc
```

---

## Notes

- Both mainnet agents share the same registry contract (`0x8004A169...`), meaning they are discoverable from a single on-chain query
- The Fuji testnet registration (Agent #15) uses a separate registry (`0x8004A818...`) deployed on the test network
- Agent IDs are sequential -- #1686 was registered before #1687
- Each registration mints an ERC-721 NFT to the registering wallet, proving ownership
- The `agentURI` points to a live URL serving the agent's registration metadata in JSON format
