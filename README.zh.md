# ai-go

> **Language**: [English](README.md) | **中文**

**Loop Engineering · Self-Improving · Trustworthy Delivery**

一个会自己干完活、并且越用越聪明的研发引擎。给它一个目标，它自主完成 研究 → 设计 → 计划 → 迭代（实现 → 验证 → 修复），直到一个"没写过这份代码"的独立评审确认全部验收标准——然后把这次踩过的坑沉淀成规则，下次不再犯。

---

## 目录

- [是什么](#是什么)
- [为什么做](#为什么做)
- [核心价值](#核心价值)
- [核心板块](#核心板块)
- [安装使用](#安装使用)
- [平台支持](#平台支持)
- [其他说明](#其他说明)
- [问题反馈与贡献](#问题反馈与贡献)
- [开源协议](#开源协议)

---

## 是什么

ai-go 是一个跑在 [OpenCode](https://opencode.ai) 上的 **loop-engineering 研发引擎**：

```text
你：/ai-go:loop 实现会员自动续费
引擎：路由 → 探索代码 → 出技术方案 → 评审 → 切片计划
      → 迭代：实现 → 跑验证 → 修复 → 提交（每片一个干净 commit）
      → 独立交付评审逐条核验验收标准 → DONE
      → 把这次踩的坑沉淀成规则（Ratchet）
```

它**不是又一个 Agent 框架**。没有 SDK、没有 DSL、没有要学的编排图——它是一份**协议**（Markdown 写成的循环契约）+ **14 个专业角色**（maker/checker 严格分离）+ **一个 harness 脚本**（无人值守驱动器）。全部实现可读、可审计、可魔改。

## 为什么做

用 AI 写代码的人迟早会撞上四堵墙：

1. **助手要人带。** 交互式助手（Copilot / Cursor / 裸用 Claude Code）由你在环内逐条指挥——AI 在打工，你在全职当监工。
2. **"完成"不可信。** 干活的 AI 自己宣布"做完了"，而它对自己的作品总是太宽容；你每次都要重新验一遍。
3. **知识随会话蒸发。** 这个会话里教会它的项目规矩、踩过的坑，下个会话全部归零，永远在重复解释。
4. **框架把路走死。** 编排框架（LangGraph / CrewAI / AutoGen）要求你预先把研发写成固定的图和流水线——可研发不是装配线，一个 bug 可能是五分钟也可能是一天，硬编码流程毁掉的恰恰是你雇 AI 来提供的判断力。

ai-go 的回答：**不造更强的助手，造一套可交付的系统**——目标进、交付出，完成由独立评审说了算，知识落在仓库里复利增长，执行路径由模型按任务自选。

## 核心价值

### 1. Loop Engineering（循环工程）

Loop 是目标驱动系统，不是流程引擎。引擎只定义三样东西：**目标与约束、停止条件、评审机制**，执行步骤交给模型判断。它位于工程能力栈的最上层：

```text
Prompt Engineering   -> 教 AI 做好一件事
Context Engineering  -> 决定 AI 看到什么
Harness Engineering  -> 搭建 AI 运行的环境（工具、权限、沙箱）
Loop Engineering     -> 设计一个自己找活、派活、验活的系统
```

### 2. Self-Improving（自进化 / 自升级）

系统**越用越聪明**，机制叫 **Ratchet（棘轮）**——只进不退：

- **每个真实失败变成一条规则**，写在下一个 agent 一定会读到的位置（知识索引、评审标准、角色文件）；
- **知识在仓库里复利**：架构认知、项目约定、历史踩坑都沉淀在 `knowledge/index.md` 与任务记录中，跨会话、跨机器、跨人复用；
- **只增有据的规则，删过时的规则**：每条规则可追溯到一次具体失败，模型进步让规则失去价值时就删掉——防止知识库膨胀成没人读的风格指南。

### 3. Trustworthy Delivery（可信交付）

- **maker/checker 分离贯穿到底**：技术评审在过程中把关，交付评审在最后以全新会话逐条重验验收标准；
- **唯一能说"完成"的，是没写代码的那个**：写代码的角色无权置 DONE；
- **证据先于结论**：迭代日志里的"我验过了"只是主张，评审自己跑出来的命令输出才是证据；验收标准只增不删，不许为了过关而改题。

### 4. Durable Memory（持久记忆）

Agent 会忘，仓库不忘。每个任务是一条任务记录（spec / plan / state），每次迭代一个干净 commit；断点续跑、跨机器恢复、隔一周接着干都没问题。不与上下文窗口对抗——无人值守模式下每次迭代都是全新会话读文件续跑。

### 5. Unattended but Braked（无人值守，但有刹车）

可以整夜自己跑，但每个刹车都是硬的：迭代上限、停滞刹车（状态连续两轮无变化即停）、三连败熔断（同一错误三轮即 BLOCKED）、硬性风控门（数据库写 / 外部写接口 / PR / 发布 / 部署必停等人）。

### 6. Portable by Contract（契约级可移植）

引擎与项目知识彻底解耦。引擎对目标项目只有四个假设：一个 `AGENTS.md` 知识入口、一组验证命令、一个任务记录位置、一组硬性红线。满足即可零改动运行——这不是口号，是被导出工具链和测试强制执行的边界（引擎文件里不允许出现任何项目私货）。

### 7. Transparent & Hackable（全透明，可魔改）

协议、角色、命令、技能全部是 Markdown，harness 是一个 Bash 脚本；MIT 协议。想改评审标准、加角色、换模型档位，打开文件就能改。

### 一张表看差异

| 对比 | 它们的模型 | ai-go 的模型 |
| --- | --- | --- |
| **交互式 AI 助手**（Copilot / Cursor / 裸用 Claude Code） | 你在环内逐条指挥，"完成"由干活的 AI 自己宣布，记忆随会话蒸发 | 目标进、交付出；独立交付评审重跑验证后才能置 DONE；记忆全落在 git 与状态文件 |
| **编排框架**（LangGraph / CrewAI / AutoGen） | 用代码把工作流写死成图，先学 SDK 再干活 | 零框架代码；协议只定义目标、停止条件与评审机制，路径由模型自选 |
| **"全自动" Agent**（AutoGPT 一脉） | 自主性强但无验证纪律，跑飞了没人拦 | 证据先于结论 + 三连败熔断 + 停滞刹车 + 硬性风控门 |
| **Agent 产品**（Devin 类） | 黑盒 SaaS，无法审计，难按团队规矩定制 | 全部 Markdown + Bash，MIT；把规矩写进知识入口，引擎当场遵守 |
| **无人值守循环脚本**（Ralph loop 及变体） | 静态 PROMPT.md + while true，无角色无风控 | 结构化状态契约 + 14 角色 + 退出码语义（DONE/BLOCKED/超限/停滞） |

## 核心板块

```text
┌─────────────────────────────────────────────────┐
│  engine/  （引擎：可移植，项目无关）                │
│  循环协议 · 14 个角色子代理 · loop 命令/技能 ·      │
│  无人值守 harness                                 │
└──────────────────────┬──────────────────────────┘
                       │ 运行时通过知识入口加载
                       ▼
┌─────────────────────────────────────────────────┐
│  目标项目的知识库（由 init-knowledge-base.sh 初始化）│
│  AGENTS.md（入口：验证命令、红线、约定）             │
│  knowledge/index.md（架构、约定、踩坑 → 自进化载体） │
│  tasks/（任务记录：spec / plan / loop 状态）        │
└─────────────────────────────────────────────────┘
```

| 板块 | 位置 | 说明 |
| --- | --- | --- |
| **循环协议（SSOT）** | `engine/loop-engineering.md` | 路由、六种模式（design/dev/fix/analyze/review/test）、多仓库规则、状态格式、迭代契约、停止条件、风险控制、Ratchet |
| **14 个专业角色** | `engine/agents/` | 命名即分层：`*-architect` 出方案（系统、后端、数据、AI、安全五位架构师，strong 档），`*-engineer` 精准执行（后端、前端、移动端、DevOps、测试五位工程师，execution 档），外加流程角色（产品分析、问题修复、技术评审、**交付评审——唯一可置 DONE**） |
| **单一入口** | `engine/commands/loop.md` | `/ai-go:loop <目标>`，内部路由，用户无需预判任务类型 |
| **会话技能** | `engine/skills/ai-go-loop/` | "loop this task"、"自动迭代交付" 等短语直接触发 |
| **无人值守 harness** | `engine/scripts/loop-run.sh` | 每迭代一个全新会话，退出码语义化，自带各种刹车 |
| **行为评测** | `engine/evals/` | 压力场景 + LLM 裁判：证明模型在诱惑下**真的遵守协议**，而不只是文件里写了。场景库靠真实使用生长：Ratchet 评测车道和 `/ai-go:autopsy` 把观察到的违规倾向变成场景草稿；`--ledger` 记录通过率趋势 |
| **知识库初始化器** | `scripts/init-knowledge-base.sh` | 一条命令让任何项目具备运行引擎的全部前提 |
| **模板与测试** | `templates/`、`tests/` | 知识库脚手架模板、OpenCode 模型绑定示例；脚本与部署的契约测试 |

## 安装使用

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
| `.opencode/` | 引擎的命令、技能、14 个角色代理（项目级加载；`--no-opencode` 跳过） |
| `.gitignore` | 追加 `tasks/**/loop/logs/`（harness 运行日志不入库） |

初始化后的加载语义是**分层**的：**知识库自动加载**（`.opencode/opencode.json` 的 `instructions` 让 `AGENTS.md` 进入该项目的每个会话）；**命令按需**（敲 `/ai-go:loop` 才执行）；**角色代理与 loop 技能按需**——配置把 `ai-go-*` 的 `task`/`skill` 权限设为 `ask`，AI 不能自作主张把活派给角色或进入循环模式，除非你亲自触发（`@ai-go-...` 提及、`/ai-go:loop`）或批准；无人值守 harness 以 `--auto` 运行，这些交互门不会卡住它。

然后补全 `AGENTS.md` 与 `knowledge/index.md` 里的 TODO（尤其是验证命令和红线）。可以手工填，也可以让引擎自己探索补全——在项目里启动 OpenCode 后运行：

```text
/ai-go:loop fill in the knowledge base: explore this repository and complete every TODO in AGENTS.md and knowledge/index.md, grounded in the actual code; write scope: those two files only
```

### 2.（可选）把引擎装到更多作用域

**引擎默认只在你指定的项目里生效**：第 1 步的初始化已经把命令、技能、角色部署到目标项目的 `.opencode/`——只有在该项目里启动 OpenCode 才会加载，不会污染其他目录。需要更多作用域时用安装脚本（作用域必须显式指定）：

```bash
scripts/install-opencode-engine.sh --workspace <root>       # 让某个项目/工作区生效
scripts/install-opencode-engine.sh --global                 # 全局：/ai-go:loop、/ai-go:design 等在任意项目可触发
scripts/install-opencode-engine.sh --uninstall --global     # 移除之前的全局安装
```

全局安装是安全的：引擎本身不含任何项目知识（知识库始终按项目加载），且安装器会在全局配置写入/提示按需门控（`ai-go-*` 的 `task`/`skill` 设为 `ask`）——命令和角色随处**可用**，但绝不**自动**参与任务，被动进入多 Agent/loop 模式前必先征得你同意。

安装/卸载后重启 OpenCode。角色代理是 `mode: subagent`，不会出现在 Tab 主代理切换器里；在输入框输入 `@ai-go` 即可看到全部 14 个。

### 3.（推荐）绑定 strong / execution 模型

**不绑定时，子代理会继承主会话的模型**，协议里的 strong/execution 分档不会自动生效——而循环耗时主要取决于模型延迟，这是收益最大的一项配置。

**推荐方式：让主 Agent 自己来。** 在 OpenCode 里运行 `/ai-go:models`，三种用法：

- `/ai-go:models show` — **查看**：打印生效模型总表（主 Agent build、plan、14 个角色子代理、compaction），标注每个绑定的来源（哪个配置文件/继承自主模型）——这也是核对"某个子 Agent 执行时用什么模型"的权威方式；
- `/ai-go:models` — **一键配置**：读取可用模型列表，给出整套配比建议（默认「最强推理 + 同厂经济型执行 + 便宜压缩」，如 GPT-5.5 + GPT-5.4-mini，或 Claude Opus 4.8 + Claude Sonnet 4.6），展示旧 → 新对照，一次确认后写入；
- `/ai-go:models --interactive` — **逐项配置**：主模型、Plan 模型、强档（9 个角色）、执行档（5 个角色）、压缩模型五个决策逐个过，每项给出建议和备选，由你亲自挑选，最后还可对单个角色微调。

要更新时（新模型上线、想换配比）重跑即可（确认后覆盖引擎旧绑定，你手动加的其他配置不受影响）；`--reset` 清除引擎绑定，恢复"子代理继承主会话模型"的默认行为。配置在进程启动时加载，重启 OpenCode 后（包括 resume 旧会话）即生效。

**手动方式**：从模板 [`templates/opencode-model-binding.example.json`](templates/opencode-model-binding.example.json) 开始，合并进 `~/.config/opencode/opencode.json`（全局）或工作区根 `opencode.json`（项目级，优先级更高）。三个要点：

- 把示例模型 ID 换成你实际可用的（`opencode models` 可列出）；
- 保留每项的 `"mode": "subagent"`——否则 OpenCode 会把配置过的 agent 当成 primary，挤进 Tab 切换器；
- 模板同时开启了自动 compaction（`auto` + `prune`）并给压缩本身绑了便宜模型。长任务优先靠任务记录断点续跑（`/ai-go:loop tasks/<task>`），compaction 只作兜底。

### 4. 日常使用

在目标项目中打开 OpenCode：

| 想做什么 | 怎么做 |
| --- | --- |
| 开发一个功能 | `/ai-go:loop implement <目标>` |
| 修一个 bug | `/ai-go:loop <问题描述>` 或 `--mode fix` |
| 只分析不改代码 | `/ai-go:loop --readonly <问题>` |
| 只要技术方案 | `/ai-go:design <PRD 或目标>` — 独立技能，任意项目可用（探索 → 大纲确认 → 完整方案）；要带任务记录的循环则用 `/ai-go:loop --mode design` |
| 评审设计或 PR | `/ai-go:loop --mode review <对象>`，或直接 `@ai-go-tech-reviewer` |
| 咨询单个专家 | `@` 任意角色（如 `@ai-go-backend-architect`、`@ai-go-security-architect`） |
| 恢复中断的循环 | `/ai-go:loop tasks/<task>`（状态都在任务记录里） |
| 复盘跑完的循环 | `/ai-go:autopsy tasks/<task>` — 从记录里挖掘违规倾向与合理化说辞，产出评测场景草稿和协议修订建议 |

循环在以下节点必定暂停等人确认：路由歧义/高风险、大爆炸半径的设计、数据库或外部写操作、PR/发布/部署。

### 5. 无人值守运行

```bash
engine/scripts/loop-run.sh --task <task-dir> --workspace <项目根> \
  [--max-iterations 10] [--iteration-timeout 1800] [--agent <只读agent>]
```

每次迭代启动一个全新 `opencode run` 会话，迭代间通过 `state.md` 交接。退出码：`0` DONE、`2` BLOCKED、`3` 达到迭代上限、`4` 协议/运行错误、`5` 停滞。

加 `--edit-scope '<path>/**'`（可重复）可以**在权限层锁定写边界**：列出范围（外加任务目录）之外的文件编辑会被显式 deny 规则拒绝，且该规则在 `--auto` 下依然生效——路由判定的 Write-Scope 从"提示词约定"变成"机器强制"。

`--runner claude` 用 Claude Code（`claude -p`）驱动迭代（实验性；`--agent`/`--edit-scope` 仅限 opencode）。每次运行会把统计（runner、迭代数、退出原因、耗时）追加到任务的 `loop/harness-runs.jsonl`。

> ⚠️ 非交互模式会自动批准所有权限。只在可接受无人值守修改的仓库和特性分支上运行，优先使用沙箱/容器环境，凭证从紧配置。运行前请阅读 `engine/loop-engineering.md` 的 "Unattended Safety" 一节。

## 平台支持

引擎的协议、角色、命令全部是纯 Markdown，harness 是 Bash——适配一个新平台主要是"资产格式转换 + 加载路径映射"，不涉及引擎逻辑改动：

| 平台 | 状态 | 适配说明 |
| --- | --- | --- |
| **OpenCode** | ✅ 已支持 | 一等公民：`.opencode/` 项目级部署（默认，只在指定项目生效）+ 可选全局安装，`/ai-go:loop`、技能、14 个子代理开箱即用 |
| **Claude Code** | 🧪 实验性 | `scripts/install-claude-code.sh`（agent 即时转换、命令带命名空间、loop 技能）；无人值守用 `loop-run.sh --runner claude`。尚未跑完完整验收循环——欢迎反馈 |
| **Cursor** | 🗺️ 规划中 | 知识入口 → Cursor rules，loop 命令 → Cursor commands，子代理经由其 agent 机制加载 |
| **Codex** | 🗺️ 规划中 | 角色代理 → TOML 配置，harness 的 `opencode run` 换成对应 CLI 调用（`OPENCODE_BIN` 已可注入） |

想优先支持某个平台，或愿意贡献适配？请开一个 [Issue](https://github.com/MonsterStorm/ai-go/issues) 或直接提 PR——适配的验收标准很简单：在该平台上跑通 `设计 → 迭代 → 独立评审置 DONE` 的完整循环。

## 其他说明

- **文档语言约定**：技术文档按语言分文件，命名 `<name>.zh.md` / `<name>.en.md`，未来可扩展更多语言（如 `<name>.ja.md`）。当前双语文档：
  - 本 README：[English](README.md)（默认展示）| **中文**
  - PRD → 技术方案 prompt：[English](prompts/prompt-prd-to-tech-design.en.md) | [中文](prompts/prompt-prd-to-tech-design.zh.md)
  - V1 系统设计（设计历史）：[English](skills/loop-engineering-design/loop-engineering-design.en.md) | [中文](skills/loop-engineering-design/loop-engineering-design.zh.md)
- **引擎目录是同步产物**：`engine/` 由维护者的上游工作区通过同步脚本生成，请勿直接修改 `engine/` 或 `.opencode/` 下的引擎文件——改动会在下次同步时被覆盖。本仓库自有能力放在 `scripts/`、`templates/`、`tests/`。
- **测试**：

```bash
bash tests/engine-deployment-test.sh    # 引擎布局与 .opencode/ 副本一致性
bash tests/init-knowledge-base-test.sh  # 知识库初始化：产物、幂等、git 地址、失败路径
```

- **行为评测**：`engine/evals/eval-run.sh` 用真实会话跑压力场景并由 LLM 裁判打分（消耗 token，不进 CI）。改动协议承重规则后运行；每条新硬规则都要配一个回归场景。
- **深入阅读**：协议 SSOT [`engine/loop-engineering.md`](engine/loop-engineering.md)；设计哲学与开源先例 [`engine/references/loop-philosophy.md`](engine/references/loop-philosophy.md)；浏览器验证手册 [`engine/references/browser-verification.md`](engine/references/browser-verification.md)。

## 问题反馈与贡献

- **Bug / 需求 / 讨论**：[GitHub Issues](https://github.com/MonsterStorm/ai-go/issues)。报告循环相关问题时，请附上任务记录（`spec.md` / `plan.md` / `loop/state.md` 的相关片段），这是定位问题最快的证据。
- **欢迎的贡献方向**：新平台适配（Claude Code / Cursor / Codex）、知识库模板改进、文档翻译（按 `<name>.<lang>.md` 约定）、契约测试补充。
- **改动约定**：`engine/` 不接受直接修改（同步产物）；脚本类改动请保证 `tests/` 全绿。

## 开源协议

本项目基于 [MIT License](LICENSE) 开源。
