# Scanner Warning and Info Codes

Complete reference for all warning (WA0XX) and informational (IA0XX) codes emitted by ERC-8004 scanners (8004scan.io, erc-8004scan.xyz). These codes follow the official 8004scan specification.

---

## Warning Codes (WA0XX)

### WA001: Missing type field

**Severity**: High
**Impact**: Agent metadata will not be recognized as ERC-8004 compliant.

The `type` field is missing from your registration metadata.

**Fix**: Add the required type field:
```json
{
  "type": "https://eips.ethereum.org/EIPS/eip-8004#registration-v1"
}
```

### WA002: Invalid type value

**Severity**: High
**Impact**: Scanner cannot classify metadata correctly.

The `type` field exists but contains an incorrect value.

**Fix**: Use the exact canonical URL:
```json
"type": "https://eips.ethereum.org/EIPS/eip-8004#registration-v1"
```

### WA003: Missing name

**Severity**: High
**Impact**: Agent will not be indexed properly.

The `name` field is absent from registration metadata.

**Fix**: Add a name between 3 and 200 characters:
```json
"name": "Your Agent Name"
```

### WA004: Missing description

**Severity**: High
**Impact**: Agent will not be indexed properly.

The `description` field is absent from registration metadata.

**Fix**: Add a description between 50 and 500 characters that clearly explains what your agent does:
```json
"description": "A brief but informative description of your agent's capabilities and purpose (50-500 chars)."
```

### WA005: Invalid image URL

**Severity**: Medium
**Impact**: No avatar displayed in the scanner UI.

The `image` URL is malformed or uses a disallowed scheme.

**Fix**: Use an absolute URI with one of the allowed schemes:
```json
"image": "https://your-agent.com/logo.png"
```
Accepted schemes: `https://`, `ipfs://`, or `data:` (base64-encoded).

### WA006: endpoints not an array

**Severity**: Medium
**Impact**: Services will not be parsed.

The `endpoints` (or `services`) field is present but is not a JSON array.

**Fix**: Ensure it is a proper array:
```json
"services": [
  { "name": "MCP", "endpoint": "https://your-agent.com/mcp" }
]
```

### WA007: Endpoint object invalid

**Severity**: Medium
**Impact**: Individual service entry is skipped during indexing.

An entry inside the services array is not a valid JSON object.

**Fix**: Ensure every entry in the array is a well-formed object with at minimum a `name` and `endpoint` field.

### WA008: Missing endpoint URL field

**Severity**: Medium
**Impact**: Service entry cannot be validated or probed.

A service object is missing its `endpoint` (URL) field.

**Fix**: Add the `endpoint` field:
```json
{ "name": "MCP", "endpoint": "https://your-agent.com/mcp", "version": "2025-06-18" }
```

### WA009: Empty endpoint URL

**Severity**: Medium
**Impact**: Service entry cannot be validated or probed.

The `endpoint` field exists but is an empty string.

**Fix**: Provide a valid, reachable URL for the service.

### WA010: registrations not an array

**Severity**: Medium
**Impact**: On-chain registration data will not be parsed.

The `registrations` field is present but is not a JSON array.

**Fix**: Use an array of registration objects:
```json
"registrations": [
  {
    "agentRegistry": "eip155:8453:0xYourRegistryAddress",
    "agentId": "123"
  }
]
```

### WA011: Registration object invalid

**Severity**: Medium
**Impact**: Individual registration entry is skipped.

An entry in the `registrations` array is not a valid JSON object.

**Fix**: Ensure each entry contains at least `agentRegistry` and `agentId`.

### WA012: Missing agentRegistry

**Severity**: High
**Impact**: Scanner cannot link metadata to an on-chain registry.

The `agentRegistry` field is missing from a registration entry.

**Fix**: Add the registry address in CAIP-10 format:
```json
"agentRegistry": "eip155:8453:0xYourRegistryAddress"
```

### WA013: Invalid agentRegistry format

**Severity**: High
**Impact**: Registry lookup will fail.

The `agentRegistry` value does not conform to CAIP-10 format.

**Fix**: Use the format `eip155:<chainId>:<0xAddress>`:
```json
"agentRegistry": "eip155:8453:0x1234567890abcdef1234567890abcdef12345678"
```

### WA014: supportedTrust not an array

**Severity**: Low
**Impact**: Trust mechanisms will not be parsed.

The `supportedTrust` field is present but is not a JSON array.

**Fix**: Use an array of trust mechanism strings:
```json
"supportedTrust": ["x402", "erc-8004-reputation"]
```

### WA015: active not boolean

**Severity**: Low
**Impact**: Active status may be misinterpreted.

