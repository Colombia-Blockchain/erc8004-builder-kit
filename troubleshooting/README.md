# Troubleshooting

Real-world problems and solutions from building and operating two ERC-8004 agents in production.

## By Category

### Deployment Issues
- [502 Bad Gateway on Railway](errors-and-fixes.md#502-bad-gateway-after-deploy)
- [Build fails: TypeScript errors](errors-and-fixes.md#build-fails-typescript-errors)
- [Missing environment variables](errors-and-fixes.md#app-crashes-missing-environment-variables)
- [Auto-deploy stops working](errors-and-fixes.md#auto-deploy-stops-working)

### Scanner Warnings
- [WA080: Metadata conflict](scanner-warnings.md#wa080-on-chain-vs-off-chain-metadata-conflict)
- [Unreachable service endpoint](scanner-warnings.md#unreachable-service-endpoint)
- [All warning codes](scanner-warnings.md)

### API Issues
- [Rate limiting (429)](errors-and-fixes.md#coingecko-rate-limiting)
- [Sequential calls causing timeouts](errors-and-fixes.md#sequential-api-calls-causing-timeouts)
- [Memory leaks from caches](errors-and-fixes.md#memory-leaks-from-uncleaned-caches)

### On-Chain Issues
- [Transaction reverted](errors-and-fixes.md#transaction-reverted-insufficient-gas)
- [Wrong agent ID](errors-and-fixes.md#wrong-agent-id-in-registration)
- [Snowtrace shows old metadata](errors-and-fixes.md#snowtrace-shows-old-metadata)

### Common Mistakes
- [Top 10 mistakes building ERC-8004 agents](common-mistakes.md)

## Quick Diagnostics

```bash
# Is my agent alive?
curl -s https://your-agent.com/api/health | jq .

# Is my metadata valid?
curl -s https://your-agent.com/registration.json | jq .

# Does MCP work?
curl -s -X POST https://your-agent.com/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}' | jq '.result.tools | length'

# Run full verification
CHAIN=base ./scripts/verify-agent.sh YOUR_AGENT_ID
```
