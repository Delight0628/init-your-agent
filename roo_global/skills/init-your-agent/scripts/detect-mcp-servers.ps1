# detect-mcp-servers.ps1 - MCP server detection (Windows) - Pure JSON output only
[CmdletBinding()]
param()

function Test-Command { param([string]$Name) $null -ne (Get-Command $Name -ErrorAction SilentlyContinue) }

$servers = @()
$foundConfig = $false
$configPaths = @(
    "$HOME\.config\mcp", "$HOME\.mcp", "$HOME\.claude\mcp.json",
    "$HOME\.claude\settings.json", "$HOME\.cursor\mcp.json",
    "$HOME\.continue\mcp.json", "$HOME\.opencode\mcp.json"
)
foreach ($configPath in $configPaths) {
    if (Test-Path $configPath -PathType Leaf) {
        try {
            $config = Get-Content $configPath -Raw | ConvertFrom-Json
            if ($config.mcpServers) {
                $foundConfig = $true
                foreach ($serverName in $config.mcpServers.PSObject.Properties.Name) {
                    $sc = $config.mcpServers.$serverName
                    $cmd = if ($sc.command) { $sc.command } else { "unknown" }
                    $status = "unknown"
                    if (Test-Command $cmd) { $status = "available" }
                    elseif ($cmd -match "npx|npm|yarn") { $status = "npx/npm_available" }
                    else { $status = "not_found" }
                    $servers += @{ name = $serverName; command = $cmd; args = if ($sc.args) { ($sc.args -join " ") } else { "" }; status = $status }
                }
            }
        } catch {}
    }
}

$mcpCli = "not_installed"
if (Test-Command "mcp") { $mcpCli = "installed" }

$sdkVersions = @()
if (Test-Command "npm") {
    try {
        $npmPkgs = npm list -g --depth=0 2>$null
        $npmMatches = [regex]::Matches($npmPkgs, "(@modelcontextprotocol/[^@\s]+)@([^@\s]+)")
        foreach ($m in $npmMatches) {
            $sdkVersions += @{ package = $m.Groups[1].Value; version = $m.Groups[2].Value }
        }
    } catch {}
}

@{
    mcp_servers = @{ servers = $servers; cli_status = $mcpCli; found_config = $foundConfig }
    protocol = @{ sdk_versions = $sdkVersions }
} | ConvertTo-Json -Depth 10