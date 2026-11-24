# ЛР4: Основи математичної статистики в R (варіант 6)
# Запуск: з папки submission/:  Rscript lab04.R
# Результати: results/console_output.txt, графіки: plots/*.png

dir.create("results", showWarnings = FALSE)
dir.create("plots", showWarnings = FALSE)
sink("results/console_output.txt", split = TRUE)

# допоміжні функції
get_mode <- function(v) {
  ux <- unique(v)
  ux[which.max(tabulate(match(v, ux)))]
}
cv_fun <- function(v) sd(v) / mean(v) * 100
open_png <- function(name, w = 1200, h = 800) {
  png(file.path("plots", name), width = w, height = h, res = 150)
}
hdr <- function(s) cat("\n==========", s, "==========\n")

# ---------------------------------------------------------------- A
hdr("A. Повний аналіз вибірки варіанта 6 (п.34-35)")
x <- c(40, 45, 48, 50, 52, 55, 58, 60, 62, 65, 68, 70)
print(x)
cat("n       =", length(x), "\n")
cat("min     =", min(x), "\n")
cat("max     =", max(x), "\n")
cat("range   =", max(x) - min(x), " (range():", range(x), ")\n")
cat("mean    =", mean(x), "\n")
cat("median  =", median(x), "\n")
cat("кількість унікальних значень =", length(unique(x)), "з", length(x), "\n")
cat("get_mode(x) =", get_mode(x),
    "(усі значення унікальні, кожне зустрічається 1 раз, тому мода фактично не визначена;",
    "функція повертає перше значення)\n")
cat("var     =", var(x), "\n")
cat("sd      =", sd(x), "\n")
cat("sqrt(var) =", sqrt(var(x)), "\n")
q <- quantile(x)
print(q)
Q1 <- unname(q[2]); Q3 <- unname(q[4])
cat("Q1 =", Q1, " Q3 =", Q3, "\n")
cat("IQR     =", IQR(x), " (Q3-Q1 =", Q3 - Q1, ")\n")
cat("CV (%)  =", cv_fun(x), "\n")
cat("\nsummary(x):\n")
print(summary(x))

# ---------------------------------------------------------------- B
hdr("B. Графіки та інтерпретація (п.36)")
open_png("hist_breaks5.png")
hist(x, breaks = 5, main = "Гістограма вибірки (breaks = 5)", xlab = "Значення", ylab = "Частота", col = "lightblue")
dev.off()
open_png("hist_breaks10.png")
hist(x, breaks = 10, main = "Гістограма вибірки (breaks = 10)", xlab = "Значення", ylab = "Частота", col = "lightblue")
dev.off()
open_png("hist_breaks_width10.png")
hist(x, breaks = seq(40, 70, by = 10), main = "Гістограма вибірки (інтервали шириною 10)", xlab = "Значення", ylab = "Частота", col = "lightblue")
dev.off()
open_png("boxplot_x.png", 800, 800)
boxplot(x, main = "Boxplot вибірки варіанта 6", ylab = "Значення", col = "lightgreen")
dev.off()

h5 <- hist(x, breaks = 5, plot = FALSE)
h10 <- hist(x, breaks = 10, plot = FALSE)
cat("hist breaks=5: межі", h5$breaks, " частоти", h5$counts, "\n")
cat("hist breaks=10: межі", h10$breaks, " частоти", h10$counts, "\n")
cat("(R трактує breaks як підказку; для обох значень отримано однакові інтервали шириною 5)\n")
cat("hist інтервали шириною 10: частоти", hist(x, breaks = seq(40, 70, by = 10), plot = FALSE)$counts, "\n")

cats <- cut(x, breaks = c(40, 50, 60, 70, 80), right = FALSE)
tab <- table(cats)
cat("\nТаблиця частот (категорії [40,50), [50,60), [60,70), [70,80)):\n")
print(tab)
cat("\nВідносні частоти, %:\n")
print(round(prop.table(tab) * 100, 2))
open_png("barplot_cats.png")
barplot(tab, main = "Розподіл за інтервалами значень", xlab = "Інтервал", ylab = "Кількість", col = "orange")
dev.off()
open_png("pie_cats.png", 900, 800)
pie(tab, main = "Частки інтервалів значень")
dev.off()

lower <- Q1 - 1.5 * IQR(x); upper <- Q3 + 1.5 * IQR(x)
cat("\nМежі викидів (1.5*IQR): нижня =", lower, " верхня =", upper, "\n")
cat("Викиди:", if (any(x < lower | x > upper)) x[x < lower | x > upper] else "немає", "\n")
cat("boxplot.stats()$out:", boxplot.stats(x)$out, "\n")
cat("mean - median =", mean(x) - median(x), "\n")
cat("Середина розмаху (min+max)/2 =", (min(x) + max(x)) / 2, "\n")
cat("Відстані: median-Q1 =", median(x) - Q1, " Q3-median =", Q3 - median(x), "\n")

