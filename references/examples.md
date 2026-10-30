# 示例与模板

## 一个合格的“公众号式代码块”应包含什么

以随机森林为例，理想结构通常是：

```r
# 1. 加载包
# 2. 读取数据
# 3. 明确因变量和解释变量
# 4. 检查列名
# 5. 按用户要求进行标准化/预处理
# 6. 固定随机种子
# 7. 建随机森林
# 8. 置换检验
# 9. 提取变量重要性和 P 值
# 10. 生成显著性标记
# 11. 排序与绘图
# 12. 导出结果
```

但实际代码不必用这 12 个标题逐条占一节。相邻动作可以合并成 5–7 个清楚章节。

---

## 一份不合格的 AI 代码通常长这样

```r
install.packages("tidyverse")
install.packages("randomForest")
install.packages("rfPermute")
library(tidyverse)
library(randomForest)
library(rfPermute)
df <- read.csv("data.csv")
df <- na.omit(df)
df <- scale(df)
set.seed(123)
model <- randomForest(y ~ ., data = df)
print(model)
```

问题：

- 每次运行都安装包。
- 不知道 y 是否存在。
- 未说明 `na.omit()` 删除多少样本。
- 把整张表 `scale()`，可能连因变量/分组一起标准化。
- 没有说明随机森林指标怎么看。
- `rfPermute` 加载了却没用。
- 无结果提取、无保存、无变量重要性解释。

---

## 改进后的写法示例

```r
# =============================================================================
# 随机森林分析示例
#
# 因变量：MCR
# 解释变量：pH, SOC, TN, DOC
# =============================================================================


# 一、加载 R 包 -------------------------------------------------------------

# 如未安装，请先取消下一行开头的 #，运行一次即可
# install.packages(c("readxl", "randomForest", "rfPermute"))

library(readxl)
library(randomForest)
library(rfPermute)


# 二、读取数据 --------------------------------------------------------------

# 运行后选择本次分析的 Excel 文件
df <- read_excel(file.choose())

# 先确认列名。后面的变量名必须与这里完全一致
names(df)


# 三、准备分析变量 ----------------------------------------------------------

response_var <- "MCR"
predictor_vars <- c("pH", "SOC", "TN", "DOC")

required_vars <- c(response_var, predictor_vars)
missing_vars <- setdiff(required_vars, names(df))

if (length(missing_vars) > 0) {
  stop(
    "数据中缺少变量：",
    paste(missing_vars, collapse = ", ")
  )
}

analysis_df <- as.data.frame(
  df[required_vars]
)

# 注意：这里没有自动删除 NA，也没有自动标准化。
# 是否进行这些处理应由你的原分析方法决定。


# 四、随机森林 --------------------------------------------------------------

# 固定随机种子，保证置换过程可重复
set.seed(123)

rf_model <- randomForest(
  MCR ~ .,
  data = analysis_df,
  ntree = 1000,
  importance = TRUE
)

rf_model

# 结果怎么看：回归随机森林重点关注 OOB 误差、模型解释情况和变量重要性。
# 变量重要性不能解释为因果效应。


# 五、变量重要性 ------------------------------------------------------------

importance_df <- as.data.frame(
  importance(rf_model)
)

importance_df$Variable <- rownames(importance_df)
rownames(importance_df) <- NULL

importance_df
```

这个示例强调的是结构和注释方式，不代表所有随机森林都必须使用这些参数。

---

## 用户只要求“改变量名”时的示例

用户说：

> AS/SOC 改成 MCR，其它不要动。

正确策略：

- 搜索所有真正代表该响应变量的对象、公式、标签和输出文件名。
- 只替换必要位置。
- `ntree`、P 值、颜色、图尺寸等完全不动。
- 不顺手“优化”包、管道或对象名。

错误策略：

> “既然改了变量，我顺便给你把代码重写成 tidyverse 版本。”

禁止。

---

## 用户要求“像博主一样标注”时，不要变成教科书

合适：

```r
# 注意：这里的第一列必须是样本名，不能把样本名作为物种丰度参与距离计算
```

过度：

