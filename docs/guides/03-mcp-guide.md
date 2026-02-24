# 03 — MCP (Model Context Protocol) Guide

Implement the MCP protocol to expose your agent's capabilities as structured tools that LLMs and other agents can call programmatically.

## Overview

MCP (Model Context Protocol) is Anthropic's open standard for connecting AI models to external tools and data sources. It provides a structured, type-safe way for LLMs to call your agent's functions.

```
┌──────────────┐       MCP (JSON-RPC)            ┌──────────────┐
│  LLM / Client│ ──────────────────────────────▶  │  Your Agent  │
│  (Caller)    │ ◀──────────────────────────────  │  (MCP Server)│
└──────────────┘     Structured Tool Calls        └──────────────┘
```

### MCP vs REST API

| Aspect | MCP | REST API |
|--------|-----|----------|
| Discovery | `tools/list` — self-documenting | OpenAPI spec (separate file) |
| Protocol | JSON-RPC 2.0 | HTTP methods |
| Integration | Native LLM tool calling | Manual prompt engineering |
| Type Safety | Built-in input schemas | Separate validation |
| Ecosystem | Claude, GPT, Gemini clients | Universal |

## How MCP Works

### The Protocol Flow

```
Client                                         Your MCP Server
  │                                                  │
  │  1. POST /mcp  { method: "initialize" }         │
  │ ────────────────────────────────────────────────▶│
  │                                                  │
  │  2. Server info + capabilities                  │
  │ ◀────────────────────────────────────────────────│
  │                                                  │
  │  3. POST /mcp  { method: "tools/list" }         │
  │ ────────────────────────────────────────────────▶│
  │                                                  │
  │  4. Tool definitions (name, schema, desc)       │
  │ ◀────────────────────────────────────────────────│
  │                                                  │
  │  5. POST /mcp  { method: "tools/call",          │
  │       params: { name: "...", arguments: {...} }} │
  │ ────────────────────────────────────────────────▶│
  │                                                  │
  │  6. Tool result                                 │
  │ ◀────────────────────────────────────────────────│
  └──────────────────────────────────────────────────┘
```

### Key Concepts

| Concept | Description |
|---------|-------------|
| **Server** | Your agent, exposing tools via MCP |
| **Client** | The LLM or application calling your tools |
| **Tool** | A named function with an input schema and description |
| **Resource** | Read-only data exposed by the server (optional) |
| **Prompt** | Pre-defined prompt templates (optional) |

## Server Side: Implementing MCP

### Step 1: Define Your Tools

Tools are the core of MCP. Each tool has:
- A unique `name`
- A human-readable `description` (the LLM reads this)
- An `inputSchema` (JSON Schema for parameters)

#### TypeScript (Hono)

```typescript
// src/mcp/tools.ts

export interface MCPTool {
  name: string;
  description: string;
  inputSchema: {
    type: "object";
    properties: Record<string, any>;
    required?: string[];
  };
}

export const tools: MCPTool[] = [
  {
    name: "getTokenPrice",
    description:
      "Get the current price of a cryptocurrency token by its symbol. " +
      "Returns price in USD, 24h change, and market cap.",
    inputSchema: {
      type: "object",
      properties: {
        symbol: {
          type: "string",
          description: "Token ticker symbol (e.g., 'ETH', 'BTC', 'SOL')",
        },
        currency: {
          type: "string",
          description: "Target currency for price (default: 'USD')",
          enum: ["USD", "EUR", "GBP", "JPY"],
        },
      },
      required: ["symbol"],
    },
  },
  {
    name: "analyzePortfolio",
    description:
      "Analyze a wallet's token portfolio. Returns holdings, total value, " +
      "allocation percentages, and risk assessment.",
    inputSchema: {
      type: "object",
      properties: {
        address: {
          type: "string",
          description: "Wallet address (0x...)",
        },
        chain: {
          type: "string",
          description: "Blockchain to analyze",
          enum: ["ethereum", "base", "avalanche", "polygon", "arbitrum"],
        },
      },
      required: ["address"],
    },
  },
  {
    name: "searchDocumentation",
    description:
      "Search the documentation for a specific topic. " +
      "Returns relevant sections with page references.",
    inputSchema: {
      type: "object",
      properties: {
        query: {
          type: "string",
          description: "Search query in natural language",
        },
        limit: {
          type: "number",
          description: "Maximum number of results (default: 5)",
        },
      },
      required: ["query"],
    },
  },
];
```

