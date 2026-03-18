# taru-mcp

MCP server for [taru](https://taru.arupa.io) — connect Claude Code or Codex to your team's shared knowledge graph.

Zero dependencies. Pure Node.js. Works with any MCP client.

## Install

### Claude Code

```bash
claude mcp add taru -- npx -y taru-mcp \
  --url https://your-server.com \
  --token xxv_your_token

# Copy the agent instructions to your project
cp node_modules/taru-mcp/samples/CLAUDE.md ./CLAUDE.md
```

### Codex (OpenAI)

```bash
codex mcp add taru -- npx -y taru-mcp \
  --url https://your-server.com \
  --token xxv_your_token

# Copy the agent instructions to your project
cp node_modules/taru-mcp/samples/AGENTS.md ./AGENTS.md
```

### Agent instructions

The `samples/` directory contains ready-to-use instruction files:

| File | For | Description |
|------|-----|-------------|
| `samples/CLAUDE.md` | Claude Code | Drop into your project root |
| `samples/AGENTS.md` | Codex | Drop into your project root |

These files teach the AI how to use taru tools, classify documents vs opinions, handle conflicts, and set confidence scores. **Copy the appropriate file to your project root** after installing.

## Options

| Flag | Env | Default | Description |
|------|-----|---------|-------------|
| `--url`, `-u` | `TARU_URL` | `http://localhost:9120` | Taru server URL |
| `--workspace-id`, `-w` | `TARU_WORKSPACE_ID` | `00000000-...0001` | Workspace UUID |
| `--token`, `-t` | `TARU_API_TOKEN` | — | API token (`xxv_...`) |

Get your API token from the taru web console: **Workspaces → Members → API Key**.

## Tools

Once connected, these MCP tools are available to the AI:

| Tool | Description |
|------|-------------|
| `search_graph` | Search the knowledge base by natural language query |
| `read_full_document` | Read full document content by UUID |
| `store_document` | Store a document or opinion with auto-conflict detection |
| `list_documents` | List all documents in the workspace |
| `list_conflicts` | View pending knowledge conflicts |
| `web_search` | Search the web via DuckDuckGo |
| `web_fetch` | Fetch and extract text from a URL |
| `rebalance` | Merge similar keywords, clean up orphan nodes |

## How it works

`taru-mcp` is a thin proxy: it reads JSON-RPC (MCP protocol) from stdin, forwards each request to the taru server over HTTP, and writes the response to stdout. No database, no AI calls — just I/O.

```
MCP Client (Claude/Codex)
    ↕ stdin/stdout (JSON-RPC)
taru-mcp (this package)
    ↕ HTTP POST
Taru Server (knowledge graph + embeddings + graph DB)
```

## License

MIT
