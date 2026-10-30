# =============================================================================
# 玉米土壤—微生物—氮供应—光合—产量的分段结构方程模型
#
# 方法：Piecewise Structural Equation Model（piecewise SEM）
# R 包：piecewiseSEM
#
# 数据结构：每一行 = 1 个独立样地
# 变量：SOC, SWC, MBN, MineralN, Pn, Yield
# =============================================================================

# 一、加载 R 包 -------------------------------------------------------------
# 如未安装，请先运行一次：
# install.packages("piecewiseSEM")
library(piecewiseSEM)

# 二、生成可直接运行的示例数据 --------------------------------------------
set.seed(20260831)
n <- 120

sem_data <- data.frame(
  Sample = paste0("Plot_", sprintf("%03d", 1:n)),
  SOC = rnorm(n, mean = 18, sd = 3.5),
  SWC = rnorm(n, mean = 25, sd = 4)
)

# 下面只是为了构造具有合理生态关系的模拟数据。
# 真正分析自己的数据时，不需要运行这些变量生成代码。
sem_data$MBN <-
  8 +
  1.80 * sem_data$SOC +
  0.55 * sem_data$SWC +
  rnorm(n, mean = 0, sd = 7)

sem_data$MineralN <-
  -3 +
  0.55 * sem_data$SOC +
  0.10 * sem_data$SWC +
  0.20 * sem_data$MBN +
  rnorm(n, mean = 0, sd = 4)

sem_data$Pn <-
  4 +
  0.42 * sem_data$MineralN +
  0.10 * sem_data$SWC +
  rnorm(n, mean = 0, sd = 2.2)

sem_data$Yield <-
  1800 +
  310 * sem_data$Pn +
  55 * sem_data$MineralN +
  rnorm(n, mean = 0, sd = 650)

head(sem_data)

# ★ 如果换成自己的 Excel 数据，可以用：
# install.packages("readxl")
# library(readxl)
# sem_data <- read_excel(file.choose())
# 注意：Excel 第一行列名必须与代码中的变量名完全一致。

# 三、正式分析前的数据检查 ---------------------------------------------------
required_vars <- c("SOC", "SWC", "MBN", "MineralN", "Pn", "Yield")

missing_vars <- setdiff(required_vars, names(sem_data))
if (length(missing_vars) > 0) {
  stop(
    "数据中缺少以下变量：",
    paste(missing_vars, collapse = ", "),
    "。请检查第一行列名。"
  )
}

numeric_check <- sapply(sem_data[required_vars], is.numeric)
if (any(!numeric_check)) {
  stop("部分 SEM 变量不是 numeric 类型，请先运行 str(sem_data) 检查。")
}

na_count <- colSums(is.na(sem_data[required_vars]))
na_count

# 注意：这里故意不自动 na.omit()。
# 因为直接删除缺失样本会改变有效样本量，应该先判断 NA 的来源。
if (any(na_count > 0)) {
  stop("SEM 变量中存在缺失值，请先处理 NA 再建模。")
}

# 四、建立各个子模型 ---------------------------------------------------------
# 子模型 1：SOC 和 SWC 影响微生物量氮
model_MBN <- lm(
  MBN ~ SOC + SWC,
  data = sem_data
)

# 子模型 2：SOC、SWC 和 MBN 影响矿质氮供应
model_MineralN <- lm(
  MineralN ~ SOC + SWC + MBN,
  data = sem_data
)

# 子模型 3：矿质氮和土壤水分影响净光合速率
model_Pn <- lm(
  Pn ~ MineralN + SWC,
  data = sem_data
)

# 子模型 4：光合速率和矿质氮共同影响产量
model_Yield <- lm(
  Yield ~ Pn + MineralN,
  data = sem_data
)

# 五、组合 Piecewise SEM -----------------------------------------------------
sem_model <- psem(
  model_MBN,
  model_MineralN,
  model_Pn,
  model_Yield,
  data = sem_data
)

# 六、整体结果 ---------------------------------------------------------------
sem_summary <- summary(
  sem_model,
  standardize = "scale"
)
sem_summary

# 结果怎么看：
# 1. Tests of directed separation：d-separation 检验
# 2. Fisher's C：整体路径结构是否与数据明显冲突
# 3. Coefficients：路径系数、P 值、标准化系数
# 4. Individual R-squared：各内生变量的解释程度
#
# 注意：Fisher's C 的 P > 0.05 不等于“证明因果机制正确”。

