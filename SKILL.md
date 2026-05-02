---
name: init-your-agent
description: >
  AI Agent 上下文初始化技能。自动检测本机开发环境并生成标准化上下文文件。
  涵盖系统硬件、开发工具链、AI 代理、MCP 服务器、运行时服务、用户偏好六大维度。
version: 1.0.0
author: Delight0628
license: MIT
trigger: manual
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

本技能用于在每次任务启动时自动检测本机开发环境，生成标准化的上下文文件（`assets/context-output.json`），帮助 AI 助手了解你的开发环境。

## 执行步骤

**必须按顺序执行以下步骤：**

### 步骤 1：执行环境检测脚本

```bash
# Windows (PowerShell)
powershell -ExecutionPolicy Bypass -File scripts/generate-context.ps1 -Batch

# Linux/macOS (Bash)
bash scripts/generate-context.sh --batch
```

### 步骤 2：读取输出文件

执行完成后，读取 `assets/context-output.json` 文件获取完整的检测结果。

### 步骤 3：使用检测结果

根据 `context-output.json` 中的环境信息，为 AI 助手提供以下上下文：

- **系统硬件**：操作系统、CPU、内存、GPU、磁盘
- **开发工具链**：编程语言版本、包管理器、编辑器、Git 配置
- **AI 代理**：已安装的 AI 代理（Claude Code、Codex、Cursor、Roo Code 等）、模型配置
- **MCP 服务器**：已配置的 MCP 服务器列表
- **运行时服务**：Docker、数据库、Web 服务器状态
- **用户偏好**：GitHub 信息、代码风格、Commit 模板

## 输出文件

- `assets/context-output.json` - 完整的检测结果（JSON 格式）
- `assets/context-output.yaml` - YAML 格式（可选）

## 异常处理

| 错误类型 | 处理策略 |
|---------|---------|
| 脚本执行失败 | 显示详细错误信息，尝试手动检测 |
| 命令不存在 | 跳过该探测项，标记为 `unavailable` |
| 权限不足 | 记录警告，继续执行其他探测 |
