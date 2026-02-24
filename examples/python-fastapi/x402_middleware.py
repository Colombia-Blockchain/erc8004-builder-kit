"""
x402 Payment Middleware for FastAPI

Extracted from Apex Arbitrage Agent production patterns.
Enables x402 micropayments on any FastAPI endpoint.

Usage:
    from x402_middleware import require_x402_payment

    @app.post("/api/premium")
    @require_x402_payment(price=10000)
    async def premium_endpoint(request: Request):
        return {"data": "premium content"}
"""

import base64
import json
import os
from functools import wraps

from fastapi import Request
from fastapi.responses import JSONResponse

DEFAULT_USDC = {
    "avalanche": "0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E",
    "base": "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913",
    "ethereum": "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
    "arbitrum": "0xaf88d065e77c8cC2239327C5EDb3A432268e5831",
    "optimism": "0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85",
    "polygon": "0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359",
}

DEFAULT_FACILITATOR = "https://facilitator.ultravioletadao.xyz"


def require_x402_payment(
    price: int,
    asset: str | None = None,
    recipient: str | None = None,
    network: str | None = None,
    facilitator_url: str | None = None,
    description: str = "Premium endpoint access",
):
    """Decorator to gate a FastAPI endpoint behind x402 payment."""

    net = network or os.environ.get("X402_NETWORK", "avalanche")
    usdc = asset or DEFAULT_USDC.get(net, DEFAULT_USDC["avalanche"])
    wallet = recipient or os.environ.get("X402_RECIPIENT", "")
    fac_url = facilitator_url or DEFAULT_FACILITATOR

    def decorator(func):
        @wraps(func)
        async def wrapper(request: Request, *args, **kwargs):
            payment_header = request.headers.get("X-PAYMENT")

            if not payment_header:
                return JSONResponse(
                    {
                        "error": "Payment Required",
                        "x402": {
                            "version": 1,
                            "amount": str(price),
                            "asset": usdc,
                            "recipient": wallet,
                            "network": net,
                            "facilitator": fac_url,
                            "description": description,
                        },
                    },
                    status_code=402,
                )

            if not await _verify_payment(payment_header, price, wallet, fac_url):
                return JSONResponse({"error": "Invalid or expired payment"}, status_code=403)

            return await func(request, *args, **kwargs)

        return wrapper

    return decorator


async def _verify_payment(header: str, min_price: int, recipient: str, facilitator: str) -> bool:
    try:
        import httpx

        payment = json.loads(base64.b64decode(header).decode("utf-8"))

        if payment.get("x402Version") != 1:
            return False

        payload = payment.get("payload", {}).get("payload", {})
        if payload.get("to", "").lower() != recipient.lower():
            return False

        amount = int(payload.get("amount", "0"))
        if amount < min_price:
            return False

        import time
        if time.time() > payload.get("validBefore", 0):
            return False

        async with httpx.AsyncClient(timeout=30) as client:
            resp = await client.post(f"{facilitator}/verify", json=payment)
            return resp.status_code == 200

    except Exception:
        return False
