# ЛР10: Прогноз електроспоживання, гібрид ARIMA + XGBoost (vic_elec, липень 2014)
# Запуск з папки submission/:  Rscript lab10.R > results/console_output.txt 2>&1
suppressPackageStartupMessages({
  library(tsibbledata); library(fpp3); library(ggplot2)
  library(xgboost); library(Matrix); library(dplyr); library(lubridate)
})
dir.create("plots", showWarnings = FALSE); dir.create("results", showWarnings = FALSE)
fam <- "Arial Unicode MS"  # коректна кирилиця на macOS
save_plot <- function(p, name, w = 9, h = 5)
  ggsave(file.path("plots", name), p + theme(text = element_text(family = fam)),
         width = w, height = h, dpi = 150)
cat("xgboost version:", as.character(packageVersion("xgboost")), "\n")

# ---------------- Завдання 1. Підготовка погодинних даних ----------------
vic_elec_prepared <- vic_elec %>%
  filter(yearmonth(Time) == yearmonth("2014 Jul")) %>%
  index_by(Time_Hourly = round_date(Time, "hour")) %>%
  summarise(
    Demand = mean(Demand),
    Temperature = mean(Temperature),
    Holiday = any(Holiday)
  )
print(vic_elec_prepared)
glimpse(vic_elec_prepared)
nrow(vic_elec_prepared)

# ---------------- Завдання 2. Навчальна та тестова вибірки ----------------
test_data <- vic_elec_prepared %>% tail(72)
train_data <- vic_elec_prepared %>%
  filter(Time_Hourly < min(test_data$Time_Hourly))
# У методичці тут стоїть зайвий рядок summarise(train_data) (без змін; виконується
# лише для діагностики, на подальші кроки не впливає):
print(summarise(train_data))
nrow(train_data)
nrow(test_data)
range(train_data$Time_Hourly)
range(test_data$Time_Hourly)

p01 <- vic_elec_prepared %>% as_tibble() %>%
  mutate(Вибірка = ifelse(Time_Hourly < min(test_data$Time_Hourly), "Навчальна (train)", "Тестова (test, 72 год)")) %>%
  ggplot(aes(Time_Hourly, Demand, color = Вибірка)) + geom_line() +
  scale_color_manual(values = c("Навчальна (train)" = "steelblue", "Тестова (test, 72 год)" = "firebrick")) +
  labs(title = "Погодинний попит, Вікторія, липень 2014", x = "Час", y = "Попит, МВт") +
  theme_minimal() + theme(legend.position = "bottom", plot.title = element_text(hjust = 0.5, face = "bold"))
save_plot(p01, "01_series_split.png")

# ---------------- Завдання 3. Базова модель ARIMA ----------------
fit_arima <- train_data %>%
  model(arima_model = ARIMA(Demand))
fc_arima <- fit_arima %>%
  forecast(h = 72)
vec_arima_pred <- fc_arima$.mean
length(vec_arima_pred)
report(fit_arima)

# ---------------- Завдання 4. Залишки ARIMA ----------------
train_fitted <- augment(fit_arima)
train_data$arima_residuals <- train_fitted$.resid
summary(train_data$arima_residuals)
sd(train_data$arima_residuals, na.rm = TRUE)

res_df <- as_tibble(train_data)
p02a <- ggplot(res_df, aes(Time_Hourly, arima_residuals)) + geom_line(color = "steelblue") +
  geom_hline(yintercept = 0, linetype = "dashed") +
  labs(title = "Залишки ARIMA у часі", x = "Час", y = "Залишок, МВт") + theme_minimal()
p02b <- ggplot(res_df, aes(arima_residuals)) +
  geom_histogram(bins = 30, fill = "lightblue", color = "black") +
  labs(title = "Розподіл залишків ARIMA", x = "Залишок, МВт", y = "Кількість") + theme_minimal()
save_plot(p02a, "02_residuals.png")
save_plot(p02b, "02_residuals_hist.png", 6, 4)

