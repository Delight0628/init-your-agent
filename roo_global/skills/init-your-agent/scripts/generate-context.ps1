# =============================================================================
# generate-context.ps1 - 上下文生成主脚本 (Windows)
# 平台: Windows (PowerShell)
# 用途: 整合所有探测模块，生成标准化上下文文件
# =============================================================================

[CmdletBinding()]
param(
    [switch]$Batch,
    [switch]$Interactive,
    [string]$OutputPath
)

$ErrorActionPreference = "SilentlyContinue"

# 脚本目录
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SkillDir = Split-Path -Parent $ScriptDir
$AssetsDir = Join-Path $SkillDir "assets"
$Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"

# 确保输出目录存在
if (-not (Test-Path $AssetsDir)) {
    New-Item -ItemType Directory -Path $AssetsDir -Force | Out-Null
}

# 默认输出路径
if (-not $OutputPath) {
    $OutputPath = Join-Path $AssetsDir "context-output.json"
}

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  DevContext 上下文生成器 v1.0.0 (Windows)" -ForegroundColor Cyan
Write-Host "  模式: $($(if($Interactive){'interactive'}else{'batch'}))" -ForegroundColor Cyan
Write-Host "  时间戳: $Timestamp" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# 辅助函数
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

# 收集系统信息
Write-Host "[STEP] 1/6 收集系统硬件信息..." -ForegroundColor Yellow

$SystemJson = & "$ScriptDir\detect-system.ps1" 2>$null
if (-not $SystemJson) {
    Write-Host "[WARN] 系统探测失败" -ForegroundColor Red
    $SystemJson = '{"error":"detection_failed"}'
}

# 收集开发栈信息
Write-Host "[STEP] 2/6 收集开发栈信息..." -ForegroundColor Yellow

# 在 Windows 上检测开发栈
$Languages = @{}
$PackageManagers = @{}
$Editors = @()
$GitConfig = @{}

# 检测语言
if (Test-Command "node") { $Languages["node"] = Get-CommandVersion "node" }
if (Test-Command "python") { $Languages["python"] = Get-CommandVersion "python" }
if (Test-Command "python3") { $Languages["python"] = Get-CommandVersion "python3" }
if (Test-Command "go") { $Languages["go"] = Get-CommandVersion "go" }
if (Test-Command "rustc") { $Languages["rust"] = Get-CommandVersion "rustc" }
if (Test-Command "java") { $Languages["java"] = Get-CommandVersion "java" }
if (Test-Command "dotnet") { $Languages["dotnet"] = Get-CommandVersion "dotnet" }

# 检测包管理器
if (Test-Command "npm") { $PackageManagers["npm"] = Get-CommandVersion "npm" }
if (Test-Command "yarn") { $PackageManagers["yarn"] = Get-CommandVersion "yarn" }
if (Test-Command "pnpm") { $PackageManagers["pnpm"] = Get-CommandVersion "pnpm" }
if (Test-Command "pip") { $PackageManagers["pip"] = Get-CommandVersion "pip" }
if (Test-Command "pip3") { $PackageManagers["pip"] = Get-CommandVersion "pip3" }
if (Test-Command "cargo") { $PackageManagers["cargo"] = Get-CommandVersion "cargo" }
if (Test-Command "choco") { $PackageManagers["chocolatey"] = Get-CommandVersion "choco" }
if (Test-Command "scoop") { $PackageManagers["scoop"] = "installed" }
if (Test-Command "winget") { $PackageManagers["winget"] = Get-CommandVersion "winget" }

# 检测编辑器
if (Test-Command "code") { $Editors += "VS Code" }
if (Test-Command "notepad++") { $Editors += "Notepad++" }
if (Test-Command "pwsh") { $Editors += "PowerShell ISE" }

# 检测 Git
if (Test-Command "git") {
    $GitConfig["version"] = Get-CommandVersion "git"
    $GitConfig["user"] = git config --global user.name 2>$null
    $GitConfig["email"] = git config --global user.email 2>$null
    $remote = git remote -v 2>$null | Select-String "origin" | Select-Object -First 1
    if ($remote) {
        $GitConfig["remote"] = ($remote.Line -split '\s+')[1]
    }
}

$DevstackJson = @{
    languages       = $Languages
    package_managers = $PackageManagers
    editors         = $Editors
    git             = $GitConfig
} | ConvertTo-Json -Depth 5

# 收集 AI 代理信息
Write-Host "[STEP] 3/6 收集 AI 编程代理信息..." -ForegroundColor Yellow

$AiAgentsJson = & "$ScriptDir\detect-ai-agents.ps1" 2>$null
if (-not $AiAgentsJson) {
    Write-Host "[WARN] AI 代理探测失败" -ForegroundColor Red
    $AiAgentsJson = '{"error":"detection_failed"}'
}

# 收集 MCP 服务器信息
Write-Host "[STEP] 4/6 收集 MCP 服务器信息..." -ForegroundColor Yellow

$McpJson = & "$ScriptDir\detect-mcp-servers.ps1" 2>$null
if (-not $McpJson) {
    Write-Host "[WARN] MCP 探测失败" -ForegroundColor Red
    $McpJson = '{"error":"detection_failed"}'
}

# 收集服务信息
Write-Host "[STEP] 5/6 收集运行时服务信息..." -ForegroundColor Yellow

# Docker 检测
$DockerStatus = "not_installed"
$DockerVersion = "unavailable"
$DockerCompose = "not_installed"
$RunningContainers = 0

