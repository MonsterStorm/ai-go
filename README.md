# ai-go

可移植的 AI 研发代理引擎（Development Agent Engine）。基于 [OpenCode](https://opencode.ai) 实现 loop-engineering：给定目标后，AI 自主完成研究 → 设计 → 计划 → 迭代（实现 → 验证 → 修复），直到独立评审确认验收标准，全程状态落盘、可恢复、可无人值守运行。

引擎与项目知识彻底分离：引擎只假设目标项目提供一个知识入口（`AGENTS.md`）、验证命令、任务记录位置和硬性红线。任何项目初始化知识库后即可直接使用。

## 仓库结构

| 路径 | 说明 |
| --- | --- |
| `engine/loop-engineering.md` | 循环协议 SSOT：路由、模式、状态格式、迭代契约、停止条件、风险控制 |
| `engine/agents/` | 13 个专业角色子代理（产品分析、系统架构、后端、前端、移动端、数据、AI、DevOps、安全、测试、问题修复、技术评审、交付评审） |
| `engine/commands/loop.md` | `/ai-go:loop` 命令定义 |
| `engine/skills/ai-go-loop/` | 会话触发技能（"loop this task"、"自动迭代交付" 等） |
| `engine/scripts/loop-run.sh` | 无人值守 harness：每次迭代一个全新 `opencode run` 会话 |
| `engine/references/` | 设计哲学与背景资料 |
| `scripts/` | 初始化、部署、安装脚本（见下） |
| `templates/` | 目标项目知识库模板（`AGENTS.md`、`knowledge/index.md`、`tasks/README.md`） |
| `.opencode/` | OpenCode 项目级加载层：从 `engine/` 同步的副本，勿直接编辑 |
| `prompts/`、`skills/loop-engineering-design/` | 设计文档与提示词资料（引擎的思想来源） |

> **注意**：`engine/` 目录由维护者的上游工作区通过同步脚本生成，属于同步产物。请勿直接修改 `engine/` 或 `.opencode/` 下的引擎文件——改动会在下次同步时被覆盖。

## 快速开始

### 1. 初始化你的项目知识库

引擎运行的前提是目标项目有知识库。指定项目地址（本地路径或 git 地址），一键初始化：

```bash
# 本地项目
scripts/init-knowledge-base.sh /path/to/your/project

# 或直接给 git 地址（先 clone 再初始化）
scripts/init-knowledge-base.sh https://github.com/you/your-project
```

脚本会在目标项目中创建（已存在的文件不会被覆盖）：

- `AGENTS.md` — 知识入口：项目概览、验证命令、硬性红线、任务记录约定
- `knowledge/index.md` — 轻量知识索引：架构、约定、踩坑记录（Ratchet 的沉淀地）
- `tasks/README.md` — 循环任务记录格式说明
- `.opencode/` — 引擎的命令、技能、角色代理（项目级加载；`--no-opencode` 可跳过）
- `.gitignore` 追加 `tasks/**/loop/logs/`

然后补全 `AGENTS.md` 和 `knowledge/index.md` 里的 TODO（尤其是验证命令和红线）。可以手工填，也可以在项目里启动 OpenCode 后让引擎自己探索补全：

```text
/ai-go:loop fill in the knowledge base: explore this repository and complete every TODO in AGENTS.md and knowledge/index.md, grounded in the actual code; write scope: those two files only
```

### 2.（可选）全局安装引擎

如果希望所有工作区都能使用 `/ai-go:loop` 与角色代理，而不是逐项目部署：

```bash
scripts/install-opencode-engine.sh   # 默认安装到 ~/.config/opencode
```

安装后重启 OpenCode。

### 3. 日常使用

在目标项目中打开 OpenCode：

| 想做什么 | 怎么做 |
| --- | --- |
| 开发一个功能 | `/ai-go:loop implement <目标>` |
| 修一个 bug | `/ai-go:loop <问题描述>` 或 `--mode fix` |
| 只分析不改代码 | `/ai-go:loop --readonly <问题>` |
| 只要技术方案 | `/ai-go:loop --mode design <PRD 或目标>` |
| 评审设计或 PR | `/ai-go:loop --mode review <对象>`，或直接 `@ai-go-tech-reviewer` |
| 咨询单个专家 | `@` 任意角色代理（如 `@ai-go-backend-architect`、`@ai-go-security-engineer`） |
| 无人值守跑完 | `engine/scripts/loop-run.sh --task <task-dir> --workspace <项目根>` |
| 恢复中断的循环 | `/ai-go:loop tasks/<task>`（状态都在任务记录里） |

循环在以下节点必定暂停等你确认：路由歧义/高风险、大爆炸半径的设计、数据库或外部写操作、PR/发布/部署。无人值守模式请先阅读 `engine/loop-engineering.md` 的 "Unattended Safety" 一节。

## 脚本一览

| 脚本 | 用途 |
| --- | --- |
| `scripts/init-knowledge-base.sh <项目路径或git地址>` | 一键初始化目标项目的知识库与引擎部署（幂等，不覆盖已有文件） |
| `scripts/install-opencode-engine.sh` | 把引擎命令/技能/角色代理装到全局 OpenCode 配置 |
| `scripts/sync-engine-assets.sh` | 把 `engine/` 同步到本仓库 `.opencode/`（引擎更新后运行） |

## 协议入口

引擎的一切行为以 `engine/loop-engineering.md` 为准：单一入口与路由、六种模式（design/dev/fix/analyze/review/test）、多仓库工作区规则、状态文件格式、迭代契约、maker/checker 分离、停止条件、风险控制、Ratchet 知识沉淀。背景哲学见 `engine/references/loop-philosophy.md`。
