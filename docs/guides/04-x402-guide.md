# 04 — x402 Payment Protocol Guide

Monetize your ERC-8004 agent with the x402 payment protocol. Enable pay-per-call access to premium tools and services using HTTP 402 responses and stablecoin payments.

## Overview

x402 is Coinbase's open protocol for HTTP-native payments. It extends the HTTP 402 "Payment Required" status code to enable machine-to-machine micropayments using stablecoins (USDC). No invoices, no subscriptions, no API keys for billing — just HTTP headers.

```
┌──────────────┐                                 ┌──────────────┐
│  Client      │  1. Request premium endpoint    │  Your Agent  │
│  (Payer)     │ ───────────────────────────────▶ │  (Payee)     │
│              │                                  │              │
│              │  2. HTTP 402 + payment details   │              │
│              │ ◀─────────────────────────────── │              │
│              │                                  │              │
│              │  3. Request + X-PAYMENT header   │              │
│              │ ───────────────────────────────▶ │              │
│              │                                  │              │
│              │  4. Response (paid content)      │              │
│              │ ◀─────────────────────────────── │              │
└──────────────┘                                 └──────────────┘
```

### Why x402?

| Feature | x402 | API Keys + Stripe | Manual Crypto |
|---------|------|-------------------|---------------|
| Setup time | Minutes | Hours/days | Hours |
| Machine-to-machine | Native | Requires integration | Custom |
| Micropayments | Sub-cent possible | $0.50+ minimum | Gas costs |
| No accounts needed | Yes | No (signup required) | No (wallet setup) |
| On-chain settlement | Yes (USDC) | No | Yes |
| Human approval needed | No | No | Often |

## How x402 Works

### The Payment Flow

```
Client                    Facilitator               Your Agent
  │                         (Coinbase)                  │
  │  1. GET /api/premium                                │
  │ ───────────────────────────────────────────────────▶│
  │                                                     │
  │  2. 402 Payment Required                           │
  │     X-PAYMENT-RESPONSE: { amount, recipient, ... } │
  │ ◀───────────────────────────────────────────────────│
  │                                                     │
  │  3. Create & sign payment                          │
  │ ─────────────────────▶│                            │
  │                       │ (validate payment)          │
  │  4. Payment token     │                            │
  │ ◀─────────────────────│                            │
  │                                                     │
  │  5. GET /api/premium                                │
  │     X-PAYMENT: <signed-payment-token>              │
  │ ───────────────────────────────────────────────────▶│
  │                       │                            │
  │                       │ 6. Verify & settle payment │
  │                       │◀───────────────────────────│
  │                       │                            │
  │  7. 200 OK + premium content                       │
  │ ◀───────────────────────────────────────────────────│
  └─────────────────────────────────────────────────────┘
```

### Key Concepts

| Concept | Description |
|---------|-------------|
| **402 Response** | HTTP status code meaning "Payment Required" |
| **Facilitator** | Service that validates payments and settles on-chain (e.g., Coinbase) |
| **Payment Token** | Signed proof of payment included in the `X-PAYMENT` header |
| **USDC** | The stablecoin used for settlements (1 USDC = $1.00) |
| **Resource** | The endpoint requiring payment |

## Server Side: Implementing x402

### Step 1: Install the x402 Middleware

#### TypeScript (Hono)

```bash
npm install x402-hono
```

#### Python (FastAPI)

```bash
pip install x402-fastapi
```

### Step 2: Configure Payment on Your Endpoint

#### TypeScript (Hono)

```typescript
import { Hono } from "hono";
import { paymentMiddleware } from "x402-hono";

const app = new Hono();

// Your wallet address (receives payments)
const PAYMENT_ADDRESS = "0xYourWalletAddress";

// Facilitator URL (Coinbase)
const FACILITATOR_URL = "https://x402.org/facilitator";

// Free endpoints — no payment required
app.get("/api/health", (c) => c.json({ status: "healthy" }));
app.get("/registration.json", (c) => c.json(registration));

// Premium endpoint — requires payment
app.use(
  "/api/premium-analysis",
  paymentMiddleware({
    price: "$0.01",                    // Price per request
    payTo: PAYMENT_ADDRESS,            // Your wallet
    network: "base-sepolia",           // Chain for settlement
    facilitatorUrl: FACILITATOR_URL,   // Payment facilitator
    description: "Premium data analysis",
  })
);

app.post("/api/premium-analysis", async (c) => {
  // This only executes after payment is verified
  const body = await c.req.json();
  const analysis = await performPremiumAnalysis(body);
  return c.json(analysis);
});
```

