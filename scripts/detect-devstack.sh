#!/usr/bin/env bash
# =============================================================================
# detect-devstack.sh - 开发栈与工具链检测脚本
# 平台: Linux / macOS
# 用途: 采集编程语言、包管理器、编辑器、Git 配置等元数据
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

# 检测单个命令版本
detect_version() {
    local cmd="$1"
    local version_flag="${2:---version}"
    
    if command -v "$cmd" &>/dev/null; then
        local version
        version=$("$cmd" $version_flag 2>/dev/null | head -1 | awk '{print $NF}')
        echo "$version"
    else
        echo "not_installed"
    fi
}

# 探测编程语言
detect_languages() {
    log_info "探测编程语言..."
    
    local langs="{"
    local first=true
    
    # Node.js
    local node_ver
    node_ver=$(detect_version "node")
    if [[ "$node_ver" != "not_installed" ]]; then
        langs+="\"node\":\"$node_ver\""
        first=false
    fi
    
    # Python
    local python_ver
    python_ver=$(detect_version "python3" || detect_version "python")
    if [[ "$python_ver" != "not_installed" ]]; then
        [[ "$first" == "false" ]] && langs+=","
        langs+="\"python\":\"$python_ver\""
        first=false
    fi
    
    # Go
    local go_ver
    go_ver=$(detect_version "go")
    if [[ "$go_ver" != "not_installed" ]]; then
        [[ "$first" == "false" ]] && langs+=","
        langs+="\"go\":\"$go_ver\""
        first=false
    fi
    
    # Rust
    local rust_ver
    rust_ver=$(detect_version "rustc")
    if [[ "$rust_ver" != "not_installed" ]]; then
        [[ "$first" == "false" ]] && langs+=","
        langs+="\"rust\":\"$rust_ver\""
        first=false
    fi
    
    # Java
    local java_ver
    java_ver=$(detect_version "java" 2>&1 | grep -oP 'version "\K[^"]+' || echo "not_installed")
    if [[ "$java_ver" != "not_installed" ]]; then
        [[ "$first" == "false" ]] && langs+=","
        langs+="\"java\":\"$java_ver\""
        first=false
    fi
    
    # Ruby
    local ruby_ver
    ruby_ver=$(detect_version "ruby")
    if [[ "$ruby_ver" != "not_installed" ]]; then
        [[ "$first" == "false" ]] && langs+=","
        langs+="\"ruby\":\"$ruby_ver\""
        first=false
    fi
    
    # PHP
    local php_ver
    php_ver=$(detect_version "php")
    if [[ "$php_ver" != "not_installed" ]]; then
        [[ "$first" == "false" ]] && langs+=","
        langs+="\"php\":\"$php_ver\""
        first=false
    fi
    
    # Dart
    local dart_ver
    dart_ver=$(detect_version "dart")
    if [[ "$dart_ver" != "not_installed" ]]; then
        [[ "$first" == "false" ]] && langs+=","
        langs+="\"dart\":\"$dart_ver\""
        first=false
    fi
    
    langs+="}"
    echo "$langs"
}

# 探测包管理器
detect_package_managers() {
    log_info "探测包管理器..."
    
    local pms="{"
    local first=true
    
    add_pm() {
        local name="$1"
        local cmd="$2"
        local ver_flag="${3:---version}"
        
        if command -v "$cmd" &>/dev/null; then
            local ver
            ver=$("$cmd" $ver_flag 2>/dev/null | head -1 | awk '{print $NF}')
            [[ "$first" == "false" ]] && pms+=","
            pms+="\"$name\":\"$ver\""
            first=false
        fi
    }
    
    add_pm "npm" "npm"
    add_pm "yarn" "yarn"
    add_pm "pnpm" "pnpm"
    add_pm "pip" "pip3"
    add_pm "pip_legacy" "pip"
    add_pm "cargo" "cargo"
    add_pm "brew" "brew"
    add_pm "apt" "apt"
    add_pm "pipx" "pipx"
    add_pm "uv" "uv"
    add_pm "poetry" "poetry"
    add_pm "deno" "deno"
    add_pm "bun" "bun"
    
    pms+="}"
    echo "$pms"
}

