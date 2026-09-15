#!/usr/bin/env bash
# =============================================================================
# detect-system.sh - 系统硬件与基础环境探测脚本
# 平台: Linux / macOS
# 用途: 采集操作系统、CPU、内存、GPU、磁盘、Shell 等元数据
# =============================================================================

set -euo pipefail

# 日志函数 (stderr only)
log_info()  { echo "[INFO] $1" >&2; }
log_warn()  { echo "[WARN] $1" >&2; }
log_error() { echo "[ERROR] $1" >&2; }

# 安全执行命令，失败返回 fallback 值
safe_exec() {
    local cmd="$1"
    local fallback="${2:-unavailable}"
    local result
    if result=$(eval "$cmd" 2>/dev/null); then
        echo "$result"
    else
        echo "$fallback"
    fi
}

# 探测操作系统信息
detect_os() {
    log_info "探测操作系统信息..."
    
    local name version kernel arch
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        name="macOS"
        version=$(safe_exec "sw_vers -productVersion")
        kernel=$(safe_exec "uname -r")
        arch=$(safe_exec "uname -m")
    elif [[ -f /etc/os-release ]]; then
        name=$(. /etc/os-release && echo "${NAME:-unknown}")
        version=$(. /etc/os-release && echo "${VERSION_ID:-unknown}")
        kernel=$(safe_exec "uname -r")
        arch=$(safe_exec "uname -m")
    elif command -v lsb_release &>/dev/null; then
        name=$(safe_exec "lsb_release -s -d" "unknown")
        version="unknown"
        kernel=$(safe_exec "uname -r")
        arch=$(safe_exec "uname -m")
    else
        name="unknown"
        version="unknown"
        kernel=$(safe_exec "uname -r" "unknown")
        arch=$(safe_exec "uname -m" "unknown")
    fi
    
    echo "{\"name\":\"$name\",\"version\":\"$version\",\"kernel\":\"$kernel\",\"arch\":\"$arch\"}"
}

# 探测 CPU 信息
detect_cpu() {
    log_info "探测 CPU 信息..."
    
    local model cores
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        model=$(safe_exec "sysctl -n machdep.cpu.brand_string" "unknown")
        cores=$(safe_exec "sysctl -n hw.physicalcpu" "0")
    elif [[ -f /proc/cpuinfo ]]; then
        model=$(safe_exec "grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs" "unknown")
        cores=$(safe_exec "nproc" "0")
    else
        model="unknown"
        cores=$(safe_exec "getconf _NPROCESSORS_ONLN" "0")
    fi
    
    echo "{\"model\":\"$model\",\"cores\":$cores}"
}

# 探测内存信息
detect_memory() {
    log_info "探测内存信息..."
    
    local total_gb
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        local bytes
        bytes=$(safe_exec "sysctl -n hw.memsize" "0")
        total_gb=$(( bytes / 1024 / 1024 / 1024 ))
    elif [[ -f /proc/meminfo ]]; then
        local kb
        kb=$(safe_exec "grep MemTotal /proc/meminfo | awk '{print $2}'" "0")
        total_gb=$(( kb / 1024 / 1024 ))
    else
        total_gb=0
    fi
    
    echo "{\"total_gb\":$total_gb}"
}

# 探测 GPU 信息
detect_gpu() {
    log_info "探测 GPU 信息..."
    
    local gpu_list="[]"
    
    if command -v nvidia-smi &>/dev/null; then
        gpu_list=$(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>/dev/null | \
            while IFS=',' read -r name vram; do
                name=$(echo "$name" | xargs)
                vram=$(echo "$vram" | xargs)
                vram_gb=$(( vram / 1024 ))
                echo "{\"model\":\"$name\",\"vram_gb\":$vram_gb}"
            done | paste -sd',' | sed 's/^/[/;s/$/]/')
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        local gpu_info
        gpu_info=$(safe_exec "system_profiler SPDisplaysDataType" "")
        if [[ -n "$gpu_info" ]]; then
            local model
            model=$(echo "$gpu_info" | grep "Chipset Model" | head -1 | cut -d: -f2 | xargs)
            gpu_list="[{\"model\":\"$model\",\"vram_gb\":0}]"
        fi
    fi
    
    echo "$gpu_list"
}

