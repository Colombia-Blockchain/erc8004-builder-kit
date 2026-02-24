# 07 — 18 Inter-Agent Communication Patterns

This guide covers the fundamental patterns for agent-to-agent communication built on ERC-8004. Each pattern includes a diagram, guidance on when to use it, a TypeScript code snippet, and which ERC-8004 features it leverages.

---

## Pattern 1: Discovery then Call

The simplest pattern. Find an agent, call it.

```
Caller ──► Registry.getAgent(id) ──► agentInfo
Caller ──► fetch(agentInfo.endpoint + "/a2a") ──► response
```

**When to use:** You already know the agent ID you need.

**ERC-8004 features:** `getAgent`, registration endpoint.

```typescript
import { createPublicClient, http } from "viem";
import { avalancheFuji } from "viem/chains";
import { REGISTRY_ABI, REGISTRY_ADDRESS } from "./constants";

async function discoveryThenCall(agentId: bigint, task: string) {
  const client = createPublicClient({ chain: avalancheFuji, transport: http() });

  const agent = await client.readContract({
    address: REGISTRY_ADDRESS,
    abi: REGISTRY_ABI,
    functionName: "getAgent",
    args: [agentId],
  });

  const regResponse = await fetch(agent.metadataURI);
  const registration = await regResponse.json();

  const a2aEndpoint = registration.services.find(
    (s: any) => s.name === "A2A"
  )?.endpoint;

  const result = await fetch(a2aEndpoint, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      jsonrpc: "2.0",
      method: "tasks/send",
      params: {
        id: crypto.randomUUID(),
        message: { role: "user", parts: [{ type: "text", text: task }] },
      },
    }),
  });

  return result.json();
}
```

---

## Pattern 2: Discovery then Capability Check then Call

Check what the agent can do before calling it.

```
Caller ──► Registry.getAgent(id) ──► agentInfo
Caller ──► fetch(endpoint + "/.well-known/agent.json") ──► agentCard
Caller ──► check agentCard.skills ──► match?
  ├── yes ──► fetch(endpoint + "/a2a") ──► response
  └── no  ──► skip
```

**When to use:** When you need a specific capability and want to avoid wasting calls.

**ERC-8004 features:** `getAgent`, A2A agent card, OASF skills.

```typescript
async function capabilityCheckedCall(
  agentId: bigint,
  requiredSkill: string,
  task: string
) {
  const client = createPublicClient({ chain: avalancheFuji, transport: http() });

  const agent = await client.readContract({
    address: REGISTRY_ADDRESS,
    abi: REGISTRY_ABI,
    functionName: "getAgent",
    args: [agentId],
  });

  const regResponse = await fetch(agent.metadataURI);
  const registration = await regResponse.json();

  // Check OASF endpoint for skills
  const oasfEndpoint = registration.services.find(
    (s: any) => s.name === "OASF"
  )?.endpoint;

  if (oasfEndpoint) {
    const oasf = await (await fetch(oasfEndpoint)).json();
    const hasSkill = oasf.skills.some((s: string) =>
      s.includes(requiredSkill)
    );
    if (!hasSkill) {
      throw new Error(`Agent ${agentId} lacks skill: ${requiredSkill}`);
    }
  }

  // Proceed with A2A call
  const a2aEndpoint = registration.services.find(
    (s: any) => s.name === "A2A"
  )?.endpoint;

  const result = await fetch(a2aEndpoint, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      jsonrpc: "2.0",
      method: "tasks/send",
      params: {
        id: crypto.randomUUID(),
        message: { role: "user", parts: [{ type: "text", text: task }] },
      },
    }),
  });

  return result.json();
}
```

---

## Pattern 3: Multi-Agent Fan-out

Ask N agents the same question, aggregate results.

```
                    ┌──► Agent A ──► result A ──┐
Caller ──► discover ├──► Agent B ──► result B ──├──► aggregate
                    └──► Agent C ──► result C ──┘
```

**When to use:** Price comparison, data aggregation, getting multiple perspectives.

**ERC-8004 features:** `getAgentCount`, `getAgent` (loop), A2A.

