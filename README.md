# taru-mcp

MCP server for [taru](https://taru.arupa.io) — connect Claude Code or Codex to your team's shared knowledge graph.

Zero dependencies. Pure Node.js. Works with any MCP client.

## Quick Setup

```bash
curl -fsSL https://raw.githubusercontent.com/arupa-inc/taru-mcp/main/setup.sh | bash
```

The script will ask you:
1. **Project folder name** — creates the workspace directory
2. **AI client** — Claude Code, Codex, or both
3. **Workspace token** — taru workspace token (`xxv_...`). Can be entered later if you don't have it yet.

It handles `npm init`, `taru-mcp` installation, agent file (`CLAUDE.md` / `AGENTS.md`) setup, and MCP registration automatically.

Get your workspace token from the taru web console: **Settings > API Key**.

## Tools

Once connected, these MCP tools are available to the AI:

| Tool | Description |
|------|-------------|
| `search_graph` | Search the knowledge base by natural language query |
| `read_full_document` | Read full document content by UUID |
| `store_document` | Store a document or opinion with auto-conflict detection |
| `list_documents` | List all documents in the workspace |
| `list_conflicts` | View pending knowledge conflicts |
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
