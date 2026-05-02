#!/usr/bin/env bash
# =============================================================================
# detect-mcp-servers.sh - MCP 服务器检测脚本
# 平台: Linux / macOS
# 用途: 检测已配置的 MCP (Model Context Protocol) 服务器
# =============================================================================

set -euo pipefail

detect_mcp_servers() {
    local servers="[]"
    local found=false

    # 检测常见 MCP 配置位置
    local config_paths=(
        "$HOME/.config/mcp"
        "$HOME/.mcp"
        "$HOME/.claude/mcp.json"
        "$HOME/.claude/settings.json"
        "$HOME/.cursor/mcp.json"
        "$HOME/.continue/mcp.json"
        "$HOME/.opencode/mcp.json"
        "/etc/mcp.json"
    )

    for config_path in "${config_paths[@]}"; do
        config_path="${config_path/#\~/$HOME}"
        config_path=$(eval echo "$config_path" 2>/dev/null || echo "$config_path")

        if [[ -f "$config_path" ]]; then
            if command -v jq &>/dev/null; then
                local server_count
                server_count=$(jq '.mcpServers | length // 0' "$config_path" 2>/dev/null || echo "0")
                if [[ "$server_count" -gt 0 ]] 2>/dev/null; then
                    found=true
                    local server_names
                    server_names=$(jq -r '.mcpServers | keys[]' "$config_path" 2>/dev/null || echo "")
                    
                    for server_name in $server_names; do
                        local server_cmd server_args
                        server_cmd=$(jq -r ".mcpServers[\"$server_name\"].command // \"unknown\"" "$config_path" 2>/dev/null || echo "unknown")
                        server_args=$(jq -r ".mcpServers[\"$server_name\"].args // [] | join(\" \")" "$config_path" 2>/dev/null || echo "")
                        
                        local cmd_status="unknown"
                        if command -v "$server_cmd" &>/dev/null; then
                            cmd_status="available"
                        elif [[ "$server_cmd" == "npx"* ]] || [[ "$server_cmd" == "npm"* ]] || [[ "$server_cmd" == "yarn"* ]]; then
                            cmd_status="npx/npm_available"
                        else
                            cmd_status="not_found"
                        fi

                        servers=$(echo "$servers" | jq --arg name "$server_name" --arg cmd "$server_cmd" --arg args "$server_args" --arg status "$cmd_status" \
                            '. + [{"name": $name, "command": $cmd, "args": $args, "status": $status}]')
                    done
                fi
            fi
        fi
    done

    # 检测 MCP CLI 工具
    local mcp_cli_status="not_installed"
    if command -v mcp &>/dev/null; then
        mcp_cli_status="installed"
    fi

    echo "{\"servers\": $servers, \"cli_status\": \"$mcp_cli_status\", \"found_config\": $found}"
}

detect_mcp_protocol() {
    local sdk_versions="[]"
    
    if command -v npx &>/dev/null; then
        local global_pkgs
        global_pkgs=$(npm list -g --depth=0 2>/dev/null || echo "")
        if echo "$global_pkgs" | grep -q "modelcontextprotocol"; then
            sdk_versions=$(echo "$global_pkgs" | grep "modelcontextprotocol" | awk '{print $NF}' | jq -R . | jq -s .)
        fi
    fi
    
    echo "{\"sdk_versions\": $sdk_versions}"
}

main() {
    echo "{"
    echo "  \"mcp_servers\": $(detect_mcp_servers),"
    echo "  \"protocol\": $(detect_mcp_protocol)"
    echo "}"
}

main "$@"