# ---------------- Завдання 5. Ознаки для XGBoost ----------------
xgboost_data <- train_data %>%
  bind_rows(test_data) %>%
  as_tibble() %>%
  mutate(
    lag_1 = lag(arima_residuals, 1),
    lag_2 = lag(arima_residuals, 2),
    lag_24 = lag(arima_residuals, 24),
    lag_168 = lag(arima_residuals, 168),
    Hour = hour(Time_Hourly),
    Wday = wday(Time_Hourly),
    Holiday = as.numeric(Holiday)
  )

# ---------------- Завдання 6. Матриці та навчання XGBoost ----------------
train_ml <- xgboost_data %>%
  filter(Time_Hourly < min(test_data$Time_Hourly)) %>%
  filter(!is.na(lag_168))
test_ml <- xgboost_data %>%
  filter(Time_Hourly >= min(test_data$Time_Hourly))
cat("train_ml rows:", nrow(train_ml), " test_ml rows:", nrow(test_ml), "\n")
cat("NA у лагах тестового періоду (lag_1, lag_2, lag_24, lag_168):",
    colSums(is.na(test_ml[, c("lag_1", "lag_2", "lag_24", "lag_168")])), "\n")

features <- c(
  "Temperature", "Holiday", "Hour", "Wday",
  "lag_1", "lag_2", "lag_24", "lag_168"
)
X_train <- as.matrix(train_ml[, features])
Y_train <- train_ml$arima_residuals
X_test <- as.matrix(test_ml[, features])
dtrain <- xgb.DMatrix(data = X_train, label = Y_train)
dtest <- xgb.DMatrix(data = X_test)

params <- list(
  objective = "reg:squarederror",
  eval_metric = "rmse",
  max_depth = 4,
  eta = 0.05,
  subsample = 0.8
)
set.seed(123)
xgb_model <- xgb.train(
  params = params,
  data = dtrain,
  nrounds = 100,
  verbose = 0
)
vec_xgb_pred <- predict(xgb_model, dtest)
length(vec_xgb_pred)

# ---------------- Завдання 7. Гібридний прогноз ----------------
final_evaluation <- test_data %>%
  as_tibble() %>%
  mutate(
    Forecast_ARIMA = vec_arima_pred,
    Forecast_XGB = vec_xgb_pred,
    Forecast_Hybrid = Forecast_ARIMA + Forecast_XGB
  )
print(head(final_evaluation))
nrow(final_evaluation)

# ---------------- Завдання 8. Метрики ----------------
mape_calc <- function(actual, predicted) {
  mean(abs((actual - predicted) / actual)) * 100
}
rmse_arima <- sqrt(mean((final_evaluation$Demand - final_evaluation$Forecast_ARIMA)^2))
mae_arima <- mean(abs(final_evaluation$Demand - final_evaluation$Forecast_ARIMA))
mape_arima <- mape_calc(final_evaluation$Demand, final_evaluation$Forecast_ARIMA)
rmse_hybrid <- sqrt(mean((final_evaluation$Demand - final_evaluation$Forecast_Hybrid)^2))
mae_hybrid <- mean(abs(final_evaluation$Demand - final_evaluation$Forecast_Hybrid))
mape_hybrid <- mape_calc(final_evaluation$Demand, final_evaluation$Forecast_Hybrid)

metrics_table <- data.frame(
  Модель = c("Базова модель (ARIMA)",
             "Запропонована гібридна модель (ARIMA + XGBoost)"),
  RMSE_MW = round(c(rmse_arima, rmse_hybrid), 2),
  MAE_MW = round(c(mae_arima, mae_hybrid), 2),
  MAPE_pct = round(c(mape_arima, mape_hybrid), 2)
)
print(metrics_table)
improvement_rmse <- ((rmse_arima - rmse_hybrid) / rmse_arima) * 100
print(round(improvement_rmse, 2))

