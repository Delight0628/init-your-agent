# =============================================================================
# generate-context.ps1 - Main context generation script (Windows)
# =============================================================================
[CmdletBinding()]
param(
    [switch]$Batch,
    [switch]$Interactive,
    [string]$OutputPath
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SkillDir = Split-Path -Parent $ScriptDir
$AssetsDir = Join-Path $SkillDir "assets"
$Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
$Fallback = '{"error":"detection_failed"}'

if (-not (Test-Path $AssetsDir)) { New-Item -ItemType Directory -Path $AssetsDir -Force | Out-Null }
if (-not $OutputPath) { $OutputPath = Join-Path $AssetsDir "context-output.json" }

function Log  { [Console]::Error.WriteLine("[INFO] $args") }
function LogW { [Console]::Error.WriteLine("[WARN] $args") }

# Run sub-script via Process, return raw JSON string only
function Run-Detector {
    param([string]$ScriptPath, [string]$Name)
    Log "Detecting $Name..."
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "powershell.exe"
        $psi.Arguments = "-ExecutionPolicy Bypass -NoProfile -File `"$ScriptPath`""
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        $proc = [System.Diagnostics.Process]::Start($psi)
        $stdout = $proc.StandardOutput.ReadToEnd()
        $null = $proc.WaitForExit(15000)  # $null = prevents boolean leak to pipeline

        $raw = $stdout.Trim()
        if ($proc.HasExited -and $proc.ExitCode -eq 0 -and $raw.Length -gt 0) {
            $null = $raw | ConvertFrom-Json  # validate
            Log "$Name OK ($($raw.Length) bytes)"
            return $raw
        }
        LogW "$Name empty (exit=$($proc.ExitCode))"
    } catch {
        LogW "$Name failed: $($_.Exception.Message)"
    }
    return $null
}

# ========== Run detectors ==========
$systemJson    = Run-Detector "$ScriptDir\detect-system.ps1"    "System"
$devstackJson  = Run-Detector "$ScriptDir\detect-devstack.ps1"  "DevStack"
$aiAgentsJson  = Run-Detector "$ScriptDir\detect-ai-agents.ps1" "AI Agents"
$mcpJson       = Run-Detector "$ScriptDir\detect-mcp-servers.ps1" "MCP"
$servicesJson  = Run-Detector "$ScriptDir\detect-services.ps1"  "Services"

# ========== User ==========
Log "Collecting user preferences..."
$githubUser = ""; $gitEmail = ""
if (Get-Command git -ErrorAction SilentlyContinue) {
    try { $githubUser = git config --global user.name 2>$null } catch {}
    try { $gitEmail = git config --global user.email 2>$null } catch {}
}
$userJson = (@{
    github = @{ username = $githubUser; email = $gitEmail }
    preferences = @{ code_style = "auto_detect"; commit_template = "auto_detect"; frameworks = @() }
}) | ConvertTo-Json -Depth 10

# ========== Assemble ==========
Log "Assembling..."

# Parse each section into PSCustomObject for proper serialization
$meta = @{ timestamp = $Timestamp; version = "2.1.0"; generator = "devcontext-init"; mode = if($Interactive){"interactive"} else {"batch"} }

$sys = if($systemJson){ $systemJson | ConvertFrom-Json } else { $Fallback | ConvertFrom-Json }
$dev = if($devstackJson){ $devstackJson | ConvertFrom-Json } else { $Fallback | ConvertFrom-Json }
$ai  = if($aiAgentsJson){ $aiAgentsJson | ConvertFrom-Json } else { $Fallback | ConvertFrom-Json }
$mcp = if($mcpJson){ $mcpJson | ConvertFrom-Json } else { $Fallback | ConvertFrom-Json }
$svc = if($servicesJson){ $servicesJson | ConvertFrom-Json } else { $Fallback | ConvertFrom-Json }
$usr = $userJson | ConvertFrom-Json

$finalObj = [ordered]@{
    meta = $meta
    system = $sys
    devstack = $dev
    ai_agents = $ai
    mcp = $mcp
    services = $svc
    user = $usr
}

$jsonOutput = $finalObj | ConvertTo-Json -Depth 10

# Validate and write
try {
    $null = $jsonOutput | ConvertFrom-Json
    [System.IO.File]::WriteAllText($OutputPath, $jsonOutput, [System.Text.Encoding]::UTF8)
    Log "Written: $OutputPath"
} catch {
    [Console]::Error.WriteLine("[ERROR] JSON invalid: $($_.Exception.Message)")
    exit 1
}

# Summary
Log ""
try {
    if ($sys.os) { Log "  OS: $($sys.os.name)" }
    if ($sys.cpu) { Log "  CPU: $($sys.cpu.model)" }
    if ($sys.memory) { Log "  RAM: $($sys.memory.total_gb) GB" }
    if ($dev.languages) { Log "  Languages: $(($dev.languages.PSObject.Properties | ForEach-Object { $_.Name }) -join ', ')" }
    if ($ai.ai_agents) { Log "  AI Agents: $($ai.ai_agents.Count) installed" }
} catch {}
Log "Done."