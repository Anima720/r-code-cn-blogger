# 数据读取、预处理与脚本规范

## R 包管理

### 安装和加载分开

推荐：

```r
# 如未安装以下 R 包，请先取消下一行开头的 #，运行一次即可
# install.packages(c("readxl", "dplyr", "ggplot2"))

library(readxl)
library(dplyr)
library(ggplot2)
```

不要默认：

```r
if (!require(ggplot2)) install.packages("ggplot2")
```

这种自动安装写法会让科研脚本在不同机器上产生不可控行为。

---

### Bioconductor / GitHub 包要写清来源

```r
# Bioconductor 包，仅在未安装时运行一次
# if (!requireNamespace("BiocManager", quietly = TRUE)) install.packages("BiocManager")
# BiocManager::install("DESeq2")
```

GitHub 包同理，不得伪装成 CRAN 包。

---

### 包尽量集中加载

不要分析到一半突然出现：

```r
library(psych)
```

除非这一包只在可选模块中使用。

---

### 函数冲突

只有存在明显冲突时使用命名空间：

```r
df <- dplyr::select(df, Treatment, SOC, TN)
```

不要为了显得专业把所有函数都写成 `包名::函数名`。

---

## 代码排版

### 赋值

新代码默认使用 `<-`。

修改已有代码时遵循原代码习惯，除非风格本身导致错误。

---

### TRUE/FALSE

使用：

```r
TRUE
FALSE
```

不要生成：

```r
T
F
```

---

### 一行做一件主要事情

推荐：

```r
corr_pearson <- cor(
  df,
  method = "pearson",
  use = "pairwise.complete.obs"
)

corr_pearson
```

不推荐：

```r
corr_pearson <- cor(df, method = "pearson"); corr_pearson
```

---

### 长函数拆行

```r
model <- randomForest::randomForest(
  CFSI ~ .,
  data = analysis_df,
  ntree = 1000,
  importance = TRUE
)
```

---

### 管道风格

- 不为了“现代”把用户的 `%>%` 全部换成 `|>`。
- 不为了“公众号感”把 `|>` 又换回 `%>%`。
- 新代码优先与当前脚本保持一致。
- 长管道一步一行。

---

### 不使用中文全角程序符号

重点检查：

- `，` 与 `,`
- `“ ”` 与 `" "`
- `（ ）` 与 `( )`
- 中文冒号与英文 `:`

用户从微信复制代码时，这是高频报错原因。

---

## 数据读取：像博主一样提前告诉用户哪里最容易错

### Excel

```r
# 运行后会弹出文件选择窗口，请选择本次分析使用的 Excel 文件
raw_data <- readxl::read_excel(
  file.choose(),
  sheet = "Sheet1"
)
```

```r
# 注意：sheet 名称必须与 Excel 底部工作表名称完全一致
```

如果用户已经提供固定文件路径或明确文件名，不要强行改成 `file.choose()`。

---

### CSV

```r
df <- read.csv(
  "data.csv",
  header = TRUE,
  check.names = FALSE
)
```

如果中文乱码风险明显，可提示：

```r
# 如果中文列名出现乱码，可根据文件实际编码尝试 UTF-8-BOM 或 GB18030
```

不要武断指定一种编码适用于所有用户。

---

### 第一列是否为行名必须说清楚

生态数据常见：

```r
spe <- read.csv(
  file.choose(),
  header = TRUE,
  row.names = 1,
  check.names = FALSE
)
```

配套说明：

```r
# 第一列作为样本名，不会进入后续物种丰度计算
```

---

## 数据读入后最低限度检查

完整分析通常至少考虑：

```r
names(df)
str(df)
head(df)
```

但不要无脑全部输出。如果用户已有大型数据，优先使用更有针对性的检查。

#### 必要变量检查

```r
required_vars <- c("CFSI", "pH", "SOC", "TN")
missing_vars <- setdiff(required_vars, names(df))

if (length(missing_vars) > 0) {
  stop(
    "数据中缺少以下变量：",
    paste(missing_vars, collapse = ", "),
    "。请检查 Excel 第一行列名。"
  )
}
```

#### 数值类型检查

```r
# 重点检查本应为数值的变量是否被 Excel 读成 character
str(df[c("SOC", "TN", "pH")])
```

不要为了“健壮”自动把所有字符列强制转成 numeric，因为这可能悄悄产生 NA。