# ---------------- Завдання 9. Графік ----------------
p03 <- ggplot(final_evaluation, aes(x = Time_Hourly)) +
  geom_line(aes(y = Demand, color = "Фактичне"), linewidth = 0.8) +
  geom_line(aes(y = Forecast_ARIMA, color = "ARIMA"), linewidth = 0.8) +
  geom_line(aes(y = Forecast_Hybrid, color = "ARIMA + XGBoost"), linewidth = 0.8) +
  scale_color_manual(name = "Ряд",
    values = c("Фактичне" = "black", "ARIMA" = "blue", "ARIMA + XGBoost" = "red")) +
  labs(title = "Порівняння фактичного та прогнозованого електроспоживання",
       x = "Час", y = "Попит, МВт") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"), legend.position = "bottom")
print(p03)
save_plot(p03, "03_forecast_compare.png")

# =====================================================================
# Покращення: рекурсивний прогноз залишків (лаги з прогнозованих залишків)
# =====================================================================
# resid_all: історія залишків (train) + місця під прогнозні залишки тесту.
# Для кожної з 72 годин лаги беруться з resid_all (спершу фактичні, далі прогнозні).
recursive_xgb <- function(model, feats, base_df, n_train, h = 72) {
  resid_all <- c(base_df$arima_residuals[seq_len(n_train)], rep(NA_real_, h))
  preds <- numeric(h)
  for (i in seq_len(h)) {
    t <- n_train + i
    row <- base_df[t, ]
    xr <- sapply(feats, function(f) {
      if (grepl("^lag_", f)) resid_all[t - as.integer(sub("lag_", "", f))] else row[[f]]
    })
    xr <- matrix(as.numeric(xr), nrow = 1, dimnames = list(NULL, feats))
    preds[i] <- predict(model, xgb.DMatrix(data = xr))
    resid_all[t] <- preds[i]
  }
  preds
}
n_train <- nrow(train_data)
vec_xgb_rec <- recursive_xgb(xgb_model, features, xgboost_data, n_train)
final_evaluation$Forecast_XGB_rec <- vec_xgb_rec
final_evaluation$Forecast_Hybrid_rec <- final_evaluation$Forecast_ARIMA + vec_xgb_rec

metr <- function(actual, pred) c(
  RMSE_MW = sqrt(mean((actual - pred)^2)), MAE_MW = mean(abs(actual - pred)),
  MAPE_pct = mape_calc(actual, pred))
metrics_ext <- rbind(
  ARIMA = metr(final_evaluation$Demand, final_evaluation$Forecast_ARIMA),
  `Hybrid (методичка, лаги NA)` = metr(final_evaluation$Demand, final_evaluation$Forecast_Hybrid),
  `Hybrid рекурсивний` = metr(final_evaluation$Demand, final_evaluation$Forecast_Hybrid_rec))
metrics_ext <- data.frame(Модель = rownames(metrics_ext), round(metrics_ext, 2), row.names = NULL)
metrics_ext$improvement_rmse_pct <- round(
  (rmse_arima - metrics_ext$RMSE_MW) / rmse_arima * 100, 2)
cat("\n=== Покращення: порівняння ARIMA / Hybrid / Hybrid рекурсивний ===\n")
print(metrics_ext)
cat("improvement_rmse (рекурсивний):",
    round((rmse_arima - metrics_ext$RMSE_MW[3]) / rmse_arima * 100, 2), "\n")
write.csv(metrics_table, "results/metrics_main.csv", row.names = FALSE, fileEncoding = "UTF-8")
write.csv(metrics_ext, "results/metrics_extended.csv", row.names = FALSE, fileEncoding = "UTF-8")
write.csv(final_evaluation, "results/final_evaluation.csv", row.names = FALSE)

