# Loop-Engineering 系统设计

> Loop Engineering is replacing yourself as the person who prompts the agent. You design the system that does it instead. — Addy Osmani

---

## 1. 什么是 Loop-Engineering

Loop-Engineering 是一套基于 AI Coding Agent 的自动化研发系统。它不是一个流程引擎，而是一个 **Goal-Driven 的循环系统**：你给出目标和停止条件，系统自行决定如何达成，在必要时征求你的确认，并在完成后沉淀经验。

### 1.1 设计哲学

本系统的设计基于三个核心范式的层叠关系：

```
Prompt Engineering  →  你教 AI 怎么做一件事
Context Engineering →  你决定 AI 看到什么信息
Harness Engineering →  你搭建 AI 运行的脚手架（工具、钩子、沙箱、权限）
Loop Engineering    →  你设计一个能自己发现工作、分配工作、检查工作的系统
```

**关键区别：** Loop 不替代 Prompt。一个 Loop 由许多 Prompt 组成。糟糕的 Prompt 在 Loop 里只会更快地产出垃圾。Loop 是 Prompt 之上的一层编排，不是替代。

### 1.2 为什么不是流程引擎

研发不是流水线。一个 bug 修复可能只需要 5 分钟的单文件改动，也可能需要跨 3 个服务反复定位一整天。把研发硬编码成"阶段 1 → 阶段 2 → 阶段 3"的固定步骤，会约束 agent 的判断力——而判断力恰恰是你需要 AI 提供的核心价值。

Loop-Engineering 的做法是：**给目标，给约束，给工具，让 agent 自己决定路径。** 你设计的是停止条件和审查机制，不是执行步骤。

### 1.3 核心原则

以下原则指导本系统的一切设计决策：

1. **Agent 是模型 + Harness。** 模型提供智能，Harness 提供双手、眼睛、记忆和安全边界。OpenCode 本身就是 Harness——我们配置它，不绕过它。

2. **信任模型，在边界执行。** 不要通过 prompt 期望 agent 自我约束。在 tool/sandbox/permission 层面执行规则。

3. **Maker/Checker 分离。** 写代码的 agent 不能自己给自己打分。独立的 checker agent 用不同的标准审查产出。这是质量的唯一保证。

4. **每次错误变成一条规则（Ratchet）。** 发现 agent 犯了一个错误？不要"下次记得告诉它"——把这个错误编码成 skill 中的一条规则，让它永远不会再犯。好的 AGENTS.md 里每一行都能追溯到一次具体的失败。

5. **Agent 忘记，Repo 不忘记。** 模型在两次运行之间遗忘一切。记忆必须在磁盘上——progress.md、git commit、文档文件——而不是在上下文窗口里。

6. **飞行员检查清单，不是风格指南。** AGENTS.md 和 Skill 要短、精确、每条有来历。60 行胜过 600 行。越多的规则让每条规则越不重要。

7. **Sub-agent 是领域专家，不是通用助手。** 每个 sub-agent 都必须是具备领域知识的专家，同时对当前业务场景和系统现状了如指掌。它给出的不是泛泛而谈的通用方案，而是深度结合了业务场景、系统架构、技术约束的针对性方案。

---

## 2. Loop 的六个原语

基于 Addy Osmani 和 Anthropic 的研究，一个完整的 Loop 由六个原语构成。本系统在 OpenCode 平台上实现全部六个：

### 2.1 Automations（心跳）

**让 Loop 真正循环起来的东西。** 不是你手动一步步推进，而是系统自己发现工作、分配工作、检查结果。

在本系统中，Automation 的形态是 **Command**（`/dev`、`/fix`、`/analyze`）。每个 Command 定义的是一个 Goal 和停止条件，而不是一个固定流程。Agent 收到 Goal 后，自行规划执行路径，循环直到停止条件满足。

