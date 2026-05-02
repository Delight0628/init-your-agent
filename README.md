# init-your-agent

[![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-1.0.0-green.svg)](https://github.com/Delight0628/init-your-agent/releases)
[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS%20%7C%20Windows-6a3de8.svg)](#-快速开始)
[![AI Platforms](https://img.shields.io/badge/AI%20Platforms-14+-ff6b6b.svg)](#-支持的-ai-平台)

## 📋 项目简介

**init-your-agent** 是一个专为 AI 编程代理设计的本地开发环境上下文自动检测与初始化工具。它在每次 AI Agent 会话启动时，自动构建完整的本机开发环境画像，消除 AI 助手与开发者本地环境之间的信息差，从而显著提升代码生成精准度与工具调用成功率。

### 为什么需要这个工具？

| 痛点 | 解决方案 |
|------|---------|
| AI 不知道你安装了什么语言/工具 | 自动检测 20+ 编程语言和包管理器 |
| AI 不知道你用什么 AI 代理 | 检测 14+ AI 编程代理及其配置 |
| AI 不知道你的 MCP 服务器配置 | 扫描所有 MCP 配置文件 |
| AI 不知道你的 Docker/数据库状态 | 检测运行时服务状态 |
| 每次都要手动告诉 AI 环境信息 | 一次运行，生成标准化上下文文件 |

## 🚀 快速开始

### 安装

```bash
# 从 GitHub 克隆
git clone https://github.com/Delight0628/init-your-agent.git
cd init-your-agent
```

### 使用

```bash
# Windows (PowerShell) - 批量模式
powershell -ExecutionPolicy Bypass -File scripts/generate-context.ps1 -Batch

# Windows (PowerShell) - 交互模式
powershell -ExecutionPolicy Bypass -File scripts/generate-context.ps1 -Interactive

# Linux/macOS (Bash) - 批量模式
bash scripts/generate-context.sh --batch

# Linux/macOS (Bash) - 交互模式
bash scripts/generate-context.sh --interactive
```

### 输出

执行完成后，会在 `assets/` 目录下生成：

- `context-output.json` - 完整的检测结果（JSON 格式）
- `context-output.yaml` - YAML 格式（需安装 yq）

## 🔍 检测维度

### 维度一：系统硬件与基础环境

- 操作系统发行版、内核版本、CPU 架构与核心数
- 内存容量、GPU 型号与显存状态
- 磁盘分区与剩余空间
- Shell 环境类型、网络代理配置

### 维度二：开发栈与工具链

- 编程语言及版本（Node.js、Python、Go、Rust、Java、Ruby、PHP、Dart、.NET 等）
- 包管理器生态（npm、yarn、pnpm、pip、cargo、brew、apt、chocolatey、winget 等）
- 代码编辑器（VS Code、Vim、Neovim、Cursor、Windsurf 等）
- Linter/Formatter（ESLint、Prettier、Black、Ruff、Gofmt 等）
- Git 远程仓库配置、SSH 密钥、GitHub CLI

### 维度三：AI 编程代理

| 代理 | 检测内容 |
|------|---------|
| Claude Code | CLI 版本、配置状态 |
| Codex CLI | CLI 版本、配置状态 |
| GitHub Copilot | CLI 版本、配置状态 |
| Cursor | CLI 版本、配置状态 |
| Continue | CLI 版本、配置状态 |
| Roo Code | CLI 版本、配置状态 |
| Ollama | CLI 版本、本地模型数量 |
| Windsurf | CLI 版本、配置状态 |
| Aider | CLI 版本、配置状态 |
| Amazon Q | CLI 版本、配置状态 |
| LM Studio | 本地服务器状态 |

### 维度四：MCP 服务器

- 已配置的 MCP (Model Context Protocol) 服务器
- MCP SDK 版本支持
- MCP CLI 工具状态

### 维度五：运行时依赖与服务

- Docker 环境状态与 Docker Compose 版本
- 容器编排工具（Kubernetes、Helm 等）
- 数据库服务（Redis、PostgreSQL、MySQL、MongoDB、SQLite）
- Web 服务器（Nginx、Apache、Caddy）
- 常用端口占用情况

### 维度六：用户画像与协作偏好

- GitHub 用户名、Commit 邮箱、个人网站链接
- 代码风格偏好、命名规范
- Commit Message 模板
- 框架使用习惯

## 📦 文件结构

```
init-your-agent/
├── SKILL.md                          # Roo Code 技能入口文件
├── README.md                         # 本文件
├── CHANGELOG.md                      # 版本更新日志
├── CONTRIBUTING.md                   # 贡献指南
├── LICENSE                           # MIT License
├── .gitignore                        # Git 忽略配置
├── scripts/
│   ├── generate-context.ps1          # 上下文生成主脚本 (Windows)
│   ├── generate-context.sh           # 上下文生成主脚本 (Linux/macOS)
│   ├── detect-system.ps1             # 系统硬件探测 (Windows)
│   ├── detect-system.sh              # 系统硬件探测 (Linux/macOS)
│   ├── detect-devstack.ps1           # 开发栈检测 (Windows)
│   ├── detect-devstack.sh            # 开发栈检测 (Linux/macOS)
│   ├── detect-ai-agents.ps1          # AI 代理检测 (Windows)
│   ├── detect-ai-agents.sh           # AI 代理检测 (Linux/macOS)
│   ├── detect-mcp-servers.ps1        # MCP 服务器检测 (Windows)
│   ├── detect-mcp-servers.sh         # MCP 服务器检测 (Linux/macOS)
│   └── detect-services.sh            # 服务扫描 (Linux/macOS)
└── assets/
    └── default-context.yaml          # 标准上下文模板
```

## 🤖 Roo Code 集成

本项目可以作为 [Roo Code](https://roocode.com) 的技能使用。将 `SKILL.md` 和 `scripts/` 目录放入 Roo Code 的技能目录即可。

### 使用方式

1. 将项目克隆到 Roo Code 技能目录
2. 在 Roo Code 中触发 `init-your-agent` 技能
3. AI 代理会自动执行检测脚本并读取结果

## 🤝 贡献指南

欢迎贡献！请阅读 [CONTRIBUTING.md](CONTRIBUTING.md) 了解详细流程。

### 开发要求

- 所有新增脚本需同时提供 Bash (`.sh`) 和 PowerShell (`.ps1`) 版本
- 使用 `safe_exec` 模式，命令失败时返回 fallback 值
- 禁止输出密钥、Token、密码等敏感信息

## 📄 许可证

本项目采用 [MIT License](LICENSE) 开源。

## 🔗 相关项目

- [Roo Code](https://roocode.com) - AI 编程代理
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) - Anthropic 的 AI 编程助手
- [Model Context Protocol](https://modelcontextprotocol.io) - MCP 协议规范

---

<div align="center">

**Made with ❤️ for the AI Developer Community**

[Report Issue](https://github.com/Delight0628/init-your-agent/issues) · [Request Feature](https://github.com/Delight0628/init-your-agent/issues) · [Contributing](https://github.com/Delight0628/init-your-agent/blob/main/CONTRIBUTING.md)

</div>
