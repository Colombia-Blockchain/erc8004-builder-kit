"""
ERC-8004 Agent — Python/FastAPI Starter

A minimal but complete ERC-8004 agent built with FastAPI.
Includes: dashboard, health check, registration metadata, A2A card, MCP server, OASF.

Usage:
    pip install -r requirements.txt
    python server.py

After deploying, register on-chain:
    CHAIN=base-sepolia PRIVATE_KEY=$KEY ./scripts/register.sh https://YOUR-URL/registration.json
"""

import json
import os
import time
from pathlib import Path
from datetime import datetime, timezone

from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse, JSONResponse, FileResponse
from fastapi.middleware.cors import CORSMiddleware

# ---------- Setup ----------

BASE_DIR = Path(__file__).parent
REGISTRATION = json.loads((BASE_DIR / "registration.json").read_text())
VERSION = "1.0.0"

app = FastAPI(title=REGISTRATION["name"], version=VERSION)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["Content-Type"],
)

# ============================================================
# FREE PUBLIC ENDPOINTS
# ============================================================

@app.get("/", response_class=HTMLResponse)
async def dashboard():
    """Visual dashboard — what users see when clicking your agent in the scanner."""
    html_path = BASE_DIR / "dashboard.html"
    if html_path.exists():
        return HTMLResponse(html_path.read_text())
    return HTMLResponse("<h1>Agent is running</h1>")


@app.get("/api/health")
async def health():
    """Health check for Railway and monitoring."""
    return {
        "status": "ok",
        "agent": REGISTRATION["name"],
        "version": VERSION,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }


@app.get("/registration.json")
async def registration():
    """ERC-8004 agent metadata."""
    return JSONResponse(REGISTRATION)


@app.get("/.well-known/agent-card.json")
async def agent_card():
    """A2A agent card — same as registration for discovery."""
    return JSONResponse(REGISTRATION)


@app.get("/.well-known/agent-registration.json")
async def domain_verification():
    """Domain verification for scanners."""
    path = BASE_DIR / ".well-known" / "agent-registration.json"
    if path.exists():
        return JSONResponse(json.loads(path.read_text()))
    return JSONResponse({"error": "Verification file not found"}, status_code=404)


@app.get("/public/{filename}")
async def serve_static(filename: str):
    """Serve agent image and static files."""
    file_path = BASE_DIR / "public" / filename
    if not file_path.exists():
        return JSONResponse({"error": "File not found"}, status_code=404)
    return FileResponse(file_path)


# ============================================================
# OASF ENDPOINT
# ============================================================

@app.get("/oasf")
async def oasf():
    """Open Agent Service Framework — skills and domains for discovery."""
    return {
        "name": REGISTRATION["name"],
        "description": REGISTRATION.get("description", ""),
        "version": VERSION,
        "skills": [
            "natural_language_processing/information_retrieval_synthesis/search",
            "tool_interaction/api_schema_understanding",
        ],
        "domains": [
            "technology/blockchain",
        ],
        "updatedAt": datetime.now(timezone.utc).isoformat(),
    }


# ============================================================
# MCP SERVER (Model Context Protocol)
# ============================================================

MCP_TOOLS = [
    {
        "name": "get_agent_info",
        "description": "Get information about this agent",
        "inputSchema": {"type": "object", "properties": {}, "required": []},
    },
    {
        "name": "ping",
        "description": "Check if this agent is alive",
        "inputSchema": {
            "type": "object",
            "properties": {
                "message": {"type": "string", "description": "Optional echo message"}
            },
            "required": [],
        },
    },
    # Add your own tools here
]


@app.post("/mcp")
async def mcp_handler(request: Request):
    """MCP JSON-RPC 2.0 endpoint."""
    try:
        body = await request.json()
    except Exception:
        return JSONResponse(
            {"jsonrpc": "2.0", "id": None, "error": {"code": -32700, "message": "Parse error"}}
        )

    method = body.get("method")
    req_id = body.get("id")
    params = body.get("params", {})

    def rpc_ok(result):
        return JSONResponse({"jsonrpc": "2.0", "id": req_id, "result": result})

    def rpc_err(code, message):
        return JSONResponse({"jsonrpc": "2.0", "id": req_id, "error": {"code": code, "message": message}})

    if method == "initialize":
        return rpc_ok({
            "protocolVersion": "2025-11-25",
            "capabilities": {"tools": {}},
            "serverInfo": {"name": f"{REGISTRATION['name']} MCP", "version": VERSION},
        })

    if method == "tools/list":
        return rpc_ok({"tools": MCP_TOOLS})

    if method == "tools/call":
        tool_name = params.get("name")
        args = params.get("arguments", {})

        if tool_name == "get_agent_info":
            result = {
                "name": REGISTRATION["name"],
                "description": REGISTRATION.get("description", ""),
                "version": VERSION,
                "capabilities": REGISTRATION.get("capabilities", []),
                "services": [s["name"] for s in REGISTRATION.get("services", [])],
            }
        elif tool_name == "ping":
            result = {
                "pong": True,
                "message": args.get("message", f"Hello from {REGISTRATION['name']}"),
                "timestamp": datetime.now(timezone.utc).isoformat(),
            }
        else:
            return rpc_err(-32601, f"Tool not found: {tool_name}")

        return rpc_ok({"content": [{"type": "text", "text": json.dumps(result)}]})

    return rpc_err(-32601, f"Method not supported: {method}")


# ============================================================
# A2A ENDPOINT
# ============================================================

@app.post("/a2a/ask")
async def a2a_ask(request: Request):
    """A2A natural language endpoint."""
    body = await request.json()
    question = body.get("question") or body.get("message") or body.get("input")

    if not question or not isinstance(question, str):
        return JSONResponse(
            {"error": "Missing 'question' field", "usage": {"method": "POST", "body": {"question": "Your question here"}}},
            status_code=400,
        )

    # Replace with your own logic (LLM call, knowledge base, etc.)
    return {
        "agent": REGISTRATION["name"],
        "question": question,
        "answer": f"This is a starter template. Implement your answer logic for: {question}",
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }


# ============================================================
# START SERVER
# ============================================================

if __name__ == "__main__":
    import uvicorn

    port = int(os.environ.get("PORT", "3000"))
    print(f"\n  {REGISTRATION['name']} v{VERSION}")
    print(f"  http://localhost:{port}\n")
    print("  Endpoints:")
    print("  GET  /                        Dashboard")
    print("  GET  /api/health              Health check")
    print("  GET  /registration.json       ERC-8004 metadata")
    print("  GET  /.well-known/agent-card  A2A agent card")
    print(f"  POST /mcp                     MCP server ({len(MCP_TOOLS)} tools)")
    print("  POST /a2a/ask                 A2A endpoint")
    print("  GET  /oasf                    OASF discovery")
    print()

    uvicorn.run(app, host="0.0.0.0", port=port)
