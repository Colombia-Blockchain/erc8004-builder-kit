# 02 — A2A (Agent-to-Agent) Protocol Guide

Implement the A2A protocol so your ERC-8004 agent can communicate with other agents and AI systems using natural language.

## Overview

A2A (Agent-to-Agent) is Google's open protocol for agent interoperability. It enables agents to discover each other's capabilities, send tasks, and receive structured responses — all over HTTP with JSON.

While MCP provides programmatic tool access, A2A provides natural language communication between agents. Think of MCP as a CLI and A2A as a conversation.

```
┌──────────────┐       A2A (JSON-RPC/HTTP)       ┌──────────────┐
│  Client Agent │ ──────────────────────────────▶  │  Your Agent  │
│  (Requester)  │ ◀──────────────────────────────  │  (Provider)  │
└──────────────┘     Natural Language Tasks       └──────────────┘
```

## How A2A Works

### The Protocol Flow

```
Client                                          Your Agent
  │                                                  │
  │  1. GET /.well-known/agent.json                 │
  │ ────────────────────────────────────────────────▶│
  │                                                  │
  │  2. Agent Card (capabilities, skills, auth)     │
  │ ◀────────────────────────────────────────────────│
  │                                                  │
  │  3. POST /a2a (tasks/send)                      │
  │     { task with natural language message }       │
  │ ────────────────────────────────────────────────▶│
  │                                                  │
  │  4. Task result (artifacts, status)             │
  │ ◀────────────────────────────────────────────────│
  │                                                  │
  │  5. POST /a2a (tasks/send) follow-up            │
  │ ────────────────────────────────────────────────▶│
  │                                                  │
  │  6. Updated task result                         │
  │ ◀────────────────────────────────────────────────│
  └──────────────────────────────────────────────────┘
```

### Key Concepts

| Concept | Description |
|---------|-------------|
| **Agent Card** | JSON document describing the agent's capabilities, hosted at `/.well-known/agent.json` |
| **Task** | A unit of work with an ID, status, messages, and artifacts |
| **Message** | A natural language input/output within a task (role: user or agent) |
| **Artifact** | Structured output from task completion (text, JSON, files) |
| **Part** | Individual content unit within a message (TextPart, DataPart, FilePart) |

### Task Lifecycle

```
           ┌──────────┐
           │ submitted │
           └────┬─────┘
                │
           ┌────▼─────┐
           │  working  │ ◀──── Agent processing
           └────┬─────┘
                │
        ┌───────┼────────┐
        │       │        │
  ┌─────▼──┐ ┌─▼──────┐ ┌▼─────────┐
  │completed│ │ failed │ │input-    │
  └────────┘ └────────┘ │required  │
                         └──────────┘
```

## Server Side: Implementing A2A

### Step 1: Create the Agent Card

The Agent Card tells other agents what your agent can do. Serve it at `/.well-known/agent.json`:

#### TypeScript (Hono)

```typescript
import { Hono } from "hono";

const app = new Hono();

// Agent Card
app.get("/.well-known/agent.json", (c) => {
  return c.json({
    name: "Your Agent",
    description: "Describe what your agent does clearly and specifically",
    url: "https://your-agent.example.com",
    version: "1.0.0",
    capabilities: {
      streaming: false,
      pushNotifications: false,
      stateTransitionHistory: false,
    },
    authentication: {
      schemes: ["none"],
    },
    defaultInputModes: ["text"],
    defaultOutputModes: ["text"],
    skills: [
      {
        id: "analyze-data",
        name: "Analyze Data",
        description: "Analyzes data sets and provides insights with visualizations",
        tags: ["analysis", "data", "insights"],
        examples: [
          "Analyze this dataset for trends",
          "What patterns do you see in this data?",
          "Give me a summary of this information",
        ],
      },
      {
        id: "generate-report",
        name: "Generate Report",
        description: "Generates structured reports from raw data",
        tags: ["report", "summary", "document"],
        examples: [
          "Generate a report on this data",
          "Create a summary document",
        ],
      },
    ],
  });
});
```

#### Python (FastAPI)

