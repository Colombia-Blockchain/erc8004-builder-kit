# Scanner Warning Codes

Reference for all warning codes from ERC-8004 scanners (8004scan.io, erc-8004scan.xyz).

## Warning Codes

### WA080: On-chain vs Off-chain Metadata Conflict

**Severity**: High
**Impact**: Lowers Compliance score

The metadata registered on-chain (`tokenURI`) doesn't match your hosted `registration.json`.

**Common causes**:
- Updated `registration.json` but didn't call `setAgentURI` on-chain
- Using IPFS with a new CID but old CID is still registered on-chain
- The `registrations` array in JSON doesn't match actual on-chain agent ID

**Fix**:
```bash
# Force metadata refresh by updating on-chain URI
CHAIN=base PRIVATE_KEY=$KEY ./scripts/update-uri.sh <agent-id> "https://your-agent.com/registration.json"
```

### WA081: Missing Required Fields

**Severity**: High
**Impact**: Agent may not be indexed

Missing `type`, `name`, `description`, or `image` in registration.json.

**Fix**: Ensure all required fields are present:
```json
{
  "type": "https://eips.ethereum.org/EIPS/eip-8004#registration-v1",
  "name": "Your Agent",
  "description": "What it does",
  "image": "https://your-agent.com/public/agent.png"
}
```

### WA082: Unreachable Service Endpoint

**Severity**: Medium
**Impact**: Lowers Service score

A service declared in `registration.json` returns non-200 status.

**Fix**: Either implement the endpoint or remove it from services array.

### WA083: Invalid Image URL

**Severity**: Medium
**Impact**: No avatar in scanner

The image URL returns 404 or non-image content type.

**Fix**:
- Ensure image is publicly accessible (test in incognito browser)
- Use PNG or JPG format, min 256x256px
- Host on same domain as agent

### WA084: Missing Version on Protocol Services

**Severity**: Low
**Impact**: May affect compatibility detection

A2A, MCP, or OASF services declared without a `version` field.

**Fix**: Add version:
- A2A: `"version": "0.3.0"`
- MCP: `"version": "2025-11-25"`
- OASF: `"version": "0.8"`

### WA085: Agent Marked Inactive

**Severity**: Info
**Impact**: Agent deprioritized in search results

`"active": false` in registration.json.

**Fix**: Set `"active": true` if your agent is live.

### WA086: No Reputation Feedback

**Severity**: Info
**Impact**: Low Engagement score

No on-chain feedback received yet.

**Fix**: Encourage users/agents to give feedback. Provide value first.

### WA087: Stale Metadata

**Severity**: Low
**Impact**: Lower Momentum score

`updatedAt` timestamp is very old (30+ days).

**Fix**: Update `updatedAt` in registration.json and redeploy:
```json
"updatedAt": 1740000000
```

### WA088: MCP Tools Mismatch

**Severity**: Medium
**Impact**: Lowers Service score

`mcpTools` listed in registration metadata don't match what `tools/list` returns.

**Fix**: Keep `mcpTools` in sync with your actual MCP tools:
```json
{
  "name": "MCP",
  "endpoint": "https://your-agent.com/mcp",
  "version": "2025-11-25",
  "mcpTools": ["tool1", "tool2", "tool3"]
}
```

## Prevention Checklist

Before registering or updating:

- [ ] `cat registration.json | jq .` validates without errors
- [ ] All service endpoints return HTTP 200
- [ ] Image URL is accessible from outside your network
- [ ] `agentId` matches your on-chain registration
- [ ] `active` is `true`
- [ ] Protocol versions are specified
- [ ] Description matches actual capabilities
