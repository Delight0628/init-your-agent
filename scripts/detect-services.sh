#!/usr/bin/env bash
# =============================================================================
# detect-services.sh - 运行时依赖与服务扫描脚本
# 平台: Linux / macOS
# 用途: 采集 Docker、数据库、Web 服务器等运行时服务状态
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1" >&2; }

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

# 探测 Docker 环境
detect_docker() {
    log_info "探测 Docker 环境..."
    
    if ! command -v docker &>/dev/null; then
        echo "{\"status\":\"not_installed\",\"version\":\"unavailable\"}"
        return
    fi
    
    local version compose_version
    version=$(detect_version "docker" "docker --version")
    compose_version="not_installed"
    
    if command -v docker-compose &>/dev/null; then
        compose_version=$(detect_version "docker-compose")
    elif docker compose version &>/dev/null; then
        compose_version=$(docker compose version 2>/dev/null | awk '{print $NF}')
    fi
    
    # 检测 Docker 运行状态
    local status="stopped"
    if docker info &>/dev/null; then
        status="running"
    fi
    
    # 检测容器数量
    local container_count=0
    if [[ "$status" == "running" ]]; then
        container_count=$(docker ps -q 2>/dev/null | wc -l | xargs)
    fi
    
    # 检测镜像数量
    local image_count=0
    if [[ "$status" == "running" ]]; then
        image_count=$(docker images -q 2>/dev/null | wc -l | xargs)
    fi
    
    cat <<EOF
{
  "status": "$status",
  "version": "$version",
  "compose_version": "$compose_version",
  "running_containers": $container_count,
  "total_images": $image_count
}
EOF
}

# 探测 Kubernetes
detect_kubernetes() {
    log_info "探测 Kubernetes..."
    
    if ! command -v kubectl &>/dev/null; then
        echo "{\"status\":\"not_installed\"}"
        return
    fi
    
    local k8s_version cluster_status
    k8s_version=$(detect_version "kubectl")
    
    if kubectl cluster-info &>/dev/null; then
        cluster_status="connected"
    else
        cluster_status="disconnected"
    fi
    
    # 检测 Helm
    local helm_status="not_installed"
    if command -v helm &>/dev/null; then
        helm_status="installed"
    fi
    
    cat <<EOF
{
  "kubectl_version": "$k8s_version",
  "cluster_status": "$cluster_status",
  "helm": "$helm_status"
}
EOF
}

# 检测单个数据库
detect_database() {
    local name="$1"
    local cmd="$2"
    local ping_cmd="${3:-}"
    
    if ! command -v "$cmd" &>/dev/null; then
        echo "not_installed"
        return
    fi
    
    local version
    version=$(detect_version "$cmd")
    
    if [[ -n "$ping_cmd" ]] && command -v "$ping_cmd" &>/dev/null; then
        if eval "$ping_cmd" &>/dev/null; then
            echo "connected:$version"
        else
            echo "disconnected:$version"
        fi
    else
        echo "installed:$version"
    fi
}

# 探测数据库服务
detect_databases() {
    log_info "探测数据库服务..."
    
    local redis_status postgres_status mysql_status mongodb_status
    
    # Redis
    if command -v redis-cli &>/dev/null; then
        if redis-cli ping &>/dev/null; then
            redis_status="connected"
        else
            redis_status="disconnected"
        fi
    elif command -v redis-server &>/dev/null; then
        redis_status="installed_not_running"
    else
        redis_status="not_installed"
    fi
    
    # PostgreSQL
    if command -v psql &>/dev/null; then
        if pg_isready &>/dev/null 2>&1; then
            postgres_status="connected"
        else
            postgres_status="disconnected"
        fi
    elif command -v postgres &>/dev/null; then
        postgres_status="installed_not_running"
    else
        postgres_status="not_installed"
    fi
    
    # MySQL/MariaDB
    if command -v mysql &>/dev/null; then
        if mysqladmin ping &>/dev/null 2>&1; then
            mysql_status="connected"
        else
            mysql_status="disconnected"
        fi
    elif command -v mariadb &>/dev/null; then
        mysql_status="installed_not_running"
    else
        mysql_status="not_installed"
    fi
    
    # MongoDB
    if command -v mongosh &>/dev/null; then
        if mongosh --eval "db.adminCommand('ping')" &>/dev/null 2>&1; then
            mongodb_status="connected"
        else
            mongodb_status="disconnected"
        fi
    elif command -v mongo &>/dev/null; then
        mongodb_status="installed_not_running"
    else
        mongodb_status="not_installed"
    fi
    
    # SQLite
    local sqlite_status="not_installed"
    if command -v sqlite3 &>/dev/null; then
        sqlite_status="installed:$(detect_version sqlite3)"
    fi
    
    cat <<EOF
{
  "redis": "$redis_status",
  "postgresql": "$postgres_status",
  "mysql": "$mysql_status",
  "mongodb": "$mongodb_status",
  "sqlite": "$sqlite_status"
}
EOF
}

