# =============================================================================
# detect-devstack.ps1 - 开发栈与工具链检测脚本 (Windows)
# 平台: Windows (PowerShell)
# 用途: 采集编程语言、包管理器、编辑器、Git 配置等元数据
# =============================================================================

[CmdletBinding()]
param()

$OutputEncoding = [System.Text.Encoding]::UTF8

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
        return $result
    } catch {
        return "not_installed"
    }
}

# 探测编程语言
function Detect-Languages {
    Write-Host "[INFO] 探测编程语言..." -ForegroundColor Green

    $langs = @{}

    # Node.js
    if (Test-Command "node") { $langs["node"] = Get-CommandVersion "node" }
    # Python
    if (Test-Command "python") { $langs["python"] = Get-CommandVersion "python" }
    if (Test-Command "python3") { $langs["python"] = Get-CommandVersion "python3" }
    # Go
    if (Test-Command "go") { $langs["go"] = Get-CommandVersion "go" }
    # Rust
    if (Test-Command "rustc") { $langs["rust"] = Get-CommandVersion "rustc" }
    # Java
    if (Test-Command "java") { $langs["java"] = Get-CommandVersion "java" }
    # .NET
    if (Test-Command "dotnet") { $langs["dotnet"] = Get-CommandVersion "dotnet" }
    # Ruby
    if (Test-Command "ruby") { $langs["ruby"] = Get-CommandVersion "ruby" }
    # PHP
    if (Test-Command "php") { $langs["php"] = Get-CommandVersion "php" }
    # Dart
    if (Test-Command "dart") { $langs["dart"] = Get-CommandVersion "dart" }

    return $langs
}

# 探测包管理器
function Detect-PackageManagers {
    Write-Host "[INFO] 探测包管理器..." -ForegroundColor Green

    $pms = @{}

    if (Test-Command "npm") { $pms["npm"] = Get-CommandVersion "npm" }
    if (Test-Command "yarn") { $pms["yarn"] = Get-CommandVersion "yarn" }
    if (Test-Command "pnpm") { $pms["pnpm"] = Get-CommandVersion "pnpm" }
    if (Test-Command "pip") { $pms["pip"] = Get-CommandVersion "pip" }
    if (Test-Command "pip3") { $pms["pip"] = Get-CommandVersion "pip3" }
    if (Test-Command "cargo") { $pms["cargo"] = Get-CommandVersion "cargo" }
    if (Test-Command "choco") { $pms["chocolatey"] = Get-CommandVersion "choco" }
    if (Test-Command "scoop") { $pms["scoop"] = "installed" }
    if (Test-Command "winget") { $pms["winget"] = Get-CommandVersion "winget" }
    if (Test-Command "uv") { $pms["uv"] = Get-CommandVersion "uv" }
    if (Test-Command "poetry") { $pms["poetry"] = Get-CommandVersion "poetry" }
    if (Test-Command "deno") { $pms["deno"] = Get-CommandVersion "deno" }
    if (Test-Command "bun") { $pms["bun"] = Get-CommandVersion "bun" }

    return $pms
}

# 探测代码编辑器
function Detect-Editors {
    Write-Host "[INFO] 探测代码编辑器..." -ForegroundColor Green

    $editors = @()

    if (Test-Command "code") { $editors += "VS Code" }
    if (Test-Command "notepad++") { $editors += "Notepad++" }
    if (Test-Command "pwsh") { $editors += "PowerShell ISE" }
    if (Test-Command "cursor") { $editors += "Cursor" }
    if (Test-Command "windsurf") { $editors += "Windsurf" }

    return $editors
}

# 探测 Linter 和 Formatter
function Detect-Tools {
    Write-Host "[INFO] 探测 Linter/Formatter..." -ForegroundColor Green

    $tools = @{}

    if (Test-Command "eslint") { $tools["eslint"] = "installed" }
    if (Test-Command "prettier") { $tools["prettier"] = "installed" }
    if (Test-Command "black") { $tools["black"] = "installed" }
    if (Test-Command "ruff") { $tools["ruff"] = "installed" }
    if (Test-Command "isort") { $tools["isort"] = "installed" }
    if (Test-Command "gofmt") { $tools["gofmt"] = "installed" }
    if (Test-Command "rustfmt") { $tools["rustfmt"] = "installed" }
    if (Test-Command "markdownlint") { $tools["markdownlint"] = "installed" }

    return $tools
}

# 探测 Git 配置
function Detect-Git {
    Write-Host "[INFO] 探测 Git 配置..." -ForegroundColor Green

    if (-not (Test-Command "git")) {
        return @{ status = "not_installed" }
    }

    $gitUser = ""
    $gitEmail = ""
    $gitRemote = ""

    try { $gitUser = git config --global user.name 2>$null } catch {}
    try { $gitEmail = git config --global user.email 2>$null } catch {}
    try {
        $remote = git remote -v 2>$null | Select-String "origin" | Select-Object -First 1
        if ($remote) { $gitRemote = ($remote.Line -split '\s+')[1] }
    } catch {}

    $gitVersion = Get-CommandVersion "git"

    # 检测 SSH 密钥
    $sshKeys = @()
    $sshDir = Join-Path $HOME ".ssh"
    if (Test-Path $sshDir) {
        Get-ChildItem -Path $sshDir -Filter "id_*" -File -ErrorAction SilentlyContinue | ForEach-Object {
            $sshKeys += $_.Name -replace "^id_", "" -replace "\.pub$", ""
        }
    }

    # 检测 GitHub CLI
    $ghStatus = "not_installed"
    if (Test-Command "gh") { $ghStatus = "installed" }

    return @{
        version  = $gitVersion
        user     = $gitUser
        email    = $gitEmail
        remote   = $gitRemote
        ssh_keys = $sshKeys
        gh_cli   = $ghStatus
    }
}

# 主探测函数
function Main {
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "  开发栈与工具链检测 (Windows)" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan

    $languages = Detect-Languages
    $packageManagers = Detect-PackageManagers
    $editors = Detect-Editors
    $tools = Detect-Tools
    $gitConfig = Detect-Git

    $output = @{
        languages          = $languages
        package_managers   = $packageManagers
        editors            = $editors
        linters_formatters = $tools
        git                = $gitConfig
    }

    $output | ConvertTo-Json -Depth 5

    Write-Host "开发栈检测完成。" -ForegroundColor Green
}

# 执行主函数
Main