```typescript
async function fanOut(agentIds: bigint[], task: string) {
  const client = createPublicClient({ chain: avalancheFuji, transport: http() });

  const agents = await Promise.all(
    agentIds.map((id) =>
      client.readContract({
        address: REGISTRY_ADDRESS,
        abi: REGISTRY_ABI,
        functionName: "getAgent",
        args: [id],
      })
    )
  );

  const registrations = await Promise.all(
    agents.map(async (a) => {
      const res = await fetch(a.metadataURI);
      return res.json();
    })
  );

  const results = await Promise.allSettled(
    registrations.map(async (reg) => {
      const a2aEndpoint = reg.services.find(
        (s: any) => s.name === "A2A"
      )?.endpoint;
      if (!a2aEndpoint) throw new Error("No A2A endpoint");

      const res = await fetch(a2aEndpoint, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          jsonrpc: "2.0",
          method: "tasks/send",
          params: {
            id: crypto.randomUUID(),
            message: { role: "user", parts: [{ type: "text", text: task }] },
          },
        }),
      });
      return res.json();
    })
  );

  const successful = results
    .filter((r) => r.status === "fulfilled")
    .map((r) => (r as PromiseFulfilledResult<any>).value);

  return {
    totalAsked: agentIds.length,
    totalResponded: successful.length,
    responses: successful,
  };
}
```

---

## Pattern 4: Chain

Agent A calls Agent B, who calls Agent C. Each agent adds value.

```
Caller ──► Agent A (translate) ──► Agent B (analyze) ──► Agent C (summarize) ──► result
```

**When to use:** Multi-step workflows where each agent has a specialty.

**ERC-8004 features:** A2A, MCP tool chaining, registration metadata.

```typescript
async function chain(
  agentIds: bigint[],
  initialTask: string
) {
  const client = createPublicClient({ chain: avalancheFuji, transport: http() });

  let currentInput = initialTask;

  for (const agentId of agentIds) {
    const agent = await client.readContract({
      address: REGISTRY_ADDRESS,
      abi: REGISTRY_ABI,
      functionName: "getAgent",
      args: [agentId],
    });

    const reg = await (await fetch(agent.metadataURI)).json();
    const a2aEndpoint = reg.services.find(
      (s: any) => s.name === "A2A"
    )?.endpoint;

    const result = await fetch(a2aEndpoint, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        jsonrpc: "2.0",
        method: "tasks/send",
        params: {
          id: crypto.randomUUID(),
          message: {
            role: "user",
            parts: [{ type: "text", text: currentInput }],
          },
        },
      }),
    });

    const response = await result.json();
    currentInput = response.result?.history?.[0]?.parts?.[0]?.text
      ?? JSON.stringify(response.result);
  }

  return currentInput;
}
```

---

## Pattern 5: Supervisor / Worker

A supervisor agent dispatches subtasks to worker agents.

```
            ┌──► Worker A (research)
Supervisor ─├──► Worker B (code)
            └──► Worker C (review)
            ◄── collect all ──► final response
```

**When to use:** Complex tasks that decompose into independent subtasks.

**ERC-8004 features:** `getAgent`, OASF skill matching, A2A.

```typescript
interface SubTask {
  agentId: bigint;
  task: string;
  priority: number;
}

async function supervisor(subTasks: SubTask[]) {
  // Sort by priority
  const sorted = [...subTasks].sort((a, b) => a.priority - b.priority);

  // Dispatch all subtasks in parallel
  const results = await Promise.allSettled(
    sorted.map((st) => discoveryThenCall(st.agentId, st.task))
  );

  // Collect and structure results
  const report = sorted.map((st, i) => ({
    agentId: st.agentId.toString(),
    task: st.task,
    status: results[i].status,
    result:
      results[i].status === "fulfilled"
        ? (results[i] as PromiseFulfilledResult<any>).value
        : (results[i] as PromiseRejectedResult).reason?.message,
  }));

  return report;
}
```

---

## Pattern 6: Negotiation

Agents negotiate price or capability before a task is executed.

```
Caller ──► Agent: "What would you charge for X?"
Agent  ──► Caller: "0.001 AVAX via x402"
Caller ──► evaluateOffer()
  ├── accept ──► pay + call
  └── reject ──► try next agent
```

