# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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