# =====================================================================
# Індивідуальні завдання 3, 4, 5, 6, 7 (однаковий тест, 72 год)
# =====================================================================
run_variant <- function(feats, max_depth = 4, nrounds = 100) {
  pr <- params; pr$max_depth <- max_depth
  dtr <- xgb.DMatrix(data = as.matrix(train_ml[, feats]), label = train_ml$arima_residuals)
  dte <- xgb.DMatrix(data = as.matrix(test_ml[, feats]))
  set.seed(123)
  m <- xgb.train(params = pr, data = dtr, nrounds = nrounds, verbose = 0)
  p_std <- predict(m, dte)
  p_rec <- recursive_xgb(m, feats, xgboost_data, n_train)
  a <- final_evaluation$Demand; ar <- final_evaluation$Forecast_ARIMA
  rbind(
    data.frame(Режим = "лаги NA (методичка)", t(metr(a, ar + p_std))),
    data.frame(Режим = "рекурсивний", t(metr(a, ar + p_rec))))
}
collect <- function(label, lst) {
  do.call(rbind, lapply(names(lst), function(n) {
    r <- lst[[n]]; cbind(Група = label, Варіант = n, r)
  }))
}
rnd <- function(d) { d[, c("RMSE_MW", "MAE_MW", "MAPE_pct")] <- round(d[, c("RMSE_MW", "MAE_MW", "MAPE_pct")], 2); d }
cat("\nБазові (ARIMA): RMSE", round(rmse_arima, 2), " MAE", round(mae_arima, 2), " MAPE", round(mape_arima, 2), "\n")

# Завдання 3: max_depth
t3 <- rnd(collect("max_depth", setNames(lapply(c(2, 4, 6), function(d) run_variant(features, max_depth = d)),
                                       paste0("max_depth = ", c(2, 4, 6)))))
cat("\n--- Завдання 3: max_depth ---\n"); print(t3, row.names = FALSE)
write.csv(t3, "results/task3_max_depth.csv", row.names = FALSE, fileEncoding = "UTF-8")

# Завдання 4: nrounds
t4 <- rnd(collect("nrounds", setNames(lapply(c(50, 100, 200), function(n) run_variant(features, nrounds = n)),
                                     paste0("nrounds = ", c(50, 100, 200)))))
cat("\n--- Завдання 4: nrounds ---\n"); print(t4, row.names = FALSE)
write.csv(t4, "results/task4_nrounds.csv", row.names = FALSE, fileEncoding = "UTF-8")

# Завдання 5: без Hour і Wday
feats_nocal <- setdiff(features, c("Hour", "Wday"))
t5 <- rnd(collect("calendar", list(`повний набір` = run_variant(features),
                                  `без Hour і Wday` = run_variant(feats_nocal))))
cat("\n--- Завдання 5: календарні ознаки ---\n"); print(t5, row.names = FALSE)
write.csv(t5, "results/task5_calendar.csv", row.names = FALSE, fileEncoding = "UTF-8")

# Завдання 6: набори лагів
feats_l124 <- c("Temperature", "Holiday", "Hour", "Wday", "lag_1", "lag_24")
t6 <- rnd(collect("lags", list(`lag_1, lag_24` = run_variant(feats_l124),
                              `lag_1, lag_2, lag_24, lag_168` = run_variant(features))))
cat("\n--- Завдання 6: лаги ---\n"); print(t6, row.names = FALSE)
write.csv(t6, "results/task6_lags.csv", row.names = FALSE, fileEncoding = "UTF-8")

# Завдання 7: графік різниці Demand - прогноз
err_df <- final_evaluation %>%
  transmute(Time_Hourly,
            `ARIMA` = Demand - Forecast_ARIMA,
            `ARIMA + XGBoost (методичка)` = Demand - Forecast_Hybrid,
            `ARIMA + XGBoost (рекурсивний)` = Demand - Forecast_Hybrid_rec) %>%
  tidyr::pivot_longer(-Time_Hourly, names_to = "Модель", values_to = "Похибка")
p04 <- ggplot(err_df, aes(Time_Hourly, Похибка, color = Модель)) +
  geom_hline(yintercept = 0, linetype = "dashed") + geom_line(linewidth = 0.8) +
  scale_color_manual(values = c("ARIMA" = "blue", "ARIMA + XGBoost (методичка)" = "red",
                                "ARIMA + XGBoost (рекурсивний)" = "darkgreen")) +
  labs(title = "Різниця між фактичним попитом і прогнозом (Demand − прогноз)",
       x = "Час", y = "Похибка, МВт") +
  theme_minimal() + theme(legend.position = "bottom", plot.title = element_text(hjust = 0.5, face = "bold"))
