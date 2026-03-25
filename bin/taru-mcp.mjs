#!/usr/bin/env node

// Suppress all stderr output to prevent Codex MCP transport from closing.
// Codex monitors stderr and kills the transport if anything is written to it.
if (!process.env.TARU_DEBUG) {
  process.stderr.write = () => true;
}
process.on('warning', () => {});
process.on('uncaughtException', () => {});
process.on('unhandledRejection', () => {});

import { createInterface } from "node:readline";
import { argv, env, stdout } from "node:process";
import { request as httpsRequest } from "node:https";
import { request as httpRequest } from "node:http";
import { appendFileSync } from "node:fs";

const LOG_FILE = process.env.TARU_LOG || "";
function log(msg) {
  if (LOG_FILE) {
    try { appendFileSync(LOG_FILE, `[${new Date().toISOString()}] ${msg}\n`); } catch {}
  }
}

// --- Parse args ---

const args = argv.slice(2);
let url = env.TARU_URL || "https://taru-api.arupa.io";
let workspaceId = env.TARU_WORKSPACE_ID || "00000000-0000-0000-0000-000000000001";
let token = env.TARU_API_TOKEN || "";

for (let i = 0; i < args.length; i++) {
  if ((args[i] === "--url" || args[i] === "-u") && args[i + 1]) {
    url = args[++i];
  } else if ((args[i] === "--workspace-id" || args[i] === "-w") && args[i + 1]) {
    workspaceId = args[++i];
  } else if ((args[i] === "--token" || args[i] === "-t") && args[i + 1]) {
    token = args[++i];
  } else if (args[i] === "--help" || args[i] === "-h") {
    console.error(`taru-mcp — MCP proxy for taru knowledge graph

Usage:
  node node_modules/taru-mcp/bin/taru-mcp.mjs [options]

Options:
  --workspace-id, -w  Workspace UUID (env: TARU_WORKSPACE_ID)
  --token, -t         Workspace token (env: TARU_API_TOKEN)
  --help, -h          Show this help

Examples:
  claude mcp add taru -- node node_modules/taru-mcp/bin/taru-mcp.mjs --token tru_...
  codex mcp add taru -- node node_modules/taru-mcp/bin/taru-mcp.mjs --token tru_...
`);
    process.exit(0);
  }
}

url = url.replace(/\/+$/, "");
const hasExplicitWorkspace = args.some(a => a === "--workspace-id" || a === "-w") || env.TARU_WORKSPACE_ID;
const endpoint = hasExplicitWorkspace ? `${url}/mcp/${workspaceId}` : `${url}/mcp`;
const isHttps = endpoint.startsWith("https://");

// --- JSON-RPC proxy: stdin → HTTP POST → stdout ---

let pendingRequests = 0;
let stdinClosed = false;

const rl = createInterface({ input: process.stdin });

rl.on("line", async (line) => {
  if (!line.trim()) return;

  pendingRequests++;
  const parsed = safeParse(line);
  const id = parsed?.id ?? null;
  const method = parsed?.method || parsed?.params?.name || "unknown";
  log(`REQ id=${id} method=${method}`);

  try {
    const { status, body } = await post(endpoint, line);
    log(`RES id=${id} status=${status} len=${body?.length || 0}`);

    // 202 Accepted = notification, no response needed
    if (status === 202) {
      pendingRequests--;
      maybeExit();
      return;
    }

    // Server returned non-200: wrap in JSON-RPC error
    if (status < 200 || status >= 300) {
      const errResp = JSON.stringify({
        jsonrpc: "2.0",
        id,
        error: { code: -32603, message: `server error (${status}): ${body}` },
      });
      stdout.write(errResp + "\n");
      pendingRequests--;
      maybeExit();
      return;
    }

    // Verify response is valid JSON before forwarding
    const responseJson = safeParse(body);
    if (responseJson) {
      stdout.write(body + "\n");
    } else {
      const errResp = JSON.stringify({
        jsonrpc: "2.0",
        id,
        error: { code: -32603, message: `invalid server response` },
      });
      stdout.write(errResp + "\n");
    }
  } catch (err) {
    log(`ERR id=${id} ${err.message}`);
    const errResp = JSON.stringify({
      jsonrpc: "2.0",
      id,
      error: { code: -32603, message: `server unreachable: ${err.message}` },
    });
    stdout.write(errResp + "\n");
  }

  pendingRequests--;
  maybeExit();
});

rl.on("close", () => {
  stdinClosed = true;
  maybeExit();
});

// Only exit after stdin closes AND all pending HTTP requests are done
function maybeExit() {
  if (stdinClosed && pendingRequests === 0) {
    process.exit(0);
  }
}

// --- HTTP POST helper ---

function post(targetUrl, body) {
  return new Promise((resolve, reject) => {
    try {
      const parsed = new URL(targetUrl);
      const requester = isHttps ? httpsRequest : httpRequest;

      const headers = { "Content-Type": "application/json" };
      if (token) headers["Authorization"] = `Bearer ${token}`;

      const req = requester(
        parsed,
        { method: "POST", headers },
        (res) => {
          const chunks = [];
          res.on("data", (chunk) => chunks.push(chunk));
          res.on("end", () => {
            resolve({ status: res.statusCode, body: Buffer.concat(chunks).toString() });
          });
        }
      );

      req.on("error", (err) => reject(err));
      req.write(body);
      req.end();
    } catch (err) {
      reject(err);
    }
  });
}

function safeParse(s) {
  try {
    return JSON.parse(s);
  } catch {
    return null;
  }
}