The `active` field contains a string or number instead of a boolean.

**Fix**: Use a literal boolean value, not a string:
```json
"active": true
```
Do not use `"true"` (string) or `1` (number).

### WA016: x402Support not boolean

**Severity**: Low
**Impact**: x402 payment capability may be misinterpreted.

The `x402Support` field is not a boolean.

**Fix**: Use a literal boolean:
```json
"x402Support": true
```

### WA020: Found singular endpoint

**Severity**: Medium
**Impact**: Field will be ignored; services will appear empty.

The metadata uses `endpoint` (singular) instead of `services` (plural).

**Fix**: Rename the field to `services` and ensure it is an array:
```json
"services": [
  { "name": "MCP", "endpoint": "https://your-agent.com/mcp" }
]
```

### WA021: Found singular registration

**Severity**: Medium
**Impact**: Field will be ignored; registrations will appear empty.

The metadata uses `registration` (singular) instead of `registrations` (plural).

**Fix**: Rename to `registrations` (plural):
```json
"registrations": [
  { "agentRegistry": "eip155:8453:0xAddr", "agentId": "123" }
]
```

### WA030: agentWallet not CAIP-10

**Severity**: Medium
**Impact**: Wallet lookups and payment routing may fail.

The `agentWallet` value is a plain Ethereum address instead of CAIP-10 format.

**Fix**: Use `eip155:<chainId>:<0xAddress>` format:
```json
"agentWallet": "eip155:8453:0xYourWalletAddress"
```

### WA031: Using legacy endpoints field

**Severity**: Medium
**Impact**: Legacy field may be deprecated in future scanner versions.

The metadata uses the old `endpoints` field name instead of `services`.

**Fix**: Migrate from `endpoints` to `services`:
```diff
- "endpoints": [...]
+ "services": [...]
```

### WA050: Base64 URI contains plain JSON

**Severity**: Low
**Impact**: Data URI will still be parsed, but encoding is non-standard.

A `data:` URI claims base64 encoding but the content is actually plain JSON text.

**Fix**: Either properly base64-encode the JSON, or use a plain data URI without the base64 flag.

### WA051: Non-standard base64 format

**Severity**: Low
**Impact**: Parsing may fail on strict implementations.

The base64-encoded content does not conform to standard encoding rules.

**Fix**: Re-encode using standard base64 (RFC 4648).

### WA052: Non-standard plain data URI

**Severity**: Low
**Impact**: May not parse on all implementations.

A plain (non-base64) data URI uses a non-standard format.

**Fix**: Use the format `data:application/json,<url-encoded-json>` or switch to base64.

### WA053: Plain JSON without URI scheme

**Severity**: Low
**Impact**: Scanner will attempt to parse it, but behavior is undefined.

The `tokenURI` or metadata source contains raw JSON without any URI scheme prefix.

**Fix**: Host the JSON at an HTTPS or IPFS URL and reference it properly, or use a `data:` URI.

### WA054: UTF-8 decode error

**Severity**: Medium
**Impact**: Metadata cannot be read.

The content could not be decoded as valid UTF-8.

**Fix**: Ensure your JSON file is saved with UTF-8 encoding without BOM.

### WA055: Invalid JSON in base64

**Severity**: High
**Impact**: Metadata cannot be parsed.

After base64-decoding, the resulting content is not valid JSON.

**Fix**: Verify that the base64-encoded payload is valid JSON before encoding. Test with:
```bash
echo "<base64-string>" | base64 -d | jq .
```

### WA056: Invalid JSON in plain data URI

**Severity**: High
**Impact**: Metadata cannot be parsed.

The plain data URI content is not valid JSON.

**Fix**: Validate the JSON payload before embedding it in the data URI.

### WA070: Metadata hash mismatch

**Severity**: High
**Impact**: Lowers Compliance score. Scanner flags the agent as potentially stale or tampered.

The `agentHash` stored on-chain does not match the hash computed from the current off-chain metadata.

**Fix**: Update the on-chain hash after any metadata change:
```bash
# Recompute and update the hash on-chain
cast send $REGISTRY "setAgentHash(uint256,bytes32)" $AGENT_ID $(cast keccak $(cat registration.json))
```

### WA071: Content changed since last sync

**Severity**: Medium
**Impact**: Scanner detects drift between indexed content and current content.

The hosted metadata has been modified since the scanner last indexed it, but no on-chain update was made.

**Fix**: Either revert the off-chain change or update the on-chain URI/hash to trigger a re-index.

### WA080: On-chain vs off-chain metadata conflict

**Severity**: High
**Impact**: Lowers Compliance score. May confuse consumers reading your agent metadata.

