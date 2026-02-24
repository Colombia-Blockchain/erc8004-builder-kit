/**
 * x402 Payment Middleware for Hono
 *
 * Extracted from AvaRiskScan production agent.
 * Enables x402 micropayments on any Hono endpoint.
 *
 * Usage:
 *   import { x402Middleware } from "./x402-middleware";
 *   app.post("/api/premium", x402Middleware({ price: 10000 }), handler);
 */

import type { Context, Next } from "hono";

interface X402Config {
  /** Price in USDC micro-units (6 decimals). 10000 = $0.01 */
  price: number;
  /** USDC contract address (defaults to Avalanche mainnet) */
  asset?: string;
  /** Recipient wallet address (defaults to env X402_RECIPIENT) */
  recipient?: string;
  /** Network identifier (defaults to env X402_NETWORK or "avalanche") */
  network?: string;
  /** Facilitator URL for payment verification */
  facilitatorUrl?: string;
  /** Description shown in 402 response */
  description?: string;
}

const DEFAULT_USDC: Record<string, string> = {
  avalanche: "0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E",
  base: "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913",
  ethereum: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
  arbitrum: "0xaf88d065e77c8cC2239327C5EDb3A432268e5831",
  optimism: "0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85",
  polygon: "0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359",
};

const DEFAULT_FACILITATOR = "https://facilitator.ultravioletadao.xyz";

export function x402Middleware(config: X402Config) {
  return async (c: Context, next: Next) => {
    const paymentHeader = c.req.header("X-PAYMENT");

    if (!paymentHeader) {
      const network = config.network || process.env.X402_NETWORK || "avalanche";
      return c.json(
        {
          error: "Payment Required",
          x402: {
            version: 1,
            amount: config.price.toString(),
            asset: config.asset || DEFAULT_USDC[network] || DEFAULT_USDC.avalanche,
            recipient: config.recipient || process.env.X402_RECIPIENT || "",
            network,
            facilitator: config.facilitatorUrl || DEFAULT_FACILITATOR,
            description: config.description || "Premium endpoint access",
          },
        },
        402
      );
    }

    // Verify payment with facilitator
    const isValid = await verifyPayment(paymentHeader, config);
    if (!isValid) {
      return c.json({ error: "Invalid or expired payment" }, 403);
    }

    await next();
  };
}

async function verifyPayment(paymentHeader: string, config: X402Config): Promise<boolean> {
  try {
    const paymentJson = Buffer.from(paymentHeader, "base64").toString("utf-8");
    const payment = JSON.parse(paymentJson);

    if (payment.x402Version !== 1) return false;

    const recipient = config.recipient || process.env.X402_RECIPIENT || "";
    if (payment.payload?.payload?.to?.toLowerCase() !== recipient.toLowerCase()) return false;

    const amount = parseInt(payment.payload?.payload?.amount || "0");
    if (amount < config.price) return false;

    const now = Math.floor(Date.now() / 1000);
    if (now > (payment.payload?.payload?.validBefore || 0)) return false;

    const facilitatorUrl = config.facilitatorUrl || DEFAULT_FACILITATOR;
    const response = await fetch(`${facilitatorUrl}/verify`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payment),
      signal: AbortSignal.timeout(30_000),
    });

    return response.ok;
  } catch {
    return false;
  }
}
