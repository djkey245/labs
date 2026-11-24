# ЛР9: Ефективність моделей регресії (diamonds): lm, randomForest, xgboost, neuralnet. Запуск з папки submission/
library(dplyr); library(randomForest); library(xgboost); library(neuralnet)
dir.create("plots", showWarnings = FALSE); dir.create("results", showWarnings = FALSE)
sink("results/console_output.txt", split = TRUE)
fam <- "Arial Unicode MS"  # коректна кирилиця на macOS
# neuralnet навчається на ВСІХ даних, як у методичці. Поріг зупинки threshold = 0.1 замість типового 0.01:
# критерій neuralnet - максимальна похідна суми квадратів помилок по ВСІХ рядках, тож він росте з обсягом даних.
# Із 0.01 на 53 940 рядках мережа не зійшлася: після 260 000 кроків градієнт застиг на 0.2615.
NN_THRESHOLD <- 0.1
# Початкові ваги (seed) для блоків 1 і 2. З seed = 123 у блоці 1 rprop застрягав на плато (градієнт 0.2615
# понад 300 000 кроків); з seed = 3 мережа зійшлася за 160 213 кроків.
NN_SEED <- c(3, 123)
# Необов'язковий кеш навчених мереж (навчання триває довго): Sys.setenv(NN_CACHE = "тека") -> моделі
# зберігаються/завантажуються як nn_block1.rds і nn_block2.rds. Без NN_CACHE мережі навчаються з нуля.
NN_CACHE <- Sys.getenv("NN_CACHE", "")
cat("xgboost version:", as.character(packageVersion("xgboost")), "\n")
t_start <- Sys.time()

diamonds <- read.csv("data/diamonds.csv", stringsAsFactors = TRUE)
diamonds_num <- diamonds %>%
  mutate(cut = as.numeric(as.factor(cut)),
         color = as.numeric(as.factor(color)),
         clarity = as.numeric(as.factor(clarity)))
cat("Розмір даних:", nrow(diamonds), "x", ncol(diamonds), "\n")
str(diamonds); print(head(diamonds_num))
print(levels(diamonds$cut)); print(levels(diamonds$color)); print(levels(diamonds$clarity))

normalize <- function(x) (x - min(x)) / (max(x) - min(x))
denorm <- function(norm_value, orig_vector) norm_value * (max(orig_vector) - min(orig_vector)) + min(orig_vector)
features <- setdiff(colnames(diamonds_num), "price")
formula_nn <- as.formula(paste("price ~", paste(features, collapse = " + ")))

# xgboost 3.x: застарілий виклик xgboost(data=, label=) -> використовуємо xgb.train + xgb.DMatrix
fit_xgb <- function(X, y) {
  params <- list(objective = "reg:squarederror", max_depth = 6, eta = 0.1)
  xgb.train(params = params, data = xgb.DMatrix(X, label = y), nrounds = 300, verbose = 0)
}
fit_nn <- function(dnorm_train, block) {
  f <- if (nzchar(NN_CACHE)) file.path(NN_CACHE, sprintf("nn_block%d.rds", block)) else ""
  if (nzchar(f) && file.exists(f)) { cat("Модель NN завантажено з кешу:", basename(f), "(час навчання збережено в моделі)\n"); return(readRDS(f)) }
  set.seed(NN_SEED[block])
  tt <- system.time(m <- neuralnet(formula_nn, data = dnorm_train, hidden = c(10), linear.output = TRUE,
                                   stepmax = 1e6, threshold = NN_THRESHOLD))
  if (is.null(m$weights)) stop("neuralnet не зійшовся за stepmax кроків")
  m$train_time <- unname(tt["elapsed"])  # фактичний час навчання (зберігається і в кеші)
  if (nzchar(f)) saveRDS(m, f)
  m
}

# ============================================================
# БЛОК 1. Методичка: навчання і MSE на ВСІХ даних (in-sample)
# ============================================================
cat("\n===== БЛОК 1: навчання і оцінка на всіх даних =====\n")

