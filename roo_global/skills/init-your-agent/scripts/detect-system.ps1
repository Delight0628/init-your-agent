# detect-system.ps1 - System detection (Windows) - Pure JSON output only
[CmdletBinding()]
param()
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Detect-OS {
    $os = Get-CimInstance Win32_OperatingSystem
    @{ name = $os.Caption; version = $os.Version; kernel = $os.Version; arch = $os.OSArchitecture }
}
function Detect-CPU {
    $cpus = Get-CimInstance Win32_Processor
    @{ model = $cpus[0].Name; cores = ($cpus | Measure-Object -Property NumberOfCores -Sum).Sum; threads = ($cpus | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum }
}
function Detect-Memory {
    $os = Get-CimInstance Win32_ComputerSystem
    @{ total_gb = [int][math]::Round($os.TotalPhysicalMemory / 1GB, 0) }
}
function Detect-GPU {
    $gpus = Get-CimInstance Win32_VideoController
    $list = @()
    foreach ($gpu in $gpus) {
        $vram_gb = [math]::Round(($_.AdapterRAM / 1GB), 0)
        $list += @{ model = $gpu.Name; vram_gb = $vram_gb }
    }
    ,@($list)
}
function Detect-Disk {
    $disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
    $list = @()
    foreach ($d in $disks) {
        # DeviceID already includes colon (e.g. "C:"), don't append another
        $list += @{ mount = $d.DeviceID; total_gb = [math]::Round($d.Size / 1GB, 0); free_gb = [math]::Round($d.FreeSpace / 1GB, 0) }
    }
    ,@($list)
}
function Detect-Shell {
    $comspec = $env:COMSPEC -replace ".exe$", ""
    $lastPart = $comspec -split '\\' | Select-Object -Last 1
    @{ primary_shell = $lastPart; wsl_distros = @() }
}
function Detect-Network {
    $proxy = @{}
    if ($env:http_proxy) { $proxy["http_proxy"] = $env:http_proxy }
    if ($env:https_proxy) { $proxy["https_proxy"] = $env:https_proxy }
    if ($env:HTTP_PROXY) { $proxy["HTTP_PROXY"] = $env:HTTP_PROXY }
    if ($env:HTTPS_PROXY) { $proxy["HTTPS_PROXY"] = $env:HTTPS_PROXY }
    $regProxy = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -ErrorAction SilentlyContinue
    if ($regProxy.ProxyEnable -eq 1) { $proxy["system_proxy"] = $regProxy.ProxyServer }
    if ($proxy.Count -eq 0) { @{ proxy = "none" } } else { $proxy }
}

# Build as hashtable to avoid PSCustomObject serialization issues
$output = @{
    os = Detect-OS
    cpu = Detect-CPU
    memory = Detect-Memory
    gpu = (Detect-GPU)
    disk = (Detect-Disk)
    shell = Detect-Shell
    network = Detect-Network
}

$output | ConvertTo-Json -Depth 10