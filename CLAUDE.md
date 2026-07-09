# 记一笔 (jiyibi)

个人记账 App，类似鲨鱼记账但补齐预算提醒等缺口。**Android 单平台先行**，全文档统一此表述，不混入 iOS 先行的说法。

## 技术栈

> 以下区分 MVP 必装 / V1 迭代 / 加固阶段。MVP 只装 MVP 必装依赖，避免一开始引入用不上的包。

- **框架**: Flutter（Android 单平台先行，minSdkVersion 21）
- **状态管理**: flutter_riverpod ^2.5.0
- **数据库**: drift ^2.16.0 + sqlite3_flutter_libs ^0.5.0 + drift_flutter ^0.2.0
- **代码生成**: build_runner + drift_dev
- **图表**: fl_chart ^0.68.0（MVP 必装，报表用）
- **日期/货币格式化**: intl ^0.19.0（MVP 必装）
- **轻量 KV**: shared_preferences ^2.2.0（MVP 必装，主题/上次分类记忆）
- **文件路径**: path_provider ^2.1.0（MVP 必装，DB 路径/导出）
- **CSV 导出**: csv ^6.0.0（MVP 必装，导出用）
- **文件分享**: share_plus ^7.0.0（MVP 必装，CSV 导出后分享到其他 App）
- **单元测试**: drift 自带 NativeDatabase.memory() 做内存库测试，无需额外包
- **V1 迭代依赖**: file_picker ^8.0.0（CSV 导入）、home_widget ^0.6.0（桌面 Widget）
- **加固阶段依赖**: local_auth ^2.2.0（应用锁）

## 开发约定

- **命名**: 文件 snake_case，类 PascalCase，变量 camelCase
- **状态管理**: 统一 Riverpod，不用 setState（简单叶子组件除外）
- **数据库**: 所有操作走 Repository，UI 层不直接碰 Database
- **金额（重要）**: 统一用 `int amountCents` 存储（分为单位，避免浮点精度问题）。
  - DB 列名一律 `amountCents` / `balanceCents`，类型 `IntColumn`
  - **禁止在业务逻辑里用 double 运算金额**；UI 显示用 `MoneyUtils.formatYuan(cents)` 转 `¥1,234.56`
  - 录入时 `MoneyUtils.yuanToCents(String)` 从字符串直接解析为分，**不经 double**（数字键盘全程字符串累积，最后一次性转）。原因：`"12.34" → double → ×100` 会经过浮点表示，极端值有精度漂移；字符串拆整数/小数部分直转 `12*100+34=1234` 彻底杜绝
  - 预算预测/统计全部在 cents 域做整数运算
- **日期**: DateTime + intl 包，不手动拼字符串
- **颜色**: 所有颜色走 ColorScheme/ThemeData，不写死 Color(0xFF...)
- **语义色**: 支出=#D85A30(珊瑚红)，收入=#3B6D11(草绿)，所有主题不变
- **分类色**: 餐饮amber/交通blue/购物coral/娱乐purple/医疗red/居家teal/学习green/其他gray
- **日志（隐私）**: 不得在日志/打印中出现金额、备注、商户等敏感字段。release 构建关闭所有 debug 日志（见隐私策略章节）
- **提交**: 每个 Task 完成后单独 commit，格式: `feat(T1.3): drift数据库定义` / `test(T1.6): repository单元测试`

## 核心数据表

| 表 | 用途 | 关键字段 | 约束 |
|---|---|---|---|
| records | 流水明细 | id, date, type(expense/income), amountCents(int 分), categoryId, note, accountId, source, sourceId, merchant, createdAt, updatedAt | **sourceId DB 唯一约束**（uniqueKeys={sourceId}，nullable；手记 null 不冲突，导入非空被拦截）|
| categories | 分类 | id, name, icon, color, type, sortOrder, archived | unique(name, type)；archived 软删除 |
| accounts | 账户 | id, name, balanceCents(int), icon, archived | unique(name)；archived 软删除 |
| budgets | 预算 | id, month(202607), amountCents(int), categoryId(**0=总预算, NOT NULL**) | unique(month, categoryId)（含总预算行 categoryId=0，同样受约束）|

### records 字段说明

| 字段 | 类型 | 说明 |
|---|---|---|
| `amountCents` | int | 金额（分），始终正数。type 决定是支出还是收入 |
| `source` | text | 数据来源：`manual`(手记) / `import`(导入) / `csv`(CSV导入)。默认 manual |
| `sourceId` | text? | 去重键，**DB 唯一约束**。导入时 = `sha1(source|date|type|amountCents|categoryId|noteNormalized|merchantNormalized)`，其中 noteNormalized/merchantNormalized = trim+lowercase，空则空串。含 type/note/merchant 避免同日同金额同分类误判（如午饭和零食都 15 元餐饮）。手记为 null，SQLite 中 NULL 不冲突 |
| `merchant` | text? | 商户/对方（V1 录入，MVP 可空） |
| `updatedAt` | DateTime | 最后修改时间，编辑时更新 |

### 归档与软删除

- 分类/账户**不物理删除**，用 `archived=true` 软删除：归档后不在选择器中显示，但历史记录仍能正确关联显示
- 预算用 unique(month, categoryId) 约束，同一月同一分类只能有一条预算，upsert 写入。**总预算行 categoryId=0**（NOT NULL DEFAULT 0），同样受约束保护——避免 SQLite 中 NULL 不冲突导致多条总预算共存

## MVP 范围（收缩版）

