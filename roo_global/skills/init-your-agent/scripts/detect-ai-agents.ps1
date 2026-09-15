# detect-ai-agents.ps1 - AI agent detection (Windows) - Pure JSON output only
[CmdletBinding()]
param()
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Test-Command { param([string]$Name) $null -ne (Get-Command $Name -ErrorAction SilentlyContinue) }
function Get-Version {
    param([string]$Name, [string]$Flag = "--version")
    try {
        $raw = & $Name $Flag 2>$null | Select-Object -First 1
        if (-not $raw) { return "unknown" }
        if ($raw -match '(\d+\.\d+(\.\d+)*)') { return $Matches[1] }
        return ($raw -split '\s+')[-1]
    } catch { return "unknown" }
}

$agents = @()
$agentDefs = @(
    @{ name="Claude Code"; cli="claude"; icon="claude"; cfg="$HOME\.claude" },
    @{ name="Codex CLI"; cli="codex"; icon="codex"; cfg="$HOME\.config\codex" },
    @{ name="GitHub Copilot"; cli="gh"; icon="gh"; cfg="$HOME\.config\github-cli" },
    @{ name="Cursor"; cli="cursor"; icon="cursor"; cfg="$HOME\.cursor" },
    @{ name="Continue"; cli="continue"; icon="continue"; cfg="$HOME\.continue" },
    @{ name="Hermes"; cli="hermes"; icon="hermes"; cfg="$HOME\.hermes" },
    @{ name="OpenCode"; cli="opencode"; icon="opencode"; cfg="$HOME\.opencode" },
    @{ name="Aider"; cli="aider"; icon="aider"; cfg="$HOME\.aider" },
    @{ name="Amazon Q"; cli="q"; icon="q"; cfg="$HOME\.q" },
    @{ name="Roo Code"; cli="roo"; icon="roo"; cfg="$HOME\.roo" },
    @{ name="Windsurf"; cli="windsurf"; icon="windsurf"; cfg="$HOME\.windsurf" },
    @{ name="Ollama"; cli="ollama"; icon="ollama"; cfg="$HOME\.ollama" },
    @{ name="MiMo"; cli="mimo"; icon="mimo"; cfg="$HOME\.mimo" }
)
foreach ($a in $agentDefs) {
    if (Test-Command $a.cli) {
        $configured = "no_config"
        if (Test-Path $a.cfg) { $configured = "configured" }
        $agents += @{
            name = $a.name; cli = $a.cli; version = (Get-Version $a.cli)
            config_status = $configured; icon = $a.icon
        }
    }
}

# Model configs
$models = @()
if ($env:ANTHROPIC_API_KEY) { $models += @{ provider="anthropic"; configured=$true } }
if ($env:OPENAI_API_KEY)    { $models += @{ provider="openai"; configured=$true } }
if ($env:GOOGLE_API_KEY)    { $models += @{ provider="google"; configured=$true } }

# Check LM Studio
try {
    $null = Invoke-WebRequest -Uri "http://localhost:1234/v1/models" -TimeoutSec 2 -ErrorAction Stop
    $models += @{ provider="lm_studio"; configured=$true }
} catch {}

@{
    ai_agents      = $agents
    active_sessions = @()
    model_configs   = $models
} | ConvertTo-Json -Depth 10