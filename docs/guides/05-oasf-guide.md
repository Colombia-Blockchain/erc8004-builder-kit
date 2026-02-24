# 05 — OASF: Open Agentic Schema Framework

OASF enables agent discovery by skills and domains. Think of it as putting a sign on your restaurant door — other agents can see what you offer without walking in.

## Why OASF?

Without OASF, another agent must:
1. Fetch your registration.json
2. Read your A2A agent card
3. Call MCP tools/list
4. Try different endpoints

With OASF, another agent sees your sign:
> "This agent knows blockchain, DeFi, and Avalanche."

**Cost: $0.** OASF is a static GET endpoint returning JSON. No external APIs, no LLM calls.

## Implementation

### Endpoint: GET /oasf

#### TypeScript (Hono)

```typescript
app.get("/oasf", (c) => {
  return c.json({
    name: registration.name,
    description: registration.description,
    version: VERSION,
    framework: "oasf",
    frameworkVersion: "0.8",
    skills: [
      "natural_language_processing/information_retrieval_synthesis/search",
      "natural_language_processing/conversation/chatbot",
      "tool_interaction/api_schema_understanding",
      "tool_interaction/automation/workflow_automation",
    ],
    domains: [
      "technology/blockchain",
      "finance/defi/analytics",
      "technology/software_engineering/apis_integration",
    ],
    mcpTools: registration.services
      ?.find((s: { name: string }) => s.name === "MCP")
      ?.mcpTools || [],
    capabilities: registration.capabilities || [],
    updatedAt: new Date().toISOString(),
  });
});
```

#### Python (FastAPI)

```python
@app.get("/oasf")
async def oasf():
    return {
        "name": REGISTRATION["name"],
        "description": REGISTRATION.get("description", ""),
        "version": VERSION,
        "framework": "oasf",
        "frameworkVersion": "0.8",
        "skills": [
            "natural_language_processing/information_retrieval_synthesis/search",
            "tool_interaction/api_schema_understanding",
        ],
        "domains": [
            "technology/blockchain",
        ],
        "mcpTools": [],
        "capabilities": REGISTRATION.get("capabilities", []),
        "updatedAt": datetime.now(timezone.utc).isoformat(),
    }
```

## Skills Taxonomy

OASF uses a hierarchical skill taxonomy:

```
natural_language_processing/
├── information_retrieval_synthesis/
│   ├── search
│   ├── summarization
│   └── question_answering
├── conversation/
│   ├── chatbot
│   └── dialogue_management
└── content_generation/
    ├── writing
    └── code_generation

tool_interaction/
├── api_schema_understanding
├── automation/
│   └── workflow_automation
└── data_processing/
    ├── extraction
    └── transformation
```

## Domains Taxonomy

```
technology/
├── blockchain/
│   ├── ethereum
│   ├── avalanche
│   └── defi
├── software_engineering/
│   ├── apis_integration
│   └── devops
└── ai_ml/
    └── model_inference

finance/
├── defi/
│   ├── analytics
│   ├── trading
│   └── risk_assessment
└── payments/
    └── micropayments
```

## Declaring OASF in Registration

```json
{
  "services": [
    {
      "name": "OASF",
      "endpoint": "https://your-agent.com/oasf",
      "version": "0.8",
      "skills": [
        "natural_language_processing/information_retrieval_synthesis/search",
        "tool_interaction/automation/workflow_automation"
      ],
      "domains": [
        "technology/blockchain",
        "finance/defi/analytics"
      ]
    }
  ]
}
```

## Testing

```bash
curl -s https://your-agent.com/oasf | jq .
```

Expected: JSON with name, skills, domains, and capabilities.

## Resources

- OASF GitHub: https://github.com/agntcy/oasf
- OASF MCP Server: For schema discovery and validation

---

*OASF is the simplest protocol to implement. One GET endpoint, zero cost, maximum discoverability.*