There is a discrepancy between on-chain state and the off-chain registration JSON. On-chain data always takes priority.

**Common causes**:
- Updated `registration.json` but did not call `setAgentURI` on-chain
- Changed IPFS CID locally but the old CID is still registered on-chain
- The `registrations` array in JSON does not match the actual on-chain agent ID

**Fix**: Synchronize by updating the on-chain URI to point to the current metadata:
```bash
CHAIN=base PRIVATE_KEY=$KEY ./scripts/update-uri.sh <agent-id> "https://your-agent.com/registration.json"
```

### WA081: Contract state vs metadata conflict

**Severity**: High
**Impact**: Consumers may see stale or contradictory information.

Fields in the on-chain contract state (e.g., active status, wallet) differ from corresponding fields in the off-chain JSON.

**Fix**: Update the on-chain metadata to match. On-chain state is authoritative:
```bash
# Example: update on-chain active status
cast send $REGISTRY "setAgentActive(uint256,bool)" $AGENT_ID true
```

### WA083: agentWallet in off-chain JSON

**Severity**: Medium
**Impact**: The wallet value in JSON is ignored; only the on-chain value is used.

The `agentWallet` field was found in the off-chain registration JSON. This field should only be set on-chain via the registry contract.

**Fix**: Remove `agentWallet` from your `registration.json` and set it exclusively via the contract:
```bash
cast send $REGISTRY "setAgentWallet(uint256,address)" $AGENT_ID 0xYourWallet
```
The scanner reads wallet data from the contract, not from JSON.

---

## Info/Recommendation Codes (IA0XX)

These are non-blocking recommendations. They do not cause compliance failures but addressing them improves your agent's visibility and score.

### IA001: Missing image

**Severity**: Info
**Impact**: No avatar in scanner listings.

No `image` field found in metadata.

**Fix**: Add a logo URL (PNG or SVG, minimum 256x256px):
```json
"image": "https://your-agent.com/logo.png"
```

### IA002: No endpoints defined

**Severity**: Info
**Impact**: Service score will be zero.

No `services` array found in metadata.

**Fix**: Add a services array with at least one entry:
```json
"services": [
  { "name": "MCP", "endpoint": "https://your-agent.com/mcp", "version": "2025-06-18" }
]
```

### IA003: Empty endpoints array

**Severity**: Info
**Impact**: Service score will be zero.

The `services` array exists but contains no entries.

**Fix**: Populate with at least one service definition.

### IA004: Missing registrations

**Severity**: Info
**Impact**: Scanner cannot link metadata to on-chain identity.

No `registrations` array found.

**Fix**: Add a registrations array:
```json
"registrations": [
  {
    "agentRegistry": "eip155:8453:0xYourRegistryAddress",
    "agentId": "123"
  }
]
```

### IA005: Empty registrations

**Severity**: Info
**Impact**: Scanner cannot link metadata to on-chain identity.

The `registrations` array exists but contains no entries.

**Fix**: Add at least one registration entry pointing to your on-chain agent ID.

### IA006: Missing agentId

**Severity**: Info
**Impact**: Scanner cannot map metadata to a specific on-chain token.

The `agentId` field is missing from a registration entry.

**Fix**: After registering your agent on-chain, update the metadata with the assigned token ID:
```json
"agentId": "42"
```

### IA007: agentId null

**Severity**: Info
**Impact**: Same as IA006.

The `agentId` field is present but set to `null`.

**Fix**: Replace `null` with the actual token ID assigned during on-chain registration.

### IA008: Empty supportedTrust

**Severity**: Info
**Impact**: Trust mechanisms will show as "none" in scanner.

The `supportedTrust` array is empty.

**Fix**: Add trust mechanisms your agent supports:
```json
"supportedTrust": ["x402", "erc-8004-reputation"]
```

### IA020: MCP missing version

**Severity**: Info
**Impact**: Compatibility detection may be inaccurate.

An MCP service entry has no `version` field.

**Fix**: Add a version using the date format `YYYY-MM-DD`:
```json
{ "name": "MCP", "endpoint": "https://your-agent.com/mcp", "version": "2025-06-18" }
```

### IA021: MCP version not date format

**Severity**: Info
**Impact**: Version comparison may fail.

The MCP version string does not follow the expected `YYYY-MM-DD` format.

**Fix**: Use a date string, for example `"2025-06-18"`.

### IA022: A2A missing version

**Severity**: Info
**Impact**: Compatibility detection may be inaccurate.

An A2A service entry has no `version` field.

**Fix**: Add a version using semantic versioning:
```json
{ "name": "A2A", "endpoint": "https://your-agent.com/a2a", "version": "0.3.0" }
```