# ---------------------------------------------------------------- C
hdr("C. Вплив викиду (п.37)")
x2 <- c(x, max(x) * 2)
cat("x2 = x + ", max(x) * 2, "\n")
cmp <- data.frame(
  characteristic = c("mean", "median", "sd", "var", "IQR", "range"),
  x  = c(mean(x), median(x), sd(x), var(x), IQR(x), diff(range(x))),
  x2 = c(mean(x2), median(x2), sd(x2), var(x2), IQR(x2), diff(range(x2)))
)
cmp$change_abs <- cmp$x2 - cmp$x
cmp$change_pct <- (cmp$x2 / cmp$x - 1) * 100
print(cmp, digits = 6)
lower2 <- quantile(x2, 0.25) - 1.5 * IQR(x2); upper2 <- quantile(x2, 0.75) + 1.5 * IQR(x2)
cat("Межі викидів для x2: нижня =", lower2, " верхня =", upper2, " викиди:", x2[x2 < lower2 | x2 > upper2], "\n")
open_png("boxplot_outlier.png")
boxplot(x, x2, names = c("x", "x2 (з викидом)"), main = "Вплив викиду", ylab = "Значення", col = c("lightgreen", "salmon"))
dev.off()

# ---------------------------------------------------------------- D
hdr("D. Пропущені значення (п.38)")
x_na <- c(12, 15, 18, NA, 20, 22, NA, 25, 27, 30)
cat("Кількість NA:", sum(is.na(x_na)), " з", length(x_na), "\n")
na_tab <- data.frame(
  func = c("mean", "median", "sd", "var"),
  without_na_rm = c(mean(x_na), median(x_na), sd(x_na), var(x_na)),
  with_na_rm = c(mean(x_na, na.rm = TRUE), median(x_na, na.rm = TRUE),
                 sd(x_na, na.rm = TRUE), var(x_na, na.rm = TRUE))
)
print(na_tab, digits = 6)

# ---------------------------------------------------------------- E
hdr("E. Моделювання (п.39)")
set.seed(2026)
xs <- rnorm(1000, mean = 100, sd = 15)
cat("mean   =", mean(xs), "\n")
cat("median =", median(xs), "\n")
cat("sd     =", sd(xs), "\n")
cat("var    =", var(xs), "\n")
print(quantile(xs))
cat("IQR    =", IQR(xs), " (теоретично для N(100,15): ", 15 * 1.34898, ")\n")
cat("Відхилення mean від 100 =", mean(xs) - 100, "; sd від 15 =", sd(xs) - 15, "\n")
cat("Викидів за 1.5*IQR:", length(boxplot.stats(xs)$out), "\n")
open_png("hist_sim.png")
hist(xs, breaks = 20, main = "rnorm(1000, 100, 15)", xlab = "Значення", ylab = "Частота", col = "lightblue")
abline(v = 100, col = "red", lwd = 2)
dev.off()
open_png("boxplot_sim.png", 800, 800)
boxplot(xs, main = "Boxplot rnorm(1000, 100, 15)", ylab = "Значення", col = "lightgreen")
dev.off()

# ---------------------------------------------------------------- F
hdr("F. Порівняння двох груп (п.33)")
group_A <- c(70, 72, 75, 76, 78, 80, 81, 83, 85, 87)
group_B <- c(50, 60, 65, 75, 80, 85, 90, 95, 100, 110)
grp <- data.frame(
  group = c("A", "B"),
  mean = c(mean(group_A), mean(group_B)),
  median = c(median(group_A), median(group_B)),
  sd = c(sd(group_A), sd(group_B)),
  var = c(var(group_A), var(group_B)),
  IQR = c(IQR(group_A), IQR(group_B)),
  range = c(diff(range(group_A)), diff(range(group_B))),
  CV_pct = c(cv_fun(group_A), cv_fun(group_B))
)
print(grp, digits = 6)
open_png("boxplot_groups.png")
boxplot(group_A, group_B, names = c("Група A", "Група B"), main = "Порівняння двох груп",
        ylab = "Результат", col = c("lightblue", "khaki"))
dev.off()

# ---------------------------------------------------------------- G
hdr("G. Завдання підвищеної складності (п.42)")
set.seed(2026)
y <- round(rnorm(1000, mean = 75, sd = 12), 1)
y2 <- c(y, 150, 160, 170, 180, 200)
g <- data.frame(
  characteristic = c("n", "mean", "median", "sd", "IQR", "min", "max"),
  before = c(length(y), mean(y), median(y), sd(y), IQR(y), min(y), max(y)),
  after = c(length(y2), mean(y2), median(y2), sd(y2), IQR(y2), min(y2), max(y2))
)
g$change_abs <- g$after - g$before
g$change_pct <- (g$after / g$before - 1) * 100
print(g, digits = 6)
cat("Викидів за 1.5*IQR до:", length(boxplot.stats(y)$out), " після:", length(boxplot.stats(y2)$out), "\n")
cat("Межі до: ", quantile(y, 0.25) - 1.5 * IQR(y), quantile(y, 0.75) + 1.5 * IQR(y), "\n")
cat("Межі після: ", quantile(y2, 0.25) - 1.5 * IQR(y2), quantile(y2, 0.75) + 1.5 * IQR(y2), "\n")
open_png("hist_hard.png")
hist(y2, breaks = 30, main = "Вибірка з п'ятьма викидами", xlab = "Значення", ylab = "Частота", col = "lightblue")
dev.off()
open_png("boxplot_hard.png")
boxplot(y, y2, names = c("без викидів", "з викидами"), main = "Завдання підвищеної складності", ylab = "Значення", col = c("lightgreen", "salmon"))
dev.off()

hdr("Кінець")
sink()