save_plot(p04, "04_error_diff.png")

# Важливість ознак основної моделі
imp <- xgb.importance(model = xgb_model)
print(imp)
p05 <- ggplot(as.data.frame(imp), aes(reorder(Feature, Gain), Gain)) + geom_col(fill = "steelblue") +
  coord_flip() + labs(title = "Важливість ознак XGBoost (Gain)", x = "Ознака", y = "Gain") + theme_minimal()
save_plot(p05, "05_xgb_importance.png", 7, 4.5)

# Зведена абляція: RMSE (режим методички)
abl <- rbind(t3, t4, t5, t6)
write.csv(abl, "results/ablation_all.csv", row.names = FALSE, fileEncoding = "UTF-8")
abl_p <- rbind(
  data.frame(Група = "base", Варіант = "ARIMA (база)", Режим = "—", RMSE_MW = rmse_arima),
  abl[, c("Група", "Варіант", "Режим", "RMSE_MW")])
abl_p$Мітка <- paste(abl_p$Група, abl_p$Варіант, sep = ": ")
p06 <- ggplot(abl_p, aes(reorder(Мітка, RMSE_MW), RMSE_MW, fill = Режим)) +
  geom_col(position = "dodge") + coord_flip() +
  geom_hline(yintercept = rmse_arima, linetype = "dashed") +
  labs(title = "Абляції: RMSE тестових 72 год (пунктир — ARIMA)", x = NULL, y = "RMSE, МВт", fill = "Режим лагів") +
  theme_minimal() + theme(legend.position = "bottom")
save_plot(p06, "06_ablation.png", 10, 7)

# Індивідуальне завдання (варіант 6): порівняння лагових ознак (ARIMA vs lag_1+lag_24 vs повний набір)
var6 <- rbind(
  data.frame(Модель = "ARIMA (база)", Режим = "—", t(metr(final_evaluation$Demand, final_evaluation$Forecast_ARIMA))),
  data.frame(Модель = paste("Гібрид:", t6$Варіант), Режим = t6$Режим, t6[, c("RMSE_MW", "MAE_MW", "MAPE_pct")]))
var6[, c("RMSE_MW", "MAE_MW", "MAPE_pct")] <- round(var6[, c("RMSE_MW", "MAE_MW", "MAPE_pct")], 2)
cat("\n=== Варіант 6: порівняння лагових ознак ===\n"); print(var6, row.names = FALSE)
write.csv(var6, "results/var6_lags.csv", row.names = FALSE, fileEncoding = "UTF-8")
var6$Модель <- factor(var6$Модель, levels = unique(var6$Модель))
var6_p <- var6[var6$Режим != "—", ]
p07 <- ggplot(var6_p, aes(Модель, RMSE_MW, fill = Режим)) +
  geom_col(position = position_dodge(width = 0.8), width = 0.7) +
  geom_text(aes(label = RMSE_MW), position = position_dodge(width = 0.8), vjust = -0.4, size = 3.5) +
  geom_hline(yintercept = rmse_arima, linetype = "dashed") +
  annotate("text", x = 1.5, y = rmse_arima, label = paste("ARIMA:", round(rmse_arima, 2)), vjust = -0.6, hjust = 0.5, size = 3.5) +
  coord_cartesian(ylim = c(0, max(var6_p$RMSE_MW) * 1.1)) +
  labs(title = "Варіант 6: RMSE гібрида для різних наборів лагів (пунктир — ARIMA)",
       x = NULL, y = "RMSE, МВт", fill = "Режим лагів") +
  theme_minimal() + theme(legend.position = "bottom", plot.title = element_text(hjust = 0.5, face = "bold"))
save_plot(p07, "07_var6_lags.png", 9, 5.5)

unlink("Rplots.pdf")
cat("\nГотово.\n")