**When to use:** When agents charge variable prices or you want the best deal.

**ERC-8004 features:** A2A, x402 payment headers, OASF capabilities.

```typescript
async function negotiate(agentIds: bigint[], task: string, maxPrice: bigint) {
  const client = createPublicClient({ chain: avalancheFuji, transport: http() });

  for (const agentId of agentIds) {
    const agent = await client.readContract({
      address: REGISTRY_ADDRESS,
      abi: REGISTRY_ABI,
      functionName: "getAgent",
      args: [agentId],
    });

    const reg = await (await fetch(agent.metadataURI)).json();
    const a2aEndpoint = reg.services.find(
      (s: any) => s.name === "A2A"
    )?.endpoint;

    // First call to get pricing info (may return 402)
    const probe = await fetch(a2aEndpoint, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        jsonrpc: "2.0",
        method: "tasks/send",
        params: {
          id: crypto.randomUUID(),
          message: {
            role: "user",
            parts: [{ type: "text", text: task }],
          },
        },
      }),
    });

    if (probe.status === 402) {
      const paymentHeader = probe.headers.get("X-Payment-Required");
      const requiredAmount = BigInt(paymentHeader ?? "0");

      if (requiredAmount <= maxPrice) {
        console.log(`Agent ${agentId} accepted at price ${requiredAmount}`);
        // Make payment and retry (see x402 guide)
        return { agentId, price: requiredAmount, status: "accepted" };
      }
      console.log(`Agent ${agentId} too expensive: ${requiredAmount}`);
      continue;
    }

    // Free agent, use directly
    return { agentId, price: 0n, result: await probe.json() };
  }

  throw new Error("No agent within budget");
}
```

---

## Pattern 7: Reputation-Gated

Only call agents above a reputation threshold.

```
Caller ──► Registry.getSummary(agentId) ──► reputation
  ├── score >= threshold ──► call agent
  └── score < threshold  ──► skip
```

**When to use:** High-stakes tasks where quality matters more than speed.

**ERC-8004 features:** `getSummary`, `getFeedback`, reputation scoring.

```typescript
async function reputationGated(
  agentIds: bigint[],
  task: string,
  minScore: number
) {
  const client = createPublicClient({ chain: avalancheFuji, transport: http() });

  const qualified: bigint[] = [];

  for (const agentId of agentIds) {
    const summary = await client.readContract({
      address: REGISTRY_ADDRESS,
      abi: REGISTRY_ABI,
      functionName: "getSummary",
      args: [agentId],
    });

    // summary returns [totalFeedback, positiveCount, negativeCount, ...]
    const total = Number(summary[0]);
    const positive = Number(summary[1]);

    if (total === 0) continue; // No reputation yet

    const score = positive / total;
    if (score >= minScore) {
      qualified.push(agentId);
    }
  }

  if (qualified.length === 0) {
    throw new Error("No agents meet reputation threshold");
  }

  // Call the best qualified agent
  return discoveryThenCall(qualified[0], task);
}
```

---

## Pattern 8: Payment-Gated (x402)

Agent requires payment before processing.

```
Caller ──► Agent endpoint ──► 402 Payment Required
Caller ──► read payment header ──► sign EIP-3009 permit
Caller ──► retry with X-PAYMENT header ──► 200 OK + result
```

**When to use:** Paid APIs, premium agent services, micropayments.

**ERC-8004 features:** x402, EIP-3009 USDC authorization, A2A.

