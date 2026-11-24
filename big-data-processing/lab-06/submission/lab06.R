# ЛР6: R/RStudio vs Apache Spark (sparklyr). Запуск з папки submission/:
#   Rscript lab06.R > results/console_output.txt 2>&1
suppressPackageStartupMessages({
  library(ggplot2); library(dplyr); library(readr); library(sparklyr); library(DBI)
})
dir.create("plots", showWarnings = FALSE); dir.create("results", showWarnings = FALSE)
fam <- "Arial Unicode MS"  # коректна кирилиця на macOS

# ===================== Завдання 1 =====================
cat("\n##### ЗАВДАННЯ 1 #####\n")
# Крок 1.1: генерація sales_data.csv
set.seed(42)
n_records <- 10000

sales_df <- data.frame(
  TransactionID = 10001:(10000 + n_records),
  Date = seq(as.Date("2024-01-01"), by = "day", length.out = n_records),
  Region = sample(c("Північ", "Південь", "Схід", "Захід"), n_records, replace = TRUE),
  Category = sample(c("Електроніка", "Одяг", "Дім і Сад", "Книги"), n_records, replace = TRUE),
  UnitsSold = sample(1:50, n_records, replace = TRUE),
  UnitPrice = round(runif(n_records, min = 10, max = 5000), 2),
  CustomerRating = round(runif(n_records, min = 1, max = 5), 1)
)
sales_df$TotalRevenue <- sales_df$UnitsSold * sales_df$UnitPrice
sales_df$CustomerRating[sample(1:n_records, 40)] <- NA

write.csv(sales_df, "sales_data.csv", row.names = FALSE)
cat("Файл sales_data.csv успішно створено. Кількість записів:", nrow(sales_df), "\n")

# Крок 1.2: EDA
df <- read_csv("sales_data.csv", show_col_types = FALSE)
glimpse(df)
print(summary(df))
print(colSums(is.na(df)))

# Крок 1.3: dplyr
region_summary <- df %>%
  filter(!is.na(CustomerRating)) %>%
  group_by(Region, Category) %>%
  summarise(
    Total_Transactions = n(),
    Total_Units = sum(UnitsSold),
    Avg_Revenue = mean(TotalRevenue),
    Total_Revenue = sum(TotalRevenue),
    Avg_Rating = mean(CustomerRating),
    .groups = "drop"
  ) %>%
  arrange(desc(Total_Revenue))
print(region_summary, n = 20, width = Inf)

# Крок 1.4: графіки
plot_1 <- ggplot(region_summary, aes(x = reorder(Region, -Total_Revenue), y = Total_Revenue, fill = Category)) +
  geom_col(position = "dodge") +
  theme_minimal(base_family = fam) +
  labs(title = "Сумарна виручка за регіонами та категоріями товарів",
       x = "Регіон", y = "Виручка (грн)", fill = "Категорія") +
  scale_fill_brewer(palette = "Set2")
ggsave("plots/plot_1_revenue_region.png", plot_1, width = 9, height = 5.5, dpi = 150)

plot_2 <- ggplot(df, aes(x = Category, y = UnitPrice, fill = Category)) +
  geom_boxplot(alpha = 0.7) +
  theme_light(base_family = fam) +
  labs(title = "Розподіл цін товарів за категоріями", x = "Категорія", y = "Ціна за одиницю")
ggsave("plots/plot_2_price_box.png", plot_2, width = 9, height = 5.5, dpi = 150)

# ===================== Завдання 2 =====================
cat("\n##### ЗАВДАННЯ 2 #####\n")
t_connect <- system.time(sc <- spark_connect(master = "local", version = "3.5.0"))[["elapsed"]]
cat("Успішне підключення до Spark! Версія:", as.character(spark_version(sc)), "\n")
cat("Час підключення до Spark (с):", round(t_connect, 2), "\n")

t_import <- system.time(
  spark_sales <- spark_read_csv(sc, name = "spark_sales_table", path = "sales_data.csv",
                                memory = TRUE, overwrite = TRUE)
)[["elapsed"]]
cat("Час імпорту CSV у Spark (с):", round(t_import, 2), "\n")
print(class(spark_sales))

spark_summary <- spark_sales %>%
  filter(UnitsSold > 5) %>%
  group_by(Category) %>%
  summarise(
    Mean_Units = mean(UnitsSold, na.rm = TRUE),
    Total_Category_Revenue = sum(TotalRevenue, na.rm = TRUE),
    Count = n()
  ) %>%
  arrange(desc(Total_Category_Revenue))
result_r <- collect(spark_summary)
print(result_r)

# Порівняння часу: та сама агрегація в R (dplyr) і в Spark
r_agg <- function() {
  df %>% filter(UnitsSold > 5) %>% group_by(Category) %>%
    summarise(Mean_Units = mean(UnitsSold, na.rm = TRUE),
              Total_Category_Revenue = sum(TotalRevenue, na.rm = TRUE), Count = n()) %>%
    arrange(desc(Total_Category_Revenue))
}
spark_agg <- function() {
  spark_sales %>% filter(UnitsSold > 5) %>% group_by(Category) %>%
    summarise(Mean_Units = mean(UnitsSold, na.rm = TRUE),
              Total_Category_Revenue = sum(TotalRevenue, na.rm = TRUE), Count = n()) %>%
    arrange(desc(Total_Category_Revenue)) %>% collect()
}
t_r_first <- system.time(r_agg())[["elapsed"]]
t_s_first <- system.time(spark_agg())[["elapsed"]]
t_r <- sapply(1:5, function(i) system.time(r_agg())[["elapsed"]])
t_s <- sapply(1:5, function(i) system.time(spark_agg())[["elapsed"]])
timing <- data.frame(
  Підхід = c("R (dplyr, data.frame в пам'яті)", "Spark (sparklyr, local)"),
  Перший_запуск_с = round(c(t_r_first, t_s_first), 4),
  Медіана_5_запусків_с = round(c(median(t_r), median(t_s)), 4),
  Мін_с = round(c(min(t_r), min(t_s)), 4),
  Макс_с = round(c(max(t_r), max(t_s)), 4)
)
cat("\nТаблиця часу (агрегація filter/group_by/summarise/arrange):\n")
print(timing, row.names = FALSE)
cat("Співвідношення медіан Spark/R:", round(median(t_s) / median(t_r), 1), "\n")
cat("Накладні витрати: підключення", round(t_connect, 2), "с + імпорт", round(t_import, 2), "с\n")

