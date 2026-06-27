# 极简记账 - 开发注意事项

## HarmonyOS 6.0 ArkTS 开发关键经验

### 1. Scroll 组件导致页面顶部大片空白
- **现象**: 首页顶部有额外空白
- **解决**: 去掉 Scroll，改用纯 Column。需要滚动用 List 替代

### 2. 旧数据库 Schema 残留导致 INSERT 失败  
- **现象**: 点击"完成"按钮无反应，数据不保存
- **根因**: `CREATE TABLE IF NOT EXISTS` 不会迁移已有表。旧表有 `book_id NOT NULL`，新代码不传导致静默失败
- **解决**: 换数据库名强制重建 schema（`JianJiZhang.db`）

### 3. Stack 内 height('100%') 导致子元素无限膨胀
- **解决**: 用 padding 撑高度代替 height('100%')

### 4. Canvas onReady 只触发一次，数据更新后图表不重绘
- **解决**: 放弃 Canvas，用 Progress + Column + Text 实现图表

### 5. 排行区高度变化导致页面下移
- **现象**: 切换收支时整个页面跳动
- **诊断**: 逐步简化：纯静态 → +总额 → +柱状图 → +排行（定位到问题）
- **解决**: 排行区加固定高度 `.height(420)`

### 6. Symbol Glyph 系统图标不可靠
- **解决**: 用 Emoji Unicode Text 替代 `$r('sys.symbol.xxx')`

### 7. Async onClick 可能不生效
- **解决**: 用 `.then()` 或 fire-and-forget

### 8. Tabs 组件限制多
- **解决**: 自定义 Row + SpaceAround 做导航栏，FAB 用 Stack + position 叠加

### 9. build-profile.json5 配置
- SDK版本统一放 products 字段，格式 `"6.1.1(24)"`
- modelVersion 在 hvigor-config.json5 和 oh-package.json5 必须一致

### 10. 数据库操作调试方法
- 先关面板验证 @Link 生效 → 再加 DB 操作验证 Promise → 逐步定位问题

## 项目结构
```
entry/src/main/ets/
├── common/     IconHelper, ThemeManager
├── components/ AddRecordPanel, TransactionItem, PieChart, LineChart, ...
├── database/   DatabaseHelper (单例)
├── models/     FinanceModels (接口+预设分类)
├── pages/      Index, HomePage, StatisticsPage, CategoriesPage, SettingsPage
└── entryability/ EntryAbility
```

## 数据库
- 名称: `JianJiZhang.db`（换过，旧名 SharkBook.db）
- 3表: categories, records, budgets
- 外键: records.category_id → categories.id
