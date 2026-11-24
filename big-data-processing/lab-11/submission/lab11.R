# ЛР11: Лінійна регресія vs нейромережа neuralnet (Grades, синтетичні дані, Варіант B)
# Запуск з папки submission/:  Rscript lab11.R > results/console_output.txt 2>&1
library(neuralnet)
dir.create("data", showWarnings = FALSE); dir.create("plots", showWarnings = FALSE)
dir.create("results", showWarnings = FALSE)
fam <- "Arial Unicode MS"  # коректна кирилиця на macOS
open_png <- function(name, w = 8, h = 5.5)
  png(file.path("plots", name), width = w, height = h, units = "in", res = 150, family = fam)

## ---------------- Крок 1. Дані (Варіант B) ----------------
set.seed(2025)
n <- 1388
students <- data.frame(
  Socioeconomic.Score = runif(n, 20, 100),
  Study.Hours = runif(n, 0, 8),
  Sleep.Hours = runif(n, 4, 10),
  Attendance = runif(n, 50, 100)
)
# Нелінійна складова включена лише для навчальної демонстрації порівняння моделей
noise <- rnorm(n, mean = 0, sd = 3)
students$Grades <- 35 +
  0.18 * students$Socioeconomic.Score +
  2.2 * students$Study.Hours +
  1.1 * students$Sleep.Hours +
  0.12 * students$Attendance -
  0.22 * (students$Study.Hours - 4)^2 +
  noise
# Обмежимо оцінку навчальним діапазоном 0-100
students$Grades <- pmin(100, pmax(0, students$Grades))
write.csv(students, "data/students_synthetic.csv", row.names = FALSE)

head(students)
summary(students)
str(students)

required <- c("Grades", "Socioeconomic.Score", "Study.Hours",
              "Sleep.Hours", "Attendance")
stopifnot(all(required %in% names(students)))
stopifnot(all(vapply(students[required], is.numeric, logical(1))))
colSums(is.na(students[required]))
students <- students[complete.cases(students[required]), required]
cat("Спостережень після complete.cases:", nrow(students), "\n")
cat("Grades == 0:", sum(students$Grades == 0), "; Grades == 100:", sum(students$Grades == 100), "\n")

## ---------------- Крок 2. Поділ 80/20 ----------------
set.seed(123)
n_total <- nrow(students)
train_id <- sample(seq_len(n_total), size = floor(0.80 * n_total))

train_data <- students[train_id, , drop = FALSE]
test_data <- students[-train_id, , drop = FALSE]

c(train_n = nrow(train_data), test_n = nrow(test_data))

## ---------------- Крок 3. Первинний опис ----------------
summary(train_data)
cat("sd Grades (train):", sd(train_data$Grades), "\n")
print(round(cor(train_data), 3))
open_png("hist_grades.png")
hist(train_data$Grades,
     main = "Розподіл оцінок у навчальній вибірці",
     xlab = "Grades", col = "lightblue", border = "white")
dev.off()
open_png("boxplot_grades.png", 5, 5.5)
boxplot(train_data$Grades,
        main = "Діаграма розмаху оцінок",
        ylab = "Grades", col = "lightgreen")
dev.off()

## ---------------- Крок 4. Базова модель ----------------
y_test <- test_data$Grades
pred_mean <- rep(mean(train_data$Grades), length(y_test))

## ---------------- Крок 5. Лінійна регресія ----------------
formula_model <- Grades ~ Socioeconomic.Score + Study.Hours +
  Sleep.Hours + Attendance

model_lm <- lm(formula_model, data = train_data)
summary(model_lm)

pred_lm <- predict(model_lm, newdata = test_data)
head(data.frame(actual = y_test, predicted_lm = pred_lm))

# Еквівалентна за суттю гаусова лінійна модель
model_glm <- glm(formula_model, data = train_data,
                 family = gaussian(link = "identity"))
print(all.equal(coef(model_lm), coef(model_glm)))
print(all.equal(as.numeric(pred_lm),
                as.numeric(predict(model_glm, newdata = test_data))))

## ---------------- Крок 6. Нормалізація min-max ----------------
scale_min <- vapply(train_data[required], min, numeric(1))
scale_max <- vapply(train_data[required], max, numeric(1))
scale_range <- scale_max - scale_min

# Захист від сталої змінної, щоб уникнути ділення на нуль
scale_range[scale_range == 0] <- 1
minmax_apply <- function(data, mins, ranges) {
  out <- as.data.frame(scale(data, center = mins, scale = ranges))
  names(out) <- names(data)
  out
}
train_scaled <- minmax_apply(train_data[required], scale_min, scale_range)
test_scaled <- minmax_apply(test_data[required], scale_min, scale_range)