if (Test-Command "docker") {
    $DockerVersion = Get-CommandVersion "docker"
    try {
        docker info >$null 2>&1
        $DockerStatus = "running"
        $RunningContainers = (docker ps -q).Count
    } catch {
        $DockerStatus = "stopped"
    }
    
    if (Test-Command "docker-compose") {
        $DockerCompose = Get-CommandVersion "docker-compose"
    } elseif (docker compose version >$null 2>&1) {
        $DockerCompose = (docker compose version 2>$null | Select-Object -First 1).Split(' ')[-1]
    }
}

# 数据库检测
$Databases = @{
    redis      = "not_installed"
    postgresql = "not_installed"
    mysql      = "not_installed"
    mongodb    = "not_installed"
    wsl        = "not_installed"
}

if (Test-Command "wsl") {
    $Databases["wsl"] = "installed"
    $distros = wsl -l -q 2>$null | Where-Object { $_ -and $_.Trim() }
    if ($distros) {
        $Databases["wsl_distros"] = $distros
    }
}

# Nginx/Apache 检测 (WSL 或原生)
$WebServers = @{
    nginx  = "not_installed"
    apache = "not_installed"
}

if (Test-Command "nginx") {
    $WebServers["nginx"] = "installed"
}

$ServicesJson = @{
    docker      = @{
        status         = $DockerStatus
        version        = $DockerVersion
        compose_version = $DockerCompose
        running_containers = $RunningContainers
    }
    databases   = $Databases
    web_servers = $WebServers
} | ConvertTo-Json -Depth 5

# 收集用户信息
Write-Host "[STEP] 6/6 收集用户偏好信息..." -ForegroundColor Yellow

$GithubUser = ""
$GitEmail = ""
$UserWebsite = ""
$CodeStyle = "auto_detect"
$CommitTemplate = "auto_detect"
$Frameworks = @()

if ($Interactive) {
    Write-Host ""
    Write-Host "  请回答以下问题（直接回车使用默认值）：" -ForegroundColor Green
    Write-Host ""
    
    $githubInput = Read-Host "  GitHub 用户名"
    if ($githubInput) { $GithubUser = $githubInput }
    
    $emailInput = Read-Host "  Commit 邮箱"
    if ($emailInput) { $GitEmail = $emailInput }
    
    $websiteInput = Read-Host "  个人网站"
    if ($websiteInput) { $UserWebsite = $websiteInput }
    
    $styleInput = Read-Host "  代码风格 [prettier/eslint/none] [prettier]"
    $CodeStyle = if ($styleInput) { $styleInput } else { "prettier" }
    
    $templateInput = Read-Host "  Commit 模板 [conventional/none] [conventional]"
    $CommitTemplate = if ($templateInput) { $templateInput } else { "conventional" }
    
    $fwInput = Read-Host "  框架偏好 (逗号分隔) [React,Node.js]"
    if ($fwInput) { $Frameworks = $fwInput -split ',' | ForEach-Object { $_.Trim() } }
} else {
    # 批量模式：从 git 配置读取
    if (Test-Command "git") {
        $GithubUser = git config --global user.name 2>$null
        $GitEmail = git config --global user.email 2>$null
    }
}

$UserJson = @{
    github = @{
        username = $GithubUser
        email    = $GitEmail
    }
    website       = $UserWebsite
    preferences   = @{
        code_style      = $CodeStyle
        commit_template = $CommitTemplate
        frameworks      = $Frameworks
    }
} | ConvertTo-Json -Depth 5

# 合并所有信息
Write-Host "合并上下文数据..." -ForegroundColor Yellow

$Output = @{
    meta     = @{
        timestamp = $Timestamp
        version   = "2.0.0"
        generator = "devcontext-init"
        mode      = $(if($Interactive){'interactive'}else{'batch'})
    }
    system   = $SystemJson | ConvertFrom-Json
    devstack = $DevstackJson | ConvertFrom-Json
    ai_agents = $AiAgentsJson | ConvertFrom-Json
    mcp      = $McpJson | ConvertFrom-Json
    services = $ServicesJson | ConvertFrom-Json
    user     = $UserJson | ConvertFrom-Json
}

# 输出 JSON
$Output | ConvertTo-Json -Depth 5 | Out-File -FilePath $OutputPath -Encoding utf8

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  上下文生成完成!" -ForegroundColor Green
Write-Host "  输出文件: $OutputPath" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan

# 显示摘要
if (Test-Command "systeminfo") {
    Write-Host ""
    Write-Host "  关键信息摘要:" -ForegroundColor Yellow
    
    $os = Get-CimInstance Win32_OperatingSystem
    Write-Host "  OS: $($os.Caption) $($os.Version)" -ForegroundColor White
    
    $memGB = [math]::Round($os.TotalPhysicalMemory / 1GB, 0)
    Write-Host "  内存: ${memGB} GB" -ForegroundColor White
    
    if ($Languages.ContainsKey("node")) {
        Write-Host "  Node: $($Languages['node'])" -ForegroundColor White
    }
    if ($Languages.ContainsKey("python")) {
        Write-Host "  Python: $($Languages['python'])" -ForegroundColor White
    }
    
    Write-Host "  Docker: $DockerStatus" -ForegroundColor White
    
    # AI 代理统计
    try {
        $aiData = $AiAgentsJson | ConvertFrom-Json
        $aiCount = $aiData.ai_agents.Count
        if ($aiCount -gt 0) {
            Write-Host "  AI 代理: $aiCount 个已安装" -ForegroundColor Cyan
        }
    } catch {}
    
    # MCP 服务器统计
    try {
        $mcpData = $McpJson | ConvertFrom-Json
        $mcpCount = $mcpData.mcp_servers.servers.Count
        if ($mcpCount -gt 0) {
            Write-Host "  MCP 服务器: $mcpCount 个已配置" -ForegroundColor Cyan
        }
    } catch {}
}

Write-Host ""
Write-Host "上下文文件已就绪，可供 AI Agent 使用。" -ForegroundColor Green
