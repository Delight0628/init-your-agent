#!/usr/bin/env bash
# =============================================================================
# detect-ai-agents.sh - AI 编程代理检测脚本
# 平台: Linux / macOS
# 用途: 检测本机已安装的 AI 编程代理及其状态
# =============================================================================

set -euo pipefail

# 检测单个代理并添加到列表
# 参数: $1=name $2=cli $3=config_paths $4=icon
add_agent() {
    local name="$1" cmd="$2" config_paths="${3:-}" icon="${4:-}"
    
    if command -v "$cmd" &>/dev/null; then
        local version
        version=$("$cmd" --version 2>/dev/null | head -1 | sed 's/.*version\s*//i' | awk '{print $1}' | xargs || echo "latest")
        
        local config_status="no_config"
        if [[ -n "$config_paths" ]]; then
            IFS=':' read -ra PATHS <<< "$config_paths"
            for path in "${PATHS[@]}"; do
                path="${path/#\~/$HOME}"
                path=$(eval echo "$path" 2>/dev/null || echo "$path")
                if [[ -d "$path" ]] || [[ -f "$path" ]]; then
                    config_status="configured"
                    break
                fi
            done
        fi
        
        echo "{\"name\":\"$name\",\"cli\":\"$cmd\",\"version\":\"$version\",\"config_status\":\"$config_status\",\"icon\":\"$icon\"}"
        return 0
    fi
    return 1
}

detect_all_agents() {
    local agents="["
    local first=true
    
    # 定义要检测的 AI 代理: name:cli:config_paths:icon
    local agents_list=(
        "Claude Code:claude:~/.claude:~/.claude/settings.json:\U0001F525"
        "Codex CLI:codex:~/.config/codex:~/.codex/config.yaml:\U0001F9EA"
        "GitHub Copilot:gh:~/.config/github-cli:\U0001F43B"
        "Cursor:cursor:~/.cursor:\U0001F5A5"
        "Continue:continue:~/.continue:\U0001F517"
        "Hermes:hermes:~/.hermes:\U0001F985"
        "OpenClaw:openclaw:~/.openclaw:\U0001F431"
        "OpenCode:opencode:~/.opencode:\U0001F4BB"
        "Aider:aider:~/.aider:\U0001F916"
        "Codeium CLI:codeium:~/.codeium:\U0001F48E"
        "Amazon Q:q:~/.q:\U0001F389"
        "Roo Code:roo:~/.roo:\U0001F9E9"
        "Windsurf:windsurf:~/.windsurf:\U0001F3C3"
        "Ollama:ollama:~/.ollama:\U0001F999"
        "LM Studio:lmstudio::\U0001F3CA"
    )
    
    for entry in "${agents_list[@]}"; do
        IFS=':' read -r name cmd config_paths icon <<< "$entry"
        if add_agent "$name" "$cmd" "$config_paths" "$icon" 2>/dev/null; then
            [[ "$first" == "false" ]] && agents+=","
            agents+="$(add_agent "$name" "$cmd" "$config_paths" "$icon")"
            first=false
        fi
    done
    
    agents+="]"
    echo "$agents"
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
