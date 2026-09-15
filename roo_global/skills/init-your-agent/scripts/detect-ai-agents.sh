#!/usr/bin/env bash
# =============================================================================
# detect-ai-agents.sh - AI 编程代理检测脚本
# 平台: Linux / macOS
# 用途: 检测本机已安装的 AI 编程代理及其状态
# =============================================================================

set -euo pipefail

# 检测单个代理，成功输出 JSON 并返回 0，失败返回 1
# 参数: $1=name $2=cli $3=config_path $4=icon
add_agent() {
    local name="$1" cmd="$2" config_path="${3:-}" icon="${4:-}"
    
    if ! command -v "$cmd" &>/dev/null; then
        return 1
    fi
    
    local version
    version=$("$cmd" --version 2>/dev/null | head -1 | sed 's/.*version\s*//i' | awk '{print $1}' | xargs || echo "unknown")
    
    local config_status="no_config"
    if [[ -n "$config_path" && -e "$config_path" ]]; then
        config_status="configured"
    fi
    
    printf '{"name":"%s","cli":"%s","version":"%s","config_status":"%s","icon":"%s"}' \
        "$name" "$cmd" "$version" "$config_status" "$icon"
    return 0
}

detect_all_agents() {
    local agents=()
    
    # name|cli|config_path|icon — 用 | 分隔避免路径中的冒号冲突
    local agents_list=(
        "Claude Code|claude|$HOME/.claude|claude"
        "Codex CLI|codex|$HOME/.config/codex|codex"
        "GitHub Copilot|gh|$HOME/.config/github-cli|gh"
        "Cursor|cursor|$HOME/.cursor|cursor"
        "Continue|continue|$HOME/.continue|continue"
        "Hermes|hermes|$HOME/.hermes|hermes"
        "OpenCode|opencode|$HOME/.opencode|opencode"
        "Aider|aider|$HOME/.aider|aider"
        "Amazon Q|q|$HOME/.q|q"
        "Roo Code|roo|$HOME/.roo|roo"
        "Windsurf|windsurf|$HOME/.windsurf|windsurf"
        "Ollama|ollama|$HOME/.ollama|ollama"
        "MiMo|mimo|$HOME/.mimo|mimo"
    )
    
    for entry in "${agents_list[@]}"; do
        local name cmd config_path icon
        IFS='|' read -r name cmd config_path icon <<< "$entry"
        local result
        if result=$(add_agent "$name" "$cmd" "$config_path" "$icon"); then
            agents+=("$result")
        fi
    done
    
    # 组装 JSON 数组
    local json="["
    local first=true
    for a in "${agents[@]}"; do
        if [[ "$first" == "false" ]]; then json+=","; fi
        json+="$a"
        first=false
    done
    json+="]"
    echo "$json"
}

# 检测 AI 代理的活跃会话
detect_active_sessions() {
    local sessions="["
    local first=true
    
    # 检查常见代理端口
    local agent_ports=(3000 3001 4000 4001 5000 5001 6000 6001 8080 8081 1234)
    for port in "${agent_ports[@]}"; do
        if command -v lsof &>/dev/null; then
            if lsof -i :"$port" -sTCP:LISTEN -t &>/dev/null; then
                [[ "$first" == "false" ]] && sessions+=","
                sessions+="{\"port\":$port,\"active\":true}"
                first=false
            fi
        elif command -v ss &>/dev/null; then
            if ss -tlnp 2>/dev/null | grep -q ":$port "; then
                [[ "$first" == "false" ]] && sessions+=","
                sessions+="{\"port\":$port,\"active\":true}"
                first=false
            fi
        fi
    done
    
    sessions+="]"
    echo "$sessions"
}

# 检测 AI 代理的模型配置
detect_model_configs() {
    local models="["
    local first=true
    
    # 检查 API 密钥
    if [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then
        [[ "$first" == "false" ]] && models+=","
        models+="{\"provider\":\"anthropic\",\"configured\":true}"
        first=false
    fi
    
    if [[ -n "${OPENAI_API_KEY:-}" ]]; then
        [[ "$first" == "false" ]] && models+=","
        models+="{\"provider\":\"openai\",\"configured\":true}"
        first=false
    fi
    
    if [[ -n "${GOOGLE_API_KEY:-}" ]]; then
        [[ "$first" == "false" ]] && models+=","
        models+="{\"provider\":\"google\",\"configured\":true}"
        first=false
    fi
    
    if [[ -n "${MISTRAL_API_KEY:-}" ]]; then
        [[ "$first" == "false" ]] && models+=","
        models+="{\"provider\":\"mistral\",\"configured\":true}"
        first=false
    fi
    
    if [[ -n "${COHERE_API_KEY:-}" ]]; then
        [[ "$first" == "false" ]] && models+=","
        models+="{\"provider\":\"cohere\",\"configured\":true}"
        first=false
    fi
    
    # 检查 Ollama
    if command -v ollama &>/dev/null; then
        if ollama list &>/dev/null; then
            local model_count
            model_count=$(ollama list 2>/dev/null | wc -l | xargs)
            [[ "$first" == "false" ]] && models+=","
            models+="{\"provider\":\"ollama\",\"model_count\":$model_count}"
            first=false
        fi
    fi
    
    # 检查 LM Studio (本地服务器)
    if command -v curl &>/dev/null; then
        if curl -s --connect-timeout 2 "http://localhost:1234/v1/models" &>/dev/null; then
            [[ "$first" == "false" ]] && models+=","
            models+="{\"provider\":\"lm_studio\",\"configured\":true}"
            first=false
        fi
    fi
    
    models+="]"
    echo "$models"
}

# 主函数
main() {
    echo "{"
    echo "  \"ai_agents\": $(detect_all_agents),"
    echo "  \"active_sessions\": $(detect_active_sessions),"
    echo "  \"model_configs\": $(detect_model_configs)"
    echo "}"
}

main "$@"
