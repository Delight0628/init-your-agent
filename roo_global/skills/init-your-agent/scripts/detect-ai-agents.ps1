# =============================================================================
# detect-ai-agents.ps1 - AI 编程代理检测脚本 (Windows)
# 平台: Windows (PowerShell)
# 用途: 检测本机已安装的 AI 编程代理及其状态
# =============================================================================

[CmdletBinding()]
param()

function Test-Command {
    param([string]$Name)
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Get-CommandVersion {
    param(
        [string]$Name,
        [string]$Flag = "--version"
    )
    try {
        $result = & $Name $Flag 2>$null | Select-Object -First 1
        return ($result -replace '.*version\s*', '') -replace '.*\s+', '' -trim
    } catch {
        return "unknown"
    }
}

function Detect-AllAgents {
    $agents = @()
    
    # 定义要检测的 AI 代理
    $agentDefs = @(
        @{ name="Claude Code"; cli="claude"; icon="🔥"; configPaths=@("$HOME\.claude") },
        @{ name="Codex CLI"; cli="codex"; icon="🧪"; configPaths=@("$HOME\.config\codex") },
        @{ name="GitHub Copilot"; cli="gh"; icon="⚡"; configPaths=@("$HOME\.config\github-cli") },
        @{ name="Cursor"; cli="cursor"; icon="🖥️"; configPaths=@("$HOME\.cursor") },
        @{ name="Continue"; cli="continue"; icon="🔗"; configPaths=@("$HOME\.continue") },
        @{ name="Hermes"; cli="hermes"; icon="🦅"; configPaths=@("$HOME\.hermes") },
        @{ name="OpenClaw"; cli="openclaw"; icon="🐾"; configPaths=@("$HOME\.openclaw") },
        @{ name="OpenCode"; cli="opencode"; icon="💻"; configPaths=@("$HOME\.opencode") },
        @{ name="Aider"; cli="aider"; icon="🤖"; configPaths=@("$HOME\.aider") },
        @{ name="Codeium CLI"; cli="codeium"; icon="🦀"; configPaths=@("$HOME\.codeium") },
        @{ name="Amazon Q"; cli="q"; icon="📦"; configPaths=@("$HOME\.q") },
        @{ name="Roo Code"; cli="roo"; icon="🧩"; configPaths=@("$HOME\.roo") },
        @{ name="Windsurf"; cli="windsurf"; icon="🏄"; configPaths=@("$HOME\.windsurf") },
        @{ name="Ollama"; cli="ollama"; icon="🦙"; configPaths=@("$HOME\.ollama") }
    )

    foreach ($agent in $agentDefs) {
        if (Test-Command $agent.cli) {
            $version = Get-CommandVersion $agent.cli
            $configStatus = "no_config"
            
            foreach ($path in $agent.configPaths) {
                if (Test-Path $path) {
                    $configStatus = "configured"
                    break
                }
            }

            $agents += [PSCustomObject]@{
                name         = $agent.name
                cli          = $agent.cli
                version      = $version
                config_status = $configStatus
                icon         = $agent.icon
            }
        }
    }

    return $agents
}

function Detect-ActiveSessions {
    $sessions = @()
    $agentPorts = @(3000, 3001, 4000, 4001, 5000, 5001, 6000, 6001, 8080, 8081, 1234)
    
    foreach ($port in $agentPorts) {
        $connections = netstat -ano 2>$null | Select-String ":$port\s+LISTENING"
        if ($connections) {
            $sessions += [PSCustomObject]@{
                port   = $port
                active = $true
            }
        }
    }

    return $sessions
}

function Detect-ModelConfigs {
    $models = @()

    # 检查 API 密钥
    if ($env:ANTHROPIC_API_KEY) { $models += @{ provider="anthropic"; configured=$true } }
    if ($env:OPENAI_API_KEY)    { $models += @{ provider="openai"; configured=$true } }
    if ($env:GOOGLE_API_KEY)    { $models += @{ provider="google"; configured=$true } }
    if ($env:MISTRAL_API_KEY)   { $models += @{ provider="mistral"; configured=$true } }
    if ($env:COHERE_API_KEY)    { $models += @{ provider="cohere"; configured=$true } }

    # 检查 Ollama
    if (Test-Command "ollama") {
        try {
            $modelList = ollama list 2>$null
            if ($modelList) {
                $modelCount = ($modelList | Where-Object { $_.Trim() } | Measure-Object).Count
                $models += @{ provider="ollama"; model_count=$modelCount }
            }
        } catch {}
    }

    # 检查 LM Studio (本地服务器)
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:1234/v1/models" -TimeoutSec 2 -ErrorAction SilentlyContinue
        if ($response) { $models += @{ provider="lm_studio"; configured=$true } }
    } catch {}

    return $models
}

# 主输出
$output = @{
    ai_agents       = Detect-AllAgents
    active_sessions  = Detect-ActiveSessions
    model_configs    = Detect-ModelConfigs
}

$output | ConvertTo-Json -Depth 5