```
/dev <需求描述>     → Goal: 需求功能可工作，测试通过，代码符合工程规范
/fix <issue描述>    → Goal: 问题根因定位，修复已验证，回归测试通过
/analyze <问题描述> → Goal: 问题定位到具体代码和逻辑，给出可信分析结论
```

### 2.2 Worktrees（并行隔离）

两个 agent 同时写同一个文件 = 两个工程师同时改同一行代码但没沟通。Git worktree 给每个 agent 一个独立的工作目录，共享同一个 repo 历史，互不干扰。

在本系统中，`/fix` 命令会自动在独立 worktree 中工作（遵循现有项目的分支规范），完成后生成 PR。`/dev` 同理，在 feature branch 上工作。

### 2.3 Skills（编码的项目知识）

Skill 是你停止每次都向 agent 重新解释项目上下文的方式。没有 Skill，Loop 每次都从零开始推导你的整个项目；有了 Skill，知识可以复利。

本系统的 Skill 分为两层：

- **通用 Skill**（`loop-engineering/SKILL.md`）：定义 Loop 系统的运作方式——六原语、停止条件判断、Ratchet 机制、progress 文件格式
- **领域 Skill**（通过 references 加载）：研发流程、代码审查标准、测试策略等。这些是 Ratchet 的载体——每次发现的"不要犯的错"都沉淀在这里

**关键：Skill 是 Ratchet 的载体。** Agent 犯的每个错误，最终都会变成 Skill 中的一条规则。这是系统持续进化的机制。

### 2.4 Connectors（连接真实工具）

一个只能看文件系统的 Loop 是一个很小的 Loop。Connectors（通过 MCP）让 agent 能读 issue tracker、查数据库、访问 staging API、在群里发消息。

本系统第一版聚焦研发工程核心流程，Connector 暂时通过 bash 工具间接实现（如 `medeo-dev psql --stg` 查数据库）。后续可通过 MCP 扩展到飞书通知、issue 管理、CI/CD 触发等。

### 2.5 Sub-agents（Maker/Checker 分离）

**Loop 中最重要的结构决策：写的人和查的人必须分开。** 写代码的 agent 对自己的作品太宽容了。一个独立的 agent 用不同的 prompt、不同的关注点，能抓住第一个 agent 说服自己忽略的问题。

本系统定义 5 个 sub-agent，每个都是特定领域的专家：

| Sub-agent | 角色 | 模型档位 | 权限 | 核心能力 |
|-----------|------|----------|------|----------|
| **architect** | 技术方案设计者 | 强力模型 | 只读 + write 方案文档 | 深度理解业务场景和系统架构，产出高质量技术方案 |
| **coder** | 代码实施者 | 执行模型 | 读写 + bash | 按方案高效编码，遵循项目工程规范 |
| **checker** | 独立审查者 | 强力模型 | 只读 | 从 PRD 符合度、工程规范、安全性、性能、扩展性多维度审查 |
| **tester** | 测试执行者 | 执行模型 | 读写 + bash | 编写并运行单元测试、API 测试、E2E 测试 |
| **investigator** | 问题定位者 | 强力模型 | 只读 + bash（只读命令） | 复现问题、分析日志、定位代码风险点 |

**模型档位说明：**

- **强力模型**（设计、审查、定位）：Claude Opus 4.8/4.6、GPT-5.5 —— 需要深度推理、全局判断、架构思维的任务
- **执行模型**（编码、测试）：Claude Sonnet 4.6/4.5、GPT-5.4-mini、Claude Haiku 4.6 —— 需要快速准确执行、遵循明确指令的任务

### 2.6 State（持久记忆）

Agent 在两次运行之间遗忘一切。State 必须在磁盘上，不在上下文窗口里。

本系统的 State 分为三层：

**层 1：Progress 文件（`.loop/progress.md`）**

每次 Loop 运行时，在项目根目录生成或更新 `.loop/progress.md`，记录：
- 当前目标和停止条件
- 已完成的工作（带 git commit hash）
- 待解决的问题
- Checker 的审查意见
- 下一步建议