summary(train_scaled)
summary(test_scaled)

## ---------------- Крок 7. Нейронна мережа ----------------
set.seed(456)
t0 <- Sys.time()
model_nn <- neuralnet(
  Grades ~ Socioeconomic.Score + Study.Hours + Sleep.Hours + Attendance,
  data = train_scaled,
  hidden = c(6, 4, 2),
  linear.output = TRUE,
  stepmax = 1e6,
  threshold = 0.01,
  lifesign = "minimal"
)
nn_time <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
cat("Час навчання NN (c(6,4,2)), с:", round(nn_time, 1), "\n")
print(model_nn$result.matrix[1:4, , drop = FALSE])
cat("Збіжність: error =", model_nn$result.matrix["error", 1],
    "; reached.threshold =", model_nn$result.matrix["reached.threshold", 1],
    "; steps =", model_nn$result.matrix["steps", 1], "\n")
open_png("nn_structure.png", 10, 7)
plot(model_nn, rep = "best", show.weights = FALSE,
     information = TRUE, fontsize = 9, x.entry = 0.2, x.out = 0.85)
dev.off()

## ---------------- Крок 8. Прогнозування ----------------
x_test_scaled <- test_scaled[, c("Socioeconomic.Score", "Study.Hours",
                                 "Sleep.Hours", "Attendance"), drop = FALSE]
nn_result <- compute(model_nn, x_test_scaled)
pred_nn_scaled <- as.numeric(nn_result$net.result)

grades_min <- scale_min["Grades"]
grades_range <- scale_range["Grades"]
pred_nn <- pred_nn_scaled * grades_range + grades_min

head(data.frame(actual = y_test,
                pred_lm = as.numeric(pred_lm),
                pred_nn = pred_nn))

## ---------------- Крок 9. Метрики ----------------
metrics <- function(actual, predicted) {
  mse <- mean((actual - predicted)^2)
  rmse <- sqrt(mse)
  mae <- mean(abs(actual - predicted))
  r2 <- 1 - sum((actual - predicted)^2) /
    sum((actual - mean(actual))^2)
  c(MSE = mse, RMSE = rmse, MAE = mae, R2_test = r2)
}

results <- rbind(
  Mean_baseline = metrics(y_test, pred_mean),
  Linear_model = metrics(y_test, as.numeric(pred_lm)),
  Neural_network = metrics(y_test, pred_nn)
)
print(round(results, 4))
write.csv(round(results, 4), "results/metrics.csv")

## ---------------- Крок 10. Графіки ----------------
open_png("actual_vs_pred.png", 10, 5)
par(mfrow = c(1, 2))
plot(y_test, pred_lm,
     main = "Лінійна регресія",
     xlab = "Фактичні Grades",
     ylab = "Прогнозовані Grades",
     pch = 19, col = "darkgreen")
abline(a = 0, b = 1, col = "red", lwd = 2)
plot(y_test, pred_nn,
     main = "Нейронна мережа",
     xlab = "Фактичні Grades",
     ylab = "Прогнозовані Grades",
     pch = 19, col = "navy")
abline(a = 0, b = 1, col = "red", lwd = 2)
par(mfrow = c(1, 1))
dev.off()

resid_lm <- y_test - as.numeric(pred_lm)
resid_nn <- y_test - pred_nn
cat("Залишки: mean lm =", mean(resid_lm), "; mean nn =", mean(resid_nn),
    "; sd lm =", sd(resid_lm), "; sd nn =", sd(resid_nn), "\n")

open_png("residuals.png", 10, 5)
par(mfrow = c(1, 2))
plot(pred_lm, resid_lm,
     main = "Залишки лінійної моделі",
     xlab = "Прогноз", ylab = "Фактичне - прогноз",
     pch = 19, col = "darkgreen")
abline(h = 0, col = "red", lwd = 2)
plot(pred_nn, resid_nn,
     main = "Залишки нейромережі",
     xlab = "Прогноз", ylab = "Фактичне - прогноз",
     pch = 19, col = "navy")
abline(h = 0, col = "red", lwd = 2)
par(mfrow = c(1, 1))
dev.off()

# Залишки за Study.Hours (де закладена нелінійність)
open_png("residuals_vs_study.png", 10, 5)
par(mfrow = c(1, 2))
plot(test_data$Study.Hours, resid_lm, main = "Залишки lm vs Study.Hours",
     xlab = "Study.Hours", ylab = "Фактичне - прогноз", pch = 19, col = "darkgreen")
