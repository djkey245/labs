# ЛР8: Кореляційний аналіз даних у R. Запуск з папки submission/:
#   Rscript lab08.R > results/console_output.txt 2>&1
dir.create("plots", showWarnings = FALSE); dir.create("results", showWarnings = FALSE)
dir.create("data", showWarnings = FALSE)
fam <- "Arial Unicode MS"  # коректна кирилиця на macOS
save_png <- function(name, expr, w = 7, h = 6) {
  png(file.path("plots", name), width = w, height = h, units = "in", res = 150, family = fam)
  force(expr); dev.off()
}

# ===========================================================
# ЛАБОРАТОРНА РОБОТА: Кореляційний аналіз даних у R
# ===========================================================

# 1. Підготовка середовища
rm(list = ls())
set.seed(123)
fam <- "Arial Unicode MS"
save_png <- function(name, expr, w = 7, h = 6) {
  png(file.path("plots", name), width = w, height = h, units = "in", res = 150, family = fam)
  force(expr); invisible(dev.off())
}

# 2. Кількість студентів
n <- 150

# 3. Формування навчального набору даних
Study_Hours <- round(runif(n, 2, 20), 1)

Attendance <- round(
  pmin(pmax(rnorm(n, 75 + Study_Hours * 0.7, 10), 40), 100), 1
)

Assignments <- round(
  pmin(pmax(rnorm(n, 45 + Study_Hours * 2.4, 12), 20), 100), 1
)

Stress <- round(
  pmin(pmax(rnorm(n, 7 - Study_Hours * 0.12, 1.5), 1), 10), 1
)

Score <- round(
  pmin(pmax(
    20 + Study_Hours * 1.5 +
      Attendance * 0.20 +
      Assignments * 0.25 -
      Stress * 1.2 +
      rnorm(n, 0, 8),
    0
  ), 100), 1
)

students <- data.frame(
  Study_Hours,
  Attendance,
  Assignments,
  Stress,
  Score
)
write.csv(students, "data/students.csv", row.names = FALSE)

# 4. Перегляд даних
print(head(students, 10))

# 5. Структура набору даних
str(students)

# 6. Загальна статистика
print(summary(students))

# 7. Кількість рядків і стовпців
print(dim(students))

# 8. Перевірка пропущених значень
print(colSums(is.na(students)))

# ---------- Завдання 2. Первинний візуальний аналіз ----------
# 1. Навчальний час і підсумковий бал
save_png("01_scatter_hours_score.png", {
  plot(
    students$Study_Hours,
    students$Score,
    main = "Навчальний час і підсумковий бал",
    xlab = "Години навчання на тиждень",
    ylab = "Підсумковий бал",
    pch = 19
  )
  # Лінійний тренд
  abline(
    lm(Score ~ Study_Hours, data = students),
    lwd = 2
  )
})

# 2. Відвідуваність і підсумковий бал
save_png("02_scatter_attendance_score.png", {
  plot(
    students$Attendance,
    students$Score,
    main = "Відвідуваність і підсумковий бал",
    xlab = "Відвідуваність, %",
    ylab = "Підсумковий бал",
    pch = 19
  )
  abline(
    lm(Score ~ Attendance, data = students),
    lwd = 2
  )
})

# 3. Рівень стресу і підсумковий бал
save_png("03_scatter_stress_score.png", {
  plot(
    students$Stress,
    students$Score,
    main = "Стрес і підсумковий бал",
    xlab = "Рівень стресу (1–10)",
    ylab = "Підсумковий бал",
    pch = 19
  )
  abline(
    lm(Score ~ Stress, data = students),
    lwd = 2
  )
})

# ---------- Завдання 3. Коефіцієнт Пірсона ----------
# Коефіцієнт кореляції Пірсона
r_pearson <- cor(
  students$Study_Hours,
  students$Score,
  method = "pearson"
)
print(r_pearson)

