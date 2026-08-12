# =============================================================================
# SKILL.md - AI Agent 上下文初始化技能
# 版本: 2.1.0
# =============================================================================

---
name: init-your-agent
description: >
  AI Agent 上下文初始化技能。自动检测本机开发环境并生成标准化上下文文件。
  涵盖系统硬件、开发工具链、AI 代理、MCP 服务器、运行时服务、用户偏好六大维度。
  检测结果保存为 assets/context-output.json，供 AI Agent 在任务启动时读取使用。
version: 2.1.0
author: Delight0628
license: MIT
trigger: always
tags:
  - ai-agent
  - context
  - environment
  - detection
  - mcp
  - devtools
---

# init-your-agent

## 概述

本技能用于在每次任务启动时自动检测本机开发环境，生成标准化的上下文文件（`assets/context-output.json`），帮助 AI 助手了解你的开发环境。检测完成后，AI Agent 应读取并引用该文件中的环境信息来优化代码生成和工具调用。

## 执行步骤

### 步骤 1：执行环境检测脚本

```powershell
# Windows (PowerShell)
powershell -ExecutionPolicy Bypass -File scripts/generate-context.ps1 -Batch

# Linux/macOS (Bash)
bash scripts/generate-context.sh --batch
```

### 步骤 2：读取输出文件

读取 `assets/context-output.json` 文件。该文件包含以下六个维度的信息：

- **system**: 操作系统、CPU、内存、GPU、磁盘、Shell、网络代理
- **devstack**: 编程语言版本、包管理器、编辑器、Linter/Formatter、Git 配置
- **ai_agents**: 已安装的 AI 编程代理（Claude Code、Codex、Cursor 等）及模型配置
- **mcp**: 已配置的 MCP 服务器列表
- **services**: Docker、数据库、Web 服务器运行状态
- **user**: GitHub 用户信息、代码风格偏好

### 步骤 3：使用检测结果

根据上下文信息优化后续工作：

- 根据已安装的语言和框架选择合适的技术方案
- 根据包管理器选择对应的依赖安装命令
- 根据 Docker/数据库状态决定是否需要启动服务
- 根据 AI 代理配置避免重复检测
- 参考用户偏好（Commit 模板、代码风格）保持一致性

## 异常处理

| 错误类型 | 处理策略 |
|---------|---------|
| 脚本执行失败 | 显示详细错误信息，尝试手动检测 |
| 命令不存在 | 跳过该探测项，标记为 `unavailable` |
| 权限不足 | 记录警告，继续执行其他探测 |
| JSON 解析失败 | 使用 fallback 值，标记 `error` 字段 |

## 安全说明

- API 密钥仅检测是否已设置，不输出密钥内容
- SSH 密钥仅检测存在性，不读取密钥文件
- 所有检测均为只读操作，不修改系统状态
