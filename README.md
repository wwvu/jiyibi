# 记一笔 (jiyibi)

个人记账 App,类似鲨鱼记账但补齐预算提醒等缺口。Android 单平台先行。

## 功能

- **记账**:支出/收入切换,数字键盘快速录入,支持账户与任意日期时间
- **明细流水**:按月汇总,支持备注/分类/账户搜索和收支/分类/账户组合筛选
- **预算管理**:总预算 + 分类预算,超支预测,支持一键沿用上月预算
- **日历视图**:按日展示支出,点击查看当日明细
- **报表**:分类饼图 + 每日支出趋势曲线(可水平滑动浏览)
- **基础资料**:分类和账户可新增、编辑、归档及恢复,账户余额随流水实时计算
- **5 套主题**:青松(默认青绿)/ 暖阳(暖橙)/ 雾兰(灰蓝)/ 樱粉(玫红)/ 暗夜(深色),所有页面和图表自适应
- **CSV 导出**:导出记账数据并分享到其他 App

## 技术栈

| 类别 | 技术 |
|------|------|
| 框架 | Flutter(Android 单平台,minSdkVersion 24) |
| 状态管理 | flutter_riverpod |
| 数据库 | drift + sqlite3_flutter_libs + drift_flutter |
| 图表 | fl_chart |
| 日期/货币格式化 | intl |
| 轻 KV 存储 | shared_preferences |
| CSV 导出 | csv + share_plus |

## 设计要点

- **金额精度**:统一用 `int amountCents`(分为单位)存储和运算,避免浮点精度问题。UI 显示用 `MoneyUtils.formatYuan(cents)` 转 `¥1,234.56`
- **录入转换**:数字键盘全程字符串累积,`MoneyUtils.yuanToCents(String)` 从字符串直接解析为分,不经 double
- **去重**:导入记录有 `sourceId` 唯一约束,手记为 null 不冲突
- **软删除**:分类/账户归档后不在选择器显示,但历史记录仍正确关联
- **语义色**:支出 `#D85A30`(珊瑚红)、收入 `#3B6D11`(草绿),所有主题不变

## 上线前边界

当前版本适合使用测试数据验证核心记账闭环。录入真实财务数据前仍需完成:

- 生物识别应用锁,覆盖启动和后台回前台场景
- 受保护的备份与恢复,恢复前二次确认
- CSV 导入及字段映射预览,复用 `sourceId` 唯一约束去重
- Release 独立签名配置和 Android 真机回归

## 快速开始

```bash
# 1. 安装依赖
flutter pub get

# 2. 生成 drift 代码(首次必做)
dart run build_runner build

# 3. 运行
flutter run
```

> 生成文件 `app_database.g.dart` 已被 `.gitignore` 排除,clone 后必须执行步骤 2 才能编译。

## 项目结构

```
lib/
├── main.dart                      # 入口,ProviderScope
├── app.dart                       # MaterialApp + 主题 + 路由
├── core/
│   ├── theme/                     # 5 套 ThemeData + theme_provider
│   ├── constants.dart             # 常量
│   ├── utils/money_utils.dart     # 分↔元转换
│   ├── logger.dart                # AppLogger
│   └── providers.dart             # 全局 Provider
├── data/
│   ├── database/                  # drift AppDatabase + 表定义
│   ├── repositories/              # Record/Category/Budget/Account Repository
│   └── export/                    # CSV 导出
├── presentation/
│   ├── home/                      # 底部 Tab 骨架
│   ├── detail/                    # 明细流水页
│   ├── editor/                    # 记账弹层 + 数字键盘
│   ├── calendar/                   # 日历视图
│   ├── report/                    # 报表(饼图+趋势图)
│   ├── budget/                    # 预算设置 + 超支预测
│   └── settings/                  # 设置页
└── shared/
    └── widgets/                   # 公共组件
```

## 核心数据表

| 表 | 用途 | 关键字段 |
|---|---|---|
| records | 流水明细 | id, date, type, amountCents, categoryId, note, sourceId |
| categories | 分类 | id, name, icon, color, type, sortOrder, archived |
| accounts | 账户 | id, name, balanceCents, icon, archived |
| budgets | 预算 | id, month, amountCents, categoryId(0=总预算) |

## 参考文档

- `docs/记账App产品分析报告.html` - 竞品分析、KANO需求模型
- `docs/记账App技术架构设计.html` - 四层架构、数据模型
- `docs/记账App交互原型.html` - 可交互 UI 原型
- `docs/记账App开发任务清单.html` - 任务详细规格