# --- 1. Лінійна регресія
model_lm <- lm(price ~ ., data = diamonds_num)
print(summary(model_lm))
pred_lm <- predict(model_lm, newdata = diamonds_num)
mse_lm <- mean((pred_lm - diamonds_num$price)^2)
cat("MSE лінійної моделі:", mse_lm, "\n")
cat("RMSE лінійної моделі:", sqrt(mse_lm), "\n")
png("plots/01_lm_diagnostics.png", width = 10, height = 8, units = "in", res = 130, family = fam)
par(mfrow = c(2, 2)); plot(model_lm); par(mfrow = c(1, 1)); dev.off()

# --- 2. Random Forest
set.seed(123)
tt <- system.time(rf_model <- randomForest(price ~ ., data = diamonds_num, ntree = 500, mtry = 4, importance = TRUE))
cat("Час RF (с):", tt["elapsed"], "\n")
print(rf_model)
pred_rf <- predict(rf_model, diamonds_num)
mse_rf <- mean((pred_rf - diamonds_num$price)^2)
cat("MSE random forest:", mse_rf, "\n")
print(importance(rf_model))
png("plots/02_rf_importance.png", width = 10, height = 6, units = "in", res = 130, family = fam)
varImpPlot(rf_model, main = "Важливість ознак (Random Forest)"); dev.off()

# --- 3. XGBoost
X <- as.matrix(diamonds_num %>% select(-price)); y <- diamonds_num$price
tt <- system.time(xgb_model <- fit_xgb(X, y))
cat("Час XGBoost (с):", tt["elapsed"], "\n")
pred_xgb <- predict(xgb_model, X)
mse_xgb <- mean((pred_xgb - y)^2)
cat("MSE XGBoost:", mse_xgb, "\n")
imp <- xgb.importance(model = xgb_model); print(imp)
png("plots/03_xgb_importance.png", width = 9, height = 5.5, units = "in", res = 130, family = fam)
par(mar = c(5, 6, 4, 2)); imp_o <- imp[order(imp$Gain), ]
barplot(imp_o$Gain, names.arg = imp_o$Feature, horiz = TRUE, las = 1, col = "steelblue",
        main = "Важливість ознак (XGBoost, Gain)", xlab = "Gain"); dev.off()

# --- 4. neuralnet
diamonds_norm <- as.data.frame(lapply(diamonds_num, normalize))
cat("Рядків для навчання NN (блок 1):", nrow(diamonds_norm), "; threshold =", NN_THRESHOLD, "\n")
nn_model <- fit_nn(diamonds_norm, 1)
time_nn1 <- nn_model$train_time
cat("Час neuralnet (с):", time_nn1, "\n")
print(nn_model$result.matrix[1:3, , drop = FALSE])
png("plots/04_nn_graph.png", width = 11, height = 7, units = "in", res = 130, family = fam)
plot(nn_model, rep = "best", information = FALSE)  # вбудований підпис обрізається - додаємо власний
grid::grid.text(sprintf("Error: %.4f   Steps: %d", nn_model$result.matrix["error", 1],
                        as.integer(nn_model$result.matrix["steps", 1])),
                x = 0.5, y = 0.03, gp = grid::gpar(fontsize = 12, fontfamily = fam)); dev.off()
pred <- compute(nn_model, diamonds_norm[, features])$net.result
pred_price <- denorm(pred, diamonds_num$price)
cat("pred (нормалізоване, 0..1) summary:\n"); print(summary(as.vector(pred)))
cat("pred_price ($) summary:\n"); print(summary(as.vector(pred_price)))
comparison_table <- data.frame(Real_Price = diamonds_num$price, Predicted_Price = pred_price)
print(head(comparison_table, 20))
mse_nn <- mean((pred_price - diamonds_num$price)^2)
cat("MSE neuralnet:", mse_nn, "\n")

in_tab <- data.frame(Model = c("lm", "randomForest", "xgboost", "neuralnet"),
                     MSE = c(mse_lm, mse_rf, mse_xgb, mse_nn))
in_tab$RMSE <- sqrt(in_tab$MSE)
cat("\nТАБЛИЦЯ (in-sample, всі дані):\n"); print(in_tab)