如果 session 中断，下次可以读这个文件接上。这就是跨 session 的记忆。

**层 2：产物文件（`.loop/artifacts/`）**

每次 Loop 产出的关键文件保存在这里：
- 技术方案文档
- 审查报告
- 测试报告
- 问题分析报告

这些文件是过程的沉淀，方便回溯和复盘。

**层 3：经验索引（`knowledge/index.md`）**

一个轻量索引文件，指向项目中真实存在的经验知识——系统架构文档、编码规范、部署规约、历史踩坑记录等。不重复存储，只是把分散在各处的重要信息组织起来。随着 Loop 的使用自然增长。

---

## 3. Sub-agent 详细设计

### 3.1 设计原则：领域专家 + 场景专家

每个 sub-agent 不是一个"换了提示词的通用 AI"，而是一个 **双重专家**：

1. **领域专家**：具备该角色所需的专业知识体系（架构设计方法论、代码审查标准、测试策略、故障排查方法论等）
2. **场景专家**：对当前项目的业务场景、系统架构、技术栈、工程规范了如指掌

实现方式：每个 sub-agent 的 prompt 分为两部分——

- **角色定义**（相对固定）：该角色的专业知识和行为准则
- **场景注入**（动态加载）：通过读取项目的 `AGENTS.md`、`knowledge/index.md`、以及 Skill 中的 references，获取当前项目的具体上下文

这意味着 **同一个 architect agent 在不同项目中的行为完全不同**——它会基于该项目的真实架构、真实约束、真实历史来做设计决策，而不是给出通用的最佳实践。

### 3.2 Architect（技术方案设计者）

**职责：** 接收需求（PRD、issue、口头描述），结合对业务场景和系统现状的深度理解，产出可落地的技术方案。

**核心行为：**

- **先探索，后设计。** 在给出任何方案之前，必须先自主探索代码仓库、数据库结构、已有文档，建立对现状的充分理解
- **方案必须扎根于现实。** 不是"理论上可以用消息队列"，而是"基于当前 order-service 已经接入的 Kafka 集群，在 order-completed topic 上新增 consumer group"
- **显式权衡。** 每个设计决策都要说明为什么选这个方案、考虑过哪些替代方案、选择的理由是什么
- **重点关注扩展性、稳定性、安全性。** 不是功能能跑就行，而是要考虑：数据量增长 10x 后怎么办？这个服务挂了影响什么？有没有数据泄露风险？

**权限：** 只读代码和文档 + 只读数据库查询 + 写方案文档到 `.loop/artifacts/`

**模型：** 强力模型（Claude Opus 4.8/4.6 或 GPT-5.5）。方案设计需要全局架构视野和深度推理。

### 3.3 Coder（代码实施者）

**职责：** 按照技术方案（或 checker 反馈），高效准确地完成代码编写。

**核心行为：**

- **遵循项目工程规范。** 代码风格、目录结构、命名约定、错误处理模式——一切以项目现有规范为准，不自创风格
- **增量实施，频繁提交。** 不是写完所有代码一次性提交，而是每完成一个逻辑单元就 commit，commit message 描述清楚做了什么
- **编码即文档。** 关键逻辑加注释，复杂函数加 docstring，接口变更更新 API 文档

**权限：** 读写文件 + bash 全权限

**模型：** 执行模型（Claude Sonnet 4.6 或 GPT-5.4-mini）。编码任务需要快速准确执行，不需要最强推理力。

### 3.4 Checker（独立审查者）

**职责：** 独立于 maker 之外，从多个维度审查产出物的质量。

**核心行为：**

这是整个系统质量的守门人。Checker 拿到的是 maker 的产出（技术方案文档、代码 diff、测试结果），用独立的标准审查。它不知道 maker 是怎么实现的，只看结果。

审查维度：

