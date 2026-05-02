# init-your-agent

[![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-1.0.0-green.svg)](https://github.com/Delight0628/init-your-agent/releases)
[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS%20%7C%20Windows-6a3de8.svg)](#-快速开始)

## 📋 项目简介

**init-your-agent** 是一个专为 AI 编程代理设计的本地开发环境上下文自动检测与初始化工具。它在每次 AI Agent 会话启动时，自动构建完整的本机开发环境画像，消除 AI 助手与开发者本地环境之间的信息差，从而显著提升代码生成精准度与工具调用成功率。

### 支持的 AI 平台

| 平台 | 支持状态 |
|------|---------||
| Claude Code (Anthropic) | ✅ 原生集成 |
| Codex CLI (OpenAI) | ✅ 原生集成 |
| GitHub Copilot | ✅ 原生集成 |
| Cursor | ✅ 原生集成 |
| Continue | ✅ 原生集成 |
| Roo Code | ✅ 原生集成 |
| Ollama | ✅ 原生集成 |

## 🚀 快速开始

### 安装

```bash
# 从 GitHub 克隆
git clone https://github.com/Delight0628/init-your-agent.git
cd init-your-agent
```

### 使用

```bash
# Windows (PowerShell)
powershell -ExecutionPolicy Bypass -File scripts/generate-context.ps1 -Batch

# Linux/macOS (Bash)
bash scripts/generate-context.sh --batch
```

### 输出

输出文件位于：`assets/context-output.json`

## 🔍 检测维度

### 维度一：系统硬件与基础环境
- 操作系统发行版、内核版本、CPU 架构与核心数
- 内存容量、GPU 型号与显存状态
- 磁盘分区与剩余空间
- Shell 环境类型、网络代理配置

### 维度二：开发栈与工具链
- 编程语言及版本（Node.js、Python、Go、Rust、Java 等）
- 包管理器生态（npm、pip、cargo、brew、apt 等）
- 代码编辑器、Linter、Formatter 配置
- Git 远程仓库配置

### 维度三：AI 编程代理
- 已安装的 AI 代理（Claude Code、Codex CLI、GitHub Copilot、Cursor、Roo Code 等）
- AI 代理配置状态
- 活跃会话检测
- 模型配置（Anthropic、OpenAI、Google、Ollama 等）

### 维度四：MCP 服务器
- 已配置的 MCP (Model Context Protocol) 服务器
- MCP SDK 版本支持
- MCP CLI 工具状态

### 维度五：运行时依赖与服务
- Docker 环境状态与 Docker Compose 版本
- 容器编排工具（Kubernetes、Helm 等）
- 数据库服务（Redis、PostgreSQL、MySQL、MongoDB）可用性
- Web 服务器（Nginx、Apache、Caddy）配置

### 维度六：用户画像与协作偏好
- GitHub 用户名、Commit 邮箱、个人网站链接
- 代码风格偏好、命名规范
- Commit Message 模板
- 框架使用习惯

## 📦 文件结构

```
init-your-agent/
├── SKILL.md                          # 技能入口文件
├── README.md                         # 本文件
├── LICENSE                           # MIT License
├── .gitignore                        # Git 忽略配置
├── scripts/
│   ├── generate-context.sh/ps1       # 上下文生成主脚本
│   ├── detect-system.sh/ps1          # 系统硬件探测
│   ├── detect-devstack.sh/ps1        # 开发栈检测
│   ├── detect-ai-agents.sh/ps1       # AI 代理检测
│   ├── detect-mcp-servers.sh/ps1     # MCP 服务器检测
│   └── detect-services.sh/ps1        # 服务扫描
└── assets/
    └── default-context.yaml          # 标准上下文模板
```

## 🤝 贡献指南

欢迎贡献！请阅读 [CONTRIBUTING.md](CONTRIBUTING.md) 了解详细流程。

## 📄 许可证

本项目采用 [MIT License](LICENSE) 开源。

---

<div align="center">

**Made with ❤️ for the AI Developer Community**

[Report Issue](https://github.com/Delight0628/init-your-agent/issues) · [Request Feature](https://github.com/Delight0628/init-your-agent/issues)

</div>