### IA023: A2A version not semver

**Severity**: Info
**Impact**: Version comparison may fail.

The A2A version string does not follow semantic versioning (e.g., `0.3.0`).

**Fix**: Use a valid semver string such as `"0.3.0"`.

### IA024: A2A missing .well-known path

**Severity**: Info
**Impact**: A2A discovery may not work for other agents.

The A2A endpoint does not include or serve the `.well-known/agent.json` path.

**Fix**: Ensure your A2A agent card is accessible at:
```
https://your-agent.com/.well-known/agent.json
```

### IA025: OASF missing version

**Severity**: Info
**Impact**: OASF compatibility cannot be determined.

An OASF service entry has no `version` field.

**Fix**: Add the OASF version:
```json
{ "name": "OASF", "endpoint": "https://your-agent.com/oasf", "version": "0.8" }
```

### IA026: OASF version not recognized

**Severity**: Info
**Impact**: May affect interoperability checks.

The OASF version does not match a known release version.

**Fix**: Use a recognized OASF version string.

### IA027: OASF schema validation failed

**Severity**: Info
**Impact**: OASF service may not interoperate correctly.

The OASF endpoint returned content that does not validate against the expected schema.

**Fix**: Verify your OASF implementation against the specification.

### IA028: OASF endpoint unreachable

**Severity**: Info
**Impact**: OASF service will not be indexed.

The OASF endpoint URL returned an error or timed out.

**Fix**: Ensure the endpoint is publicly reachable and returns a valid response.

### IA040: HTTP URI not content-addressed

**Severity**: Info
**Impact**: Metadata integrity cannot be verified without a hash.

The `tokenURI` uses a plain HTTPS URL, which means content can change without on-chain detection.

**Fix**: Either:
1. Switch to IPFS for content-addressed hosting, or
2. Set `agentHash` on-chain so the scanner can verify integrity:
```bash
cast send $REGISTRY "setAgentHash(uint256,bytes32)" $AGENT_ID $(cast keccak $(cat registration.json))
```

### IA050: Value from contract state

**Severity**: Info
**Impact**: None (informational only).

The scanner is reporting a value that was read directly from contract state rather than from off-chain metadata. This is normal behavior and indicates that on-chain data is being used as the authoritative source.

No action required.

---

## Why My Service Score Is 0

Having services declared in your `registration.json` is **necessary but not sufficient** for a non-zero Service score. The scanner computes Service score based on **actual interactions**, not just declared capabilities.

### How Service Score Works

1. **Declaration** -- You list services (MCP, A2A, OASF) in your metadata. This satisfies compliance checks but does not directly contribute to the Service score.
2. **Consumption** -- Other agents or clients must actually call your service endpoints. The scanner indexes these interactions by monitoring protocol-level activity (MCP tool calls, A2A task executions, x402 payment flows).
3. **Indexing** -- The scanner crawls and indexes interaction logs on a periodic cycle. Until the next indexing pass, new interactions will not be reflected.

### Common Reasons for Service = 0

- **No external consumers**: Your agent has declared services but no other agent has called them yet.
- **Interactions not logged**: Calls are happening but are not being captured in a way the scanner can index (e.g., private network, no x402 payment receipts).
- **Indexing delay**: Interactions occurred recently but the scanner has not re-indexed yet.

### How to Fix It

1. **Get other agents to call your endpoints.** Register your agent in directories, announce it in agent networks, and ensure your MCP/A2A endpoints are publicly reachable.
2. **Use x402 payments.** When your agent provides paid services via x402, the on-chain payment transactions serve as verifiable proof of service consumption that the scanner can index.
3. **Wait for re-indexing.** After interactions occur, allow time for the scanner's next indexing cycle to pick up the new data.

---

## Why TRACER Capability/Reputation Is 0

The TRACER scoring system has independent dimensions. Capability and Reputation each require specific on-chain or verifiable activity to be non-zero.

### Capability Score = 0

The Capability score measures whether your agent's declared tools and services actually function correctly. It requires a **sentinel** (an automated test agent) to:

1. Discover your agent's declared tools (via MCP `tools/list`, A2A agent card, etc.)
2. Execute those tools with test inputs
3. Verify the outputs meet expected criteria
4. Report the results back to the scanner

Until a sentinel has tested your agent's actual tool execution, the Capability score remains at zero. You can deploy your own sentinel to perform these tests (see the `src/sentinels` directory in this repository for examples).

### Reputation Score = 0

The Reputation score is derived from on-chain feedback stored in the **ReputationRegistry** contract:

```
ReputationRegistry: 0x8004BAa17C55a88189AE136b182e5fdA19dE9b63
```

For Reputation to be non-zero, other agents or users must submit feedback about your agent using the `giveFeedback()` function:

```solidity
function giveFeedback(
    uint256 agentId,
    uint8 rating,       // 1-5
    string calldata comment
) external;
```

**Example using cast:**
```bash
cast send 0x8004BAa17C55a88189AE136b182e5fdA19dE9b63 \
  "giveFeedback(uint256,uint8,string)" \
  42 5 "Reliable MCP tool execution, fast responses" \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL
```

### How to Fix Both

1. **Deploy a sentinel** that periodically tests your agent's tools and reports results. This addresses Capability.
2. **Encourage feedback.** After successful interactions (especially paid x402 interactions), prompt the calling agent or user to submit on-chain feedback. This addresses Reputation.
3. **Provide genuine value.** Both scores are designed to reflect real-world utility. Agents that reliably serve useful tools and earn positive feedback will naturally accumulate scores.

---

## Real-World Example: From Zero to Scored

Our own agents (Cyberpaisa sentinel network) initially showed **Service = 0** and **Reputation = 0** on 8004scan despite having well-formed metadata and declared services. Here is what we observed and what we did:

### Initial State
- Compliance score: High (metadata was valid, no WA0XX warnings)
- Service score: 0 (no indexed interactions)
- Capability score: 0 (no sentinel had tested our tools)
- Reputation score: 0 (no on-chain feedback)

### Actions Taken
1. **Enabled x402 payment flows** on our MCP endpoints. This created on-chain transaction receipts that the scanner could index as proof of service consumption.
2. **Deployed a sentinel** (see `src/sentinels/`) that periodically calls our agent's tools and reports execution results.
3. **Submitted on-chain feedback** via `giveFeedback()` on the ReputationRegistry after verifying successful cross-agent interactions.

### Expected Outcome
After the next scanner indexing cycle, we expect:
- **Service score** to increase based on indexed x402 transactions
- **Capability score** to increase based on sentinel test reports
- **Reputation score** to increase based on on-chain feedback entries

This process is not instant. Scanner indexing runs on a periodic schedule. Allow at least one full cycle (typically 24-48 hours) before expecting score changes.

---

## Prevention Checklist

Run through this checklist before registering or updating your agent:

### Metadata Validation
- [ ] `cat registration.json | jq .` parses without errors
- [ ] `type` field is exactly `"https://eips.ethereum.org/EIPS/eip-8004#registration-v1"`
- [ ] `name` is between 3 and 200 characters
- [ ] `description` is between 50 and 500 characters
- [ ] `image` URL uses `https://`, `ipfs://`, or `data:` scheme and is publicly accessible
- [ ] `active` is a boolean (`true` or `false`), not a string
- [ ] `x402Support` is a boolean if present

### Services
- [ ] Field is named `services` (not `endpoints` or `endpoint`)
- [ ] `services` is a JSON array
- [ ] Every service object has a `name` and `endpoint` field
- [ ] Every `endpoint` URL is non-empty and publicly reachable (returns HTTP 200)
- [ ] MCP services include `version` in `YYYY-MM-DD` format (e.g., `"2025-06-18"`)
- [ ] A2A services include `version` in semver format (e.g., `"0.3.0"`)
- [ ] A2A agent card is served at `/.well-known/agent.json`
- [ ] OASF services include `version` if applicable

### Registrations
- [ ] Field is named `registrations` (not `registration`)
- [ ] `registrations` is a JSON array with at least one entry
- [ ] Every entry has `agentRegistry` in CAIP-10 format (`eip155:<chainId>:<0xAddress>`)
- [ ] Every entry has `agentId` set to the actual on-chain token ID (not `null`)

### On-Chain Consistency
- [ ] On-chain `tokenURI` points to the current, live metadata URL
- [ ] `agentHash` on-chain matches `keccak256` of the current metadata (if using HTTP URIs)
- [ ] `agentWallet` is set only on-chain via `setAgentWallet()`, not in the JSON
- [ ] On-chain `active` status matches the intended state

### Trust and Payments
- [ ] `supportedTrust` array is populated if applicable
- [ ] `agentWallet` is in CAIP-10 format on-chain (if set)
- [ ] x402 payment endpoints are functional if `x402Support` is `true`

### Post-Registration
- [ ] Run `8004scan` or check the scanner UI for any WA0XX or IA0XX codes
- [ ] Verify all scores are updating after interactions occur
- [ ] Monitor for WA070 (hash mismatch) after any metadata update
- [ ] Re-sync on-chain state after any off-chain metadata change
