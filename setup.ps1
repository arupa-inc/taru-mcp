# taru MCP setup script for Windows
# Usage:
#   irm https://raw.githubusercontent.com/arupa-inc/taru-mcp/main/setup.ps1 | iex

$ErrorActionPreference = "Stop"
$URL = "https://taru-api.arupa.io"

Write-Host ""
Write-Host "  🌳 taru MCP Setup" -ForegroundColor Green
Write-Host ""

# 1. Ask project folder name
$Folder = Read-Host "Project folder name"
if (-not $Folder) {
    Write-Host "Error: folder name is required" -ForegroundColor Red
    exit 1
}

if (Test-Path $Folder) {
    Write-Host "==> Directory '$Folder' already exists, using it."
} else {
    New-Item -ItemType Directory -Path $Folder | Out-Null
    Write-Host "==> Created '$Folder'"
}
Set-Location $Folder

# 2. Ask client type
Write-Host ""
Write-Host "Which AI client do you use?"
Write-Host "  1) Claude Code"
Write-Host "  2) Codex"
Write-Host "  3) Not sure (copies both CLAUDE.md and AGENTS.md)"
Write-Host ""
$ClientChoice = Read-Host "Choose [1/2/3]"

switch ($ClientChoice) {
    "1" { $Client = "claude" }
    "2" { $Client = "codex" }
    default { $Client = "both" }
}

# 3. Ask token (skippable)
Write-Host ""
$Token = Read-Host "Workspace token (xxv_..., press Enter to add later)"

# Check npm
if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
    Write-Host "Error: 'npm' not found. Install Node.js first." -ForegroundColor Red
    exit 1
}

# Init & install
if (-not (Test-Path "package.json")) {
    Write-Host "==> Initializing package.json..."
    npm init -y --silent 2>&1 | Out-Null
}

Write-Host "==> Installing taru-mcp..."
npm install taru-mcp --silent

# Copy agent files
function Copy-AgentFile($File) {
    $src = "node_modules/taru-mcp/samples/$File"
    if (Test-Path $File) {
        Write-Host "==> $File already exists, appending taru instructions..."
        Add-Content -Path $File -Value ""
        Get-Content $src | Add-Content -Path $File
    } else {
        Copy-Item $src -Destination "./$File"
        Write-Host "==> Created $File"
    }
}

if ($Client -eq "claude") {
    Copy-AgentFile "CLAUDE.md"
} elseif ($Client -eq "codex") {
    Copy-AgentFile "AGENTS.md"
} else {
    Copy-AgentFile "CLAUDE.md"
    Copy-AgentFile "AGENTS.md"
}

# Register MCP server
function Register-MCP($Cli) {
    $tokenArgs = ""
    if ($Token) { $tokenArgs = " --token $Token" }

    if (Get-Command $Cli -ErrorAction SilentlyContinue) {
        Write-Host "==> Registering MCP server with $Cli..."
        $cmd = "$Cli mcp add taru -- npx taru-mcp --url $URL$tokenArgs"
        Invoke-Expression $cmd
    } else {
        Write-Host "==> '$Cli' not found, skipping MCP registration."
        Write-Host "    Run this later: $Cli mcp add taru -- npx taru-mcp --url $URL$tokenArgs"
    }
}

if ($Client -eq "claude") {
    Register-MCP "claude"
} elseif ($Client -eq "codex") {
    Register-MCP "codex"
} else {
    Register-MCP "claude"
    Register-MCP "codex"
}

Write-Host ""
Write-Host "  ✅ Setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "  Project: $(Get-Location)"
if ($Client -eq "claude" -or $Client -eq "both") { Write-Host "  Agent file: ./CLAUDE.md" }
if ($Client -eq "codex" -or $Client -eq "both") { Write-Host "  Agent file: ./AGENTS.md" }
if ($Token) { Write-Host "  Token: configured" } else { Write-Host "  Token: not set yet (add via settings)" }
Write-Host ""
Write-Host "  Open this folder in your AI client to start growing the tree."
Write-Host ""