abline(h = 0, col = "red", lwd = 2)
plot(test_data$Study.Hours, resid_nn, main = "Залишки NN vs Study.Hours",
     xlab = "Study.Hours", ylab = "Фактичне - прогноз", pch = 19, col = "navy")
abline(h = 0, col = "red", lwd = 2)
par(mfrow = c(1, 1))
dev.off()

# Самост. 7: діагностика lm
open_png("lm_diagnostics.png", 9, 9)
par(mfrow = c(2, 2))
plot(model_lm)
par(mfrow = c(1, 1))
dev.off()
cat("Shapiro-Wilk залишків lm (train):\n"); print(shapiro.test(residuals(model_lm)))

## ---------------- Допоміжна функція fit_nn (для кроку 11, самост. 5, 6, 9) ----------------
# Масштабує за train, навчає NN, повертає прогноз у початковій шкалі
fit_nn <- function(train, test, hidden, seed) {
  mn <- vapply(train[required], min, numeric(1))
  rg <- vapply(train[required], max, numeric(1)) - mn
  rg[rg == 0] <- 1
  tr_s <- minmax_apply(train[required], mn, rg)
  te_s <- minmax_apply(test[required], mn, rg)
  set.seed(seed)
  t0 <- Sys.time()
  m <- tryCatch(suppressWarnings(neuralnet(
    Grades ~ Socioeconomic.Score + Study.Hours + Sleep.Hours + Attendance,
    data = tr_s, hidden = hidden, linear.output = TRUE,
    stepmax = 1e6, threshold = 0.01)), error = function(e) NULL)
  el <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  conv <- !is.null(m) && !is.null(m$result.matrix) &&
    "reached.threshold" %in% rownames(m$result.matrix)
  if (!conv) return(list(converged = FALSE, time = el, steps = NA, pred = rep(NA_real_, nrow(test))))
  p <- as.numeric(compute(m, te_s[setdiff(required, "Grades")])$net.result)
  list(converged = TRUE, time = el, steps = unname(m$result.matrix["steps", 1]),
       pred = p * rg["Grades"] + mn["Grades"])
}
hid_str <- function(h) paste0("c(", paste(h, collapse = ","), ")")

## ---------------- Крок 11 / Самост. 5: архітектури ----------------
cat("\n===== Крок 11 / Самост. 5: архітектури (один поділ, seed NN = 456) =====\n")
architectures <- list(c(5, 3, 2), c(5, 4, 2), c(6, 4, 2), c(6, 3))
arch_tab <- do.call(rbind, lapply(architectures, function(h) {
  r <- fit_nn(train_data, test_data, h, 456)
  m <- if (r$converged) metrics(y_test, r$pred) else rep(NA_real_, 4)
  data.frame(seed = 456, hidden = hid_str(h), converged = r$converged,
             steps = r$steps, time_s = round(r$time, 1),
             MSE = m[1], RMSE = m[2], MAE = m[3], R2_test = m[4], row.names = NULL)
}))
arch_tab[, 6:9] <- round(arch_tab[, 6:9], 4)
print(arch_tab)
write.csv(arch_tab, "results/architectures.csv", row.names = FALSE)

# Правильна процедура: добір архітектури на валідації всередині train
cat("\n--- Добір архітектури на валідації (train -> train' 80% / val 20%, тест не використовується) ---\n")
set.seed(99)
in_id <- sample(seq_len(nrow(train_data)), size = floor(0.8 * nrow(train_data)))
tr_in <- train_data[in_id, ]; val <- train_data[-in_id, ]
cat("train' =", nrow(tr_in), "; val =", nrow(val), "\n")
val_tab <- do.call(rbind, lapply(architectures, function(h) {
  r <- fit_nn(tr_in, val, h, 456)
  data.frame(hidden = hid_str(h), converged = r$converged,
             val_RMSE = if (r$converged) round(metrics(val$Grades, r$pred)["RMSE"], 4) else NA,
             row.names = NULL)
}))
print(val_tab)
write.csv(val_tab, "results/architectures_validation.csv", row.names = FALSE)
best_h <- architectures[[which.min(val_tab$val_RMSE)]]
cat("Обрана за валідацією архітектура:", hid_str(best_h), "\n")
r_best <- fit_nn(train_data, test_data, best_h, 456)
cat("Фінальна тестова оцінка обраної архітектури (один раз):\n")
print(round(metrics(y_test, r_best$pred), 4))