```typescript
import { createWalletClient, http, parseUnits } from "viem";
import { privateKeyToAccount } from "viem/accounts";

async function paymentGatedCall(endpoint: string, task: string) {
  const account = privateKeyToAccount(
    process.env.PRIVATE_KEY as `0x${string}`
  );

  // First attempt
  const firstTry = await fetch(endpoint, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      jsonrpc: "2.0",
      method: "tasks/send",
      params: {
        id: crypto.randomUUID(),
        message: {
          role: "user",
          parts: [{ type: "text", text: task }],
        },
      },
    }),
  });

  if (firstTry.status !== 402) {
    return firstTry.json(); // Free endpoint
  }

  // Parse x402 payment requirements from response
  const paymentDetails = await firstTry.json();
  const { amount, recipient, token } = paymentDetails;

  // Sign EIP-3009 transferWithAuthorization
  const walletClient = createWalletClient({
    account,
    chain: avalancheFuji,
    transport: http(),
  });

  // Build and sign authorization (see x402 guide for full flow)
  const signature = await walletClient.signTypedData({
    domain: {
      name: "USD Coin",
      version: "2",
      chainId: 43113,
      verifyingContract: token,
    },
    types: {
      TransferWithAuthorization: [
        { name: "from", type: "address" },
        { name: "to", type: "address" },
        { name: "value", type: "uint256" },
        { name: "validAfter", type: "uint256" },
        { name: "validBefore", type: "uint256" },
        { name: "nonce", type: "bytes32" },
      ],
    },
    primaryType: "TransferWithAuthorization",
    message: {
      from: account.address,
      to: recipient,
      value: parseUnits(amount, 6),
      validAfter: 0n,
      validBefore: BigInt(Math.floor(Date.now() / 1000) + 3600),
      nonce: `0x${Buffer.from(crypto.getRandomValues(new Uint8Array(32))).toString("hex")}` as `0x${string}`,
    },
  });

  // Retry with payment
  const secondTry = await fetch(endpoint, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-PAYMENT": signature,
    },
    body: JSON.stringify({
      jsonrpc: "2.0",
      method: "tasks/send",
      params: {
        id: crypto.randomUUID(),
        message: {
          role: "user",
          parts: [{ type: "text", text: task }],
        },
      },
    }),
  });

  return secondTry.json();
}
```

---

## Pattern 9: Heartbeat Monitoring

Periodically check if agents are alive and responsive.

```
Monitor ──► loop every 60s:
  ├──► Agent A /health ──► 200 OK ──► mark alive
  ├──► Agent B /health ──► timeout ──► mark dead
  └──► Agent C /health ──► 500    ──► mark degraded
```

**When to use:** Maintaining a live index of available agents.

**ERC-8004 features:** Registration endpoint, health checks.

```typescript
interface AgentHealth {
  agentId: bigint;
  status: "alive" | "dead" | "degraded";
  latencyMs: number;
  lastChecked: string;
}

async function heartbeatMonitor(
  agentIds: bigint[],
  intervalMs: number = 60_000
) {
  const healthMap = new Map<string, AgentHealth>();
  const client = createPublicClient({ chain: avalancheFuji, transport: http() });

  async function checkAgent(agentId: bigint): Promise<AgentHealth> {
    const start = Date.now();
    try {
      const agent = await client.readContract({
        address: REGISTRY_ADDRESS,
        abi: REGISTRY_ABI,
        functionName: "getAgent",
        args: [agentId],
      });

      const reg = await (await fetch(agent.metadataURI)).json();
      const healthEndpoint = reg.services?.find(
        (s: any) => s.name === "A2A"
      )?.endpoint;

      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 5000);

      const res = await fetch(healthEndpoint, { signal: controller.signal });
      clearTimeout(timeout);

      return {
        agentId,
        status: res.ok ? "alive" : "degraded",
        latencyMs: Date.now() - start,
        lastChecked: new Date().toISOString(),
      };
    } catch {
      return {
        agentId,
        status: "dead",
        latencyMs: Date.now() - start,
        lastChecked: new Date().toISOString(),
      };
    }
  }

  // Run initial check
  const results = await Promise.all(agentIds.map(checkAgent));
  results.forEach((r) => healthMap.set(r.agentId.toString(), r));

  // Set up interval
  setInterval(async () => {
    const checks = await Promise.all(agentIds.map(checkAgent));
    checks.forEach((r) => healthMap.set(r.agentId.toString(), r));
  }, intervalMs);

  return healthMap;
}
```

---

## Pattern 10: Event-Driven (Webhook Callbacks)

Agent sends results via callback URL instead of synchronous response.

```
Caller ──► Agent: "Do X, callback to https://me.com/webhook"
Agent  ──► starts processing
Agent  ──► POST https://me.com/webhook ──► result
```