# 探测磁盘信息
detect_disk() {
    log_info "探测磁盘信息..."

    local disk_list="["
    local first=true

    if command -v powershell &>/dev/null; then
        # Windows: use PowerShell to get disk info
        while IFS=',' read -r mount total_bytes free_bytes; do
            mount=$(echo "$mount" | xargs)
            total_bytes=$(echo "$total_bytes" | xargs)
            free_bytes=$(echo "$free_bytes" | xargs)
            if [[ -n "$mount" && -n "$total_bytes" && "$total_bytes" =~ ^[0-9]+$ ]]; then
                local total_gb free_gb used_gb
                total_gb=$(( total_bytes / 1073741824 ))
                free_gb=$(( free_bytes / 1073741824 ))
                used_gb=$(( total_gb - free_gb ))
                if [[ "$first" == "true" ]]; then
                    first=false
                else
                    disk_list+=","
                fi
                disk_list+="{\"mount\":\"$mount\",\"total_gb\":$total_gb,\"free_gb\":$free_gb,\"used_gb\":$used_gb}"
            fi
        done < <(powershell -Command "[Console]::OutputEncoding=[System.Text.Encoding]::UTF8; Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' | ForEach-Object { Write-Output ('{0},{1},{2}' -f \$_.DeviceID, \$_.Size, \$_.FreeSpace) }" 2>/dev/null)
    else
        # Linux/macOS: use df
        while IFS= read -r line; do
            local mount total_gb free_gb
            mount=$(echo "$line" | awk '{print $6}')
            total_gb=$(echo "$line" | awk '{print $2}' | tr -d 'G')
            free_gb=$(echo "$line" | awk '{print $4}' | tr -d 'G')

            if [[ "$first" == "true" ]]; then
                first=false
            else
                disk_list+=","
            fi
            disk_list+="{\"mount\":\"$mount\",\"total_gb\":$total_gb,\"free_gb\":$free_gb}"
        done < <(df -BG 2>/dev/null | grep '^/' | head -5)
    fi

    disk_list+="]"
    echo "$disk_list"
}

# 探测 Shell 环境
detect_shell() {
    log_info "探测 Shell 环境..."
    
    local shell_name
    
    if [[ -n "$BASH" ]]; then
        shell_name="bash"
    elif [[ -n "$ZSH_NAME" ]]; then
        shell_name="zsh"
    elif [[ -n "$FISH_VERSION" ]]; then
        shell_name="fish"
    else
        shell_name=$(basename "$SHELL" 2>/dev/null || echo "unknown")
    fi
    
    echo "{\"primary_shell\":\"$shell_name\",\"wsl_distros\":[]}"
}

# 探测网络代理配置
detect_network() {
    log_info "探测网络配置..."
    
    local proxy=""
    
    # HTTP 代理
    if [[ -n "${http_proxy:-}" ]]; then
        proxy="http_proxy=$http_proxy"
    fi
    if [[ -n "${https_proxy:-}" ]]; then
        proxy="$proxy,https_proxy=$https_proxy"
    fi
    if [[ -n "${HTTP_PROXY:-}" ]]; then
        proxy="$proxy,HTTP_PROXY=$HTTP_PROXY"
    fi
    if [[ -n "${HTTPS_PROXY:-}" ]]; then
        proxy="$proxy,HTTPS_PROXY=$HTTPS_PROXY"
    fi
    
    if [[ -z "$proxy" ]]; then
        echo "{\"proxy\":\"none\"}"
    else
        echo "{\"proxy\":\"$proxy\"}"
    fi
}

# 主探测函数
main() {
    log_info "=========================================="
    log_info "  系统硬件与基础环境探测"
    log_info "=========================================="
    
    local os cpu memory gpu disk shell network
    
    os=$(detect_os)
    cpu=$(detect_cpu)
    memory=$(detect_memory)
    gpu=$(detect_gpu)
    disk=$(detect_disk)
    shell=$(detect_shell)
    network=$(detect_network)
    
    # 输出 JSON (Schema 与 Windows 版一致)
    cat <<EOF
{
  "os": $os,
  "cpu": $cpu,
  "memory": $memory,
  "gpu": $gpu,
  "disk": $disk,
  "shell": $shell,
  "network": $network
}
EOF
    
    log_info "系统探测完成。"
}

# 执行主函数
main "$@"
