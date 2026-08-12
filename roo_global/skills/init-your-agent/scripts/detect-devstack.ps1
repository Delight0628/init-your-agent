# detect-devstack.ps1 - Dev stack detection (Windows) - Pure JSON output only
[CmdletBinding()]
param()
$OutputEncoding = [System.Text.Encoding]::UTF8

function Test-Command { param([string]$Name) $null -ne (Get-Command $Name -ErrorAction SilentlyContinue) }
function Get-Version {
    param([string]$Name, [string]$Flag = "--version")
    try { & $Name $Flag 2>$null | Select-Object -First 1 } catch { "not_installed" }
}

$langs = @{}
if (Test-Command "node")    { $langs["node"]   = Get-Version "node" }
if (Test-Command "python")  { $langs["python"]  = Get-Version "python" }
if (Test-Command "python3") { $langs["python"] = Get-Version "python3" }
if (Test-Command "go")      { $langs["go"]     = Get-Version "go" }
if (Test-Command "rustc")   { $langs["rust"]   = Get-Version "rustc" }
if (Test-Command "java")    { $langs["java"]   = Get-Version "java" }
if (Test-Command "dotnet")  { $langs["dotnet"] = Get-Version "dotnet" }
if (Test-Command "ruby")    { $langs["ruby"]   = Get-Version "ruby" }
if (Test-Command "php")     { $langs["php"]    = Get-Version "php" }
if (Test-Command "dart")    { $langs["dart"]   = Get-Version "dart" }

$pms = @{}
if (Test-Command "npm")    { $pms["npm"]         = Get-Version "npm" }
if (Test-Command "yarn")   { $pms["yarn"]        = Get-Version "yarn" }
if (Test-Command "pnpm")   { $pms["pnpm"]        = Get-Version "pnpm" }
if (Test-Command "pip")    { $pms["pip"]         = Get-Version "pip" }
if (Test-Command "pip3")   { $pms["pip"]         = Get-Version "pip3" }
if (Test-Command "cargo")  { $pms["cargo"]       = Get-Version "cargo" }
if (Test-Command "choco")  { $pms["chocolatey"]  = Get-Version "choco" }
if (Test-Command "scoop")  { $pms["scoop"]       = "installed" }
if (Test-Command "winget") { $pms["winget"]      = Get-Version "winget" }
if (Test-Command "uv")     { $pms["uv"]          = Get-Version "uv" }
if (Test-Command "poetry") { $pms["poetry"]      = Get-Version "poetry" }
if (Test-Command "deno")   { $pms["deno"]        = Get-Version "deno" }
if (Test-Command "bun")    { $pms["bun"]         = Get-Version "bun" }

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
    $gitConfig["version"] = Get-Version "git"
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