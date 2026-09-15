# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.2.0] - 2026-08-11

### Fixed

- **detect-services.sh 崩溃修复**: 补充缺失的 `detect_version()` 函数，修复 Linux/macOS 上直接崩溃的致命问题
- **detect-services.sh Docker 版本检测**: 修正 `detect_version` 多余参数调用
- **detect-services.sh 冗余重定向**: 移除 `pg_isready &>/dev/null 2>&1` 中的重复重定向
- **detect-services.sh 死代码清理**: 移除从未调用的 `detect_database()` 函数
- **JSON Schema 统一 (跨平台)**: `detect-system.sh` 输出结构对齐 Windows 版 — `memory_gb` 扁平数字改为 `memory.total_gb` 对象，`shell` 字符串改为 `{primary_shell, wsl_distros}` 对象，`network_proxy` 字符串改为 `network` 对象
- **detect-ai-agents.sh 双重调用修复**: `add_agent` 不再被调用两次（测试+输出），消除性能浪费
- **detect-ai-agents.sh 分隔符修复**: 代理列表从冒号分隔改为管道分隔 `|`，解决配置路径中冒号导致的解析错误
- **detect-devstack.sh macOS 兼容**: Java 版本检测从 `grep -oP`（GNU only）改为 `sed`，修复 macOS 上检测失败
- **detect-devstack.sh SSH 密钥解析**: 修正 `sed 's/id_-//;s/\.ssh//'` 为正确的 `sed 's/^id_//;s/\.pub$//'`
- **generate-context.sh 日志清理**: `log_step` 从 stdout 重定向到 stderr，移除 ANSI 颜色码
- **generate-context.sh 版本号**: 从过时的 `2.0.0` / `devcontext-init` 更新为 `2.2.0` / `init-your-agent`
- **磁盘挂载点双冒号**: `DeviceID` 已含 `:`，移除多余的拼接，`"C::"` → `"C:"`
- **版本字符串过长**: 所有 `Get-Version` 统一提取纯 `x.y.z` 版本号，不再输出完整命令行
- **空对象序列化**: `Get-Version` 返回 `$null` 时跳过该字段，不再输出 `"dotnet": {}`
- **OS 中文乱码**: `detect-system.ps1` 和 `detect-services.ps1` 增加 `[Console]::OutputEncoding = UTF8`
- **kubectl_version 空对象**: 统一返回 `"unavailable"` 字符串而非空 hashtable

### Changed

- **AI 代理列表同步**: PowerShell 和 Bash 版本的代理列表统一，新增 MiMo 代理检测
- **icon 字段语义化**: 从 emoji/图标名改为 CLI 工具名，便于 Agent 直接引用
- **版本号统一**: SKILL.md、脚本输出、CHANGELOG、default-context.yaml 全部更新为 2.2.0
- **generator 标识**: 从 `devcontext-init` 统一为 `init-your-agent`
- **日志格式**: 所有 bash 脚本移除 ANSI 颜色码，使用纯文本 `[INFO]`/`[WARN]`/`[ERROR]` 前缀

## [2.1.0] - 2026-08-11

### Fixed

- **输出 JSON 污染修复 (PowerShell)**: 所有 `.ps1` 子脚本移除 stdout 日志输出，只输出纯 JSON
- **输出 JSON 污染修复 (Bash)**: 所有 `.sh` 脚本的 `log_info()` 函数重定向到 stderr (`>&2`)，确保 stdout 只输出纯 JSON
- **版本号统一**: SKILL.md、脚本输出、CHANGELOG 版本号统一为 2.1.0
- **generate-context.ps1 重构**: 使用 `System.Diagnostics.Process` 在独立进程中运行子脚本，避免 PowerShell 管道序列化问题；移除内联 devstack 检测
- **JSON 验证**: 主脚本在写入文件前验证 JSON 有效性
- **PowerShell 5.1 兼容性**: 移除 `1>&2`、`??`、`.Trim()` 等不兼容语法
- **detect-ai-agents.ps1 性能优化**: 使用 `Get-NetTCPConnection` 替代慢速的 `netstat -ano`

### Added

- **detect-services.ps1**: 新增 Windows 版运行时服务检测脚本 (Docker、Kubernetes、数据库、Web 服务器、端口占用)
- **SKILL.md 改进**: 增加详细的执行步骤说明、异常处理策略、安全说明
- **错误回退机制**: 运行时服务检测失败时自动使用基本的 Docker 检测作为回退

### Changed

- **日志系统**: 所有脚本的日志输出统一重定向到 stderr，stdout 只包含 JSON 数据
- **子脚本架构**: 从内联检测改为独立脚本调用，每个脚本可独立运行和测试

## [1.0.0] - 2026-05-02

### Added

- 系统硬件探测：操作系统、CPU、内存、GPU、磁盘、Shell 环境检测
- 开发栈检测：编程语言、包管理器、编辑器、Linter/Formatter、Git 配置
- AI 代理检测：Claude Code、Codex CLI、GitHub Copilot、Cursor、Continue、Roo Code、Ollama 等 14+ 代理
- MCP 服务器检测：Model Context Protocol 服务器配置扫描
- 运行时服务检测：Docker、Kubernetes、数据库、Web 服务器
- 用户偏好收集：GitHub 信息、代码风格、Commit 模板、框架偏好
- 跨平台支持：Bash (Linux/macOS) + PowerShell (Windows) 双版本脚本
- 批量/交互模式：支持批量自动检测和交互式配置
- JSON 输出：标准化 JSON 格式输出，便于 AI 代理解析
- Roo Code 技能集成：SKILL.md 入口文件，支持 Roo Code 原生调用