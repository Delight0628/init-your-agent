# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-05-02

### Added

- **系统硬件探测**：操作系统、CPU、内存、GPU、磁盘、Shell 环境检测
- **开发栈检测**：编程语言、包管理器、编辑器、Linter/Formatter、Git 配置
- **AI 代理检测**：Claude Code、Codex CLI、GitHub Copilot、Cursor、Continue、Roo Code、Ollama 等 14+ 代理
- **MCP 服务器检测**：Model Context Protocol 服务器配置扫描
- **运行时服务检测**：Docker、Kubernetes、数据库（Redis/PostgreSQL/MySQL/MongoDB）、Web 服务器
- **用户偏好收集**：GitHub 信息、代码风格、Commit 模板、框架偏好
- **跨平台支持**：Bash (Linux/macOS) + PowerShell (Windows) 双版本脚本
- **批量/交互模式**：支持批量自动检测和交互式配置
- **JSON 输出**：标准化 JSON 格式输出，便于 AI 代理解析
- **YAML 输出**：可选的 YAML 格式输出（需安装 yq）
- **Roo Code 技能集成**：SKILL.md 入口文件，支持 Roo Code 原生调用

### Supported AI Platforms

- Claude Code (Anthropic)
- Codex CLI (OpenAI)
- GitHub Copilot
- Cursor
- Continue
- Roo Code
- Ollama
- LM Studio
- Windsurf
- Aider
- Codeium CLI
- Amazon Q
- Hermes
- OpenClaw
- OpenCode