```python
from fastapi import FastAPI
from fastapi.responses import JSONResponse

app = FastAPI()

@app.get("/.well-known/agent.json")
async def agent_card():
    return JSONResponse({
        "name": "Your Agent",
        "description": "Describe what your agent does clearly and specifically",
        "url": "https://your-agent.example.com",
        "version": "1.0.0",
        "capabilities": {
            "streaming": False,
            "pushNotifications": False,
            "stateTransitionHistory": False,
        },
        "authentication": {
            "schemes": ["none"],
        },
        "defaultInputModes": ["text"],
        "defaultOutputModes": ["text"],
        "skills": [
            {
                "id": "analyze-data",
                "name": "Analyze Data",
                "description": "Analyzes data sets and provides insights",
                "tags": ["analysis", "data", "insights"],
                "examples": [
                    "Analyze this dataset for trends",
                    "What patterns do you see in this data?",
                ],
            },
        ],
    })
```

### Step 2: Implement the A2A Endpoint

The main A2A endpoint handles JSON-RPC requests:

#### TypeScript (Hono)

```typescript
import { v4 as uuidv4 } from "uuid";

// In-memory task store (use Redis/DB in production)
const tasks = new Map<string, any>();

app.post("/a2a", async (c) => {
  const body = await c.req.json();
  const { method, id, params } = body;

  try {
    switch (method) {
      case "tasks/send":
        return c.json(await handleTaskSend(params, id));
      case "tasks/get":
        return c.json(await handleTaskGet(params, id));
      case "tasks/cancel":
        return c.json(await handleTaskCancel(params, id));
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
  } catch (error) {
    return c.json({
      jsonrpc: "2.0",
      id,
      error: {
        code: -32603,
        message: error instanceof Error ? error.message : "Internal error",
      },
    });
  }
});

async function handleTaskSend(params: any, id: number) {
  const taskId = params.id || uuidv4();
  const userMessage = params.message;

  // Extract text from the message parts
  const userText = userMessage.parts
    .filter((p: any) => p.type === "text")
    .map((p: any) => p.text)
    .join("\n");

  // Process the task (replace with your actual logic)
  const result = await processTask(userText);

  const task = {
    id: taskId,
    status: {
      state: "completed",
      timestamp: new Date().toISOString(),
    },
    artifacts: [
      {
        name: "result",
        parts: [
          {
            type: "text",
            text: result,
          },
        ],
      },
    ],
    history: [
      userMessage,
      {
        role: "agent",
        parts: [{ type: "text", text: result }],
      },
    ],
  };

  tasks.set(taskId, task);

  return {
    jsonrpc: "2.0",
    id,
    result: task,
  };
}

async function handleTaskGet(params: any, id: number) {
  const task = tasks.get(params.id);
  if (!task) {
    return {
      jsonrpc: "2.0",
      id,
      error: { code: -32602, message: "Task not found" },
    };
  }
  return { jsonrpc: "2.0", id, result: task };
}

async function handleTaskCancel(params: any, id: number) {
  const task = tasks.get(params.id);
  if (!task) {
    return {
      jsonrpc: "2.0",
      id,
      error: { code: -32602, message: "Task not found" },
    };
  }
  task.status = { state: "canceled", timestamp: new Date().toISOString() };
  return { jsonrpc: "2.0", id, result: task };
}

async function processTask(userText: string): Promise<string> {
  // Replace this with your actual agent logic
  // e.g., call an LLM, query a database, run analysis
  return `Processed your request: "${userText}"`;
}
```

#### Python (FastAPI)

```python
import uuid
from datetime import datetime

# In-memory task store
tasks: dict = {}

@app.post("/a2a")
async def a2a_endpoint(request: Request):
    body = await request.json()
    method = body.get("method")
    rpc_id = body.get("id")
    params = body.get("params", {})

    try:
        if method == "tasks/send":
            result = await handle_task_send(params)
        elif method == "tasks/get":
            result = handle_task_get(params)
        elif method == "tasks/cancel":
            result = handle_task_cancel(params)
        else:
            return JSONResponse({
                "jsonrpc": "2.0",
                "id": rpc_id,
                "error": {"code": -32601, "message": f"Method not found: {method}"},
            })

        return JSONResponse({"jsonrpc": "2.0", "id": rpc_id, "result": result})

    except Exception as e:
        return JSONResponse({
            "jsonrpc": "2.0",
            "id": rpc_id,
            "error": {"code": -32603, "message": str(e)},
        })


async def handle_task_send(params: dict) -> dict:
    task_id = params.get("id", str(uuid.uuid4()))
    user_message = params["message"]

    user_text = "\n".join(
        p["text"] for p in user_message["parts"] if p.get("type") == "text"
    )

    # Replace with your actual logic
    result_text = await process_task(user_text)

    task = {
        "id": task_id,
        "status": {
            "state": "completed",
            "timestamp": datetime.utcnow().isoformat() + "Z",
        },
        "artifacts": [
            {
                "name": "result",
                "parts": [{"type": "text", "text": result_text}],
            }
        ],
        "history": [
            user_message,
            {"role": "agent", "parts": [{"type": "text", "text": result_text}]},
        ],
    }

    tasks[task_id] = task
    return task


def handle_task_get(params: dict) -> dict:
    task = tasks.get(params["id"])
    if not task:
        raise ValueError("Task not found")
    return task


def handle_task_cancel(params: dict) -> dict:
    task = tasks.get(params["id"])
    if not task:
        raise ValueError("Task not found")
    task["status"] = {
        "state": "canceled",
        "timestamp": datetime.utcnow().isoformat() + "Z",
    }
    return task


async def process_task(user_text: str) -> str:
    # Replace with your actual agent logic
    return f'Processed your request: "{user_text}"'
```

