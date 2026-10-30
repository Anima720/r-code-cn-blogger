# 更新记录

## v3.0.0（2026-10）

### 结构

- `SKILL.md` 从约 2000 行精简为约 650 行的主文件，只保留所有任务都适用的规矩：定位、决策优先级、任务模式、分析地图、回答结构、注释体系、"AI 味"禁止项、自检清单。
- 方法专项、绘图、报错、示例拆到 `references/` 下 6 个参考文件，按任务按需加载。原有规则内容全部保留，只是换了位置。
- frontmatter 改为标准字段：`name`、`description`、`license`、`metadata.version`。
- `references_source_profiles.md` 并入 `references/style-sources.md`。

### 新增：面向新一代模型的约束（`SKILL.md` 第 1 节）

能运行就真的运行，没运行如实说明；不凭记忆编函数和参数；从结果对象取值后验证；不编造结果；控制篇幅；长对话里守住分析协议；不碰用户原始数据；该问就问。第 15 节"可运行性检查"和第 18 节"自检清单"同步增加对应条目。

### R 包与写法更新（均已在 R 4.5.1 上实际运行验证）

- vegan：`adonis2()` 自 2.6-8 起默认 `by = NULL`，规范改为要求显式写 `by`，并说明 `"terms"` 与 `"margin"` 的区别；补充区组设计下用 `permute::how()` 限制置换；`adonis()` 已停用。
- vegan：2.7 起不能用 `summary()` 取排序得分，RDA 规范和完整模板改用 `scores(display = , choices = , scaling = )`，并要求写明 `scaling`；补充 `RsquareAdj()`、`eigenvals()` 和 `anova(by = "margin")`。
- ggplot2 4.x：新增写法对照表（`linewidth`、`geom_errorbar(orientation = "y")`、`legend.position = "inside"`、`after_stat()`、`coord_transform()` 等），以及 `theme_classic()` 变化、主题预设的书写顺序、分箱默认值等提醒。
- 新增与 `rfigure` 等专门绘图 Skill 的配合说明。

### 修正

- `examples/piecewise_sem_example.R`：原来用 `sem_summary$CStat` 提取 Fisher's C，元素名应为 `Cstat`。R 用 `$` 取不存在的元素不会报错，只返回 `NULL`，导致导出的 `SEM_Fishers_C.csv` 是空文件。现改用 `fisherC(sem_model)`，并加 `stopifnot()` 检查。已在 piecewiseSEM 2.3.1 上运行确认。

### 风格来源

- 新增二傻统计、红皇后学术、小田的生信随笔 3 个公众号。计划新增的地上地下生态学未检索到，暂未纳入。
- 通过搜狗微信搜索重新检索各账号。微信原文无法批量读取，这一轮只看到标题和摘要，没有读到正文，也无法核实发布日期；画像中逐个标注证据强度，并写明哪些内容是按统计常识补充的。
- `references/style-sources.md` 每个账号写明吸收了什么、避开了什么，新增跨账号共识与共同糟粕清单。

### 依据调研补充的方法规范（`references/ecology-stats.md` 等）

- 混合模型：先写清为什么用；拟合后做残差诊断（`performance::check_model()`、DHARMa 模拟残差）；区分边际与条件 R²；`emmeans` 事后比较；用模型预测值出图。
- 多变量批量方差分析：逐变量检查前提，区分变量内与跨变量的多重比较校正，LSD/Duncan 的宽松性提醒。
- 几类"变量重要性"（随机森林置换重要性、glmm.hp、rdacca.hp、varpart）各回答什么问题。
- 先筛变量再检验的选择偏倚；树模型的评估指标与 SHAP 解释的边界。
- SEM：piecewiseSEM 与 lavaan 的选择、样本量、交互与非线性路径、分类外生变量、结果解读。
- Meta 分析：效应量类型、多层模型处理非独立性、异质性、发表偏倚、原始数据核对。
- 微生物组：预处理、功能预测、群落构建、复刻 STAMP 时要写明的决定；RDA 前向选择的共线性与 P 值偏乐观提醒。
- 示例数据规范；"AI 味"禁止项新增 `rm(list = ls())`、残缺代码话术、夸张说法、只复刻外观等条目。

## v2.0.0

首次公开发布。
