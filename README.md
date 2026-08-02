<div align="center">

# 🤖 init-your-agent

### AI Agent 上下文初始化技能

**自动检测本机开发环境并生成标准化上下文文件**

<br/>

[![MIT License](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](LICENSE)
[![Version](https://img.shields.io/badge/Version-1.0.0-green.svg?style=for-the-badge)](https://github.com/Delight0628/init-your-agent/releases)
[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS%20%7C%20Windows-6a3de8.svg?style=for-the-badge)](#-快速开始)
[![AI Platforms](https://img.shields.io/badge/AI%20Platforms-14%2B-ff6b6b.svg?style=for-the-badge)](#-支持的-ai-编程代理)
[![MCP](https://img.shields.io/badge/MCP-Ready-00d4aa.svg?style=for-the-badge)](#-mcp-服务器检测)

<br/>

<img src="https://img.shields.io/badge/Scripts-Bash%20%26%20PowerShell-orange?style=flat-square" alt="scripts"/>
<img src="https://img.shields.io/badge/Detection-20%2B%20Languages-blueviolet?style=flat-square" alt="languages"/>
<img src="https://img.shields.io/badge/Roo%20Code-Integrated-success?style=flat-square" alt="roo code"/>

</div>

---

## 💡 为什么需要这个工具？

> AI 不了解你的开发环境？每次对话都要重复配置？**一次运行，永久解决。**

| 😩 痛点 | ✅ 解决方案 |
|---------|-----------|
| AI 不知道你安装了什么语言/工具 | 自动检测 **20+ 编程语言**和包管理器 |
| AI 不知道你用什么 AI 代理 | 检测 **14+ AI 编程代理**及其配置 |
| AI 不知道你的 MCP 服务器配置 | 扫描所有 MCP 配置文件 |
| AI 不知道你的 Docker/数据库状态 | 检测运行时服务状态 |
| 每次都要手动告诉 AI 环境信息 | 一次运行，生成标准化上下文文件 |

---

## ⚡ 快速开始

### 1. 克隆项目

```bash
git clone https://github.com/Delight0628/init-your-agent.git
cd init-your-agent
```

### 2. 运行检测

<details>
<summary><b>🪟 Windows (PowerShell)</b></summary>

```powershell
# 批量模式 - 一键检测
powershell -ExecutionPolicy Bypass -File scripts/generate-context.ps1 -Batch

# 交互模式 - 逐步确认
powershell -ExecutionPolicy Bypass -File scripts/generate-context.ps1 -Interactive
```
</details>

<details>
<summary><b>🐧 Linux / macOS (Bash)</b></summary>

```bash
# 批量模式
bash scripts/generate-context.sh --batch

# 交互模式
bash scripts/generate-context.sh --interactive
```
</details>

### 3. 查看结果

执行完成后，`assets/` 目录下会生成：

| 文件 | 说明 |
|------|------|
| `context-output.json` | 完整的检测结果（JSON 格式） |
| `context-output.yaml` | YAML 格式（需安装 `yq`） |

---

## 🔍 检测维度

<table>
<tr>
<td width="50%">

### 🖥️ 系统硬件与基础环境

- 操作系统发行版、内核版本
- CPU 架构与核心数
- 内存容量、GPU 型号与显存
- 磁盘分区与剩余空间
- Shell 环境、网络代理配置

</td>
<td width="50%">

### 🛠️ 开发栈与工具链

- **编程语言：** Node.js、Python、Go、Rust、Java、Ruby、PHP、Dart、.NET...
- **包管理器：** npm、yarn、pnpm、pip、cargo、brew、apt、chocolatey、winget...
- **编辑器：** VS Code、Vim、Neovim、Cursor、Windsurf...
- **代码质量：** ESLint、Prettier、Black、Ruff、Gofmt...
- **Git：** 远程仓库、SSH 密钥、GitHub CLI

</td>
</tr>
</table>

### 🤖 支持的 AI 编程代理

<table>
<tr>
<td>

- ✅ Claude Code
- ✅ Codex CLI
- ✅ GitHub Copilot
- ✅ Cursor
- ✅ Continue

</td>
<td>

- ✅ Roo Code
- ✅ Ollama
- ✅ Windsurf
- ✅ Aider
- ✅ Amazon Q

</td>
<td>

- ✅ LM Studio
- ✅ Hermes Agent
- ✅ OpenAI Codex
- ✅ Cline
- ✅ 更多...

</td>
</tr>
</table>

### 🔌 MCP 服务器检测

- 已配置的 **Model Context Protocol** 服务器
- MCP SDK 版本支持
- MCP CLI 工具状态

### 🐳 运行时依赖与服务

- Docker 环境状态与 Docker Compose 版本
- 容器编排工具（Kubernetes、Helm）
- 数据库（Redis、PostgreSQL、MySQL、MongoDB、SQLite）
- Web 服务器（Nginx、Apache、Caddy）
- 常用端口占用情况

### 👤 用户画像与协作偏好

- GitHub 用户名、Commit 邮箱、个人网站
- 代码风格偏好、命名规范
- Commit Message 模板、框架使用习惯

---

## 📁 项目结构

```
init-your-agent/
├── SKILL.md                    # 🤖 Roo Code 技能入口
├── README.md                   # 📖 项目说明（你在这里）
├── CONTRIBUTING.md             # 🤝 贡献指南
├── CHANGELOG.md                # 📋 版本日志
├── LICENSE                     # ⚖️ MIT 开源协议
├── scripts/
│   ├── generate-context.ps1    # Windows 主脚本
│   ├── generate-context.sh     # Linux/macOS 主脚本
│   ├── detect-system.*         # 系统硬件探测
│   ├── detect-devstack.*       # 开发栈检测
│   ├── detect-ai-agents.*      # AI 代理检测
│   ├── detect-mcp-servers.*    # MCP 服务器检测
│   └── detect-services.sh      # 服务扫描
└── assets/
    └── default-context.yaml    # 标准上下文模板
```

---

## 🤖 Roo Code 集成

本项目可以作为 [Roo Code](https://roocode.com) 的技能使用：

1. 将项目克隆到 Roo Code 技能目录
2. 在 Roo Code 中触发 `init-your-agent` 技能
3. AI 代理自动执行检测并读取结果

---

## 🤝 贡献指南

我们欢迎任何形式的贡献！

### 快速贡献流程

```bash
# 1. Fork 本仓库
# 2. 创建特性分支
git checkout -b feature/amazing-feature
# 3. 提交更改
git commit -m 'feat: add amazing feature'
# 4. 推送分支
git push origin feature/amazing-feature
# 5. 创建 Pull Request
```

### 开发要求

- 📝 所有新增脚本需同时提供 **Bash** (`.sh`) 和 **PowerShell** (`.ps1`) 版本
- 🛡️ 使用 `safe_exec` 模式，命令失败时返回 fallback 值
- 🔒 **禁止输出**密钥、Token、密码等敏感信息

详细流程请查看 [CONTRIBUTING.md](CONTRIBUTING.md)。

---

## 📜 许可证

本项目采用 [MIT License](LICENSE) 开源。

---

## 🔗 相关项目

| 项目 | 说明 |
|------|------|
| [Roo Code](https://roocode.com) | AI 编程代理 |
| [Claude Code](https://docs.anthropic.com/en/docs/claude-code) | Anthropic AI 编程助手 |
| [Model Context Protocol](https://modelcontextprotocol.io) | MCP 协议规范 |

---

<div align="center">

**Made with ❤️ for the AI Developer Community**

[Report Issue](https://github.com/Delight0628/init-your-agent/issues) · [Request Feature](https://github.com/Delight0628/init-your-agent/issues) · [Contributing](https://github.com/Delight0628/init-your-agent/blob/main/CONTRIBUTING.md)

</div>
