#!/usr/bin/env node

import { createInterface } from "node:readline";
import { argv, env, stderr, stdout } from "node:process";
import { request as httpsRequest } from "node:https";
import { request as httpRequest } from "node:http";

// --- Parse args ---

const args = argv.slice(2);
let url = env.TARU_URL || "http://localhost:9120";
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
    stderr.write(`taru-mcp — MCP proxy for taru knowledge graph

Usage:
  npx taru-mcp [options]

Options:
  --url, -u           Taru server URL (env: TARU_URL, default: http://localhost:9120)
  --workspace-id, -w  Workspace UUID (env: TARU_WORKSPACE_ID)
  --token, -t         API token (env: TARU_API_TOKEN)
  --help, -h          Show this help

Examples:
  claude mcp add taru -- npx -y taru-mcp --url https://taru.example.com --token xxv_...
  codex mcp add taru -- npx -y taru-mcp -u http://localhost:9120 -w <uuid>
`);
    process.exit(0);
  }
}

url = url.replace(/\/+$/, "");
const endpoint = `${url}/mcp/${workspaceId}`;
const isHttps = endpoint.startsWith("https://");

stderr.write(`[taru-mcp] endpoint: ${endpoint}\n`);

// --- JSON-RPC proxy: stdin → HTTP POST → stdout ---

const rl = createInterface({ input: process.stdin });

rl.on("line", async (line) => {
  if (!line.trim()) return;

  try {
    const body = await post(endpoint, line);

    // 202 Accepted = notification, no response needed
    if (body === null) return;

    stdout.write(body + "\n");
  } catch (err) {
    const parsed = safeParse(line);
    const id = parsed?.id ?? null;
    const errResp = JSON.stringify({
      jsonrpc: "2.0",
      id,
      error: { code: -32603, message: `server unreachable: ${err.message}` },
    });
    stdout.write(errResp + "\n");
  }
});

rl.on("close", () => process.exit(0));

// --- HTTP POST helper ---

function post(targetUrl, body) {
  return new Promise((resolve, reject) => {
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
          if (res.statusCode === 202) {
            resolve(null);
            return;
          }
          resolve(Buffer.concat(chunks).toString());
        });
      }
    );

    req.on("error", reject);
    req.write(body);
    req.end();
  });
}

function safeParse(s) {
  try {
    return JSON.parse(s);
  } catch {
    return null;
  }
}
