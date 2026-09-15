# detect-devstack.ps1 - Dev stack detection (Windows) - Pure JSON output only
[CmdletBinding()]
param()
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Test-Command { param([string]$Name) $null -ne (Get-Command $Name -ErrorAction SilentlyContinue) }
function Get-Version {
    param([string]$Name, [string]$Flag = "--version")
    try {
        $raw = & $Name $Flag 2>$null | Select-Object -First 1
        if (-not $raw) { return $null }
        # Extract pure version number: match x.y.z pattern
        if ($raw -match '(\d+\.\d+(\.\d+)*)') { return $Matches[1] }
        return ($raw -split '\s+')[-1]
    } catch { return $null }
}

$langs = @{}
if (Test-Command "node")    { $v = Get-Version "node";    if ($v) { $langs["node"] = $v } }
if (Test-Command "python")  { $v = Get-Version "python";  if ($v) { $langs["python"] = $v } }
if (Test-Command "python3") { $v = Get-Version "python3"; if ($v) { $langs["python"] = $v } }
if (Test-Command "go")      { $v = Get-Version "go";      if ($v) { $langs["go"] = $v } }
if (Test-Command "rustc")   { $v = Get-Version "rustc";   if ($v) { $langs["rust"] = $v } }
if (Test-Command "java")    { $v = Get-Version "java";    if ($v) { $langs["java"] = $v } }
if (Test-Command "dotnet")  { $v = Get-Version "dotnet";  if ($v) { $langs["dotnet"] = $v } }
if (Test-Command "ruby")    { $v = Get-Version "ruby";    if ($v) { $langs["ruby"] = $v } }
if (Test-Command "php")     { $v = Get-Version "php";     if ($v) { $langs["php"] = $v } }
if (Test-Command "dart")    { $v = Get-Version "dart";    if ($v) { $langs["dart"] = $v } }

$pms = @{}
if (Test-Command "npm")    { $v = Get-Version "npm";    if ($v) { $pms["npm"] = $v } }
if (Test-Command "yarn")   { $v = Get-Version "yarn";   if ($v) { $pms["yarn"] = $v } }
if (Test-Command "pnpm")   { $v = Get-Version "pnpm";   if ($v) { $pms["pnpm"] = $v } }
if (Test-Command "pip")    { $v = Get-Version "pip";    if ($v) { $pms["pip"] = $v } }
if (Test-Command "pip3")   { $v = Get-Version "pip3";   if ($v) { $pms["pip"] = $v } }
if (Test-Command "cargo")  { $v = Get-Version "cargo";  if ($v) { $pms["cargo"] = $v } }
if (Test-Command "choco")  { $v = Get-Version "choco";  if ($v) { $pms["chocolatey"] = $v } }
if (Test-Command "scoop")  { $pms["scoop"] = "installed" }
if (Test-Command "winget") { $v = Get-Version "winget"; if ($v) { $pms["winget"] = $v } }
if (Test-Command "uv")     { $v = Get-Version "uv";     if ($v) { $pms["uv"] = $v } }
if (Test-Command "poetry") { $v = Get-Version "poetry"; if ($v) { $pms["poetry"] = $v } }
if (Test-Command "deno")   { $v = Get-Version "deno";   if ($v) { $pms["deno"] = $v } }
if (Test-Command "bun")    { $v = Get-Version "bun";    if ($v) { $pms["bun"] = $v } }

$editors = @()
if (Test-Command "code")      { $editors += "VS Code" }
if (Test-Command "notepad++") { $editors += "Notepad++" }
if (Test-Command "pwsh")      { $editors += "PowerShell ISE" }
if (Test-Command "cursor")    { $editors += "Cursor" }
if (Test-Command "windsurf")  { $editors += "Windsurf" }

$tools = @{}
if (Test-Command "eslint")       { $tools["eslint"]       = "installed" }
if (Test-Command "prettier")     { $tools["prettier"]     = "installed" }
if (Test-Command "black")        { $tools["black"]        = "installed" }
if (Test-Command "ruff")         { $tools["ruff"]         = "installed" }
if (Test-Command "isort")        { $tools["isort"]        = "installed" }
if (Test-Command "gofmt")        { $tools["gofmt"]        = "installed" }
if (Test-Command "rustfmt")      { $tools["rustfmt"]      = "installed" }
if (Test-Command "markdownlint") { $tools["markdownlint"] = "installed" }

# Git config
$gitConfig = @{ version = ""; user = ""; email = ""; remote = ""; ssh_keys = @(); gh_cli = "not_installed" }
if (Test-Command "git") {
    $gv = Get-Version "git"; if ($gv) { $gitConfig["version"] = $gv }
    try { $gitConfig["user"] = git config --global user.name 2>$null } catch {}
    try { $gitConfig["email"] = git config --global user.email 2>$null } catch {}
    try {
        $remote = git remote -v 2>$null | Select-String "origin" | Select-Object -First 1
        if ($remote) { $gitConfig["remote"] = ($remote.Line -split '\s+')[1] }
    } catch {}
    $sshDir = Join-Path $HOME ".ssh"
    if (Test-Path $sshDir) {
        $keys = @()
        Get-ChildItem -Path $sshDir -Filter "id_*" -File -ErrorAction SilentlyContinue | ForEach-Object {
            $keys += $_.Name -replace "^id_", "" -replace "\.pub$", ""
        }
        $gitConfig["ssh_keys"] = $keys
    }
    if (Test-Command "gh") { $gitConfig["gh_cli"] = "installed" }
}

@{
    languages        = $langs
    package_managers = $pms
    editors          = $editors
    linters_formatters = $tools
    git              = $gitConfig
} | ConvertTo-Json -Depth 10