# ============================================================
# БЛОК 2. Чесне порівняння: train/test 80/20
# ============================================================
cat("\n===== БЛОК 2: train/test 80/20 =====\n")
set.seed(123)
idx <- sample(nrow(diamonds_num), floor(0.8 * nrow(diamonds_num)))
train <- diamonds_num[idx, ]; test <- diamonds_num[-idx, ]
cat("train:", nrow(train), " test:", nrow(test), "\n")
ev <- function(pred, real) { m <- mean((pred - real)^2); c(MSE = m, RMSE = sqrt(m), R2 = 1 - sum((pred - real)^2) / sum((real - mean(real))^2)) }

lm2 <- lm(price ~ ., data = train)
p_lm <- predict(lm2, newdata = test)

set.seed(123)
rf2 <- randomForest(price ~ ., data = train, ntree = 500, mtry = 4)
p_rf <- predict(rf2, test)

xgb2 <- fit_xgb(as.matrix(train %>% select(-price)), train$price)
p_xgb <- predict(xgb2, as.matrix(test %>% select(-price)))

mn <- sapply(diamonds_num, min); mx <- sapply(diamonds_num, max)  # нормалізація за всіма даними, як у методичці
norm_df <- function(d) as.data.frame(lapply(names(d), function(n) (d[[n]] - mn[n]) / (mx[n] - mn[n])), col.names = names(d))
train_n <- norm_df(train); test_n <- norm_df(test)
cat("Рядків для навчання NN (блок 2):", nrow(train_n), "; threshold =", NN_THRESHOLD, "\n")
nn2 <- fit_nn(train_n, 2)
time_nn2 <- nn2$train_time
cat("Час neuralnet, блок 2 (с):", time_nn2, "\n")
print(nn2$result.matrix[1:3, , drop = FALSE])
p_nn <- as.vector(compute(nn2, test_n[, features])$net.result) * (mx["price"] - mn["price"]) + mn["price"]

te <- rbind(lm = ev(p_lm, test$price), randomForest = ev(p_rf, test$price),
            xgboost = ev(p_xgb, test$price), neuralnet = ev(p_nn, test$price))
cat("\nТАБЛИЦЯ (test, 20% даних):\n"); print(te)
cat("R2 lm (in-sample, summary):", summary(model_lm)$r.squared, "\n")
cat("R2 всіх моделей in-sample:\n")
print(c(lm = ev(pred_lm, y)["R2"], rf = ev(pred_rf, y)["R2"], xgb = ev(pred_xgb, y)["R2"], nn = ev(as.vector(pred_price), y)["R2"]))

# Графіки
png("plots/05_pred_vs_actual.png", width = 10, height = 9, units = "in", res = 130, family = fam)
par(mfrow = c(2, 2))
preds <- list(lm = p_lm, randomForest = p_rf, xgboost = p_xgb, neuralnet = p_nn)
for (nm in names(preds)) {
  plot(test$price, preds[[nm]], pch = 16, cex = 0.3, col = rgb(0, 0, 1, 0.3), xlab = "Реальна ціна ($)",
       ylab = "Прогноз ($)", main = paste0(nm, " (test): MSE = ", round(te[nm, "MSE"])))
  abline(0, 1, col = "red", lwd = 2)
}
par(mfrow = c(1, 1)); dev.off()

png("plots/06_mse_compare.png", width = 9, height = 5.5, units = "in", res = 130, family = fam)
mm <- rbind(`На всіх даних` = in_tab$MSE, `Test 20%` = te[, "MSE"])
colnames(mm) <- in_tab$Model
par(mar = c(5, 6, 4, 2))
bp <- barplot(mm / 1000, beside = TRUE, col = c("lightgray", "steelblue"), ylim = c(0, max(mm) / 1000 * 1.15),
        legend.text = rownames(mm), args.legend = list(x = "topright", bty = "n"),
        main = "MSE моделей", ylab = "MSE, тис. $²", las = 1)
text(bp, mm / 1000, labels = format(round(mm / 1000), big.mark = " "), pos = 3, cex = 0.8); dev.off()

cat("\nЗагальний час скрипта (хв):", as.numeric(difftime(Sys.time(), t_start, units = "mins")), "\n")
sink()