# Spark SQL
sql_query <- "
  SELECT Region, COUNT(*) as Tx_Count, SUM(TotalRevenue) as Regional_Revenue
  FROM spark_sales_table
  WHERE CustomerRating >= 4.0
  GROUP BY Region
  ORDER BY Regional_Revenue DESC"
spark_sql_result <- dbGetQuery(sc, sql_query)
print(spark_sql_result)

spark_write_csv(spark_sales, path = "spark_output_sales", mode = "overwrite")
cat("Файли в spark_output_sales:", paste(list.files("spark_output_sales"), collapse = ", "), "\n")
spark_disconnect(sc)
cat("Spark-сесію успішно завершено.\n")

# ===================== Варіант 5.1 =====================
cat("\n##### ВАРІАНТ 5.1: Spark ML лінійна регресія #####\n")
sc <- spark_connect(master = "local", version = "3.5.0")

# Спроба 1: читання CSV точно за методичкою (без nullValue)
sales_raw <- spark_read_csv(sc, name = "ml_sales_raw", path = "sales_data.csv")
cat("Тип CustomerRating при читанні за методичкою:", sdf_schema(sales_raw)$CustomerRating$type, "\n")
cat("Рядків 'NA' (рядкове значення) що пройшли filter(!is.na):",
    sdf_nrow(sales_raw %>% filter(!is.na(CustomerRating) & CustomerRating == "NA")), "\n")
part0 <- sales_raw %>% filter(!is.na(CustomerRating)) %>% sdf_random_split(training = 0.7, test = 0.3, seed = 123)
model0 <- part0$training %>% ml_linear_regression(TotalRevenue ~ UnitsSold + UnitPrice + CustomerRating)
cat("Спроба 1: кількість коефіцієнтів моделі:", length(coef(model0)),
    "(CustomerRating оброблено як категоріальна змінна)\n")
r2_0 <- ml_regression_evaluator(ml_predict(model0, part0$test), label_col = "TotalRevenue", metric_name = "r2")
cat("Спроба 1: R-squared на тесті:", r2_0, "\n")

# Спроба 2 (основна): nullValue = "NA" -> CustomerRating числовий, NA стають справжніми null
spark_sales <- spark_read_csv(sc, name = "ml_sales", path = "sales_data.csv", options = list(nullValue = "NA"))
cat("Тип CustomerRating з nullValue='NA':", sdf_schema(spark_sales)$CustomerRating$type, "\n")

partitions <- spark_sales %>%
  filter(!is.na(CustomerRating)) %>%
  sdf_random_split(training = 0.7, test = 0.3, seed = 123)
train_data <- partitions$training
test_data <- partitions$test
cat("Рядків train:", sdf_nrow(train_data), " test:", sdf_nrow(test_data), "\n")

model <- train_data %>%
  ml_linear_regression(TotalRevenue ~ UnitsSold + UnitPrice + CustomerRating)
print(summary(model))
print(coef(model))

predictions <- ml_predict(model, test_data)
r2   <- ml_regression_evaluator(predictions, label_col = "TotalRevenue", metric_name = "r2")
rmse <- ml_regression_evaluator(predictions, label_col = "TotalRevenue", metric_name = "rmse")
mae  <- ml_regression_evaluator(predictions, label_col = "TotalRevenue", metric_name = "mae")
cat("R-squared моделі на тестових даних:", r2, "\n")
cat("RMSE на тестових даних:", rmse, "\n")
cat("MAE на тестових даних:", mae, "\n")

pred_r <- predictions %>% select(TotalRevenue, prediction) %>% collect()
cat("Кореляція факт/прогноз (тест):", cor(pred_r$TotalRevenue, pred_r$prediction), "\n")
cat("Середня виручка (тест):", mean(pred_r$TotalRevenue), " SD:", sd(pred_r$TotalRevenue), "\n")
set.seed(42)
samp <- pred_r[sample(nrow(pred_r), min(1500, nrow(pred_r))), ]
plot_3 <- ggplot(samp, aes(x = TotalRevenue, y = prediction)) +
  geom_point(alpha = 0.4, color = "steelblue") +
  geom_abline(slope = 1, intercept = 0, color = "red", linetype = "dashed") +
  theme_minimal(base_family = fam) +
  labs(title = "Лінійна регресія Spark ML: фактична vs прогнозована виручка",
       subtitle = sprintf("Тестова вибірка (1500 випадкових точок), R² = %.3f", r2),
       x = "Фактична виручка (грн)", y = "Прогноз (грн)")
ggsave("plots/plot_3_pred_vs_actual.png", plot_3, width = 8, height = 6, dpi = 150)

spark_disconnect(sc)
cat("Готово.\n")