### Step 3: Register the A2A Service

Add A2A to your `registration.json`:

```json
{
  "services": [
    { "name": "web", "endpoint": "https://your-agent.example.com/" },
    { "name": "A2A", "endpoint": "https://your-agent.example.com/a2a", "version": "0.2" },
    { "name": "MCP", "endpoint": "https://your-agent.example.com/mcp", "version": "2025-11-25" }
  ]
}
```

## Client Side: Calling Other Agents

### Discovery

Before sending a task, discover the agent's capabilities:

#### TypeScript

```typescript
async function discoverAgent(agentUrl: string) {
  const response = await fetch(`${agentUrl}/.well-known/agent.json`);
  const agentCard = await response.json();

  console.log(`Agent: ${agentCard.name}`);
  console.log(`Skills: ${agentCard.skills.map((s: any) => s.name).join(", ")}`);

  return agentCard;
}

// Example
const card = await discoverAgent("https://your-agent.example.com");
```

#### Python

```python
import httpx

async def discover_agent(agent_url: str) -> dict:
    async with httpx.AsyncClient() as client:
        response = await client.get(f"{agent_url}/.well-known/agent.json")
        agent_card = response.json()

    print(f"Agent: {agent_card['name']}")
    print(f"Skills: {[s['name'] for s in agent_card['skills']]}")

    return agent_card

# Example
card = await discover_agent("https://your-agent.example.com")
```

### Sending Tasks

#### TypeScript

```typescript
async function sendTask(agentUrl: string, message: string, taskId?: string) {
  const response = await fetch(`${agentUrl}/a2a`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      jsonrpc: "2.0",
      method: "tasks/send",
      id: 1,
      params: {
        id: taskId || crypto.randomUUID(),
        message: {
          role: "user",
          parts: [{ type: "text", text: message }],
        },
      },
    }),
  });

  const result = await response.json();
  return result.result;
}

// Example usage
const task = await sendTask(
  "https://your-agent.example.com",
  "Analyze the latest trends in this dataset"
);

console.log(`Status: ${task.status.state}`);
console.log(`Result: ${task.artifacts[0].parts[0].text}`);
```

#### Python

```python
import httpx
import uuid

async def send_task(agent_url: str, message: str, task_id: str = None) -> dict:
    task_id = task_id or str(uuid.uuid4())

    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{agent_url}/a2a",
            json={
                "jsonrpc": "2.0",
                "method": "tasks/send",
                "id": 1,
                "params": {
                    "id": task_id,
                    "message": {
                        "role": "user",
                        "parts": [{"type": "text", "text": message}],
                    },
                },
            },
        )

    result = response.json()
    return result["result"]

# Example usage
task = await send_task(
    "https://your-agent.example.com",
    "Analyze the latest trends in this dataset"
)
print(f"Status: {task['status']['state']}")
print(f"Result: {task['artifacts'][0]['parts'][0]['text']}")
```

### Multi-Turn Conversations

Continue a conversation by reusing the task ID:

```typescript
// First message
const task = await sendTask(agentUrl, "What patterns do you see in this data?");
const taskId = task.id;

// Follow-up using the same task ID
const followUp = await sendTask(
  agentUrl,
  "Can you focus on the outliers?",
  taskId
);
```

## Agent Card Specification

The Agent Card is the discovery document for A2A agents. Here is the complete schema:

```json
{
  "name": "string (required)",
  "description": "string (required)",
  "url": "string URL (required)",
  "version": "string (required)",
  "provider": {
    "organization": "string",
    "url": "string URL"
  },
  "documentationUrl": "string URL (optional)",
  "capabilities": {
    "streaming": "boolean",
    "pushNotifications": "boolean",
    "stateTransitionHistory": "boolean"
  },
  "authentication": {
    "schemes": ["none | apiKey | bearer | oauth2"],
    "credentials": "string (optional)"
  },
  "defaultInputModes": ["text", "data", "file"],
  "defaultOutputModes": ["text", "data", "file"],
  "skills": [
    {
      "id": "string (required)",
      "name": "string (required)",
      "description": "string (required)",
      "tags": ["string"],
      "examples": ["string"],
      "inputModes": ["text"],
      "outputModes": ["text"]
    }
  ]
}
```

### Skill Design Best Practices

1. **Be specific in descriptions** — "Analyzes DeFi protocol risk using on-chain data" is better than "Analyzes things"
2. **Include examples** — Real example prompts help other agents understand usage
3. **Use descriptive tags** — Tags enable filtering and routing in multi-agent systems
4. **Declare input/output modes** — If your skill returns structured data, include `"data"` in outputModes

## Multi-Agent Workflow

A2A enables orchestration where one agent coordinates multiple specialist agents:

```
                    ┌─────────────────┐
                    │  Orchestrator   │
                    │     Agent       │
                    └───────┬─────────┘
                            │
              ┌─────────────┼─────────────┐
              │             │             │
      ┌───────▼──────┐ ┌───▼──────┐ ┌───▼──────────┐
      │  Data Agent  │ │ Analysis │ │   Report     │
      │  (fetches)   │ │  Agent   │ │   Agent      │
      └──────────────┘ └──────────┘ └──────────────┘
```

### Orchestrator Pattern (TypeScript)

```typescript
async function orchestrateAnalysis(dataUrl: string) {
  // Step 1: Fetch data from the data agent
  const dataTask = await sendTask(
    "https://data-agent.example.com",
    `Fetch and normalize data from: ${dataUrl}`
  );
  const rawData = dataTask.artifacts[0].parts[0].text;

  // Step 2: Analyze with the analysis agent
  const analysisTask = await sendTask(
    "https://analysis-agent.example.com",
    `Analyze this data for trends and anomalies:\n${rawData}`
  );
  const analysis = analysisTask.artifacts[0].parts[0].text;

  // Step 3: Generate report with the report agent
  const reportTask = await sendTask(
    "https://report-agent.example.com",
    `Generate a professional report from this analysis:\n${analysis}`
  );

  return reportTask.artifacts[0].parts[0].text;
}
```

### Orchestrator Pattern (Python)

```python
async def orchestrate_analysis(data_url: str) -> str:
    # Step 1: Fetch data
    data_task = await send_task(
        "https://data-agent.example.com",
        f"Fetch and normalize data from: {data_url}"
    )
    raw_data = data_task["artifacts"][0]["parts"][0]["text"]

    # Step 2: Analyze
    analysis_task = await send_task(
        "https://analysis-agent.example.com",
        f"Analyze this data for trends and anomalies:\n{raw_data}"
    )
    analysis = analysis_task["artifacts"][0]["parts"][0]["text"]

    # Step 3: Generate report
    report_task = await send_task(
        "https://report-agent.example.com",
        f"Generate a professional report:\n{analysis}"
    )

    return report_task["artifacts"][0]["parts"][0]["text"]
```

## A2A vs MCP: When to Use What

| Aspect | A2A | MCP |
|--------|-----|-----|
| **Communication style** | Natural language | Structured tool calls |
| **Use case** | Agent-to-agent conversation | Programmatic tool access |
| **Protocol** | JSON-RPC over HTTP | JSON-RPC over HTTP/SSE/stdio |
| **Discovery** | Agent Card (`/.well-known/agent.json`) | `tools/list` method |
| **Statefulness** | Task-based (multi-turn) | Stateless per call |
| **Best for** | Complex reasoning, delegation | Data retrieval, actions |
| **Human analogy** | Asking a colleague | Using an API |

### Use Both Together

Most production agents implement both protocols:

```json
{
  "services": [
    { "name": "A2A", "endpoint": "https://your-agent.example.com/a2a", "version": "0.2" },
    { "name": "MCP", "endpoint": "https://your-agent.example.com/mcp", "version": "2025-11-25" }
  ]
}
```

- **MCP** for when clients need specific data: "Get the price of ETH"
- **A2A** for when clients need reasoning: "What should I do with my ETH position given current market conditions?"

## Reputation Feedback for A2A

After interacting with an agent via A2A, submit on-chain reputation feedback:

```typescript
import { createWalletClient, http } from "viem";
import { baseSepolia } from "viem/chains";

const REPUTATION_REGISTRY = "0x8004B5118Ee0495fBBFB889882503dd4a20e5444";

async function submitFeedback(agentId: number, rating: number) {
  const walletClient = createWalletClient({
    account,
    chain: baseSepolia,
    transport: http(),
  });

  await walletClient.writeContract({
    address: REPUTATION_REGISTRY,
    abi: reputationABI,
    functionName: "giveFeedback",
    args: [
      BigInt(agentId),        // agentId
      BigInt(rating),         // value (0-100)
      0,                      // decimals
      "starred",              // tag1
      "a2a",                  // tag2 (marks this as A2A feedback)
      "https://your-agent.example.com/a2a",  // endpoint
      "",                     // feedbackURI
      "0x" + "0".repeat(64),  // feedbackHash
    ],
  });
}
```

### Feedback Tags for A2A

| tag1 | tag2 | Meaning |
|------|------|---------|
| `starred` | `a2a` | Overall A2A quality rating |
| `responseTime` | `a2a` | A2A response latency |
| `successRate` | `a2a` | Task completion rate |
| `reachable` | `a2a` | A2A endpoint availability |

## Governance and Standards

### A2A Protocol Versioning

The current A2A version is `0.2`. Register with the version in your services:

```json
{ "name": "A2A", "endpoint": "https://your-agent.example.com/a2a", "version": "0.2" }
```

### Required Methods

| Method | Required | Description |
|--------|----------|-------------|
| `tasks/send` | Yes | Send a task to the agent |
| `tasks/get` | Recommended | Retrieve task status and results |
| `tasks/cancel` | Optional | Cancel a running task |
| `tasks/sendSubscribe` | Optional | Subscribe to task updates (streaming) |

### Error Codes

| Code | Meaning |
|------|---------|
| `-32700` | Parse error — invalid JSON |
| `-32600` | Invalid request — missing required fields |
| `-32601` | Method not found |
| `-32602` | Invalid params |
| `-32603` | Internal error |
| `-32001` | Task not found |
| `-32002` | Task not cancelable |
| `-32003` | Push notification not supported |
| `-32004` | Unsupported operation |

## Testing A2A

### curl Commands

```bash
# Discover agent
curl https://your-agent.example.com/.well-known/agent.json

# Send a task
curl -X POST https://your-agent.example.com/a2a \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tasks/send",
    "id": 1,
    "params": {
      "id": "test-task-001",
      "message": {
        "role": "user",
        "parts": [{"type": "text", "text": "Hello, what can you do?"}]
      }
    }
  }'

# Get task status
curl -X POST https://your-agent.example.com/a2a \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tasks/get",
    "id": 2,
    "params": {"id": "test-task-001"}
  }'
```

### Automated Testing

```typescript
import assert from "assert";

async function testA2A(baseUrl: string) {
  // Test 1: Agent Card
  const cardRes = await fetch(`${baseUrl}/.well-known/agent.json`);
  assert(cardRes.ok, "Agent card should be accessible");
  const card = await cardRes.json();
  assert(card.name, "Agent card should have a name");
  assert(card.skills?.length > 0, "Agent card should have skills");

  // Test 2: Task Send
  const taskRes = await fetch(`${baseUrl}/a2a`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      jsonrpc: "2.0",
      method: "tasks/send",
      id: 1,
      params: {
        id: "test-001",
        message: {
          role: "user",
          parts: [{ type: "text", text: "Hello" }],
        },
      },
    }),
  });
  const task = await taskRes.json();
  assert(task.result?.status?.state, "Task should have a status");
  assert(
    ["completed", "working", "input-required"].includes(task.result.status.state),
    "Task state should be valid"
  );

  console.log("All A2A tests passed");
}
```

## Security Considerations

1. **Input validation** — Always validate and sanitize incoming messages
2. **Rate limiting** — Protect your A2A endpoint from abuse
3. **Authentication** — Consider requiring API keys or bearer tokens for production
4. **Task limits** — Set maximum message length and task history depth
5. **Timeout handling** — Set timeouts for long-running tasks
6. **Content filtering** — Filter malicious content in messages

```typescript
// Example: Rate limiting middleware (Hono)
import { rateLimiter } from "hono-rate-limiter";

app.use(
  "/a2a",
  rateLimiter({
    windowMs: 60 * 1000, // 1 minute
    limit: 30,           // 30 requests per minute
  })
);
```

---

*A2A enables your agent to participate in the emerging multi-agent ecosystem. Combined with MCP for programmatic access and x402 for payments, your agent becomes a full participant in the decentralized agent economy.*