```r
# 在R语言中，row.names参数用于指定数据框的行名称。R语言是一门广泛用于……
```

注释应该帮助当前任务，而不是扩写百科。

---

## 用户给出论文图或公众号代码截图时

应先识别：

1. 这是数据处理代码、模型代码还是绘图代码。
2. 图上的数值来自哪一步。
3. 星号/字母来自哪一步。
4. 是否存在截图中没显示的前置对象。

不能只照着可见几行抄，因为很多公众号截图会省略数据准备部分。

---

## 参考实现模板：生态学 RDA

```r
# =============================================================================
# RDA 冗余分析
#
# species.csv：行 = 样本，列 = 物种/OTU/ASV
# environment.csv：行 = 样本，列 = 环境因子
# =============================================================================


# 一、加载 R 包 -------------------------------------------------------------

# install.packages(c("vegan", "ggplot2", "ggrepel"))

library(vegan)
library(ggplot2)
library(ggrepel)


# 二、读取数据 --------------------------------------------------------------

# 第一列作为样本名，不参与后续数值分析
spe <- read.csv(
  "species.csv",
  header = TRUE,
  row.names = 1,
  check.names = FALSE
)

env <- read.csv(
  "environment.csv",
  header = TRUE,
  row.names = 1,
  check.names = FALSE
)


# 三、检查样本是否对应 ------------------------------------------------------

# 注意：两个矩阵必须是同一批样本，并且行顺序一致
if (!identical(rownames(spe), rownames(env))) {
  stop("物种矩阵和环境矩阵的样本名或顺序不一致，请先检查。")
}


# 四、数据预处理 ------------------------------------------------------------

# 这里使用 Hellinger 转换只是示例。
# 实际分析中是否转换，应根据原文方法和数据性质决定，不能机械套用。
spe_hel <- decostand(
  spe,
  method = "hellinger"
)


# 五、RDA -------------------------------------------------------------------

rda_model <- rda(
  spe_hel ~ .,
  data = env
)

rda_model

# 调整后的总解释率
RsquareAdj(rda_model)

# 各轴解释率（占总惯量的比例）
summary(eigenvals(rda_model))

# 置换检验：整体模型与各解释变量
# 注意：by = "margin" 是控制其他变量后的边际检验
anova(rda_model, permutations = 999)
anova(rda_model, by = "margin", permutations = 999)


# 六、提取排序坐标 ----------------------------------------------------------

# 注意：vegan 2.7 起不能用 summary(rda_model)$sites 取坐标，统一用 scores()
# ★ scaling = 2 适合看物种与环境因子的关系；scaling = 1 适合看样本间距离
SCALING <- 2

site_scores <- as.data.frame(
  scores(rda_model, display = "sites", choices = 1:2, scaling = SCALING)
)

species_scores <- as.data.frame(
  scores(rda_model, display = "species", choices = 1:2, scaling = SCALING)
)

biplot_scores <- as.data.frame(
  scores(rda_model, display = "bp", choices = 1:2, scaling = SCALING)
)

# site_scores：样本位置
# species_scores：物种/响应变量位置
# biplot_scores：环境因子箭头坐标


# 七、绘制样本和环境因子 ----------------------------------------------------

site_scores$Sample <- rownames(site_scores)
biplot_scores$Variable <- rownames(biplot_scores)

p <- ggplot(site_scores, aes(x = RDA1, y = RDA2)) +
  geom_point(size = 3) +
  geom_segment(
    data = biplot_scores,
    aes(
      x = 0,
      y = 0,
      xend = RDA1,
      yend = RDA2
    ),
    arrow = arrow(length = unit(0.18, "cm")),
    linewidth = 0.5,    # ggplot2 3.4 起线条粗细用 linewidth，不再用 size
    inherit.aes = FALSE
  ) +
  geom_text_repel(
    data = biplot_scores,
    aes(
      x = RDA1,
      y = RDA2,
      label = Variable
    ),
    inherit.aes = FALSE
  ) +
  theme_classic()

p
```

这个模板只展示“代码应该怎样写得清楚”。实际 RDA 的转换、变量筛选、显著性检验和坐标缩放必须依据具体研究设计。
