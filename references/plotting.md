# 绘图、保存与结果解读

## 绘图代码：把“分析”和“美化”拆开

### 图对象命名

```r
p <- ggplot(
  plot_df,
  aes(x = Treatment, y = Value)
) +
  geom_boxplot() +
  theme_classic()

p
```

便于后续修改和保存。

---

### 分组顺序

```r
# 这里只控制显示顺序，不改变统计结果
plot_df$Treatment <- factor(
  plot_df$Treatment,
  levels = c("CK", "A", "B", "C")
)
```

---

### 把常改参数集中

对于复杂科研图，可在绘图前集中：

```r
# ★ 常用绘图参数，可按论文版式调整
point_size <- 3
text_size <- 12
line_width <- 0.6
```

不要把所有 `theme()` 参数全部抽成变量，反而降低可读性。

---

### 配色

用户没有指定时：

- 以清晰和可打印为先。
- 不自动引入 3 个配色包。
- 不为了“Nature 风”虚构所谓统一配色标准。

---

### ggplot2 4.x 写法要点

ggplot2 4.0（2025 年下半年发布）内部改用 S7 对象系统，公开写法大多不变，但下面这些旧写法会报警告甚至出错。新写代码一律用右边的写法；改用户旧代码时，只有当旧写法确实报错或警告时才改，并说明改了什么。

| 旧写法 | 新写法 |
|---|---|
| 线条类 geom 用 `size =` 控制粗细 | `linewidth =`（点和文字仍用 `size`） |
| `geom_errorbarh()` | `geom_errorbar(orientation = "y")` |
| `legend.position = c(0.8, 0.2)` | `legend.position = "inside", legend.position.inside = c(0.8, 0.2)` |
| `aes_string("x")` | `aes(.data[["x"]])` |
| `..count..` 等点点写法 | `after_stat(count)` |
| `coord_trans()` | `coord_transform()` |
| `scale_*(trans = )` | `scale_*(transform = )` |
| `geom_violin(draw_quantiles = )` | 分位数参数改由 `stat_ydensity()` 的 `quantiles` 提供，并且改为按原始数据计算，结果与旧版不完全相同；具体参数名先查 `?geom_violin` |
| `fatten =`（箱线图、点区间） | 用各自的 `median.linewidth`、`size` 等参数 |

其他要提醒用户的变化：

- `theme_classic()` 的刻度颜色、轴线端点和 4.0 以前略有不同；复现旧图要对照原图检查。
- 主题预设（`theme_classic()` 等）是**完整主题**，必须写在自己的 `theme()` 之前，否则自己设的参数会被覆盖。
- 默认分箱的 `boundary` 变了，直方图的分箱结果可能和旧版不一样。
- `geom_boxplot()` 新增 `quantile.type`（默认 7）；如果要和 SAS 等软件的分位数对上，需要显式设置。

如果用户机器上的 ggplot2 还是 3.x，上表右边多数写法同样可用；不确定时，先请用户运行 `packageVersion("ggplot2")`。

---

### 发表级图形的进一步规范

本 Skill 只管"代码写得清楚、统计不出错"。如果用户要的是投稿用的成品图（固定物理尺寸、字体字号、多面板对齐、地图投影与南海插图等），而环境里装有 `rfigure` 这类专门的绘图 Skill，可以配合使用：统计部分仍按本 Skill 的规范写，图形的版式和导出交给专门的 Skill。两者冲突时，统计含义优先。

---

### 显著性标记

图中星号、字母、P 值必须明确来自哪一统计检验。

不能出现：

- ANOVA 用 Tukey，图注却说 LSD。
- 图里星号来自原始 P，表里是 BH P。
- 字母顺序与处理顺序错位。

---

## 保存图形：给可编辑和投稿场景留余地

```r
# PDF 为矢量图，适合后续排版或 AI/Illustrator 编辑
ggsave(
  filename = "Figure_1.pdf",
  plot = p,
  width = 7,
  height = 5,
  units = "in"
)
```

位图：

```r
ggsave(
  filename = "Figure_1.tiff",
  plot = p,
  width = 7,
  height = 5,
  units = "in",
  dpi = 600
)
```

不要声称某个尺寸或 dpi 自动满足所有期刊要求。

---

## “结果怎么看”应该放在哪里

用户是初学者或方法较复杂时，可在关键输出旁加入一句：

```r
summary(model)

# 结果怎么看：重点查看各解释变量的 Estimate、P 值，以及模型整体 R²
```

排序分析：

```r
nmds_model$stress

# 结果怎么看：stress 越低通常表示低维排序对原距离结构的保留越好
# 具体是否可接受需要结合数据和研究场景判断，不要机械套一个绝对阈值
```

不要在代码里写一整段教科书。
