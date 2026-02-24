# Registration Transactions

On-chain proof that ERC-8004 agents are registered with real NFTs on the Avalanche network.

## Agent #1686 — AvaRiskScan (Avalanche Mainnet)

| Field | Value |
|-------|-------|
| Chain | Avalanche C-Chain (eip155:43114) |
| Agent ID | 1686 |
| Registry | `0x8004A169FB4a3325136EB29fA0ceB6D2e539a432` |
| Wallet | `0x29a45b03F07D1207f2e3ca34c38e7BE5458CE71a` |
| Registration URL | `https://avariskscan-defi-production.up.railway.app/registration.json` |

### How to Verify

```bash
# Read the agent's registration URI from the registry (ERC-721 standard)
cast call 0x8004A169FB4a3325136EB29fA0ceB6D2e539a432 \
  "tokenURI(uint256)(string)" 1686 \
  --rpc-url https://api.avax.network/ext/bc/C/rpc

# Check the owner of the agent NFT
cast call 0x8004A169FB4a3325136EB29fA0ceB6D2e539a432 \
  "ownerOf(uint256)(address)" 1686 \
  --rpc-url https://api.avax.network/ext/bc/C/rpc

# Fetch the registration metadata
curl -s https://avariskscan-defi-production.up.railway.app/registration.json | jq .
```

---

## Agent #1687 — Apex Arbitrage (Avalanche Mainnet)

| Field | Value |
|-------|-------|
| Chain | Avalanche C-Chain (eip155:43114) |
| Agent ID | 1687 |
| Registry | `0x8004A169FB4a3325136EB29fA0ceB6D2e539a432` |
| Wallet | `0xcd595a299ad1d5D088B7764e9330f7B0be7ca983` |
| Registration URL | `https://apex-arbitrage-agent-production.up.railway.app/registration.json` |

### How to Verify

```bash
# Read the agent's registration URI from the registry (ERC-721 standard)
cast call 0x8004A169FB4a3325136EB29fA0ceB6D2e539a432 \
  "tokenURI(uint256)(string)" 1687 \
  --rpc-url https://api.avax.network/ext/bc/C/rpc

# Check the owner of the agent NFT
cast call 0x8004A169FB4a3325136EB29fA0ceB6D2e539a432 \
  "ownerOf(uint256)(address)" 1687 \
  --rpc-url https://api.avax.network/ext/bc/C/rpc

# Fetch the registration metadata
curl -s https://apex-arbitrage-agent-production.up.railway.app/registration.json | jq .
```

---

## Agent #15 — AvaRiskScan (Avalanche Fuji Testnet)

| Field | Value |
|-------|-------|
| Chain | Avalanche Fuji Testnet (eip155:43113) |
| Agent ID | 15 |
| Registry | `0x8004A818C2B4fF20386a0e25Ca0d69e418e9cE77` |
| Registration URL | `https://avariskscan-defi-production.up.railway.app/registration.json` |

### How to Verify

```bash
# Read the agent's registration URI from the Fuji registry (ERC-721 standard)
cast call 0x8004A818C2B4fF20386a0e25Ca0d69e418e9cE77 \
  "tokenURI(uint256)(string)" 15 \
  --rpc-url https://api.avax-test.network/ext/bc/C/rpc

# Check the owner of the agent NFT
cast call 0x8004A818C2B4fF20386a0e25Ca0d69e418e9cE77 \
  "ownerOf(uint256)(address)" 15 \
  --rpc-url https://api.avax-test.network/ext/bc/C/rpc
```

---

## Notes

- Both mainnet agents share the same Identity Registry contract (`0x8004A169...`), meaning they are discoverable from a single on-chain query
- The Fuji testnet registration (Agent #15) uses a separate registry (`0x8004A818...`) deployed on the test network
- Agent IDs are sequential -- #1686 was registered before #1687
- Each registration mints an ERC-721 NFT to the registering wallet, proving ownership
- The `tokenURI` function (ERC-721 standard) returns a live URL serving the agent's registration metadata in JSON format
- Feedback and reputation are handled by a separate **Reputation Registry** (`0x8004BAa17C55a88189AE136b182e5fdA19dE9b63`)