# 探测代码编辑器
detect_editors() {
    log_info "探测代码编辑器..."
    
    local editors="["
    local first=true
    
    add_editor() {
        local name="$1"
        local cmd="$2"
        
        if command -v "$cmd" &>/dev/null; then
            [[ "$first" == "false" ]] && editors+=","
            editors+="\"$name\""
            first=false
        fi
    }
    
    add_editor "VS Code" "code"
    add_editor "Vim" "vim"
    add_editor "Neovim" "nvim"
    add_editor "Emacs" "emacs"
    add_editor "Sublime" "subl"
    add_editor "Atom" "atom"
    add_editor "Zed" "zed"
    
    editors+="]"
    echo "$editors"
}

# 探测 Linter 和 Formatter
detect_tools() {
    log_info "探测 Linter/Formatter..."
    
    local tools="{"
    local first=true
    
    add_tool() {
        local name="$1"
        local cmd="$2"
        
        if command -v "$cmd" &>/dev/null; then
            [[ "$first" == "false" ]] && tools+=","
            tools+="\"$name\":\"installed\""
            first=false
        fi
    }
    
    add_tool "eslint" "eslint"
    add_tool "prettier" "prettier"
    add_tool "stylelint" "stylelint"
    add_tool "black" "black"
    add_tool "ruff" "ruff"
    add_tool "isort" "isort"
    add_tool "gofmt" "gofmt"
    add_tool "rustfmt" "rustfmt"
    add_tool "clang-format" "clang-format"
    add_tool "markdownlint" "markdownlint"
    
    tools+="}"
    echo "$tools"
}

# 探测 Git 配置
detect_git() {
    log_info "探测 Git 配置..."
    
    if ! command -v git &>/dev/null; then
        echo "{\"status\":\"not_installed\"}"
        return
    fi
    
    local git_user git_email git_remote
    
    git_user=$(safe_exec "git config --global user.name" "not_configured")
    git_email=$(safe_exec "git config --global user.email" "not_configured")
    git_remote=$(safe_exec "git remote -v 2>/dev/null | grep -m1 origin | awk '{print $2}'" "none")
    
    local git_version
    git_version=$(detect_version "git")
    
    # 检测 SSH 密钥
    local ssh_keys="[]"
    if [[ -d "$HOME/.ssh" ]]; then
        local key_list="["
        local key_first=true
        for key in "$HOME/.ssh/"id_*; do
            if [[ -f "$key" ]]; then
                local key_name
                key_name=$(basename "$key" | sed 's/id_-//;s/\.ssh//')
                [[ "$key_first" == "false" ]] && key_list+=","
                key_list+="\"$key_name\""
                key_first=false
            fi
        done
        key_list+="]"
        ssh_keys="$key_list"
    fi
    
    # 检测 GitHub CLI
    local gh_status="not_installed"
    if command -v gh &>/dev/null; then
        gh_status="installed"
    fi
    
    cat <<EOF
{
  "version": "$git_version",
  "user": "$git_user",
  "email": "$git_email",
  "remote": "$git_remote",
  "ssh_keys": $ssh_keys,
  "gh_cli": "$gh_status"
}
EOF
}

# 主探测函数
main() {
    log_info "=========================================="
    log_info "  开发栈与工具链检测"
    log_info "=========================================="
    
    local languages package_managers editors tools git_config
    
    languages=$(detect_languages)
    package_managers=$(detect_package_managers)
    editors=$(detect_editors)
    tools=$(detect_tools)
    git_config=$(detect_git)
    
    cat <<EOF
{
  "languages": $languages,
  "package_managers": $package_managers,
  "editors": $editors,
  "linters_formatters": $tools,
  "git": $git_config
}
EOF
    
    log_info "开发栈检测完成。"
}

main "$@"