**When to use:** Long-running tasks, async workflows, decoupled architectures.

**ERC-8004 features:** A2A tasks/sendSubscribe, webhook URLs in task metadata.

```typescript
import { Hono } from "hono";

const app = new Hono();
const pendingTasks = new Map<string, { resolve: Function; reject: Function }>();

// Webhook receiver
app.post("/webhook/:taskId", async (c) => {
  const taskId = c.req.param("taskId");
  const body = await c.req.json();

  const pending = pendingTasks.get(taskId);
  if (pending) {
    pending.resolve(body);
    pendingTasks.delete(taskId);
  }

  return c.json({ received: true });
});

// Send task with callback
async function sendWithCallback(
  agentEndpoint: string,
  task: string,
  callbackBase: string
) {
  const taskId = crypto.randomUUID();

  const promise = new Promise((resolve, reject) => {
    pendingTasks.set(taskId, { resolve, reject });
    // Timeout after 5 minutes
    setTimeout(() => {
      pendingTasks.delete(taskId);
      reject(new Error("Callback timeout"));
    }, 300_000);
  });

  await fetch(agentEndpoint, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      jsonrpc: "2.0",
      method: "tasks/send",
      params: {
        id: taskId,
        message: {
          role: "user",
          parts: [{ type: "text", text: task }],
        },
        metadata: {
          callbackUrl: `${callbackBase}/webhook/${taskId}`,
        },
      },
    }),
  });

  return promise;
}
```

---

## Pattern 11: Consensus

Ask multiple agents the same question, take the majority answer.

```
Caller ──► Agent A ──► "42"  ──┐
Caller ──► Agent B ──► "42"  ──├──► majority = "42"
Caller ──► Agent C ──► "41"  ──┘
```

**When to use:** Fact-checking, critical decisions, reducing hallucinations.

**ERC-8004 features:** `getAgent`, A2A, OASF domain matching.

```typescript
async function consensus(agentIds: bigint[], question: string) {
  // Fan out to all agents
  const results = await fanOut(agentIds, question);

  // Extract text answers
  const answers = results.responses.map((r: any) => {
    const text = r.result?.history?.[0]?.parts?.[0]?.text ?? "";
    return text.trim().toLowerCase();
  });

  // Count votes
  const votes = new Map<string, number>();
  answers.forEach((answer: string) => {
    votes.set(answer, (votes.get(answer) || 0) + 1);
  });

  // Find majority
  let bestAnswer = "";
  let bestCount = 0;
  for (const [answer, count] of votes) {
    if (count > bestCount) {
      bestAnswer = answer;
      bestCount = count;
    }
  }

  const quorum = Math.ceil(agentIds.length / 2);
  return {
    answer: bestAnswer,
    confidence: bestCount / answers.length,
    reachedQuorum: bestCount >= quorum,
    totalVotes: answers.length,
    breakdown: Object.fromEntries(votes),
  };
}
```

---

## Pattern 12: Specialist Routing

Route tasks to the most appropriate specialist agent.

```
Router ──► analyze task ──► "This is a DeFi question"
Router ──► find agents with domain "finance/defi" via OASF
Router ──► call best match
```

**When to use:** General-purpose gateways, multi-domain platforms.

**ERC-8004 features:** OASF domains/skills, `getAgent`, A2A.