| 维度 | 关注点 |
|------|--------|
| **PRD 符合度** | 每个需求点是否都有对应的实现？有无遗漏？ |
| **工程规范** | 代码是否符合项目现有规范？目录结构、命名、错误处理是否一致？ |
| **安全性** | 有没有 SQL 注入、XSS、越权访问、敏感数据泄露风险？ |
| **性能** | 有没有 N+1 查询？大数据量下会不会成为瓶颈？索引是否合理？ |
| **扩展性** | 硬编码？魔法数字？如果未来需求变化，改动成本高不高？ |
| **稳定性** | 异常处理是否完备？依赖服务挂了会怎样？有没有降级策略？ |
| **测试覆盖** | 关键路径有没有测试？边界条件有没有覆盖？ |

**审查输出格式：**

```markdown
## 审查结果：PASS / NEEDS_WORK / BLOCK

### 通过项
- [x] PRD 功能点 A 已实现且符合预期
- [x] 数据库索引设计合理

### 需要改进
- [ ] order-service 的 createOrder 方法缺少对 amount <= 0 的校验
- [ ] 新增的 API 没有鉴权中间件

### 阻断项（必须修复才能继续）
- [ ] 用户密码以明文存储在日志中（安全风险）
```

**权限：** 完全只读。Checker 不能修改任何代码——它只能提出意见，修复由 coder 执行。

**模型：** 强力模型（Claude Opus 4.8/4.6 或 GPT-5.5）。审查需要对工程质量有全面深入的判断。

### 3.5 Tester（测试执行者）

**职责：** 编写并运行各层级的测试，确保代码质量。

**核心行为：**

- **分层测试策略。** 根据改动范围决定测试层级——小改动跑单元测试即可，涉及接口变更跑 API 测试，涉及用户流程跑 E2E 测试
- **测试必须跑通，不是写完就算。** 写完测试后必须实际执行，确认通过。测试失败的信息要反馈给 coder
- **覆盖正常路径和边界条件。** 不是只测 happy path，异常输入、边界值、并发场景都要覆盖

测试层级：

| 层级 | 场景 | 工具 |
|------|------|------|
| 单元测试 | 函数/方法级别的逻辑验证 | 项目现有测试框架 |
| API 测试 | 接口的请求/响应/错误码验证 | 项目现有测试框架或 curl/httpie |
| 集成测试 | 多模块/服务间的协作验证 | 项目现有测试框架 |
| E2E 测试 | 完整用户流程验证 | Playwright / Puppeteer / 项目现有工具 |
| 性能测试 | 响应时间、吞吐量验证 | k6 / wrk / 项目现有工具 |

**权限：** 读写文件 + bash 全权限

**模型：** 执行模型（Claude Sonnet 4.6 或 Claude Haiku 4.6）。测试编写和执行是明确的任务，不需要最强推理力。

### 3.6 Investigator（问题定位者）

**职责：** 接收 issue 或问题描述，系统性地定位到具体的代码和逻辑。

**核心行为：**

- **先复现，后分析。** 尝试在相同环境中复现问题，获取第一手的错误日志和堆栈信息
- **日志是证据。** 不做主观猜测。每个结论必须有日志、代码、数据作为支撑。"我觉得可能是 X"不可接受，"日志第 42 行显示 Y，对应代码 Z 的第 N 行的逻辑是..."才可接受
- **多轮收敛。** 通常需要多轮分析才能定位根因——先缩小范围到服务/模块，再定位到具体函数/行，最后确认根因和影响面
- **评估影响面。** 不只是找到 bug，还要评估：这个问题影响多少用户？有没有数据损坏？修复方案的影响面是什么？

**权限：** 只读代码 + 只读 bash（查日志、查数据库、curl 测试接口）。不修改任何代码。

**模型：** 强力模型（Claude Opus 4.8/4.6 或 GPT-5.5）。问题定位需要深度推理和全局视野。

---

## 4. 三个 Loop 的设计

### 4.1 `/dev` — 研发循环

**Goal：** 需求功能可工作，测试通过，代码符合工程规范，Checker 审查通过。

**停止条件：**
- Checker 给出 PASS 评价
- 所有相关测试通过
- 代码已提交到 feature branch

