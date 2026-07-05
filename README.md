# ai-go

**可移植的 AI 研发代理引擎（Development Agent Engine）**，基于 [OpenCode](https://opencode.ai) 实现 loop-engineering：给定目标后，AI 自主完成 研究 → 设计 → 计划 → 迭代（实现 → 验证 → 修复），直到独立评审确认全部验收标准。全程状态落盘、可中断恢复、可无人值守运行。

任何项目只需初始化一份知识库（一个 `AGENTS.md` 入口 + 验证命令 + 任务记录位置 + 硬性红线），引擎即可直接在其上工作，无需修改引擎本身。

---

## 设计理念

### Loop ≠ 流水线

Loop 是**目标驱动系统，不是流程引擎**。研发工作不是装配线：一个 bug 可能是五分钟的单文件修改，也可能是一整天的跨服务排查——硬编码执行阶段会毁掉你雇 AI 来提供的判断力。所以引擎只定义三样东西：**目标与约束、停止条件、评审机制**，执行策略交给模型自己选择。

它建立在下面的分层之上（每一层解决不同的问题）：

```text
Prompt Engineering   -> 教 AI 做好一件事
Context Engineering  -> 决定 AI 看到什么
Harness Engineering  -> 搭建 AI 运行的环境（工具、权限、沙箱）
Loop Engineering     -> 设计一个自己找活、派活、验活的系统
```

### 核心原则

1. **Agent = 模型 + Harness**。模型提供智能，harness 提供手、眼、记忆和安全边界；配置 harness，而不是绕过它。
2. **信任模型，在边界强制**。不靠 prompt 约束自觉，靠工具/权限/沙箱层强制执行规则。
3. **Maker/Checker 分离**。写代码的 agent 不能给自己的作品打分。独立的评审者（不同 prompt、独立会话）是质量保证，包括对"完成"这个判断本身——只有交付评审角色能把任务置为 DONE。
4. **每个真实失败都变成规则（Ratchet）**。不是"下次记得提醒它"，而是把失败编码成规则，写在下一个 agent 一定会读到的位置。
5. **Agent 会忘，仓库会记**。记忆存在磁盘上——状态文件、git 提交、文档——从不依赖上下文窗口。每次迭代用全新会话读取良好的状态文件，胜过累积一整个长会话。
6. **飞行员检查单，不是风格指南**。规则要短、准、可追溯。60 行好规则胜过 600 行；模型进步让某条规则失去价值时，删掉它。
7. **子代理是双重专家**。每个角色既是领域专家（方法论），又通过知识入口加载当前项目的架构、约束与历史，成为场景专家。

### 引擎 / 知识分离

这是本项目最重要的架构决策：**引擎（怎么干活）与项目知识（这个项目的规矩）彻底解耦**。

```text
┌─────────────────────────────────────────────────┐
│  engine/  （本仓库，可移植，项目无关）              │
│  循环协议 · 13 个角色子代理 · loop 命令/技能 ·      │
│  无人值守 harness                                 │
└──────────────────────┬──────────────────────────┘
                       │ 运行时通过知识入口加载
                       ▼
┌─────────────────────────────────────────────────┐
│  目标项目的知识库（由 init-knowledge-base.sh 初始化）│
│  AGENTS.md（入口：验证命令、红线、约定）             │
│  knowledge/index.md（架构、约定、踩坑记录）          │
│  tasks/（任务记录：spec / plan / loop 状态）        │
└─────────────────────────────────────────────────┘
```

引擎对目标项目只有四个假设：知识入口（`AGENTS.md`）、验证命令、任务记录位置、硬性红线。满足这四点，引擎在任何项目上零改动运行。

### 单一入口与路由

用户只需要记住一个命令：`/ai-go:loop <目标>`。循环启动时先做一次轻量**路由**判断——意图（模式）、涉及仓库、写风险、不确定性、停止条件、需要的角色——然后自选执行策略。六种内部模式：

| 模式 | 典型输入 | 默认写范围 |
| --- | --- | --- |
| `design` | "PRD → 技术方案" | 仅任务产物 |
| `dev` | "实现 X" | 代码、测试、文档（分支/worktree） |
| `fix` | "修这个 bug" | 代码、测试、文档（分支/worktree） |
| `analyze` | "为什么会发生 Y" | 只读 |
| `review` | "评审这个方案/PR" | 只读 |
| `test` | "给 Z 补测试" | 仅测试 |

### 13 个专业角色

覆盖研发全生命周期的角色子代理，maker（产品分析、架构、前后端、移动端、数据、AI、DevOps、安全、测试、问题修复）与 checker（技术评审、交付评审）职责分离，checker 工具层只读、只提意见不改代码：

产品分析 · 系统架构 · 后端架构 · 前端专家 · 移动端专家 · 数据工程 · AI 工程 · DevOps · 安全工程 · 测试工程 · 问题修复 · 技术评审 · **交付评审（唯一可置 DONE 的角色）**

### 状态与恢复

每个循环任务是一条任务记录：`tasks/<task>/spec.md`（验收标准，只增不删）、`plan.md`（切片清单）、`loop/state.md`（机器可读状态 + 迭代日志）。任何迭代都是"一次 revert 即可回退"的干净提交；换机器、断会话，读文件即可续跑。

完整协议见 [`engine/loop-engineering.md`](engine/loop-engineering.md)（SSOT），设计哲学与开源先例分析见 [`engine/references/loop-philosophy.md`](engine/references/loop-philosophy.md)。

---

## 快速开始

### 0. 前置条件

- 安装 [OpenCode](https://opencode.ai) CLI
- clone 本仓库

### 1. 初始化目标项目的知识库

指定项目地址（本地路径或 git 地址），一键初始化：

```bash
# 本地项目
scripts/init-knowledge-base.sh /path/to/your/project

# 或直接给 git 地址（先 clone 再初始化）
scripts/init-knowledge-base.sh https://github.com/you/your-project
```

脚本幂等、从不覆盖已有文件，会在目标项目创建：

| 产物 | 作用 |
| --- | --- |
| `AGENTS.md` | 知识入口：项目概览、**验证命令**、**硬性红线**、任务记录约定 |
| `knowledge/index.md` | 轻量知识索引：架构、约定、踩坑记录（Ratchet 沉淀地） |
| `tasks/README.md` | 循环任务记录格式说明 |
| `.opencode/` | 引擎的命令、技能、13 个角色代理（项目级加载；`--no-opencode` 跳过） |
| `.gitignore` | 追加 `tasks/**/loop/logs/`（harness 运行日志不入库） |

然后补全 `AGENTS.md` 与 `knowledge/index.md` 里的 TODO（尤其是验证命令和红线）。可以手工填，也可以让引擎自己探索补全——在项目里启动 OpenCode 后运行：

```text
/ai-go:loop fill in the knowledge base: explore this repository and complete every TODO in AGENTS.md and knowledge/index.md, grounded in the actual code; write scope: those two files only
```

### 2.（可选）全局安装引擎

希望所有工作区都能用 `/ai-go:loop` 和角色代理、而不是逐项目部署时：

```bash
scripts/install-opencode-engine.sh   # 默认装到 ~/.config/opencode
```

安装后重启 OpenCode。角色代理是 `mode: subagent`，不会出现在 Tab 主代理切换器里；在输入框输入 `@ai-go` 即可看到全部 13 个。

### 3. 日常使用

在目标项目中打开 OpenCode：

| 想做什么 | 怎么做 |
| --- | --- |
| 开发一个功能 | `/ai-go:loop implement <目标>` |
| 修一个 bug | `/ai-go:loop <问题描述>` 或 `--mode fix` |
| 只分析不改代码 | `/ai-go:loop --readonly <问题>` |
| 只要技术方案 | `/ai-go:loop --mode design <PRD 或目标>` |
| 评审设计或 PR | `/ai-go:loop --mode review <对象>`，或直接 `@ai-go-tech-reviewer` |
| 咨询单个专家 | `@` 任意角色（如 `@ai-go-backend-architect`、`@ai-go-security-engineer`） |
| 恢复中断的循环 | `/ai-go:loop tasks/<task>`（状态都在任务记录里） |

循环在以下节点必定暂停等人确认：路由歧义/高风险、大爆炸半径的设计、数据库或外部写操作、PR/发布/部署。

### 4. 无人值守运行

```bash
engine/scripts/loop-run.sh --task <task-dir> --workspace <项目根> \
  [--max-iterations 10] [--iteration-timeout 1800] [--agent <只读agent>]
```

每次迭代启动一个全新 `opencode run` 会话（新鲜上下文优于累积上下文），迭代间通过 `state.md` 交接。退出码：`0` DONE、`2` BLOCKED、`3` 达到迭代上限、`4` 协议/运行错误、`5` 停滞（状态连续两轮无变化）。

> ⚠️ 非交互模式会自动批准所有权限。只在可接受无人值守修改的仓库和特性分支上运行，优先使用沙箱/容器环境，凭证从紧配置。运行前请阅读 `engine/loop-engineering.md` 的 "Unattended Safety" 一节。

---

## 仓库结构

| 路径 | 说明 |
| --- | --- |
| `engine/loop-engineering.md` | 循环协议 SSOT：路由、模式、状态格式、迭代契约、停止条件、风险控制 |
| `engine/agents/` | 13 个专业角色子代理 |
| `engine/commands/loop.md` | `/ai-go:loop` 命令定义 |
| `engine/skills/ai-go-loop/` | 会话触发技能（"loop this task"、"自动迭代交付" 等） |
| `engine/scripts/loop-run.sh` | 无人值守 harness |
| `engine/references/` | 设计哲学与背景资料 |
| `scripts/init-knowledge-base.sh` | 一键初始化目标项目知识库（幂等） |
| `scripts/install-opencode-engine.sh` | 全局安装引擎到 OpenCode 配置 |
| `scripts/sync-engine-assets.sh` | 把 `engine/` 同步到本仓库 `.opencode/` |
| `templates/` | 目标项目知识库模板 |
| `tests/` | 脚本与部署的契约测试（`bash tests/<test>.sh`） |
| `.opencode/` | OpenCode 项目级加载层：从 `engine/` 同步的副本，勿直接编辑 |
| `prompts/`、`skills/loop-engineering-design/` | 设计文档与提示词资料（引擎的思想来源） |

> **注意**：`engine/` 目录由维护者的上游工作区通过同步脚本生成，属于同步产物。请勿直接修改 `engine/` 或 `.opencode/` 下的引擎文件——改动会在下次同步时被覆盖。本仓库自有能力放在 `scripts/`、`templates/`、`tests/`。

## 测试

```bash
bash tests/engine-deployment-test.sh    # 引擎布局与 .opencode/ 副本一致性
bash tests/init-knowledge-base-test.sh  # 知识库初始化：产物、幂等、git 地址、失败路径
```

## 开源协议

本项目基于 [MIT License](LICENSE) 开源。