#### Python (FastAPI)

```python
# mcp/tools.py

tools = [
    {
        "name": "getTokenPrice",
        "description": (
            "Get the current price of a cryptocurrency token by its symbol. "
            "Returns price in USD, 24h change, and market cap."
        ),
        "inputSchema": {
            "type": "object",
            "properties": {
                "symbol": {
                    "type": "string",
                    "description": "Token ticker symbol (e.g., 'ETH', 'BTC', 'SOL')",
                },
                "currency": {
                    "type": "string",
                    "description": "Target currency for price (default: 'USD')",
                    "enum": ["USD", "EUR", "GBP", "JPY"],
                },
            },
            "required": ["symbol"],
        },
    },
    {
        "name": "analyzePortfolio",
        "description": (
            "Analyze a wallet's token portfolio. Returns holdings, total value, "
            "allocation percentages, and risk assessment."
        ),
        "inputSchema": {
            "type": "object",
            "properties": {
                "address": {
                    "type": "string",
                    "description": "Wallet address (0x...)",
                },
                "chain": {
                    "type": "string",
                    "description": "Blockchain to analyze",
                    "enum": ["ethereum", "base", "avalanche", "polygon", "arbitrum"],
                },
            },
            "required": ["address"],
        },
    },
    {
        "name": "searchDocumentation",
        "description": (
            "Search the documentation for a specific topic. "
            "Returns relevant sections with page references."
        ),
        "inputSchema": {
            "type": "object",
            "properties": {
                "query": {
                    "type": "string",
                    "description": "Search query in natural language",
                },
                "limit": {
                    "type": "number",
                    "description": "Maximum number of results (default: 5)",
                },
            },
            "required": ["query"],
        },
    },
]
```

### Step 2: Implement Tool Handlers

#### TypeScript (Hono)

```typescript
// src/mcp/handlers.ts

type ToolHandler = (args: Record<string, any>) => Promise<any>;

const toolHandlers: Record<string, ToolHandler> = {
  getTokenPrice: async (args) => {
    const { symbol, currency = "USD" } = args;

    // Replace with your actual data source
    const response = await fetch(
      `https://api.coingecko.com/api/v3/simple/price?ids=${symbol.toLowerCase()}&vs_currencies=${currency.toLowerCase()}&include_24hr_change=true&include_market_cap=true`
    );
    const data = await response.json();

    return {
      symbol: symbol.toUpperCase(),
      price: data[symbol.toLowerCase()]?.[currency.toLowerCase()] ?? "N/A",
      change24h: data[symbol.toLowerCase()]?.[`${currency.toLowerCase()}_24h_change`] ?? "N/A",
      currency,
      timestamp: new Date().toISOString(),
    };
  },

  analyzePortfolio: async (args) => {
    const { address, chain = "ethereum" } = args;

    // Replace with your actual analysis logic
    return {
      address,
      chain,
      totalValue: "$12,345.67",
      holdings: [
        { token: "ETH", amount: "2.5", value: "$5,000", allocation: "40.5%" },
        { token: "USDC", amount: "5000", value: "$5,000", allocation: "40.5%" },
        { token: "LINK", amount: "100", value: "$2,345.67", allocation: "19.0%" },
      ],
      riskLevel: "moderate",
      timestamp: new Date().toISOString(),
    };
  },

  searchDocumentation: async (args) => {
    const { query, limit = 5 } = args;

    // Replace with your actual search logic
    return {
      query,
      results: [
        {
          title: "Getting Started",
          excerpt: "Follow these steps to set up your first agent...",
          relevance: 0.95,
        },
      ],
      totalResults: 1,
    };
  },
};