#### Python (FastAPI)

```python
from fastapi import FastAPI, Request
from x402_fastapi import x402_middleware

app = FastAPI()

PAYMENT_ADDRESS = "0xYourWalletAddress"
FACILITATOR_URL = "https://x402.org/facilitator"

# Free endpoints
@app.get("/api/health")
async def health():
    return {"status": "healthy"}

# Premium endpoint with x402
app.add_middleware(
    x402_middleware,
    routes={
        "/api/premium-analysis": {
            "price": "$0.01",
            "pay_to": PAYMENT_ADDRESS,
            "network": "base-sepolia",
            "facilitator_url": FACILITATOR_URL,
            "description": "Premium data analysis",
        }
    }
)

@app.post("/api/premium-analysis")
async def premium_analysis(request: Request):
    body = await request.json()
    analysis = await perform_premium_analysis(body)
    return analysis
```

### Step 3: Define a Pricing Strategy

Common pricing patterns for AI agents:

| Pattern | Price | Use Case |
|---------|-------|----------|
| Flat per-call | $0.001 - $0.01 | Simple lookups, data retrieval |
| Tiered by complexity | $0.01 - $1.00 | Analysis, report generation |
| Compute-based | Variable | LLM calls, heavy computation |
| Subscription-like | $0.00 (with API key) | Frequent users with pre-payment |

```typescript
// Example: Multiple endpoints with different prices
const pricing = {
  "/api/basic-lookup": { price: "$0.001", description: "Basic data lookup" },
  "/api/analysis": { price: "$0.01", description: "Data analysis" },
  "/api/full-report": { price: "$0.10", description: "Full research report" },
};

for (const [path, config] of Object.entries(pricing)) {
  app.use(
    path,
    paymentMiddleware({
      price: config.price,
      payTo: PAYMENT_ADDRESS,
      network: "base-sepolia",
      facilitatorUrl: FACILITATOR_URL,
      description: config.description,
    })
  );
}
```

### Step 4: Mixed Free and Paid Endpoints

A common pattern is to offer basic functionality for free and charge for premium features:

```typescript
// Free: basic MCP tools
app.post("/mcp", mcpHandler);

// Free: basic A2A tasks
app.post("/a2a", a2aHandler);

// Paid: premium analysis via MCP
app.use("/mcp/premium", paymentMiddleware({ price: "$0.01", ... }));
app.post("/mcp/premium", premiumMCPHandler);

// Paid: detailed reports
app.use("/api/report", paymentMiddleware({ price: "$0.05", ... }));
app.post("/api/report", reportHandler);
```

## Client Side: Paying for Services

### TypeScript Client

```typescript
import { createX402Client } from "x402-client";
import { createWalletClient, http } from "viem";
import { baseSepolia } from "viem/chains";
import { privateKeyToAccount } from "viem/accounts";

// Set up wallet
const account = privateKeyToAccount(process.env.PRIVATE_KEY as `0x${string}`);
const wallet = createWalletClient({
  account,
  chain: baseSepolia,
  transport: http(),
});

// Create x402-aware HTTP client
const client = createX402Client(wallet);

// This automatically handles 402 responses:
// 1. Receives 402 + payment details
// 2. Signs payment with your wallet
// 3. Retries with X-PAYMENT header
// 4. Returns the paid response
const response = await client.fetch(
  "https://your-agent.example.com/api/premium-analysis",
  {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ query: "Analyze this dataset" }),
  }
);

const result = await response.json();
console.log("Premium analysis:", result);
```

### Python Client

```python
from x402_client import X402Client
from eth_account import Account

# Set up wallet
account = Account.from_key(PRIVATE_KEY)

# Create x402-aware client
client = X402Client(account)

# Automatically handles 402 payment flow
response = await client.post(
    "https://your-agent.example.com/api/premium-analysis",
    json={"query": "Analyze this dataset"},
)

result = response.json()
print("Premium analysis:", result)
```

### Manual Payment Flow

If you need more control, handle the 402 flow manually:

```typescript
async function payAndFetch(url: string, options: RequestInit) {
  // Step 1: Make the request
  const response = await fetch(url, options);

  if (response.status !== 402) {
    return response; // No payment needed
  }

  // Step 2: Parse payment requirements
  const paymentInfo = JSON.parse(
    response.headers.get("X-PAYMENT-RESPONSE") || "{}"
  );

  console.log(`Payment required: ${paymentInfo.amount} USDC`);
  console.log(`Recipient: ${paymentInfo.recipient}`);

  // Step 3: Create and sign payment
  const payment = await createPayment(paymentInfo, wallet);

  // Step 4: Retry with payment
  const paidResponse = await fetch(url, {
    ...options,
    headers: {
      ...options.headers,
      "X-PAYMENT": payment.token,
    },
  });

  return paidResponse;
}
```

## Registration with x402 Support

Advertise x402 support in your `registration.json`:

```json
{
  "type": "https://eips.ethereum.org/EIPS/eip-8004#registration-v1",
  "name": "Your Agent",
  "description": "Agent with free and premium services",
  "image": "https://your-agent.example.com/public/agent.png",
  "x402Support": true,
  "services": [
    { "name": "web", "endpoint": "https://your-agent.example.com/" },
    { "name": "MCP", "endpoint": "https://your-agent.example.com/mcp", "version": "2025-11-25" },
    { "name": "A2A", "endpoint": "https://your-agent.example.com/a2a", "version": "0.2" }
  ],
  "registrations": [
    {
      "agentId": 42,
      "agentRegistry": "eip155:84532:0x8004A169FB4a3325136EB29fA0ceB6D2e539a432"
    }
  ]
}
```

The `x402Support: true` flag tells clients and scanners that some endpoints may require payment.

## Testing x402

### Test Without Real Payments (Testnet)

Use Base Sepolia for testing:

```bash
# Step 1: Get testnet USDC
# Visit https://faucet.circle.com for Sepolia USDC

# Step 2: Make a request to your paid endpoint
curl -i https://your-agent.example.com/api/premium-analysis \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"query": "test"}'

# Expected: HTTP/1.1 402 Payment Required
# With X-PAYMENT-RESPONSE header containing payment details
```

### Verify Payment Receipt

```typescript
// Check your wallet balance after payments
import { createPublicClient, http } from "viem";
import { baseSepolia } from "viem/chains";

const publicClient = createPublicClient({
  chain: baseSepolia,
  transport: http(),
});

const usdcBalance = await publicClient.readContract({
  address: USDC_CONTRACT,
  abi: erc20ABI,
  functionName: "balanceOf",
  args: [PAYMENT_ADDRESS],
});

console.log(`USDC balance: ${Number(usdcBalance) / 1e6}`);
```

## Pricing Best Practices

### 1. Start Low

```typescript
// Start with minimal prices during testnet/beta
const BETA_PRICING = {
  "/api/basic": "$0.001",   // Fraction of a cent
  "/api/analysis": "$0.01", // One cent
  "/api/report": "$0.05",   // Five cents
};
```

### 2. Be Transparent

Include pricing in your agent card and documentation:

```typescript
app.get("/api/pricing", (c) => {
  return c.json({
    endpoints: [
      { path: "/api/basic", price: "$0.001", description: "Basic data lookup" },
      { path: "/api/analysis", price: "$0.01", description: "Data analysis" },
      { path: "/api/report", price: "$0.05", description: "Full research report" },
    ],
    currency: "USDC",
    network: "base",
    freeEndpoints: ["/api/health", "/mcp", "/a2a", "/registration.json"],
  });
});
```

### 3. Offer Free Tiers

Always provide free functionality:

| Tier | Access | Price |
|------|--------|-------|
| Free | Basic MCP tools, health, registration | $0.00 |
| Basic | Standard analysis, simple queries | $0.001-0.01 |
| Premium | Deep analysis, full reports, bulk data | $0.01-0.10 |

### 4. Consider Value-Based Pricing

```typescript
// Dynamic pricing based on request complexity
app.use("/api/analysis", async (c, next) => {
  const body = await c.req.json();
  const complexity = estimateComplexity(body);

  const price =
    complexity === "simple" ? "$0.001" :
    complexity === "moderate" ? "$0.01" :
    "$0.05";

  return paymentMiddleware({
    price,
    payTo: PAYMENT_ADDRESS,
    network: "base",
    facilitatorUrl: FACILITATOR_URL,
    description: `Analysis (${complexity})`,
  })(c, next);
});
```

## Supported Networks

