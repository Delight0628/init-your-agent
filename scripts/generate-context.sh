#!/usr/bin/env bash
# =============================================================================
# generate-context.sh - 上下文生成主脚本
# 平台: Linux / macOS
# 用途: 整合所有探测模块，生成标准化上下文文件
# =============================================================================

set -euo pipefail

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
ASSETS_DIR="$SKILL_DIR/assets"
OUTPUT_FILE="$ASSETS_DIR/context-output.json"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1" >&2; }
log_step()  { echo -e "${BLUE}[STEP]${NC} $1"; }

# 确保输出目录存在
mkdir -p "$ASSETS_DIR"

# 模式解析
MODE="batch"
if [[ "${1:-}" == "--interactive" ]] || [[ "${1:-}" == "-i" ]]; then
    MODE="interactive"
fi

log_info "============================================"
log_info "  DevContext 上下文生成器 v1.0.0"
log_info "  模式: $MODE"
log_info "  时间戳: $TIMESTAMP"
log_info "============================================"

# 初始化上下文结构
context="{}"

# 收集系统信息
log_step "1/6 收集系统硬件信息..."
if [[ -f "$SCRIPT_DIR/detect-system.sh" ]]; then
    system_json=$(bash "$SCRIPT_DIR/detect-system.sh" 2>/dev/null || echo '{"error":"detection_failed"}')
else
    log_warn "detect-system.sh 不存在，跳过系统探测"
    system_json='{"error":"script_missing"}'
fi

# 收集开发栈信息
log_step "2/6 收集开发栈信息..."
if [[ -f "$SCRIPT_DIR/detect-devstack.sh" ]]; then
    devstack_json=$(bash "$SCRIPT_DIR/detect-devstack.sh" 2>/dev/null || echo '{"error":"detection_failed"}')
else
    log_warn "detect-devstack.sh 不存在，跳过开发栈探测"
    devstack_json='{"error":"script_missing"}'
fi

# 收集 AI 代理信息
log_step "3/6 收集 AI 编程代理信息..."
if [[ -f "$SCRIPT_DIR/detect-ai-agents.sh" ]]; then
    ai_agents_json=$(bash "$SCRIPT_DIR/detect-ai-agents.sh" 2>/dev/null || echo '{"error":"detection_failed"}')
else
    log_warn "detect-ai-agents.sh 不存在，跳过 AI 代理探测"
    ai_agents_json='{"error":"script_missing"}'
fi

# 收集 MCP 服务器信息
log_step "4/6 收集 MCP 服务器信息..."
if [[ -f "$SCRIPT_DIR/detect-mcp-servers.sh" ]]; then
    mcp_json=$(bash "$SCRIPT_DIR/detect-mcp-servers.sh" 2>/dev/null || echo '{"error":"detection_failed"}')
else
    log_warn "detect-mcp-servers.sh 不存在，跳过 MCP 探测"
    mcp_json='{"error":"script_missing"}'
fi

# 收集服务信息
log_step "5/6 收集运行时服务信息..."
if [[ -f "$SCRIPT_DIR/detect-services.sh" ]]; then
    services_json=$(bash "$SCRIPT_DIR/detect-services.sh" 2>/dev/null || echo '{"error":"detection_failed"}')
else
    log_warn "detect-services.sh 不存在，跳过服务探测"
    services_json='{"error":"script_missing"}'
fi

# 收集用户信息（交互式）
log_step "6/6 收集用户偏好信息..."
if [[ "$MODE" == "interactive" ]]; then
    log_info "进入交互式配置模式..."
    echo ""
    echo "  请回答以下问题（直接回车使用默认值）："
    echo ""
    
    # GitHub 用户名
    read -r -p "  GitHub 用户名: " github_user 2>/dev/null || github_user=""
    github_user="${github_user:-$(git config --global user.name 2>/dev/null || echo '')}"
    
    # Commit 邮箱
    read -r -p "  Commit 邮箱: " git_email 2>/dev/null || git_email=""
    git_email="${git_email:-$(git config --global user.email 2>/dev/null || echo '')}"
    
    # 个人网站
    read -r -p "  个人网站: " user_website 2>/dev/null || user_website=""
    
    # 代码风格
    read -r -p "  代码风格 [prettier/eslint/none] [prettier]: " code_style 2>/dev/null || code_style=""
    code_style="${code_style:-prettier}"
    
    # Commit 模板
    read -r -p "  Commit 模板 [conventional/none] [conventional]: " commit_template 2>/dev/null || commit_template=""
    commit_template="${commit_template:-conventional}"
    
    # 框架偏好
    read -r -p "  框架偏好 (逗号分隔) [React,Node.js]: " frameworks 2>/dev/null || frameworks=""
    frameworks="${frameworks:-React,Node.js}"
    
    # 转换为 JSON
    user_json=$(cat <<USEREOF
{
  "github": {
    "username": "$github_user",
    "email": "$git_email"
  },
  "website": "$user_website",
  "preferences": {
    "code_style": "$code_style",
    "commit_template": "$commit_template",
    "frameworks": "$(echo "$frameworks" | sed 's/,/","/g')"
  }
}
USEREOF
)
else
    # 批量模式：从 git 配置读取基本信息
    github_user=$(git config --global user.name 2>/dev/null || echo "")
    git_email=$(git config --global user.email 2>/dev/null || echo "")
    
    user_json=$(cat <<USEREOF
{
  "github": {
    "username": "$github_user",
    "email": "$git_email"
  },
  "website": "",
  "preferences": {
    "code_style": "auto_detect",
    "commit_template": "auto_detect",
    "frameworks": []
  }
}
USEREOF
)
fi