**分级控制：**

| 操作 | 风险 | 控制方式 |
|------|------|----------|
| 代码仓库探索、文档阅读 | 低 | 自动执行 |
| 技术方案设计 | 中 | 自动执行，完成后**暂停等待用户确认** |
| 代码编写、测试编写 | 低 | 自动执行 |
| Checker 审查 | 低 | 自动执行 |
| 根据审查意见修改代码 | 低 | 自动执行 |
| 创建 PR / 发布操作 | 高 | **暂停等待用户确认** |

**Maker/Checker 循环：**

```
用户: /dev <需求>
  │
  ├─ [architect] 探索项目 → 设计技术方案
  │   └─ [checker] 审查方案 → PASS / NEEDS_WORK
  │       └─ NEEDS_WORK → architect 修改 → checker 再审 → ... (循环)
  │
  ├─ ⏸ 用户确认技术方案
  │
  ├─ [coder] 按方案编码，增量提交
  │   └─ [tester] 编写并运行测试
  │       └─ 测试失败 → coder 修复 → tester 再跑 → ... (循环)
  │
  ├─ [checker] 审查代码 + 测试 → PASS / NEEDS_WORK
  │   └─ NEEDS_WORK → coder 修复 → checker 再审 → ... (循环)
  │
  └─ ⏸ 用户确认，创建 PR
```

注意：这不是一个固定的流程图。Agent 有权根据需求的复杂度跳过步骤或调整顺序。简单的改动可能不需要完整的技术方案；复杂的改动可能需要多轮 architect-checker 来回。上图只是展示最常见的路径。

### 4.2 `/fix` — 修复循环

**Goal：** 问题根因已定位，修复已实施，回归测试通过，Checker 审查通过。

**停止条件：**
- 问题已复现并定位到具体代码
- 修复代码通过所有相关测试
- Checker 确认修复方案合理且无副作用
- 代码已提交到 fix branch

**分级控制：**

| 操作 | 风险 | 控制方式 |
|------|------|----------|
| 问题复现、日志分析 | 低 | 自动执行 |
| 根因定位、影响面评估 | 低 | 自动执行 |
| 修复方案确认 | 中 | 自动执行，但 investigator 分析结果会**展示给用户** |
| 代码修复、测试 | 低 | 自动执行 |
| Checker 审查 | 低 | 自动执行 |
| 创建 PR | 高 | **暂停等待用户确认** |

**循环结构：**

```
用户: /fix <issue 描述>
  │
  ├─ [investigator] 复现问题 → 分析日志 → 定位根因 → 评估影响面
  │   └─ 输出：问题分析报告（代码位置、根因、影响面、建议修复方案）
  │
  ├─ [coder] 在独立 worktree 上修复
  │   └─ [tester] 运行回归测试
  │       └─ 测试失败 → coder 修复 → tester 再跑 → ... (循环)
  │
  ├─ [checker] 审查修复 → 无副作用？回归测试覆盖充分？
  │   └─ NEEDS_WORK → coder 修复 → checker 再审 → ... (循环)
  │
  └─ ⏸ 用户确认，创建 PR
```

### 4.3 `/analyze` — 分析循环

**Goal：** 问题定位到具体代码和逻辑，给出有证据支撑的分析结论。

**停止条件：**
- 分析结论指向具体的应用、代码文件、函数和行号
- 每个结论有日志、代码或数据作为证据支撑
- 输出了结构化的分析报告

**特殊之处：** 这个 Loop **完全只读**，不修改任何代码。只用 investigator agent。

```
用户: /analyze <问题描述>
  │
  └─ [investigator] 
      ├─ 定位相关系统和应用
      ├─ 阅读代码逻辑
      ├─ 查询日志和数据（如需要）
      ├─ 多轮分析收敛
      └─ 输出：分析报告（代码位置、逻辑说明、问题成因、建议）
```

---

## 5. 文件结构

