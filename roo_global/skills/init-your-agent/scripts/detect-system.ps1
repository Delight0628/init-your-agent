# =============================================================================
# detect-system.ps1 - 系统硬件与基础环境探测脚本
# 平台: Windows (PowerShell)
# 用途: 采集操作系统、CPU、内存、GPU、磁盘、Shell 等元数据
# =============================================================================

[CmdletBinding()]
param(
    [switch]$Batch,
    [switch]$Interactive
)

# 编码设置
$OutputEncoding = [System.Text.Encoding]::UTF8

function Write-Info  { Write-Host "[INFO] $args" -ForegroundColor Green }
function Write-Warn  { Write-Host "[WARN] $args" -ForegroundColor Yellow }
function Write-Error { Write-Host "[ERROR] $args" -ForegroundColor Red }

# 安全执行命令
function Safe-Exec {
    param(
        [string]$Command,
        [string]$Fallback = "unavailable"
    )
    try {
        $result = Invoke-Expression $Command 2>$null
        if ($result) { return $result }
    } catch {
        Write-Warn "Command failed: $Command"
    }
    return $Fallback
}

# 探测操作系统信息
function Detect-OS {
    Write-Info "探测操作系统信息..."
    
    $os = Get-CimInstance Win32_OperatingSystem
    $cpu = Get-CimInstance Win32_Processor
    
    $result = [PSCustomObject]@{
        name    = $os.Caption
        version = $os.Version
        kernel  = $os.Version  # Windows 没有 uname 风格的内核版本
        arch    = $os.OSArchitecture
    }
    
    return $result | ConvertTo-Json -Compress
}

# 探测 CPU 信息
function Detect-CPU {
    Write-Info "探测 CPU 信息..."
    
    $cpus = Get-CimInstance Win32_Processor
    $model = $cpus[0].Name
    $cores = ($cpus | Measure-Object -Property NumberOfCores -Sum).Sum
    $threads = ($cpus | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum
    
    $result = [PSCustomObject]@{
        model = $model
        cores = $cores
        threads = $threads
    }
    
    return $result | ConvertTo-Json -Compress
}

# 探测内存信息
function Detect-Memory {
    Write-Info "探测内存信息..."
    
    $os = Get-CimInstance Win32_ComputerSystem
    $total_gb = [math]::Round($os.TotalPhysicalMemory / 1GB, 0)
    
    return @{ total_gb = [int]$total_gb } | ConvertTo-Json -Compress
}

# 探测 GPU 信息
function Detect-GPU {
    Write-Info "探测 GPU 信息..."
    
    $gpus = Get-CimInstance Win32_VideoController
    
    if ($gpus) {
        $gpuList = @()
        foreach ($gpu in $gpus) {
            $vram_mb = if ($gpu.AdapterRAM) { $gpu.AdapterRAM } else { 0 }
            $vram_gb = [math]::Round($vram_mb / 1GB, 0)
            
            $gpuList += [PSCustomObject]@{
                model  = $gpu.Name
                vram_gb = $vram_gb
            }
        }
        return $gpuList | ConvertTo-Json -Compress
    }
    
    return "[]"
}

# 探测磁盘信息
function Detect-Disk {
    Write-Info "探测磁盘信息..."
    
    $disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
    
    $diskList = @()
    foreach ($disk in $disks) {
        $total_gb = [math]::Round($disk.Size / 1GB, 0)
        $free_gb = [math]::Round($disk.FreeSpace / 1GB, 0)
        
        $diskList += [PSCustomObject]@{
            mount   = "$($disk.DeviceID):"
            total_gb = $total_gb
            free_gb = $free_gb
        }
    }
    
    return $diskList | ConvertTo-Json -Compress
}

# 探测 Shell 环境
function Detect-Shell {
    Write-Info "探测 Shell 环境..."
    
    $comspec = $env:COMSPEC -replace ".exe$", ""
    $lastPart = $comspec -split '\\' | Select-Object -Last 1
    
    # 检测 WSL
    $wslDistros = @()
    if (Get-Command wsl 2>$null) {
        $wslDistros = (wsl -l -q 2>$null | Where-Object { $_ -and $_.Trim() })
    }
    
    $result = [PSCustomObject]@{
        primary_shell = $lastPart
        wsl_distros   = $wslDistros
    }
    
    return $result | ConvertTo-Json -Compress
}

# 探测网络代理配置
function Detect-Network {
    Write-Info "探测网络配置..."
    
    $proxy = @{}
    
    if ($env:http_proxy) { $proxy.http_proxy = $env:http_proxy }
    if ($env:https_proxy) { $proxy.https_proxy = $env:https_proxy }
    if ($env:HTTP_PROXY) { $proxy.HTTP_PROXY = $env:HTTP_PROXY }
    if ($env:HTTPS_PROXY) { $proxy.HTTPS_PROXY = $env:HTTPS_PROXY }
    
    # 检测 IE/系统代理设置
    $regProxy = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -ErrorAction SilentlyContinue
    if ($regProxy.ProxyEnable -eq 1) {
        $proxy.system_proxy = $regProxy.ProxyServer
    }
    
    if ($proxy.Count -eq 0) {
        return @{ proxy = "none" } | ConvertTo-Json -Compress
    }
    
    return $proxy | ConvertTo-Json -Compress
}

# 主探测函数
function Main {
    Write-Info "=========================================="
    Write-Info "  系统硬件与基础环境探测 (Windows)"
    Write-Info "=========================================="
    
    $os     = Detect-OS
    $cpu    = Detect-CPU
    $memory = Detect-Memory
    $gpu    = Detect-GPU
    $disk   = Detect-Disk
    $shell  = Detect-Shell
    $network = Detect-Network
    
    # 合并输出
    $output = @{
        os       = $os | ConvertFrom-Json
        cpu      = $cpu | ConvertFrom-Json
        memory   = $memory | ConvertFrom-Json
        gpu      = $gpu | ConvertFrom-Json
        disk     = $disk | ConvertFrom-Json
        shell    = $shell | ConvertFrom-Json
        network  = $network | ConvertFrom-Json
    }
    
    $output | ConvertTo-Json -Depth 5
    
    Write-Info "系统探测完成。"
}

# 执行主函数
Main