export async function callTool(
  name: string,
  args: Record<string, any>
): Promise<any> {
  const handler = toolHandlers[name];
  if (!handler) {
    throw new Error(`Unknown tool: ${name}`);
  }
  return handler(args);
}
```

#### Python (FastAPI)

```python
# mcp/handlers.py
import httpx
from datetime import datetime


async def handle_get_token_price(args: dict) -> dict:
    symbol = args["symbol"]
    currency = args.get("currency", "USD")

    # Replace with your actual data source
    async with httpx.AsyncClient() as client:
        response = await client.get(
            "https://api.coingecko.com/api/v3/simple/price",
            params={
                "ids": symbol.lower(),
                "vs_currencies": currency.lower(),
                "include_24hr_change": "true",
                "include_market_cap": "true",
            },
        )
        data = response.json()

    key = symbol.lower()
    cur = currency.lower()
    return {
        "symbol": symbol.upper(),
        "price": data.get(key, {}).get(cur, "N/A"),
        "change24h": data.get(key, {}).get(f"{cur}_24h_change", "N/A"),
        "currency": currency,
        "timestamp": datetime.utcnow().isoformat() + "Z",
    }


async def handle_analyze_portfolio(args: dict) -> dict:
    address = args["address"]
    chain = args.get("chain", "ethereum")

    # Replace with your actual analysis logic
    return {
        "address": address,
        "chain": chain,
        "totalValue": "$12,345.67",
        "holdings": [
            {"token": "ETH", "amount": "2.5", "value": "$5,000", "allocation": "40.5%"},
            {"token": "USDC", "amount": "5000", "value": "$5,000", "allocation": "40.5%"},
        ],
        "riskLevel": "moderate",
        "timestamp": datetime.utcnow().isoformat() + "Z",
    }


async def handle_search_documentation(args: dict) -> dict:
    query = args["query"]
    limit = args.get("limit", 5)

    # Replace with your actual search logic
    return {
        "query": query,
        "results": [
            {
                "title": "Getting Started",
                "excerpt": "Follow these steps to set up your first agent...",
                "relevance": 0.95,
            }
        ],
        "totalResults": 1,
    }


TOOL_HANDLERS = {
    "getTokenPrice": handle_get_token_price,
    "analyzePortfolio": handle_analyze_portfolio,
    "searchDocumentation": handle_search_documentation,
}


async def call_tool(name: str, args: dict) -> dict:
    handler = TOOL_HANDLERS.get(name)
    if not handler:
        raise ValueError(f"Unknown tool: {name}")
    return await handler(args)
```

### Step 3: Implement the JSON-RPC Handler

The MCP endpoint handles three key methods: `initialize`, `tools/list`, and `tools/call`.

#### TypeScript (Hono)

```typescript
// src/mcp/handler.ts
import { Hono } from "hono";
import { tools } from "./tools";
import { callTool } from "./handlers";

const mcp = new Hono();

mcp.post("/", async (c) => {
  const body = await c.req.json();
  const { method, id, params } = body;

  switch (method) {
    case "initialize":
      return c.json({
        jsonrpc: "2.0",
        id,
        result: {
          protocolVersion: "2025-11-25",
          serverInfo: {
            name: "your-agent",
            version: "1.0.0",
          },
          capabilities: {
            tools: { listChanged: false },
          },
        },
      });

    case "tools/list":
      return c.json({
        jsonrpc: "2.0",
        id,
        result: { tools },
      });

    case "tools/call": {
      const { name, arguments: args } = params;

      try {
        const result = await callTool(name, args || {});

        return c.json({
          jsonrpc: "2.0",
          id,
          result: {
            content: [
              {
                type: "text",
                text:
                  typeof result === "string"
                    ? result
                    : JSON.stringify(result, null, 2),
              },
            ],
          },
        });
      } catch (error) {
        return c.json({
          jsonrpc: "2.0",
          id,
          error: {
            code: -32603,
            message:
              error instanceof Error ? error.message : "Tool execution failed",
          },
        });
      }
    }

    case "notifications/initialized":
      // Client notification — no response needed for notifications
      return c.json({ jsonrpc: "2.0", id, result: {} });

    default:
      return c.json({
        jsonrpc: "2.0",
        id,
        error: {
          code: -32601,
          message: `Method not found: ${method}`,
        },
      });
  }
});