# Перевірка статистичної значущості
test_pearson <- cor.test(
  students$Study_Hours,
  students$Score,
  method = "pearson",
  alternative = "two.sided",
  conf.level = 0.95
)
print(test_pearson)

# Окреме отримання результатів
cat("Коефіцієнт Пірсона:", test_pearson$estimate, "\n")
cat("p-value:", test_pearson$p.value, "\n")
cat("95% довірчий інтервал:",
    test_pearson$conf.int[1], "—",
    test_pearson$conf.int[2], "\n")

# ---------- Завдання 4. Коефіцієнт Спірмена ----------
# Коефіцієнт кореляції Спірмена
r_spearman <- cor(
  students$Study_Hours,
  students$Score,
  method = "spearman"
)
print(r_spearman)

# Перевірка статистичної значущості
test_spearman <- cor.test(
  students$Study_Hours,
  students$Score,
  method = "spearman",
  alternative = "two.sided",
  exact = FALSE,
  conf.level = 0.95
)
print(test_spearman)

cat("Коефіцієнт Спірмена:",
    test_spearman$estimate, "\n")
cat("p-value:", test_spearman$p.value, "\n")

# ---------- Завдання 5. Кореляційна матриця ----------
# Вибір числових змінних
numeric_data <- students[
  , sapply(students, is.numeric)
]

# Кореляційна матриця Пірсона
cor_matrix_pearson <- cor(
  numeric_data,
  method = "pearson",
  use = "complete.obs"
)
# Виведення матриці
print(round(cor_matrix_pearson, 3))

cor_matrix_spearman <- cor(
  numeric_data,
  method = "spearman",
  use = "complete.obs"
)

print(round(cor_matrix_spearman, 3))

# ---------- Завдання 6. Теплова карта ----------
if (!requireNamespace("corrplot", quietly = TRUE)) {
  install.packages("corrplot")
}
library(corrplot)
# Теплова карта: Пірсон
save_png("04_heatmap_pearson.png", {
  corrplot(
    cor_matrix_pearson,
    method = "color",
    type = "upper",
    order = "original",
    addCoef.col = "black",
    number.cex = 0.8,
    tl.col = "black",
    tl.srt = 45,
    diag = FALSE,
    title = "Кореляційна матриця Пірсона",
    mar = c(0, 0, 2, 0)
  )
})

# Теплова карта: Спірмен
save_png("05_heatmap_spearman.png", {
  corrplot(
    cor_matrix_spearman,
    method = "color",
    type = "upper",
    order = "original",
    addCoef.col = "black",
    number.cex = 0.8,
    tl.col = "black",
    tl.srt = 45,
    diag = FALSE,
    title = "Кореляційна матриця Спірмена",
    mar = c(0, 0, 2, 0)
  )
})

# ---------- Завдання 7. Значущість усіх пар ----------
# Функція для матриці p-value
get_p_matrix <- function(data, method = "pearson") {

  k <- ncol(data)
  p_matrix <- matrix(
    NA_real_,
    nrow = k,
    ncol = k,
    dimnames = list(names(data), names(data))
  )
  for (i in seq_len(k)) {
    for (j in seq_len(k)) {

      if (i == j) {
        p_matrix[i, j] <- 0
      } else {
        test <- cor.test(
          data[[i]],
          data[[j]],
          method = method,
          exact = if (method == "spearman") FALSE else NULL
        )

        p_matrix[i, j] <- test$p.value
      }
    }
  }
  return(p_matrix)
}
# Матриці значущості
p_pearson <- get_p_matrix(
  numeric_data,
  method = "pearson"
)
p_spearman <- get_p_matrix(
  numeric_data,
  method = "spearman"
)
# Виведення p-value
print(round(p_pearson, 4))
print(round(p_spearman, 4))

# Позначення значущих пар
alpha <- 0.05
significant_pearson <- p_pearson < alpha
significant_spearman <- p_spearman < alpha
diag(significant_pearson) <- FALSE
diag(significant_spearman) <- FALSE
print(significant_pearson)
print(significant_spearman)