| Network | Chain ID | USDC Address | Status |
|---------|----------|--------------|--------|
| Base | 8453 | `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` | Production |
| Base Sepolia | 84532 | `0x036CbD53842c5426634e7929541eC2318f3dCF7e` | Testnet |
| Ethereum | 1 | `0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48` | Production |
| Arbitrum | 42161 | `0xaf88d065e77c8cC2239327C5EDb3A432268e5831` | Production |

## Error Handling

### Common x402 Errors

| Error | Description | Solution |
|-------|-------------|----------|
| 402 without `X-PAYMENT-RESPONSE` | Malformed 402 response | Ensure middleware is configured correctly |
| Invalid payment token | Payment signature is invalid | Check wallet/account is correct |
| Insufficient balance | Payer doesn't have enough USDC | Fund the wallet with USDC |
| Payment expired | Payment token expired before use | Retry with fresh payment |
| Network mismatch | Payment on wrong chain | Ensure client and server use same network |

### Server-Side Error Handling

```typescript
app.onError((err, c) => {
  if (err.message.includes("x402")) {
    return c.json(
      {
        error: "PAYMENT_ERROR",
        message: "Payment processing failed",
        details: err.message,
      },
      500
    );
  }
  return c.json({ error: "INTERNAL_ERROR", message: err.message }, 500);
});
```

## Python Implementation

### Using the Decorator Pattern (FastAPI)

```python
from x402_middleware import require_x402_payment

@app.post("/api/premium-analysis")
@require_x402_payment(price=10000, description="Premium DeFi analysis")
async def premium_analysis(request: Request):
    body = await request.json()
    analysis = await perform_analysis(body)
    return analysis
```

See `examples/python-fastapi/x402_middleware.py` for the full implementation.

### Decorator Implementation Details

The decorator pattern wraps your endpoint and handles the full 402 flow:

```python
# x402_middleware.py
from functools import wraps
from fastapi import Request
from fastapi.responses import JSONResponse


def require_x402_payment(
    price: int,
    description: str,
    pay_to: str = None,
    network: str = "base-sepolia",
    facilitator_url: str = "https://x402.org/facilitator",
):
    """
    Decorator that adds x402 payment requirement to a FastAPI endpoint.

    Args:
        price: Price in USDC micro-units (10000 = $0.01)
        description: Human-readable description of what is being purchased
        pay_to: Wallet address to receive payment (defaults to env var)
        network: Settlement network
        facilitator_url: URL of the payment facilitator
    """
    def decorator(func):
        @wraps(func)
        async def wrapper(request: Request, *args, **kwargs):
            # Check for payment header
            payment_token = request.headers.get("X-PAYMENT")

            if not payment_token:
                # Return 402 with payment requirements
                return JSONResponse(
                    status_code=402,
                    content={
                        "error": "Payment Required",
                        "description": description,
                        "price": price,
                        "currency": "USDC",
                        "network": network,
                    },
                    headers={
                        "X-PAYMENT-RESPONSE": json.dumps({
                            "amount": price,
                            "recipient": pay_to or os.getenv("PAYMENT_ADDRESS"),
                            "network": network,
                            "facilitator": facilitator_url,
                            "description": description,
                        })
                    },
                )

            # Verify payment with facilitator
            is_valid = await verify_payment(payment_token, facilitator_url)
            if not is_valid:
                return JSONResponse(
                    status_code=402,
                    content={"error": "Invalid payment token"},
                )

            # Payment verified — execute the endpoint
            return await func(request, *args, **kwargs)

        return wrapper
    return decorator


async def verify_payment(token: str, facilitator_url: str) -> bool:
    """Verify a payment token with the facilitator service."""
    import httpx
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{facilitator_url}/verify",
            json={"token": token},
        )
        return response.status_code == 200 and response.json().get("valid", False)
```

### Multiple Paid Endpoints (Python)

```python
@app.post("/api/basic-lookup")
@require_x402_payment(price=1000, description="Basic data lookup")
async def basic_lookup(request: Request):
    body = await request.json()
    return await perform_lookup(body)


@app.post("/api/deep-analysis")
@require_x402_payment(price=50000, description="Deep analysis with AI")
async def deep_analysis(request: Request):
    body = await request.json()
    return await perform_deep_analysis(body)


@app.post("/api/full-report")
@require_x402_payment(price=100000, description="Full research report")
async def full_report(request: Request):
    body = await request.json()
    return await generate_report(body)
```

---

*x402 brings native payments to the agent economy. Start on testnet, validate your pricing, then switch to mainnet for production revenue.*
