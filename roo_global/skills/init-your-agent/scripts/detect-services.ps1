# detect-services.ps1 - Runtime services detection (Windows) - Pure JSON output only
[CmdletBinding()]
param()
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Test-Command { param([string]$Name) $null -ne (Get-Command $Name -ErrorAction SilentlyContinue) }
function Get-Version {
    param([string]$Name, [string]$Flag = "--version")
    try {
        $raw = & $Name $Flag 2>$null | Select-Object -First 1
        if (-not $raw) { return "unavailable" }
        if ($raw -match '(\d+\.\d+(\.\d+)*)') { return $Matches[1] }
        return ($raw -split '\s+')[-1]
    } catch { return "unavailable" }
}

# Docker
$dockerStatus = "not_installed"; $dockerVersion = "unavailable"; $dockerCompose = "not_installed"; $containers = 0; $images = 0
if (Test-Command "docker") {
    $dockerVersion = Get-Version "docker"
    if (Test-Command "docker-compose") { $dockerCompose = Get-Version "docker-compose" }
    elseif (& docker compose version 2>$null) { $dockerCompose = (& docker compose version 2>$null | Select-Object -First 1) -replace '^.*version\s*', '' }
    try { docker info 2>$null | Out-Null; $dockerStatus = "running"; $containers = (docker ps -q 2>$null | Measure-Object).Count; $images = (docker images -q 2>$null | Measure-Object).Count } catch { $dockerStatus = "stopped" }
}

# Kubernetes
$k8sVersion = "not_installed"; $clusterStatus = "disconnected"; $helm = "not_installed"
if (Test-Command "kubectl") {
    $k8sVersion = Get-Version "kubectl"
    try { $null = & kubectl cluster-info 2>$null; $clusterStatus = "connected" } catch {}
    if (Test-Command "helm") { $helm = "installed" }
}

# Databases
$databases = @{
    redis = if (Test-Command "redis-cli") { "installed" } else { "not_installed" }
    postgresql = if (Test-Command "psql") { "installed" } else { "not_installed" }
    mysql = if (Test-Command "mysql") { "installed" } else { "not_installed" }
    mongodb = if (Test-Command "mongosh" -or Test-Command "mongo") { "installed" } else { "not_installed" }
    sqlite = if (Test-Command "sqlite3") { "installed" } else { "not_installed" }
}

# Web servers
$webServers = @{
    nginx = if (Test-Command "nginx") { "installed" } else { "not_installed" }
    apache = if (Test-Command "apache2" -or Test-Command "httpd") { "installed" } else { "not_installed" }
    caddy = if (Test-Command "caddy") { "installed" } else { "not_installed" }
}

# Ports
$ports = @{}
try {
    $listeningPorts = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Select-Object -ExpandProperty LocalPort -Unique
    $portMap = @{ 6379="redis"; 5432="postgres"; 3306="mysql"; 27017="mongodb"; 80="http"; 443="https"; 3000="node_dev"; 8000="python_dev"; 8080="go_dev" }
    foreach ($p in $portMap.Keys) {
        if ($listeningPorts -contains $p) { $ports[$p.ToString()] = $portMap[$p] }
    }
} catch {}

@{
    docker = @{ status = $dockerStatus; version = $dockerVersion; compose_version = $dockerCompose; running_containers = $containers; total_images = $images }
    kubernetes = @{ kubectl_version = $k8sVersion; cluster_status = $clusterStatus; helm = $helm }
    databases = $databases
    web_servers = $webServers
    ports_in_use = $ports
} | ConvertTo-Json -Depth 10