# Корекція множинних перевірок:
# використовуємо лише унікальні пари
upper_index <- upper.tri(p_pearson)
adjusted_p_pearson <- matrix(
  NA_real_,
  nrow = ncol(numeric_data),
  ncol = ncol(numeric_data),
  dimnames = list(names(numeric_data), names(numeric_data))
)
adjusted_p_pearson[upper_index] <- p.adjust(
  p_pearson[upper_index],
  method = "BH"
)

# Відновлюємо симетричну матрицю
adjusted_p_pearson[
  lower.tri(adjusted_p_pearson)
] <- t(adjusted_p_pearson)[
  lower.tri(adjusted_p_pearson)
]
print(round(adjusted_p_pearson, 4))

# ---------- Завдання 8. Автоматична інтерпретація ----------
describe_correlation <- function(r) {
  strength <- if (abs(r) < 0.20) {
    "дуже слабкий"
  } else if (abs(r) < 0.40) {
    "слабкий"
  } else if (abs(r) < 0.60) {
    "помірний"
  } else if (abs(r) < 0.80) {
    "сильний"
  } else {
    "дуже сильний"
  }

  direction <- if (r > 0) {
    "додатний"
  } else if (r < 0) {
    "від'ємний"
  } else {
    "нульовий"
  }

  paste(strength, direction, "зв'язок")
}

# Приклад для кореляції навчального часу та бала
r <- cor_matrix_pearson[
  "Study_Hours", "Score"
]
cat("Коефіцієнт:", round(r, 3), "\n")
cat("Інтерпретація:", describe_correlation(r), "\n")

# ---------- Додатково: таблиця унікальних пар (Пірсон + Спірмен + BH) ----------
build_pairs_table <- function(data) {
  nm <- names(data); idx <- which(upper.tri(diag(length(nm))), arr.ind = TRUE)
  res <- do.call(rbind, lapply(seq_len(nrow(idx)), function(k) {
    a <- nm[idx[k, 1]]; b <- nm[idx[k, 2]]
    tp <- cor.test(data[[a]], data[[b]], method = "pearson")
    ts <- cor.test(data[[a]], data[[b]], method = "spearman", exact = FALSE)
    data.frame(pair = paste(a, b, sep = " - "), r_pearson = unname(tp$estimate),
               p_raw = tp$p.value, rho_spearman = unname(ts$estimate),
               p_spearman = ts$p.value, stringsAsFactors = FALSE)
  }))
  res$p_BH <- p.adjust(res$p_raw, method = "BH")
  res$p_spearman_BH <- p.adjust(res$p_spearman, method = "BH")
  res$sig_before <- res$p_raw < 0.05
  res$sig_after_BH <- res$p_BH < 0.05
  res$description <- sapply(res$r_pearson, describe_correlation)
  res
}
pairs_table <- build_pairs_table(numeric_data)
write.csv(pairs_table, "results/pairs_table.csv", row.names = FALSE)
cat("\n=== Таблиця унікальних пар (основний набір) ===\n")
print(format(pairs_table, digits = 4), row.names = FALSE)
cat("Значущих пар (Пірсон) до BH:", sum(pairs_table$sig_before),
    "з", nrow(pairs_table), "; після BH:", sum(pairs_table$sig_after_BH), "\n")
cat("Значущих пар (Спірмен) до BH:", sum(pairs_table$p_spearman < 0.05),
    "; після BH:", sum(pairs_table$p_spearman_BH < 0.05), "\n")
cat("Пари, що втратили значущість після BH:",
    paste(pairs_table$pair[pairs_table$sig_before & !pairs_table$sig_after_BH], collapse = "; "), "\n")

# ---------- 4. Вплив пропущених значень ----------
students_missing <- students

students_missing$Score[c(5, 12, 20)] <- NA
students_missing$Stress[c(8, 15)] <- NA

# Кількість пропусків
print(colSums(is.na(students_missing)))