# 合并所有信息
log_info "合并上下文数据..."

# 使用 Python 或 jq 合并 JSON（优先使用 jq）
if command -v jq &>/dev/null; then
    cat <<EOF | jq '.' > "$OUTPUT_FILE"
{
  "meta": {
    "timestamp": "$TIMESTAMP",
    "version": "2.0.0",
    "generator": "devcontext-init",
    "mode": "$MODE"
  },
  "system": $system_json,
  "devstack": $devstack_json,
  "ai_agents": $ai_agents_json,
  "mcp": $mcp_json,
  "services": $services_json,
  "user": $user_json
}
EOF
elif command -v python3 &>/dev/null || command -v python &>/dev/null; then
    python3 -c "
import json, sys

system = json.loads('$system_json'.replace(\"'\", '"'))
devstack = json.loads('$devstack_json'.replace(\"'\", '"'))
ai_agents = json.loads('$ai_agents_json'.replace(\"'\", '"'))
mcp = json.loads('$mcp_json'.replace(\"'\", '"'))
services = json.loads('$services_json'.replace(\"'\", '"'))
user = json.loads('$user_json'.replace(\"'\", '"'))

output = {
    'meta': {
        'timestamp': '$TIMESTAMP',
        'version': '2.0.0',
        'generator': 'devcontext-init',
        'mode': '$MODE'
    },
    'system': system,
    'devstack': devstack,
    'ai_agents': ai_agents,
    'mcp': mcp,
    'services': services,
    'user': user
}

with open('$OUTPUT_FILE', 'w') as f:
    json.dump(output, f, indent=2, ensure_ascii=False)
" 2>/dev/null || {
        # Python 失败时直接写入原始数据
        cat <<RAWEOF > "$OUTPUT_FILE"
{
  "meta": {
    "timestamp": "$TIMESTAMP",
    "version": "2.0.0",
    "generator": "devcontext-init",
    "mode": "$MODE"
  },
  "system": $system_json,
  "devstack": $devstack_json,
  "ai_agents": $ai_agents_json,
  "mcp": $mcp_json,
  "services": $services_json,
  "user": $user_json
}
RAWEOF
    }
else
    # 无 JSON 工具时直接写入
    cat <<EOF > "$OUTPUT_FILE"
{
  "meta": {
    "timestamp": "$TIMESTAMP",
    "version": "2.0.0",
    "generator": "devcontext-init",
    "mode": "$MODE"
  },
  "system": $system_json,
  "devstack": $devstack_json,
  "ai_agents": $ai_agents_json,
  "mcp": $mcp_json,
  "services": $services_json,
  "user": $user_json
}
EOF
fi

# 生成 YAML 版本（如果 yq 可用）
if command -v yq &>/dev/null; then
    yq_file="$ASSETS_DIR/context-output.yaml"
    yq '.' "$OUTPUT_FILE" > "$yq_file" 2>/dev/null || true
    log_info "YAML 输出: $yq_file"
fi

# 输出摘要
log_info "============================================"
log_info "  上下文生成完成!"
log_info "  输出文件: $OUTPUT_FILE"
log_info "============================================"

# 显示文件大小
if [[ -f "$OUTPUT_FILE" ]]; then
    local_size=$(wc -c < "$OUTPUT_FILE" | xargs)
    log_info "  文件大小: ${local_size} bytes"
fi

# 显示关键信息摘要
log_info ""
log_info "  关键信息摘要:"
if command -v jq &>/dev/null; then
    os_name=$(jq -r '.system.os.name // "unknown"' "$OUTPUT_FILE" 2>/dev/null || echo "unknown")
    os_arch=$(jq -r '.system.os.arch // "unknown"' "$OUTPUT_FILE" 2>/dev/null || echo "unknown")
    mem_gb=$(jq -r '.system.memory_gb // 0' "$OUTPUT_FILE" 2>/dev/null || echo "0")
    log_info "  OS: $os_name ($os_arch)"
    log_info "  内存: ${mem_gb} GB"
    
    node_ver=$(jq -r '.devstack.languages.node // "N/A"' "$OUTPUT_FILE" 2>/dev/null || echo "N/A")
    python_ver=$(jq -r '.devstack.languages.python // "N/A"' "$OUTPUT_FILE" 2>/dev/null || echo "N/A")
    log_info "  Node: $node_ver | Python: $python_ver"
    
    docker_status=$(jq -r '.services.docker.status // "N/A"' "$OUTPUT_FILE" 2>/dev/null || echo "N/A")
    log_info "  Docker: $docker_status"
    
    # AI 代理统计
    ai_count=$(jq '.ai_agents.ai_agents | length' "$OUTPUT_FILE" 2>/dev/null || echo "0")
    if [[ "$ai_count" -gt 0 ]] 2>/dev/null; then
        log_info "  AI 代理: $ai_count 个已安装"
    fi
    
    # MCP 服务器统计
    mcp_count=$(jq '.mcp.mcp_servers.servers | length' "$OUTPUT_FILE" 2>/dev/null || echo "0")
    if [[ "$mcp_count" -gt 0 ]] 2>/dev/null; then
        log_info "  MCP 服务器: $mcp_count 个已配置"
    fi
fi

log_info ""
log_info "上下文文件已就绪，可供 AI Agent 使用。"