```
ai-go/
├── opencode/                              # 安装到目标项目的 .opencode/ 下
│   ├── agents/
│   │   ├── architect.md                   # 技术方案设计者
│   │   ├── coder.md                       # 代码实施者
│   │   ├── checker.md                     # 独立审查者
│   │   ├── tester.md                      # 测试执行者
│   │   └── investigator.md                # 问题定位者
│   ├── commands/
│   │   ├── dev.md                         # /dev — 研发循环入口
│   │   ├── fix.md                         # /fix — 修复循环入口
│   │   └── analyze.md                     # /analyze — 分析循环入口
│   └── skills/
│       └── loop-engineering/
│           ├── SKILL.md                   # 核心 Skill：Loop 系统运作方式
│           └── references/
│               ├── dev-workflow.md        # 研发循环的领域知识
│               ├── fix-workflow.md        # 修复循环的领域知识
│               ├── review-criteria.md     # Checker 审查标准（Ratchet 载体）
│               ├── test-strategy.md       # 测试策略
│               └── progress-format.md     # State 文件格式规范
├── prompt-prd-to-tech-design.md           # 已有的 PRD → 技术方案 prompt（将被 architect 复用）
├── install.sh                             # 安装脚本
└── README.md
```

### 安装方式

```bash
# 在目标项目根目录执行
curl -fsSL https://raw.githubusercontent.com/MonsterStorm/ai-go/main/install.sh | bash
```

`install.sh` 做的事情很简单：
1. 将 `opencode/agents/` 复制到 `.opencode/agents/`
2. 将 `opencode/commands/` 复制到 `.opencode/commands/`
3. 将 `opencode/skills/` 复制到 `.opencode/skills/`
4. 确保 `.opencode/package.json` 包含 `@opencode-ai/plugin` 依赖（如果有 tools 需要）
5. 在 `.gitignore` 中添加 `.loop/` 目录（progress 和 artifacts 不提交到代码仓库）

安装后，在项目中打开 OpenCode 即可使用 `/dev`、`/fix`、`/analyze` 命令。

---

## 6. 知识沉淀机制

### 6.1 Ratchet：每次错误变成规则

这是系统持续进化的核心机制。当 Loop 运行中发现问题时：

1. **Checker 发现的问题** → 如果是系统性问题（不只是这一次的个例），写入 `review-criteria.md`
2. **测试反复失败的模式** → 写入 `test-strategy.md`
3. **Agent 反复犯的错误** → 写入对应 agent 的 prompt 或项目的 `AGENTS.md`

**原则：只在真实失败发生时添加规则，不预设规则。** 每条规则都能追溯到一次具体的失败。当模型进步让某条规则不再需要时，删掉它。

### 6.2 经验索引

`knowledge/index.md` 是一个轻量级的索引文件，不重复存储信息，只组织指针：

```markdown
# 项目知识索引

## 系统架构
- [order-service 架构文档](link-to-internal-doc)
- [数据库 ER 图](link-to-internal-doc)

## 工程规范
- [Go 编码规范](link-to-internal-doc)
- [API 设计规范](link-to-internal-doc)
- [数据库变更规范](link-to-internal-doc)

## 历史踩坑
- 2024-03: order-service 的 Redis 连接池泄露 → 改用 pgxpool（见 PR #234）
- 2024-06: 用户并发下单导致库存超卖 → 使用分布式锁（见技术方案 xxx）

## 发布规约
- [泳道发布流程](link-to-internal-doc)
- [stg/prd 发布检查清单](link-to-internal-doc)
```

这个文件会随着 Loop 的使用自然增长。每次 architect 在设计方案时引用了某个文档，或 investigator 在分析问题时发现了某个历史教训，都会顺手更新索引。

---

## 7. 与现有工具的关系

### 7.1 复用 prompt-prd-to-tech-design.md

你已有的 PRD → 技术方案 prompt 是一份优秀的、经过验证的领域知识。在本系统中，它的核心内容会被拆解复用到：