# Варіант 1: використовувати лише повні рядки
cor_complete <- cor(
  students_missing,
  use = "complete.obs"
)

# Варіант 2: використовувати всі доступні пари
cor_pairwise <- cor(
  students_missing,
  use = "pairwise.complete.obs"
)

print(round(cor_complete, 3))
print(round(cor_pairwise, 3))

# Додатково: обсяг вибірки та різниця
cat("\nПовних рядків (complete.obs):", sum(complete.cases(students_missing)), "з", n, "\n")
cat("Обсяг для пари Study_Hours-Score (pairwise):",
    sum(complete.cases(students_missing[, c("Study_Hours", "Score")])), "\n")
cat("Обсяг для пари Stress-Score (pairwise):",
    sum(complete.cases(students_missing[, c("Stress", "Score")])), "\n")
cat("Обсяг для пари Study_Hours-Attendance (pairwise):",
    sum(complete.cases(students_missing[, c("Study_Hours", "Attendance")])), "\n")
cat("\nРізниця (pairwise - complete), round 3:\n")
print(round(cor_pairwise - cor_complete, 3))
cat("Максимальна абсолютна різниця:", round(max(abs(cor_pairwise - cor_complete)), 4), "\n")
cat("Різниця відносно повних даних (complete - original), максимум:",
    round(max(abs(cor_complete - cor_matrix_pearson)), 4), "\n")
cat("Різниця відносно повних даних (pairwise - original), максимум:",
    round(max(abs(cor_pairwise - cor_matrix_pearson)), 4), "\n")
cat("r(Study_Hours, Score): повні дані =", round(cor_matrix_pearson["Study_Hours", "Score"], 4),
    "; complete =", round(cor_complete["Study_Hours", "Score"], 4),
    "; pairwise =", round(cor_pairwise["Study_Hours", "Score"], 4), "\n")
cat("r(Stress, Score): повні дані =", round(cor_matrix_pearson["Stress", "Score"], 4),
    "; complete =", round(cor_complete["Stress", "Score"], 4),
    "; pairwise =", round(cor_pairwise["Stress", "Score"], 4), "\n")

# ---------- 5. Дані для підсумкового аналізу ----------
cat("\n=== Розділ 5: підсумкові дані ===\n")
sc <- cor_matrix_pearson[, "Score"]; sc <- sc[names(sc) != "Score"]
cat("Пірсон із Score:\n"); print(round(sc, 3))
cat("Спірмен із Score:\n"); ss <- cor_matrix_spearman[, "Score"]; print(round(ss[names(ss) != "Score"], 3))
cat("Найсильніший додатний зв'язок зі Score (Пірсон):", names(which.max(sc)), round(max(sc), 3), "\n")
cat("Від'ємні зв'язки зі Score (Пірсон):", paste(names(sc)[sc < 0], round(sc[sc < 0], 3), collapse = "; "), "\n")
cat("Максимальна різниця |Пірсон - Спірмен| у матриці:",
    round(max(abs(cor_matrix_pearson - cor_matrix_spearman)), 3), "\n")
print(round(abs(cor_matrix_pearson - cor_matrix_spearman), 3))
cat("Значущі до BH (Пірсон):", paste(pairs_table$pair[pairs_table$sig_before], collapse = "; "), "\n")
cat("Значущі після BH (Пірсон):", paste(pairs_table$pair[pairs_table$sig_after_BH], collapse = "; "), "\n")
cat("Не значущі до BH:", paste(pairs_table$pair[!pairs_table$sig_before], collapse = "; "), "\n")