**原则：先跑通核心记账闭环，CSV导入/桌面Widget/备份/应用锁全部后移。**

| 阶段 | 内容 | 任务 |
|---|---|---|
| **MVP 第1周** | 项目骨架 + 数据层 + Repository 测试 | T1.1-T1.6 |
| **MVP 第2周** | 记账核心（明细/记账弹层/编辑） | T2.1-T2.3 |
| **MVP 第3周** | 预算提醒 + 日历 + 报表（差异化） | T3.1-T3.4 |
| **MVP 第4周** | 设置页 + CSV导出 + 测试打包 | T4.1-T4.3 |
| **上线前加固** | 应用锁 + 敏感日志禁止 + 备份保护 | S1-S3（正式自用前必做）|
| **V1 迭代** | CSV导入(鲨鱼迁移) + 桌面Widget | V1.1-V1.2 |

> ⚠️ **正式自用前必须完成加固阶段**。MVP 可用测试数据验证，但放入真实记账数据前需 S1-S3 就位。

## 隐私策略

1. **应用锁（加固 S2）**: local_auth 生物识别锁，App 启动 + 后台回前台时校验。开关持久化。正式自用前必须开启。
2. **敏感日志禁止（加固 S1）**: 
   - 全项目用一个 `AppLogger` 封装，禁止直接 `print`
   - **日志中不得出现金额、备注、商户、sourceId 等敏感字段**；debug 打印 Record 时只打 id/type/date
   - release 构建自动关闭 debug 级日志（`if (kDebugMode)`）
3. **备份保护（加固 S3）**: 备份文件不得明文落到公开目录。正式自用前：备份需经应用锁校验后才可导出/恢复；恢复前二次确认。

## 测试策略

- **Repository 单元测试（T1.6，MVP 必做）**: 用 drift `NativeDatabase.memory()` 起内存库，测：insert/查询/按月汇总/按分类/按日/batchInsertIfNew/updatedAt 更新/去重（DB 唯一约束：重复 sourceId 抛异常；多条 null 不冲突）
- **金额转换测试**: `MoneyUtils.formatYuan` / `yuanToCents(String)` 边界（""→0、"12"→1200、"12.3"→1230、"12.34"→1234、"12.345"→1234截断、"-12.34"→-1234）
- **预算预测测试（T3.2）**: 已知输入手算预期，断言 predictMonthEndCents / 超支判定 / 日均建议
- **导入去重测试（V1.1）**: 同一 sourceId 重复插入被跳过
- **集成测试清单（T4.3）**: 全流程手测

## 项目结构

```
lib/
├── main.dart                      # 入口，ProviderScope
├── app.dart                        # MaterialApp + 主题 + 路由
├── core/
│   ├── theme/                      # 5套 ThemeData + theme_provider
│   ├── constants.dart              # 常量
│   ├── utils/
│   │   └── money_utils.dart        # 分↔元转换（MVP 必做）
│   ├── logger.dart                 # AppLogger（加固 S1，MVP 先放空壳）
│   └── providers.dart              # 全局 Provider 定义
├── data/
│   ├── database/                   # drift AppDatabase + 表定义
│   ├── repositories/               # Record/Category/Budget/Account Repository
│   ├── export/                     # CSV 导出（MVP）
│   ├── import/                     # CSV 导入（V1）
│   └── backup/                     # 备份恢复（加固 S3）
├── presentation/
│   ├── home/                       # 底部 Tab 骨架
│   ├── detail/                     # 明细流水页
│   ├── editor/                     # 记账弹层 + 数字键盘
│   ├── calendar/                   # 日历视图
│   ├── report/                     # 报表（饼图+趋势图）
│   ├── budget/                     # 预算设置 + 超支预测
│   └── settings/                   # 设置页
└── shared/
    └── widgets/                    # 公共组件
```

## 开发任务清单

**完整任务清单在 `docs/记账App开发任务清单.html`**（v2 收缩版）：MVP 16 个任务 + 加固 3 个 + V1 迭代 2 个。

执行顺序：
- **第 1 周**: T1.1→T1.2→T1.3→T1.4→T1.5→T1.6 (项目骨架+数据层+测试，关键路径)
- **第 2 周**: T2.1→T2.2→T2.3 (记账核心)
- **第 3 周**: T3.1→T3.2 (预算+超支预测) | T3.3 日历 | T3.4 报表
- **第 4 周**: T4.1 设置页 | T4.2 CSV导出 | T4.3 测试打包
- **上线前加固**: S1 日志规范 → S2 应用锁 → S3 备份保护
- **V1 迭代**: V1.1 CSV导入 | V1.2 桌面Widget

每个任务的详细规格（目标/依赖/要创建的文件/实现要点/验收标准）在任务清单 HTML 中。

## 参考文档

- `docs/记账App产品分析报告.html` — 竞品分析、KANO需求模型、功能规划
- `docs/记账App技术架构设计.html` — 四层架构、数据模型、核心代码范式（v2 基准，与本文档完全一致）
- `docs/记账App交互原型.html` — 可交互 UI 原型（6页面+5主题+导入导出+桌面Widget）
- `docs/记账App开发任务清单.html` — v2 任务详细规格

## 5 套主题

青松(默认青绿#0F6E56) / 暖阳(暖橙#D97706) / 雾兰(灰蓝#6B8299) / 樱粉(玫红#C0446E) / 暗夜(深色#2DD4A7)

切换后所有页面和图表自适应。支出/收入语义色所有主题不变。
