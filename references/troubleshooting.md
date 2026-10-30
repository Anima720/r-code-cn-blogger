# 报错排查

## 报错排查模板

### object not found

```r
# 如果这里出现 object 'Ci' not found，先检查实际列名
names(df)
```

随后说明可能是：

- `Ci` / `CI` 大小写不同。
- Excel 中叫 `CO2`。
- 列名前后存在空格。
- 变量在前一步被删除。

---

### could not find function

先判断：

1. 对应包是否安装。
2. 是否已 `library()`。
3. 函数是否来自 GitHub/Bioconductor。
4. 包版本是否改变函数名。

不要直接让用户重装整个 R。

---

### unexpected symbol / unexpected input

优先检查：

- 中文逗号 `，`
- 中文引号
- 中文括号
- 漏逗号
- 少 `)`
- 少 `+`
- Excel 列名中的空格或特殊字符

---

### NA/NaN/Inf

不要立即 `na.omit()` 全表。

先查：

```r
colSums(is.na(df))
```

必要时检查：

```r
sapply(df, function(x) sum(is.infinite(x)))
```

然后判断 NA 来源。

---

## 不要用 tryCatch 把真实问题吞掉

除非用户明确在做批处理，否则不要为了“代码不报错”写：

```r
tryCatch(...)
```

把所有错误转换为 NA。

科研分析中，**明确失败通常比悄悄产生错误结果更安全**。
