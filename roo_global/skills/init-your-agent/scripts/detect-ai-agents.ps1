# detect-ai-agents.ps1 - AI agent detection (Windows) - Pure JSON output only
[CmdletBinding()]
param()

function Test-Command { param([string]$Name) $null -ne (Get-Command $Name -ErrorAction SilentlyContinue) }
function Get-Version {
    param([string]$Name, [string]$Flag = "--version")
    try { & $Name $Flag 2>$null | Select-Object -First 1 } catch { "unknown" }
}

$agents = @()
$agentDefs = @(
    @{ name="Claude Code"; cli="claude"; icon="fire"; cfg="$HOME\.claude" },
    @{ name="Codex CLI"; cli="codex"; icon="flask"; cfg="$HOME\.config\codex" },
    @{ name="GitHub Copilot"; cli="gh"; icon="bolt"; cfg="$HOME\.config\github-cli" },
    @{ name="Cursor"; cli="cursor"; icon="monitor"; cfg="$HOME\.cursor" },
    @{ name="Continue"; cli="continue"; icon="link"; cfg="$HOME\.continue" },
    @{ name="Hermes"; cli="hermes"; icon="eagle"; cfg="$HOME\.hermes" },
    @{ name="OpenCode"; cli="opencode"; icon="laptop"; cfg="$HOME\.opencode" },
    @{ name="Aider"; cli="aider"; icon="robot"; cfg="$HOME\.aider" },
    @{ name="Amazon Q"; cli="q"; icon="package"; cfg="$HOME\.q" },
    @{ name="Roo Code"; cli="roo"; icon="puzzle"; cfg="$HOME\.roo" },
    @{ name="Windsurf"; cli="windsurf"; icon="surf"; cfg="$HOME\.windsurf" },
    @{ name="Ollama"; cli="ollama"; icon="llama"; cfg="$HOME\.ollama" }
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