```typescript
async function specialistRoute(task: string, candidateIds: bigint[]) {
  const client = createPublicClient({ chain: avalancheFuji, transport: http() });

  // Build agent profiles via OASF
  const profiles = await Promise.all(
    candidateIds.map(async (id) => {
      try {
        const agent = await client.readContract({
          address: REGISTRY_ADDRESS,
          abi: REGISTRY_ABI,
          functionName: "getAgent",
          args: [id],
        });
        const reg = await (await fetch(agent.metadataURI)).json();
        const oasfEndpoint = reg.services?.find(
          (s: any) => s.name === "OASF"
        )?.endpoint;
        if (!oasfEndpoint) return null;

        const oasf = await (await fetch(oasfEndpoint)).json();
        return { id, oasf, reg };
      } catch {
        return null;
      }
    })
  );

  const validProfiles = profiles.filter(Boolean);

  // Simple keyword-based routing (replace with LLM classification)
  const keywords: Record<string, string> = {
    defi: "finance/defi",
    blockchain: "technology/blockchain",
    code: "technology/software_engineering",
    analyze: "natural_language_processing/information_retrieval_synthesis",
  };

  const taskLower = task.toLowerCase();
  let targetDomain = "";
  for (const [keyword, domain] of Object.entries(keywords)) {
    if (taskLower.includes(keyword)) {
      targetDomain = domain;
      break;
    }
  }

  // Find matching specialist
  const specialist = validProfiles.find((p: any) =>
    p.oasf.domains?.some((d: string) => d.startsWith(targetDomain))
  );

  if (!specialist) {
    throw new Error(`No specialist found for domain: ${targetDomain}`);
  }

  return discoveryThenCall(specialist!.id, task);
}
```

---

## Pattern 13: Fallback Chain

Try agents in order. If one fails, try the next.

```
Caller ──► Agent A ──► fail
Caller ──► Agent B ──► fail
Caller ──► Agent C ──► success ──► return result
```

**When to use:** High availability, mission-critical tasks.

**ERC-8004 features:** `getAgent`, A2A, reputation for ordering.

```typescript
async function fallbackChain(agentIds: bigint[], task: string) {
  const errors: Array<{ agentId: string; error: string }> = [];

  for (const agentId of agentIds) {
    try {
      const result = await discoveryThenCall(agentId, task);

      // Check if result is actually valid
      if (result?.error) {
        throw new Error(result.error.message || "Agent returned error");
      }

      return {
        result,
        agentUsed: agentId.toString(),
        failedAttempts: errors.length,
        errors,
      };
    } catch (error: any) {
      errors.push({
        agentId: agentId.toString(),
        error: error.message,
      });
      console.log(`Agent ${agentId} failed, trying next...`);
    }
  }

  throw new Error(
    `All ${agentIds.length} agents failed: ${JSON.stringify(errors)}`
  );
}
```

---

## Pattern 14: Batch Processing

Send multiple tasks to an agent in bulk.

```
Caller ──► Agent: [task1, task2, task3, ..., taskN]
Agent  ──► process all ──► [result1, result2, ..., resultN]
```

**When to use:** Data processing, bulk analysis, CSV/JSON transformations.

**ERC-8004 features:** A2A, MCP tools for structured data.

```typescript
async function batchProcess(
  agentId: bigint,
  tasks: string[],
  concurrency: number = 5
) {
  const client = createPublicClient({ chain: avalancheFuji, transport: http() });

  const agent = await client.readContract({
    address: REGISTRY_ADDRESS,
    abi: REGISTRY_ABI,
    functionName: "getAgent",
    args: [agentId],
  });

  const reg = await (await fetch(agent.metadataURI)).json();
  const a2aEndpoint = reg.services.find(
    (s: any) => s.name === "A2A"
  )?.endpoint;

  const results: any[] = new Array(tasks.length);
  let index = 0;

  async function worker() {
    while (index < tasks.length) {
      const currentIndex = index++;
      const task = tasks[currentIndex];

      try {
        const res = await fetch(a2aEndpoint, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            jsonrpc: "2.0",
            method: "tasks/send",
            params: {
              id: crypto.randomUUID(),
              message: {
                role: "user",
                parts: [{ type: "text", text: task }],
              },
            },
          }),
        });
        results[currentIndex] = await res.json();
      } catch (error: any) {
        results[currentIndex] = { error: error.message };
      }
    }
  }

  // Launch concurrent workers
  const workers = Array.from({ length: concurrency }, () => worker());
  await Promise.all(workers);

  return results;
}
```

---

## Pattern 15: Streaming Relay

Relay a streaming response from one agent through to another.

```
Caller ──► Agent A (SSE stream) ──► token by token ──► Agent B (accumulate) ──► final
```

**When to use:** Real-time UIs, progressive processing, live translation.

**ERC-8004 features:** A2A tasks/sendSubscribe, SSE streaming.