# 探测 Web 服务器
detect_web_servers() {
    log_info "探测 Web 服务器..."
    
    local nginx_status apache_status caddy_status
    
    # Nginx
    if command -v nginx &>/dev/null; then
        if nginx -t &>/dev/null; then
            nginx_status="configured:$(detect_version nginx)"
        else
            nginx_status="installed:$(detect_version nginx)"
        fi
    else
        nginx_status="not_installed"
    fi
    
    # Apache
    if command -v apache2 &>/dev/null || command -v httpd &>/dev/null; then
        local apache_cmd="apache2"
        command -v httpd &>/dev/null && apache_cmd="httpd"
        apache_status="installed:$(detect_version "$apache_cmd")"
    else
        apache_status="not_installed"
    fi
    
    # Caddy
    if command -v caddy &>/dev/null; then
        caddy_status="installed:$(detect_version caddy)"
    else
        caddy_status="not_installed"
    fi
    
    cat <<EOF
{
  "nginx": "$nginx_status",
  "apache": "$apache_status",
  "caddy": "$caddy_status"
}
EOF
}

# 探测常用端口占用
detect_ports() {
    log_info "探测常用端口..."
    
    local ports="{"
    local first=true
    
    add_port() {
        local name="$1"
        local port="$2"
        
        if command -v lsof &>/dev/null; then
            local pid
            pid=$(lsof -i :"$port" -sTCP:LISTEN -t 2>/dev/null | head -1)
        elif command -v netstat &>/dev/null; then
            local pid
            pid=$(netstat -tlnp 2>/dev/null | grep ":$port " | awk '{print $NF}' | cut -d/ -f1 | head -1)
        elif command -v ss &>/dev/null; then
            local pid
            pid=$(ss -tlnp 2>/dev/null | grep ":$port " | awk '{print $NF}' | sed 's/.*pid=//' | cut -d, -f1 | head -1)
        else
            local pid=""
        fi
        
        if [[ -n "$pid" ]]; then
            [[ "$first" == "false" ]] && ports+=","
            ports+="\"$port\":\"$pid\""
            first=false
        fi
    }
    
    add_port "redis" 6379
    add_port "postgres" 5432
    add_port "mysql" 3306
    add_port "mongodb" 27017
    add_port "mongodb" 27018
    add_port "mongodb" 27019
    add_port "elasticsearch" 9200
    add_port "kibana" 5601
    add_port "grafana" 3000
    add_port "prometheus" 9090
    add_port "docker_api" 2375
    add_port "docker_tls" 2376
    add_port "http" 80
    add_port "https" 443
    add_port "node_dev" 3000
    add_port "python_dev" 8000
    add_port "go_dev" 8080
    
    ports+="}"
    echo "$ports"
}

# 主探测函数
main() {
    log_info "=========================================="
    log_info "  运行时依赖与服务扫描"
    log_info "=========================================="
    
    local docker k8s databases web_servers ports
    
    docker=$(detect_docker)
    k8s=$(detect_kubernetes)
    databases=$(detect_databases)
    web_servers=$(detect_web_servers)
    ports=$(detect_ports)
    
    cat <<EOF
{
  "docker": $docker,
  "kubernetes": $k8s,
  "databases": $databases,
  "web_servers": $web_servers,
  "ports_in_use": $ports
}
EOF
    
    log_info "服务扫描完成。"
}

main "$@"