export default mcp;
```

#### Python (FastAPI)

```python
# mcp/handler.py
from fastapi import APIRouter, Request
from fastapi.responses import JSONResponse
from .tools import tools
from .handlers import call_tool

router = APIRouter()


@router.post("/mcp")
async def mcp_endpoint(request: Request):
    body = await request.json()
    method = body.get("method")
    rpc_id = body.get("id")
    params = body.get("params", {})

    if method == "initialize":
        return JSONResponse({
            "jsonrpc": "2.0",
            "id": rpc_id,
            "result": {
                "protocolVersion": "2025-11-25",
                "serverInfo": {
                    "name": "your-agent",
                    "version": "1.0.0",
                },
                "capabilities": {
                    "tools": {"listChanged": False},
                },
            },
        })

    elif method == "tools/list":
        return JSONResponse({
            "jsonrpc": "2.0",
            "id": rpc_id,
            "result": {"tools": tools},
        })

    elif method == "tools/call":
        name = params.get("name")
        arguments = params.get("arguments", {})

        try:
            result = await call_tool(name, arguments)
            text = result if isinstance(result, str) else json.dumps(result, indent=2)

            return JSONResponse({
                "jsonrpc": "2.0",
                "id": rpc_id,
                "result": {
                    "content": [{"type": "text", "text": text}],
                },
            })
        except Exception as e:
            return JSONResponse({
                "jsonrpc": "2.0",
                "id": rpc_id,
                "error": {"code": -32603, "message": str(e)},
            })

    elif method == "notifications/initialized":
        return JSONResponse({"jsonrpc": "2.0", "id": rpc_id, "result": {}})

    else:
        return JSONResponse({
            "jsonrpc": "2.0",
            "id": rpc_id,
            "error": {"code": -32601, "message": f"Method not found: {method}"},
        })
```

### Step 4: Register in Your Server

#### TypeScript

```typescript
// src/index.ts
import { Hono } from "hono";
import mcp from "./mcp/handler";

const app = new Hono();

// Mount MCP at /mcp
app.route("/mcp", mcp);

export default app;
```

#### Python

```python
# server.py
from fastapi import FastAPI
from mcp.handler import router as mcp_router

app = FastAPI()
app.include_router(mcp_router)
```

## Client Side: Calling MCP Tools

### TypeScript Client

```typescript
class MCPClient {
  private baseUrl: string;
  private requestId = 0;

  constructor(baseUrl: string) {
    this.baseUrl = baseUrl;
  }

  private async rpc(method: string, params?: any) {
    const response = await fetch(this.baseUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        jsonrpc: "2.0",
        method,
        id: ++this.requestId,
        params,
      }),
    });
    const data = await response.json();
    if (data.error) throw new Error(data.error.message);
    return data.result;
  }

  async initialize() {
    return this.rpc("initialize");
  }

  async listTools() {
    const result = await this.rpc("tools/list");
    return result.tools;
  }

  async callTool(name: string, args: Record<string, any>) {
    const result = await this.rpc("tools/call", { name, arguments: args });
    return result.content;
  }
}

// Usage
const client = new MCPClient("https://your-agent.example.com/mcp");

await client.initialize();

const tools = await client.listTools();
console.log("Available tools:", tools.map((t: any) => t.name));

const price = await client.callTool("getTokenPrice", { symbol: "ETH" });
console.log("ETH price:", price[0].text);
```

### Python Client

```python
import httpx


class MCPClient:
    def __init__(self, base_url: str):
        self.base_url = base_url
        self.request_id = 0

    async def _rpc(self, method: str, params: dict = None) -> dict:
        self.request_id += 1
        async with httpx.AsyncClient() as client:
            response = await client.post(
                self.base_url,
                json={
                    "jsonrpc": "2.0",
                    "method": method,
                    "id": self.request_id,
                    "params": params or {},
                },
            )
        data = response.json()
        if "error" in data:
            raise Exception(data["error"]["message"])
        return data["result"]

    async def initialize(self) -> dict:
        return await self._rpc("initialize")

    async def list_tools(self) -> list:
        result = await self._rpc("tools/list")
        return result["tools"]

    async def call_tool(self, name: str, arguments: dict) -> list:
        result = await self._rpc("tools/call", {"name": name, "arguments": arguments})
        return result["content"]