---

## 数据转换和标准化：必须说明“为什么”和“改变了什么”

### Z-score

```r
# 对解释变量做 Z-score 标准化：均值变为 0，标准差变为 1
# 这会改变变量的量纲，但不会改变样本之间的相对排序
predictor_vars <- c("pH", "SOC", "TN")
analysis_df[predictor_vars] <- scale(
  analysis_df[predictor_vars]
)
```

如果用户要求“所有指标在随机森林前都 Z-score”，应准确执行其指定范围。

不要自行决定是否标准化因变量。

---

### log 转换

```r
# 注意：log10() 不能直接处理 0 和负值
log_soc <- log10(df$SOC)
```

如果存在 0：

- 不自动 `+1`。
- 先判断该处理是否有理论和数据意义。
- 如果原文写 `log10(x + 1)`，才忠实使用。

---

### Hellinger 转换

```r
# Hellinger 转换常用于群落丰度数据的排序分析
# 注意：这一步来自当前分析方法/原文要求时才执行，不能把它当作所有 RDA 的固定步骤
spe_hel <- vegan::decostand(
  spe,
  method = "hellinger"
)
```

---

## 缺失值处理

任何会改变有效样本量的做法都应让用户知道。

```r
# 注意：na.rm = TRUE 会忽略缺失值，因此不同变量实际参与计算的 n 可能不同
mean_soc <- mean(
  df$SOC,
  na.rm = TRUE
)
```

不得把：

- 删除缺失行
- 中位数填补
- missForest
- MICE
- 随机森林插补

当成可互换的方法。

如果使用插补，应明确：

1. 哪些变量参与插补。
2. 哪些变量不会被插补。
3. 是单次插补还是多重插补。
4. 插补后是否进行质量评估。

---

## 输出结果文件时的习惯

科研脚本应把导出的东西命名得能看懂：

推荐：

```r
write.csv(
  importance_df,
  "MCR_random_forest_importance.csv",
  row.names = FALSE
)
```

不推荐：

```r
write.csv(x, "result.csv")
```

如果用户原代码已有固定输出名，最小改动模式下保持原命名规则。

---

## 版本兼容提醒

只有真正可能影响运行时才提示版本问题，例如：

```r
# 如果这里提示某函数不存在，请先运行 packageVersion("microeco") 检查包版本
```

不要每份代码都加一段 R 版本宣言。

如果原论文指定版本且复现依赖明显，应保留版本信息。

### 近两年默认值或接口有变化、写代码时要显式写参数的地方

以下变化都会让"同一段代码在新旧版本上结果不同或直接报错"。新写代码时把相关参数写明；复现旧论文时，按原文使用的版本行为来写，并在注释里说明。

| 包 | 变化 | 写代码时怎么做 |
|---|---|---|
| vegan ≥ 2.6-8 | `adonis2()` 默认 `by = NULL`，只给整体检验 | 需要逐项结果时写明 `by = "terms"` 或 `by = "margin"` |
| vegan ≥ 2.7 | `adonis()` 停用；不能用 `summary()` 取排序得分 | 用 `adonis2()`；用 `scores(..., display = , scaling = )` 取坐标 |
| ggplot2 ≥ 3.4 / 4.0 | 线条粗细改用 `linewidth`；`geom_errorbarh()` 弃用；图例放图内要用 `legend.position = "inside"` | 详见 `references/plotting.md` |
| piecewiseSEM 2.3 | 要求 R ≥ 4.5 | 用户 R 版本较旧时，提醒先升级 R 或安装旧版包 |

这张表只列本 Skill 里用到、且已核实的变化。其他包的版本差异，不确定时让用户运行 `packageVersion("包名")` 核对，不要凭记忆断言。

---

## 示例数据的规范

给教程式脚本附带示例数据时：

- 用 `set.seed()` 固定随机数，并在注释里写明"这是模拟数据，运行结果没有生物学意义"。
- 能用公开数据集就用公开数据集，例如 vegan 自带的 `varespec`、`varechem`、`dune`、`dune.env`、`BCI`，并写明出处。
- 示例数据的生成和用户真实数据的读取分成两段。用户换成自己的数据时，只需要改读取那一段。
- 模拟数据的结构（行是什么、列是什么、有无重复和分组）要和用户描述的真实数据一致，否则跑通了也说明不了问题。