# ===========================================================
# 6. Індивідуальне завдання (варіант 6): Відвідуваність - пропуски
# занять, активність, оцінки
# Дослідницьке запитання: чи пов'язані пропуски занять з активністю
# та підсумковою оцінкою студентів? (дані синтетичні)
# ===========================================================
set.seed(2025)
m <- 120
# Пропуски занять за семестр (0-20, цілі): асиметричний розподіл
Absences <- as.integer(round(pmin(pmax(rgamma(m, shape = 2, scale = 3), 0), 20)))
# Активність на заняттях (бали 0-10): помірно спадає з пропусками
Activity <- round(pmin(pmax(rnorm(m, 7 - 0.25 * Absences, 1.8), 0), 10), 1)
# Підсумкова оцінка (0-100): зростає з активністю, спадає з пропусками;
# після ~10 пропусків спад різко посилюється (монотонний нелінійний зв'язок)
Grade <- round(pmin(pmax(
  72 + 2.5 * (Activity - 5) - 0.8 * Absences - 3.0 * pmax(Absences - 10, 0) +
    rnorm(m, 0, 7), 0), 100), 1)
att_students <- data.frame(Absences, Activity, Grade)
write.csv(att_students, "data/attendance_students.csv", row.names = FALSE)

cat("\n=== Індивідуальне завдання (варіант 6): відвідуваність ===\n")
print(head(att_students, 10)); print(summary(att_students)); print(colSums(is.na(att_students)))

att_pearson <- cor(att_students, method = "pearson")
att_spearman <- cor(att_students, method = "spearman")
cat("Матриця Пірсона:\n"); print(round(att_pearson, 3))
cat("Матриця Спірмена:\n"); print(round(att_spearman, 3))
att_pairs <- build_pairs_table(att_students)
write.csv(att_pairs, "results/att_pairs_table.csv", row.names = FALSE)
print(format(att_pairs, digits = 4), row.names = FALSE)
cat("Значущих пар (Пірсон) до BH:", sum(att_pairs$sig_before), "; після BH:", sum(att_pairs$sig_after_BH), "\n")
cat("Значущих пар (Спірмен) до BH:", sum(att_pairs$p_spearman < 0.05), "; після BH:", sum(att_pairs$p_spearman_BH < 0.05), "\n")
print(cor.test(att_students$Absences, att_students$Grade, method = "pearson"))
print(cor.test(att_students$Absences, att_students$Grade, method = "spearman", exact = FALSE))

save_png("07_att_heatmap_pearson.png", {
  corrplot(att_pearson, method = "color", type = "upper", addCoef.col = "black",
           number.cex = 0.8, tl.col = "black", tl.srt = 45, diag = FALSE,
           title = "Відвідуваність: матриця Пірсона", mar = c(0, 0, 2, 0))
})
save_png("08_att_heatmap_spearman.png", {
  corrplot(att_spearman, method = "color", type = "upper", addCoef.col = "black",
           number.cex = 0.8, tl.col = "black", tl.srt = 45, diag = FALSE,
           title = "Відвідуваність: матриця Спірмена", mar = c(0, 0, 2, 0))
})
save_png("09_att_scatter.png", {
  par(mfrow = c(1, 3), mar = c(4, 4, 3, 1))
  plot(att_students$Absences, att_students$Activity, pch = 19, main = "Пропуски і активність",
       xlab = "Пропуски, занять", ylab = "Активність, бали (0-10)")
  abline(lm(Activity ~ Absences, data = att_students), lwd = 2)
  lines(lowess(att_students$Absences, att_students$Activity), lwd = 2, lty = 2, col = "red")
  plot(att_students$Absences, att_students$Grade, pch = 19, main = "Пропуски і оцінка",
       xlab = "Пропуски, занять", ylab = "Підсумкова оцінка (0-100)")
  abline(lm(Grade ~ Absences, data = att_students), lwd = 2)
  lines(lowess(att_students$Absences, att_students$Grade), lwd = 2, lty = 2, col = "red")
  plot(att_students$Activity, att_students$Grade, pch = 19, main = "Активність і оцінка",
       xlab = "Активність, бали (0-10)", ylab = "Підсумкова оцінка (0-100)")
  abline(lm(Grade ~ Activity, data = att_students), lwd = 2)
  lines(lowess(att_students$Activity, att_students$Grade), lwd = 2, lty = 2, col = "red")
}, w = 12, h = 4.5)