# Usage
async def main():
    client = MCPClient("https://your-agent.example.com/mcp")

    await client.initialize()

    tools = await client.list_tools()
    print("Available tools:", [t["name"] for t in tools])

    price = await client.call_tool("getTokenPrice", {"symbol": "ETH"})
    print("ETH price:", price[0]["text"])
```

## Testing MCP Endpoints

### curl Commands

```bash
# Initialize
curl -X POST https://your-agent.example.com/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"initialize","id":1}'

# List tools
curl -X POST https://your-agent.example.com/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":2}'

# Call a tool
curl -X POST https://your-agent.example.com/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0",
    "method":"tools/call",
    "id":3,
    "params":{
      "name":"getTokenPrice",
      "arguments":{"symbol":"ETH"}
    }
  }'

# Call with multiple parameters
curl -X POST https://your-agent.example.com/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0",
    "method":"tools/call",
    "id":4,
    "params":{
      "name":"analyzePortfolio",
      "arguments":{"address":"0x1234...","chain":"ethereum"}
    }
  }'
```

### Expected Responses

#### Initialize Response

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "protocolVersion": "2025-11-25",
    "serverInfo": {
      "name": "your-agent",
      "version": "1.0.0"
    },
    "capabilities": {
      "tools": { "listChanged": false }
    }
  }
}
```

#### Tools List Response

```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "result": {
    "tools": [
      {
        "name": "getTokenPrice",
        "description": "Get the current price of a cryptocurrency token...",
        "inputSchema": {
          "type": "object",
          "properties": {
            "symbol": { "type": "string", "description": "Token ticker symbol" }
          },
          "required": ["symbol"]
        }
      }
    ]
  }
}
```

#### Tool Call Response

```json
{
  "jsonrpc": "2.0",
  "id": 3,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\n  \"symbol\": \"ETH\",\n  \"price\": 3456.78,\n  \"change24h\": 2.5,\n  \"currency\": \"USD\"\n}"
      }
    ]
  }
}
```

## Tool Design Best Practices

### 1. Write Descriptions for LLMs

Tool descriptions are read by LLMs to decide when to use them. Be specific and include:
- What the tool does
- What it returns
- When to use it vs. alternatives

```typescript
// Good
{
  name: "getTokenPrice",
  description:
    "Get the current price of a cryptocurrency token by its ticker symbol. " +
    "Returns price in the specified currency, 24-hour percentage change, " +
    "and market capitalization. Use this for real-time price lookups. " +
    "For historical prices, use getHistoricalPrice instead.",
}

// Bad
{
  name: "getTokenPrice",
  description: "Gets token price",
}
```

### 2. Use Proper JSON Schema Types

```typescript
{
  inputSchema: {
    type: "object",
    properties: {
      // String with enum constraints
      chain: {
        type: "string",
        enum: ["ethereum", "base", "avalanche"],
        description: "Target blockchain",
      },
      // Number with range
      limit: {
        type: "number",
        minimum: 1,
        maximum: 100,
        description: "Number of results (1-100)",
      },
      // Boolean with default
      includeMetadata: {
        type: "boolean",
        description: "Include metadata in response (default: false)",
      },
      // Array of strings
      tags: {
        type: "array",
        items: { type: "string" },
        description: "Filter by tags",
      },
    },
    required: ["chain"],
  },
}
```

### 3. Return Structured Data

Always return structured, parseable data:

```typescript
// Good — structured and parseable
return {
  symbol: "ETH",
  price: 3456.78,
  change24h: 2.5,
  marketCap: 415000000000,
  timestamp: "2025-01-15T10:30:00Z",
};

// Bad — free-form text
return "ETH is trading at $3,456.78 which is up 2.5% from yesterday";
```

### 4. Handle Errors Gracefully

