# ai-go

**一个会自己干完活的研发引擎。** 给它一个目标，它自主完成 研究 → 设计 → 计划 → 迭代（实现 → 验证 → 修复），直到一个"没写过这份代码"的独立评审确认全部验收标准——只有它有权说"完成"。全程状态落盘，随时中断、随时续跑、可整夜无人值守。

ai-go 不是又一个 Agent 框架。它是一份**协议**（Markdown 写成的循环契约）+ **13 个专业角色**（maker/checker 严格分离）+ **一个 harness 脚本**（无人值守驱动器），跑在 [OpenCode](https://opencode.ai) 上。没有 SDK，没有 DSL，没有需要学习的编排图——全部实现可读、可审计、可魔改。

```text
你：/ai-go:loop 实现会员自动续费
引擎：路由 → 探索代码 → 出技术方案 → 评审 → 切片计划
      → 迭代：实现 → 跑验证 → 修复 → 提交（每片一个干净 commit）
      → 独立交付评审逐条核验验收标准 → DONE
      → 把这次踩的坑沉淀成规则（Ratchet）
```

---

## 它和其他东西有什么不同

一句话：**别人给你一个更强的"助手"或一个更复杂的"框架"，ai-go 给你一套可交付的"研发系统"。**

| 对比 | 它们的模型 | ai-go 的模型 |
| --- | --- | --- |
| **交互式 AI 助手**（Copilot / Cursor / 裸用 Claude Code） | 你在环内逐条指挥，"完成"由干活的 AI 自己宣布，记忆随会话蒸发 | 目标进、交付出；写代码的角色**无权**宣布完成，独立交付评审重跑验证命令后才能置 DONE；记忆全部落在 git 与状态文件里 |
| **编排框架**（LangGraph / CrewAI / AutoGen） | 用代码把工作流写死成图和流水线，先学 SDK 再干活 | **零框架代码**。研发不是装配线——协议只定义目标、停止条件与评审机制，执行路径由模型按任务自选（six modes, one router） |
| **"全自动" Agent**（AutoGPT 一脉） | 自主性强但无验证纪律，跑飞了没人拦 | 证据先于结论（没有验证输出的切片不算完成）、三连败熔断、停滞刹车、迭代上限、硬性风控门（DB 写 / 发布 / PR 必停） |
| **Agent 产品**（Devin 类） | 黑盒 SaaS，无法审计，难以按团队规矩定制 | 全部是 Markdown + Bash，MIT 协议；把你的规矩写进知识库入口，引擎当场遵守 |
| **无人值守循环脚本**（Ralph loop 及其变体） | 静态 PROMPT.md + while true，无角色、无风控 | 同样"每迭代一个新会话"，但换成**结构化状态契约**（机器可解析的 state.md）+ 13 角色 + 退出码语义（DONE/BLOCKED/超限/停滞） |

四个最值得知道的设计决策：

1. **唯一能说"完成"的，是没写代码的那个。** maker/checker 分离贯穿到底：技术评审在过程中把关，交付评审在最后以全新会话逐条重验验收标准——迭代日志里的"我验过了"只是主张，评审自己的命令输出才是证据。
2. **Agent 会忘，仓库不忘。** 不与上下文窗口对抗：每个任务是一条任务记录（spec / plan / state），每次迭代一个干净 commit，无人值守模式下每次迭代都是全新会话读文件续跑。换机器、断网、隔一周，都能接上。
3. **引擎不带任何项目私货。** 引擎对目标项目只有四个假设：一个 `AGENTS.md` 知识入口、一组验证命令、一个任务记录位置、一组硬性红线。满足即可零改动运行——这不是口号，是被导出工具链和测试强制执行的边界。
4. **失败不白费（Ratchet）。** 每个真实踩坑被写成一条短规则，放在下一个 agent 一定会读到的位置；规则失去价值就删。系统随使用变聪明，而不是随规则膨胀变笨。

---

## 设计

### Loop ≠ 流水线

Loop 是**目标驱动系统，不是流程引擎**。一个 bug 可能是五分钟的单文件修改，也可能是一整天的跨服务排查——硬编码执行阶段会毁掉你雇 AI 来提供的判断力。引擎只定义三样东西：**目标与约束、停止条件、评审机制**。它建立在这个分层之上：

```text
Prompt Engineering   -> 教 AI 做好一件事
Context Engineering  -> 决定 AI 看到什么
Harness Engineering  -> 搭建 AI 运行的环境（工具、权限、沙箱）
Loop Engineering     -> 设计一个自己找活、派活、验活的系统
```

### 引擎 / 知识分离

最重要的架构决策：**引擎（怎么干活）与项目知识（这个项目的规矩）彻底解耦。**

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

### 单一入口与六种模式

用户只需要记住一个命令：`/ai-go:loop <目标>`。循环启动时先做一次轻量**路由**——意图、涉及仓库、写风险、不确定性、停止条件、需要的角色——然后自选执行策略：

| 模式 | 典型输入 | 默认写范围 |
| --- | --- | --- |
| `design` | "PRD → 技术方案" | 仅任务产物 |
| `dev` | "实现 X" | 代码、测试、文档（分支/worktree） |
| `fix` | "修这个 bug" | 代码、测试、文档（分支/worktree） |
| `analyze` | "为什么会发生 Y" | 只读 |
| `review` | "评审这个方案/PR" | 只读 |
| `test` | "给 Z 补测试" | 仅测试 |

### 13 个专业角色

覆盖研发全生命周期，checker 在工具层强制只读、只提意见不改代码：

产品分析 · 系统架构 · 后端架构 · 前端专家 · 移动端专家 · 数据工程 · AI 工程 · DevOps · 安全工程 · 测试工程 · 问题修复 · 技术评审 · **交付评审（唯一可置 DONE 的角色）**

完整协议见 [`engine/loop-engineering.md`](engine/loop-engineering.md)（SSOT），设计哲学与开源先例分析见 [`engine/references/loop-philosophy.md`](engine/references/loop-philosophy.md)，V1 原始设计文档见 [`skills/loop-engineering-design/`](skills/loop-engineering-design/loop-engineering-design.md)。

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
| `prompts/`、`skills/loop-engineering-design/` | 技术方案 prompt 与 V1 系统设计文档（英文） |

> **注意**：`engine/` 目录由维护者的上游工作区通过同步脚本生成，属于同步产物。请勿直接修改 `engine/` 或 `.opencode/` 下的引擎文件——改动会在下次同步时被覆盖。本仓库自有能力放在 `scripts/`、`templates/`、`tests/`。

## 测试

```bash
bash tests/engine-deployment-test.sh    # 引擎布局与 .opencode/ 副本一致性
bash tests/init-knowledge-base-test.sh  # 知识库初始化：产物、幂等、git 地址、失败路径
```

## 开源协议

本项目基于 [MIT License](LICENSE) 开源。