## ---------------- Самост. 6: вплив seed поділу ----------------
cat("\n===== Самост. 6: повторні поділи =====\n")
split_seeds <- c(123, 1, 42, 2024, 777, 31415, 9)
seed_tab <- do.call(rbind, lapply(split_seeds, function(s) {
  set.seed(s)
  id <- sample(seq_len(n_total), size = floor(0.80 * n_total))
  tr <- students[id, ]; te <- students[-id, ]
  lmm <- lm(formula_model, data = tr)
  rm_lm <- sqrt(mean((te$Grades - predict(lmm, te))^2))
  rm_base <- sqrt(mean((te$Grades - mean(tr$Grades))^2))
  r <- fit_nn(tr, te, c(6, 4, 2), 456)
  data.frame(split_seed = s, RMSE_baseline = round(rm_base, 4), RMSE_lm = round(rm_lm, 4),
             RMSE_nn = if (r$converged) round(sqrt(mean((te$Grades - r$pred)^2)), 4) else NA,
             nn_converged = r$converged, nn_time_s = round(r$time, 1), row.names = NULL)
}))
seed_tab$nn_better <- seed_tab$RMSE_nn < seed_tab$RMSE_lm
print(seed_tab)
write.csv(seed_tab, "results/seeds.csv", row.names = FALSE)
ok <- seed_tab[seed_tab$nn_converged, ]
cat(sprintf("lm: mean RMSE = %.4f, sd = %.4f\n", mean(seed_tab$RMSE_lm), sd(seed_tab$RMSE_lm)))
cat(sprintf("nn (збіглись %d з %d): mean RMSE = %.4f, sd = %.4f\n", nrow(ok), nrow(seed_tab),
            mean(ok$RMSE_nn), sd(ok$RMSE_nn)))
cat("NN краща за lm у", sum(ok$nn_better), "з", nrow(ok), "поділів\n")
open_png("seeds_rmse.png", 8, 5)
matplot(seq_len(nrow(seed_tab)), cbind(seed_tab$RMSE_lm, seed_tab$RMSE_nn), type = "b",
        pch = 19, lty = 1, col = c("darkgreen", "navy"), xaxt = "n",
        ylim = range(seed_tab$RMSE_lm, seed_tab$RMSE_nn) + c(-0.08, 0.01),
        xlab = "seed поділу", ylab = "Тестове RMSE", main = "RMSE на різних поділах 80/20")
axis(1, at = seq_len(nrow(seed_tab)), labels = seed_tab$split_seed)
legend("bottom", c("Лінійна модель", "Нейромережа c(6,4,2)"), col = c("darkgreen", "navy"),
       pch = 19, lty = 1, horiz = TRUE, bty = "n")
dev.off()

## ---------------- Самост. 9: підмножини предикторів ----------------
cat("\n===== Самост. 9: підмножини предикторів (вибір на валідації) =====\n")
subsets <- list(
  all4 = c("Socioeconomic.Score", "Study.Hours", "Sleep.Hours", "Attendance"),
  no_Socio = c("Study.Hours", "Sleep.Hours", "Attendance"),
  no_Attendance = c("Socioeconomic.Score", "Study.Hours", "Sleep.Hours"),
  Study_Sleep = c("Study.Hours", "Sleep.Hours"),
  Study_only = c("Study.Hours")
)
rmse <- function(a, p) sqrt(mean((a - p)^2))
sub_tab <- do.call(rbind, lapply(names(subsets), function(nm) {
  f <- reformulate(subsets[[nm]], response = "Grades")
  m_in <- lm(f, data = tr_in)
  data.frame(model = nm, predictors = paste(subsets[[nm]], collapse = " + "),
             val_RMSE = round(rmse(val$Grades, predict(m_in, val)), 4), row.names = NULL)
}))
best_sub <- sub_tab$model[which.min(sub_tab$val_RMSE)]
# Для інформації: тестове RMSE після перенавчання на всьому train (використовується лише обрана)
fit_full <- function(nm) lm(reformulate(subsets[[nm]], response = "Grades"), data = train_data)
sub_tab$chosen <- sub_tab$model == best_sub
print(sub_tab)
write.csv(sub_tab, "results/subsets.csv", row.names = FALSE)
cat("Обрано за валідацією:", best_sub, "\n")
m_final <- fit_full(best_sub)
cat("Фінальна тестова оцінка обраної моделі (один раз):\n")
print(round(metrics(y_test, predict(m_final, test_data)), 4))
cat("Для довідки: lm all4 на тесті RMSE =", round(rmse(y_test, predict(model_lm, test_data)), 4), "\n")
cat("\nГотово.\n")