- **architect agent 的 prompt**：角色定义、工作方法论（先探索后设计、必问项/按需问）
- **dev-workflow.md skill reference**：技术方案的文档模板、输出规范
- **review-criteria.md**：方案审查的维度

这样做的好处是：单独的 prompt 只能在手动模式下使用，拆解后的知识可以在 Loop 的自动循环中被不同 agent 引用。

### 7.2 与 OpenCode 原生能力的关系

本系统不重新发明轮子，而是配置和编排 OpenCode 已有的能力：

| 需求 | 本系统的做法 | 不做的事 |
|------|-------------|---------|
| 循环控制 | Command 定义 Goal + 停止条件，agent 自行循环 | 不写 Plugin 控制状态机 |
| 权限管控 | 用 OpenCode 的 agent permission 系统 | 不写自定义 gate tool |
| 模型选择 | 在 agent 定义中指定 model | 不动态切换模型 |
| 上下文管理 | 依赖 OpenCode 的 compaction + skill 按需加载 | 不自己管理 context window |
| 并行隔离 | 依赖 git worktree | 不自己管理文件锁 |

---

## 8. 扩展路线

本设计是 V1，聚焦研发工程核心流程。以下是明确的扩展方向：

### Phase 2：工程协作
- 泳道部署自动化（通过项目的 CI/CD 脚本）
- 飞书群通知（通过 lark-im MCP）
- Issue 自动关联和状态更新

### Phase 3：多平台支持
- Claude Code 适配（agents 转为 `.claude/agents/` 格式，commands 转为 slash commands）
- Codex 适配（agents 转为 TOML 格式）

### Phase 4：高级 Loop 模式
- `/goal` 模式：不限于单次 session，定义一个持续运行直到条件满足的 goal
- 定时 Automation：每日自动扫描 CI 失败、新 issue，主动发起修复
- 跨项目 Loop：一个需求涉及多个服务时，在多个 worktree 中并行工作

---

## 9. 风险与缓解

| 风险 | 描述 | 缓解措施 |
|------|------|----------|
| **验证仍在你** | Loop 自动运行也意味着自动犯错 | Maker/Checker 分离 + 高风险操作暂停审批 |
| **理解力债务** | Loop 越快产出你没写的代码，你和代码之间的理解差距越大 | 定期阅读 Loop 产出的代码和方案文档，保持理解 |
| **认知投降** | Loop 能自动跑之后，很容易放弃自己的判断，什么都接受 | 记住：设计 Loop 是为了更快地做你理解的工作，不是为了逃避理解 |
| **Token 成本** | 设计不当的 Loop 可能在几小时内烧掉数十美元 | 每个 Loop 设置最大迭代次数（建议 5-10 轮） |
| **编排税** | 并行 agent 越多，你的 review 带宽越紧张 | 你的 review 能力决定了能并行多少，不是工具 |

---

## 参考资料

- [Addy Osmani — Loop Engineering](https://addyosmani.com/blog/loop-engineering/) (2026-06-07)
- [Addy Osmani — Agent Harness Engineering](https://addyosmani.com/blog/agent-harness-engineering/) (2026-04-19)
- [Anthropic — Effective harnesses for long-running agents](https://www.anthropic.com/engineering/claude-code-best-practices) (2025-11)
- [Anthropic — Harness design for long-running application development](https://www.anthropic.com/engineering/harness-design-long-running-apps) (2026-03)
- [Anthropic — Scaling Managed Agents: Decoupling the brain from the hands](https://www.anthropic.com/engineering/scaling-managed-agents) (2026-04)
- [OpenAI — Harness engineering](https://developers.openai.com/codex/harness-engineering) (2026-02)
- [LangChain — The Art of Loop Engineering](https://langchain.com/blog/the-art-of-loop-engineering) (2026-06-16)
- [Simon Willison — Designing agentic loops](https://simonwillison.net/2025/Sep/30/designing-agentic-loops/) (2025-09-30)
- [OpenCode Documentation](https://opencode.ai/docs)