```typescript
const handler: ToolHandler = async (args) => {
  const { symbol } = args;

  if (!symbol || typeof symbol !== "string") {
    throw new Error("'symbol' is required and must be a string");
  }

  try {
    const data = await fetchPrice(symbol);
    if (!data) {
      return {
        error: "TOKEN_NOT_FOUND",
        message: `No price data found for symbol: ${symbol}`,
        suggestion: "Check the symbol is correct. Common symbols: ETH, BTC, SOL",
      };
    }
    return data;
  } catch (error) {
    throw new Error(`Failed to fetch price for ${symbol}: ${error.message}`);
  }
};
```

## MCP Error Codes

| Code | Name | Description |
|------|------|-------------|
| `-32700` | Parse Error | Invalid JSON received |
| `-32600` | Invalid Request | JSON-RPC request is malformed |
| `-32601` | Method Not Found | Method does not exist |
| `-32602` | Invalid Params | Invalid method parameters |
| `-32603` | Internal Error | Server-side error during execution |
| `-32000` | Tool Not Found | Requested tool name does not exist |
| `-32001` | Tool Execution Error | Tool handler threw an error |
| `-32002` | Input Validation Error | Arguments don't match input schema |

## Advanced: Streaming Responses

For long-running tools, implement SSE (Server-Sent Events) streaming:

### TypeScript

```typescript
app.post("/mcp/stream", async (c) => {
  const body = await c.req.json();

  if (body.method === "tools/call") {
    return new Response(
      new ReadableStream({
        async start(controller) {
          const encoder = new TextEncoder();

          // Send progress updates
          controller.enqueue(
            encoder.encode(
              `data: ${JSON.stringify({
                jsonrpc: "2.0",
                method: "notifications/progress",
                params: { progress: 0.5, message: "Processing..." },
              })}\n\n`
            )
          );

          // Send final result
          const result = await callTool(body.params.name, body.params.arguments);
          controller.enqueue(
            encoder.encode(
              `data: ${JSON.stringify({
                jsonrpc: "2.0",
                id: body.id,
                result: { content: [{ type: "text", text: JSON.stringify(result) }] },
              })}\n\n`
            )
          );

          controller.close();
        },
      }),
      {
        headers: {
          "Content-Type": "text/event-stream",
          "Cache-Control": "no-cache",
          Connection: "keep-alive",
        },
      }
    );
  }
});
```

## Advanced: Tool Composition

Tools can call other tools internally:

```typescript
const toolHandlers: Record<string, ToolHandler> = {
  getPortfolioInsights: async (args) => {
    // Compose: call other tools internally
    const portfolio = await toolHandlers.analyzePortfolio(args);
    const prices = await Promise.all(
      portfolio.holdings.map((h: any) =>
        toolHandlers.getTokenPrice({ symbol: h.token })
      )
    );

    return {
      portfolio,
      currentPrices: prices,
      generatedAt: new Date().toISOString(),
    };
  },
};
```

## Registering MCP in registration.json

```json
{
  "services": [
    {
      "name": "MCP",
      "endpoint": "https://your-agent.example.com/mcp",
      "version": "2025-11-25"
    }
  ]
}
```

The version field should match the `protocolVersion` returned by your `initialize` handler.

## Security Considerations

1. **Input validation** — Validate all tool arguments against the schema before processing
2. **Rate limiting** — Protect against excessive tool calls
3. **Authentication** — Consider requiring API keys for production use
4. **Timeout** — Set execution timeouts for tool handlers
5. **Resource limits** — Cap response sizes and processing time

```typescript
// Example: Validation middleware
function validateToolArgs(name: string, args: Record<string, any>) {
  const tool = tools.find((t) => t.name === name);
  if (!tool) throw new Error(`Unknown tool: ${name}`);

  for (const required of tool.inputSchema.required || []) {
    if (args[required] === undefined) {
      throw new Error(`Missing required parameter: ${required}`);
    }
  }
}
```

---

*MCP makes your agent's capabilities discoverable and callable by any LLM client. Combined with A2A for natural language and x402 for payments, your agent becomes a full participant in the AI ecosystem.*