```typescript
async function streamingRelay(
  sourceAgentEndpoint: string,
  task: string,
  onToken: (token: string) => void
) {
  const response = await fetch(sourceAgentEndpoint, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Accept: "text/event-stream",
    },
    body: JSON.stringify({
      jsonrpc: "2.0",
      method: "tasks/sendSubscribe",
      params: {
        id: crypto.randomUUID(),
        message: {
          role: "user",
          parts: [{ type: "text", text: task }],
        },
      },
    }),
  });

  if (!response.body) throw new Error("No stream body");

  const reader = response.body.getReader();
  const decoder = new TextDecoder();
  let fullText = "";

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;

    const chunk = decoder.decode(value, { stream: true });
    const lines = chunk.split("\n");

    for (const line of lines) {
      if (line.startsWith("data: ")) {
        try {
          const data = JSON.parse(line.slice(6));
          const text = data.result?.status?.message?.parts?.[0]?.text ?? "";
          if (text) {
            fullText += text;
            onToken(text);
          }
        } catch {
          // Skip non-JSON lines
        }
      }
    }
  }

  return fullText;
}
```

---

## Pattern 16: Cross-Chain Discovery

Find agents registered on different chains.

```
Caller ──► Avalanche Registry ──► agents [A, B]
Caller ──► Base Registry      ──► agents [C, D]
Caller ──► merge + deduplicate ──► [A, B, C, D]
```

**When to use:** Maximum agent pool, cross-chain interoperability.

**ERC-8004 features:** Same contract ABI on multiple chains, `getAgent`.

```typescript
import { avalancheFuji, baseSepolia } from "viem/chains";

const CHAIN_CONFIGS = [
  {
    chain: avalancheFuji,
    registry: "0x..." as `0x${string}`,
    rpc: "https://api.avax-test.network/ext/bc/C/rpc",
  },
  {
    chain: baseSepolia,
    registry: "0x..." as `0x${string}`,
    rpc: "https://sepolia.base.org",
  },
];

async function crossChainDiscovery() {
  const allAgents: Array<{ chain: string; id: bigint; agent: any }> = [];

  await Promise.all(
    CHAIN_CONFIGS.map(async (config) => {
      const client = createPublicClient({
        chain: config.chain,
        transport: http(config.rpc),
      });

      const count = await client.readContract({
        address: config.registry,
        abi: REGISTRY_ABI,
        functionName: "getAgentCount",
      });

      for (let i = 1n; i <= count; i++) {
        try {
          const agent = await client.readContract({
            address: config.registry,
            abi: REGISTRY_ABI,
            functionName: "getAgent",
            args: [i],
          });
          allAgents.push({
            chain: config.chain.name,
            id: i,
            agent,
          });
        } catch {
          // Skip invalid agents
        }
      }
    })
  );

  return allAgents;
}
```

---

## Pattern 17: Trust Circle (Web-of-Trust Feedback Filtering)

Only consider feedback from agents you trust.

```
Caller ──► getSummary(agentId, trustedPeers[]) ──► filtered reputation
  ├── trustedPeers gave positive ──► high confidence
  └── only strangers gave positive ──► lower confidence
```

**When to use:** Sybil resistance, curated agent networks, high-trust environments.

**ERC-8004 features:** `getSummary` with web-of-trust parameter, `getFeedback`.

```typescript
async function trustCircleCheck(
  agentId: bigint,
  trustedPeers: `0x${string}`[],
  minTrustScore: number
) {
  const client = createPublicClient({ chain: avalancheFuji, transport: http() });

  // Get all feedback for the agent
  const feedbackCount = await client.readContract({
    address: REGISTRY_ADDRESS,
    abi: REGISTRY_ABI,
    functionName: "getSummary",
    args: [agentId],
  });

  // Read individual feedback entries
  const feedbacks: any[] = [];
  for (let i = 0n; i < feedbackCount[0]; i++) {
    const fb = await client.readContract({
      address: REGISTRY_ADDRESS,
      abi: REGISTRY_ABI,
      functionName: "getFeedback",
      args: [agentId, i],
    });
    feedbacks.push(fb);
  }

  // Filter to trusted peers only
  const trustedFeedback = feedbacks.filter((fb) =>
    trustedPeers.includes(fb.reviewer.toLowerCase() as `0x${string}`)
  );

  if (trustedFeedback.length === 0) {
    return {
      trusted: false,
      reason: "No feedback from trusted peers",
      totalFeedback: feedbacks.length,
      trustedFeedback: 0,
    };
  }

  const positive = trustedFeedback.filter((fb) => fb.isPositive).length;
  const trustScore = positive / trustedFeedback.length;

  return {
    trusted: trustScore >= minTrustScore,
    trustScore,
    trustedFeedback: trustedFeedback.length,
    totalFeedback: feedbacks.length,
  };
}
```

