# =============================================================================
# detect-mcp-servers.ps1 - MCP 服务器检测脚本 (Windows)
# 平台: Windows (PowerShell)
# 用途: 检测已配置的 MCP (Model Context Protocol) 服务器
# =============================================================================

[CmdletBinding()]
param()

function Test-Command {
    param([string]$Name)
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Detect-MCPServers {
    $servers = @()
    $foundConfig = $false

    $configPaths = @(
        "$HOME\.config\mcp",
        "$HOME\.mcp",
        "$HOME\.claude\mcp.json",
        "$HOME\.claude\settings.json",
        "$HOME\.cursor\mcp.json",
        "$HOME\.continue\mcp.json",
        "$HOME\.opencode\mcp.json"
    )

    foreach ($configPath in $configPaths) {
        if (Test-Path $configPath -PathType Leaf) {
            try {
                $configContent = Get-Content $configPath -Raw | ConvertFrom-Json
                if ($configContent.mcpServers) {
                    $foundConfig = $true
                    foreach ($serverName in $configContent.mcpServers.PSObject.Properties.Name) {
                        $serverConfig = $configContent.mcpServers.$serverName
                        $cmd = $serverConfig.command ?? "unknown"
                        $args = if ($serverConfig.args) { $serverConfig.args -join " " } else { "" }
                        
                        $cmdStatus = "unknown"
                        if (Test-Command $cmd) { $cmdStatus = "available" }
                        elseif ($cmd -match "npx|npm|yarn") { $cmdStatus = "npx/npm_available" }
                        else { $cmdStatus = "not_found" }

                        $servers += [PSCustomObject]@{
                            name     = $serverName
                            command  = $cmd
                            args     = $args
                            status   = $cmdStatus
                        }
                    }
                }
            } catch {}
        }
    }

    $mcpCliStatus = "not_installed"
    if (Test-Command "mcp") { $mcpCliStatus = "installed" }

    return @{
        servers      = $servers
        cli_status   = $mcpCliStatus
        found_config = $foundConfig
    } | ConvertTo-Json -Depth 5
}

function Detect-MCPProtocol {
    $sdkVersions = @()
    
    if (Test-Command "npm") {
        try {
            $globalPkgs = npm list -g --depth=0 2>$null
            $matches = [regex]::Matches($globalPkgs, "(@modelcontextprotocol/[^@\s]+)@([^@\s]+)")
            foreach ($match in $matches) {
                $sdkVersions += @{
                    package = $match.Groups[1].Value
                    version = $match.Groups[2].Value
                }
            }
        } catch {}
    }

    return @{ sdk_versions = $sdkVersions } | ConvertTo-Json -Depth 5
}

$output = @{
    mcp_servers = Detect-MCPServers | ConvertFrom-Json
    protocol    = Detect-MCPProtocol | ConvertFrom-Json
}

$output | ConvertTo-Json -Depth 5