# 七、提取 d-separation ------------------------------------------------------
dsep_table <- sem_summary$dTable
dsep_table

# 八、提取 Fisher's C --------------------------------------------------------
# 注意：用专门的 fisherC() 提取，不要写 sem_summary$CStat。
# summary 对象里的元素名是 Cstat（小写 s），写错大小写时 R 不会报错，
# 而是悄悄返回 NULL，导出的结果文件会是空的。
fisher_c <- fisherC(sem_model)
fisher_c

# 运行后确认确实提取到了结果，而不是 NULL
stopifnot(!is.null(fisher_c), nrow(fisher_c) == 1)

# 九、提取标准化路径系数 -----------------------------------------------------
path_coefficients <- coefs(
  sem_model,
  standardize = "scale"
)
path_coefficients

# Estimate 为原始尺度路径系数；Std.Estimate 为标准化路径系数。

# 十、提取各内生变量 R² ------------------------------------------------------
r2_table <- rsquared(sem_model)
r2_table

# 十一、计算 SOC -> Yield 的指定间接效应 ------------------------------------
b_SOC_MBN <- path_coefficients$Std.Estimate[
  path_coefficients$Response == "MBN" &
    path_coefficients$Predictor == "SOC"
]

b_MBN_MineralN <- path_coefficients$Std.Estimate[
  path_coefficients$Response == "MineralN" &
    path_coefficients$Predictor == "MBN"
]

b_SOC_MineralN <- path_coefficients$Std.Estimate[
  path_coefficients$Response == "MineralN" &
    path_coefficients$Predictor == "SOC"
]

b_MineralN_Pn <- path_coefficients$Std.Estimate[
  path_coefficients$Response == "Pn" &
    path_coefficients$Predictor == "MineralN"
]

b_MineralN_Yield <- path_coefficients$Std.Estimate[
  path_coefficients$Response == "Yield" &
    path_coefficients$Predictor == "MineralN"
]

b_Pn_Yield <- path_coefficients$Std.Estimate[
  path_coefficients$Response == "Yield" &
    path_coefficients$Predictor == "Pn"
]

indirect_1 <- b_SOC_MineralN * b_MineralN_Yield
indirect_2 <- b_SOC_MineralN * b_MineralN_Pn * b_Pn_Yield
indirect_3 <- b_SOC_MBN * b_MBN_MineralN * b_MineralN_Yield
indirect_4 <- b_SOC_MBN * b_MBN_MineralN * b_MineralN_Pn * b_Pn_Yield

total_indirect_SOC_Yield <- indirect_1 + indirect_2 + indirect_3 + indirect_4

indirect_effects <- data.frame(
  Path = c(
    "SOC -> MineralN -> Yield",
    "SOC -> MineralN -> Pn -> Yield",
    "SOC -> MBN -> MineralN -> Yield",
    "SOC -> MBN -> MineralN -> Pn -> Yield",
    "Total indirect effect"
  ),
  Std_Effect = c(
    indirect_1,
    indirect_2,
    indirect_3,
    indirect_4,
    total_indirect_SOC_Yield
  )
)

indirect_effects

# 十二、绘制结构方程模型路径图 ----------------------------------------------
# 非显著路径用虚线表示，但仍然保留在模型中。
plot(
  sem_model,
  show = "std",
  digits = 2,
  ns_dashed = TRUE,
  alpha = 0.05
)

# 十三、导出结果 -------------------------------------------------------------
write.csv(
  path_coefficients,
  "SEM_path_coefficients.csv",
  row.names = FALSE
)

write.csv(
  dsep_table,
  "SEM_d_separation_tests.csv",
  row.names = FALSE
)

write.csv(
  fisher_c,
  "SEM_Fishers_C.csv",
  row.names = FALSE
)

write.csv(
  r2_table,
  "SEM_R_squared.csv",
  row.names = FALSE
)

write.csv(
  indirect_effects,
  "SEM_indirect_effects.csv",
  row.names = FALSE
)

# =============================================================================
# 结束
#
# 最终建议重点检查：
# 1. Fisher's C 的 P 值
# 2. d-separation 中是否存在显著遗漏关系
# 3. Std.Estimate
# 4. 各路径 P.Value
# 5. 各内生变量 R²
# 6. 直接效应和间接效应是否与研究假设一致
#
# SEM 路径应该首先来自研究假设，而不是根据哪些路径显著再反过来画模型。
# =============================================================================