---

## Pattern 18: Autonomous Loop (Self-Improving via Feedback)

Agent iterates on its own output using feedback from other agents.

```
Agent ──► produce output v1
Agent ──► send to Reviewer Agent ──► feedback
Agent ──► incorporate feedback ──► produce output v2
Agent ──► send to Reviewer Agent ──► "looks good"
Agent ──► return output v2
```

**When to use:** Quality-critical content, code generation, report writing.

**ERC-8004 features:** A2A, feedback loop, `giveFeedback`.

```typescript
async function autonomousLoop(
  workerAgentId: bigint,
  reviewerAgentId: bigint,
  task: string,
  maxIterations: number = 3
) {
  let currentOutput = "";
  let iteration = 0;

  // Initial generation
  const initialResult = await discoveryThenCall(workerAgentId, task);
  currentOutput =
    initialResult.result?.history?.[0]?.parts?.[0]?.text ?? "";

  while (iteration < maxIterations) {
    iteration++;

    // Send to reviewer
    const reviewPrompt = `Review the following output and provide specific improvements. If the output is satisfactory, respond with exactly "APPROVED".\n\nOutput:\n${currentOutput}`;

    const review = await discoveryThenCall(reviewerAgentId, reviewPrompt);
    const reviewText =
      review.result?.history?.[0]?.parts?.[0]?.text ?? "";

    if (reviewText.includes("APPROVED")) {
      console.log(`Output approved after ${iteration} iterations`);
      break;
    }

    // Incorporate feedback
    const revisionPrompt = `Original task: ${task}\n\nPrevious output:\n${currentOutput}\n\nReviewer feedback:\n${reviewText}\n\nPlease produce an improved version incorporating the feedback.`;

    const revised = await discoveryThenCall(workerAgentId, revisionPrompt);
    currentOutput =
      revised.result?.history?.[0]?.parts?.[0]?.text ?? "";
  }

  return {
    finalOutput: currentOutput,
    iterations: iteration,
    converged: iteration < maxIterations,
  };
}
```

---

## Pattern Summary

| # | Pattern | Agents | Complexity | Key Feature |
|---|---------|--------|------------|-------------|
| 1 | Discovery then Call | 1 | Low | getAgent |
| 2 | Capability Check | 1 | Low | OASF |
| 3 | Fan-out | N | Medium | Parallel A2A |
| 4 | Chain | N (serial) | Medium | Sequential A2A |
| 5 | Supervisor/Worker | 1+N | Medium | Task decomposition |
| 6 | Negotiation | N | Medium | x402 |
| 7 | Reputation-Gated | N | Medium | getSummary |
| 8 | Payment-Gated | 1 | Medium | x402 |
| 9 | Heartbeat | N | Low | Health checks |
| 10 | Event-Driven | 2 | Medium | Webhooks |
| 11 | Consensus | 3+ | Medium | Voting |
| 12 | Specialist Routing | N | Medium | OASF domains |
| 13 | Fallback Chain | N | Low | Error handling |
| 14 | Batch Processing | 1 | Medium | Concurrency |
| 15 | Streaming Relay | 2 | High | SSE |
| 16 | Cross-Chain | N | High | Multi-chain |
| 17 | Trust Circle | N | High | Web-of-trust |
| 18 | Autonomous Loop | 2 | High | Feedback cycle |

---

*These patterns compose. A real-world system might combine Reputation-Gated (7) with Fallback Chain (13) and Payment-Gated (8) for a robust, paid, high-quality agent interaction.*
