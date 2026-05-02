# 贡献指南

感谢你对 init-your-agent 项目的关注！本文档说明了如何为项目做出贡献。

## 📋 贡献方式

### 报告问题

如果你发现了 bug 或有功能建议，请 [创建 Issue](https://github.com/Delight0628/init-your-agent/issues)：

- **Bug 报告**：请包含操作系统、版本、复现步骤
- **功能建议**：请描述使用场景和预期行为

### 提交代码

#### 开发环境准备

```bash
# 1. Fork 本仓库
# 2. Clone 到本地
git clone https://github.com/<your-username>/init-your-agent.git
cd init-your-agent

# 3. 创建特性分支
git checkout -b feature/amazing-feature
```

#### 开发要求

- **脚本兼容**：所有新增脚本需同时提供 Bash (`.sh`) 和 PowerShell (`.ps1`) 版本
- **错误处理**：使用 `safe_exec` 模式，命令失败时返回 fallback 值
- **输出格式**：JSON 输出需符合 schema 定义
- **敏感信息**：禁止输出密钥、Token、密码

#### 提交规范

遵循 [Conventional Commits](https://www.conventionalcommits.org/) 规范：

```
feat: add Ollama detection support
fix: handle missing jq gracefully
docs: update architecture diagram
refactor: simplify JSON merging logic
test: add unit tests for detect-ai-agents
chore: update version to 1.0.0
```

**类型说明：**
- `feat`: 新功能
- `fix`: 修复 bug
- `docs`: 文档更新
- `style`: 代码格式（不影响代码运行）
- `refactor`: 重构
- `test`: 测试相关
- `chore`: 构建/工具链变更

#### 提交前检查

```bash
# 1. 检查脚本语法 (Bash)
bash -n scripts/detect-*.sh

# 2. 检查脚本语法 (PowerShell)
pwsh -NoProfile -Command "Test-Path scripts/detect-*.ps1 | ForEach-Object { & $PSHOME/pwsh.exe -NoProfile -Command \"& { \$ErrorActionPreference='Stop'; \$null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $_ -Raw), [ref \$null]) }\" }"

# 3. 运行探测脚本测试
./scripts/generate-context.sh --batch
```

### 添加新的探测工具

1. 在对应的检测脚本中添加检测逻辑
2. 在 `default-context.yaml` 中更新 schema
3. 提供 Bash 和 PowerShell 双版本

## 🔍 代码审查

所有 PR 需要经过：

1. **自动检查**：CI 流程验证脚本语法
2. **人工审查**：至少一名维护者批准
3. **兼容性测试**：在 Linux、macOS、Windows 上验证

## 📐 架构原则

1. **模块化**：每个探测维度独立脚本
2. **幂等性**：多次运行结果一致
3. **容错性**：单个探测失败不影响整体
4. **跨平台**：Bash + PowerShell 双版本
5. **安全性**：不采集敏感信息

## 💬 社区

- [GitHub Issues](https://github.com/Delight0628/init-your-agent/issues) - 问题与建议
- [GitHub Discussions](https://github.com/Delight0628/init-your-agent/discussions) - 讨论与交流

---

感谢你的贡献！🎉
