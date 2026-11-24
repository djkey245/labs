# ЛР12: CSV у R + Apache Spark (sparklyr) + варіант 5.2 (часові ряди). Запуск з папки submission/:
#   PATH=/opt/homebrew/bin:/usr/bin:/bin Rscript lab12.R > results/console_output.txt 2>&1
suppressPackageStartupMessages({
  library(ggplot2); library(dplyr); library(readr); library(sparklyr); library(DBI)
  library(lubridate); library(zoo)
})
dir.create("plots", showWarnings = FALSE); dir.create("results", showWarnings = FALSE)
fam <- "Arial Unicode MS"  # коректна кирилиця на macOS

# ===================== Завдання 1 =====================
cat("\n##### ЗАВДАННЯ 1 #####\n")
# Крок 1.1: генерація sales_data.csv (код методички ЛР12)
set.seed(42)
n_records <- 10000

sales_df <- data.frame(
  TransactionID = 10001:(10000 + n_records),
  Date = seq(as.Date("2024-01-01"), by = "day", length.out = n_records),
  Region = sample(c("Північ", "Південь", "Схід", "Захід"), n_records, replace = TRUE),
  Category = sample(c("Електроніка", "Одяг", "Дім і сад", "Книги"), n_records, replace = TRUE),
  UnitsSold = sample(1:50, n_records, replace = TRUE),
  UnitPrice = round(runif(n_records, min = 10, max = 500), 2),
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
ggsave("plots/01_revenue_region.png", plot_1, width = 9, height = 5.5, dpi = 150)

plot_2 <- ggplot(df, aes(x = Category, y = UnitPrice, fill = Category)) +
  geom_boxplot(alpha = 0.7) +
  theme_light(base_family = fam) +
  labs(title = "Розподіл цін товарів за категоріями", x = "Категорія", y = "Ціна за одиницю") +
  guides(fill = "none")
ggsave("plots/02_price_box.png", plot_2, width = 9, height = 5.5, dpi = 150)

# ===================== Завдання 2 =====================
cat("\n##### ЗАВДАННЯ 2 #####\n")
t_connect <- system.time(sc <- spark_connect(master = "local", version = "3.5.0"))[["elapsed"]]
cat("Успішне підключення до Spark! Версія:", as.character(spark_version(sc)), "\n")
cat("Час підключення до Spark (с):", round(t_connect, 2), "\n")

# Дослівний варіант методички (без nullValue) - лише для документування типу стовпця
raw_tbl <- spark_read_csv(sc, name = "spark_sales_raw", path = "sales_data.csv", memory = FALSE, overwrite = TRUE)
cat("Тип CustomerRating при читанні за методичкою (без nullValue):", sdf_schema(raw_tbl)$CustomerRating$type, "\n")
cat("Кількість рядків зі значенням 'NA' (текст), які filter(!is.na) не відкидає:",
    sdf_nrow(raw_tbl %>% filter(CustomerRating == "NA")), "\n")

# Основний імпорт: memory = TRUE + nullValue = "NA" (NA -> справжні null, стовпець числовий)
t_import <- system.time(
  spark_sales <- spark_read_csv(sc, name = "spark_sales_table", path = "sales_data.csv",
                                memory = TRUE, overwrite = TRUE,
                                options = list(nullValue = "NA"))
)[["elapsed"]]
cat("Тип CustomerRating з nullValue='NA':", sdf_schema(spark_sales)$CustomerRating$type, "\n")
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

# Spark SQL
sql_query <- "
  SELECT Region, COUNT(*) as Tx_Count, SUM(TotalRevenue) as Regional_Revenue
  FROM spark_sales_table
  WHERE CustomerRating >= 4.0
  GROUP BY Region
  ORDER BY Regional_Revenue DESC"
spark_sql_result <- dbGetQuery(sc, sql_query)
print(spark_sql_result)

# Збереження у CSV у методичці закоментовано - залишаємо так само
#spark_write_csv(spark_sales, path = "spark_output_sales", mode = "overwrite")

# ---- Порівняння часу: та сама агрегація в R (dplyr) і в Spark ----
r_agg <- function(d) {
  d %>% filter(UnitsSold > 5) %>% group_by(Category) %>%
    summarise(Mean_Units = mean(UnitsSold, na.rm = TRUE),
              Total_Category_Revenue = sum(TotalRevenue, na.rm = TRUE), Count = n()) %>%
    arrange(desc(Total_Category_Revenue))
}
spark_agg <- function(tb) {
  tb %>% filter(UnitsSold > 5) %>% group_by(Category) %>%
    summarise(Mean_Units = mean(UnitsSold, na.rm = TRUE),
              Total_Category_Revenue = sum(TotalRevenue, na.rm = TRUE), Count = n()) %>%
    arrange(desc(Total_Category_Revenue)) %>% collect()
}
bench <- function(label, d, tb) {
  tf_r <- system.time(r_agg(d))[["elapsed"]]
  tf_s <- system.time(spark_agg(tb))[["elapsed"]]
  tr <- sapply(1:5, function(i) system.time(r_agg(d))[["elapsed"]])
  ts <- sapply(1:5, function(i) system.time(spark_agg(tb))[["elapsed"]])
  out <- data.frame(
    Підхід = c("R (dplyr, data.frame в пам'яті)", "Spark (sparklyr, local)"),
    Перший_запуск_с = round(c(tf_r, tf_s), 4),
    Медіана_5_запусків_с = round(c(median(tr), median(ts)), 4),
    Мін_с = round(c(min(tr), min(ts)), 4),
    Макс_с = round(c(max(tr), max(ts)), 4))
  cat("\nТаблиця часу,", label, "(агрегація filter/group_by/summarise/arrange):\n")
  print(out, row.names = FALSE)
  cat("Співвідношення медіан Spark/R (", label, "):", round(median(ts) / median(tr), 1), "\n", sep = "")
  invisible(out)
}
other_r <- system("pgrep -x R | wc -l", intern = TRUE)
cat("\nУмови заміру: інших R-процесів у системі на момент заміру (без цього):", max(0, as.integer(trimws(other_r)) - 1), "\n")
bench("10 000 рядків", df, spark_sales)
cat("Накладні витрати: підключення", round(t_connect, 2), "с + імпорт", round(t_import, 2), "с\n")
t_r_read <- system.time(read_csv("sales_data.csv", show_col_types = FALSE))[["elapsed"]]
cat("Для порівняння: read_csv у R, 10 000 рядків (с):", round(t_r_read, 3), "\n")

# ---- Додатково: збільшений датасет ×100 = 1 000 000 рядків ----
cat("\n##### ДОДАТКОВО: 1 000 000 рядків (sales_df x100) #####\n")
big_path <- file.path(tempdir(), "sales_big.csv")
big_df <- sales_df[rep(seq_len(nrow(sales_df)), 100), ]
write.csv(big_df, big_path, row.names = FALSE); rm(big_df)
cat("Рядків:", format(length(readLines(big_path)) - 1, scientific = FALSE), " Розмір файлу (МБ):", round(file.size(big_path) / 1e6, 1), "\n")
t_r_read_big <- system.time(df_big <- read_csv(big_path, show_col_types = FALSE))[["elapsed"]]
cat("Час read_csv у R, 1 млн рядків (с):", round(t_r_read_big, 2), "\n")
t_import_big <- system.time(
  spark_big <- spark_read_csv(sc, name = "spark_big_table", path = big_path, memory = TRUE,
                              overwrite = TRUE, options = list(nullValue = "NA"))
)[["elapsed"]]
cat("Час імпорту CSV у Spark, 1 млн рядків (с):", round(t_import_big, 2), "\n")
cat("Рядків у Spark:", format(sdf_nrow(spark_big), scientific = FALSE), "\n")
bench("1 000 000 рядків", df_big, spark_big)
unlink(big_path)

spark_disconnect(sc)
cat("Spark-сесію успішно завершено.\n")

# ===================== Варіант 5.2: часові ряди =====================
cat("\n##### ВАРІАНТ 5.2: Часові ряди та ковзні середні #####\n")
# Агрегація продажів по днях (код методички)
daily_sales <- df %>%
  group_by(Date) %>%
  summarise(Daily_Revenue = sum(TotalRevenue), .groups = "drop") %>%
  arrange(Date)
cat("Унікальних дат:", nrow(daily_sales), " рядків у df:", nrow(df),
    " (максимум транзакцій на день:", max(table(df$Date)), ")\n")

daily_sales <- daily_sales %>%
  mutate(
    MA_7 = rollmean(Daily_Revenue, k = 7, fill = NA, align = "right"),
    MA_30 = rollmean(Daily_Revenue, k = 30, fill = NA, align = "right"))
cat("Перші значення, де MA_7 уже визначено:\n"); print(head(filter(daily_sales, !is.na(MA_7)), 3))
cat("Перші значення, де MA_30 уже визначено:\n"); print(head(filter(daily_sales, !is.na(MA_30)), 3))
cat("Останні 3 рядки:\n"); print(tail(daily_sales, 3))

plot_3 <- ggplot(daily_sales, aes(x = Date)) +
  geom_line(aes(y = Daily_Revenue, color = "Денна виручка"), alpha = 0.4) +
  geom_line(aes(y = MA_7, color = "7-денне ковзне середнє"), linewidth = 1) +
  geom_line(aes(y = MA_30, color = "30-денне ковзне середнє"), linewidth = 1.2) +
  scale_color_manual(values = c("Денна виручка" = "gray70", "7-денне ковзне середнє" = "blue",
                                "30-денне ковзне середнє" = "red")) +
  theme_minimal(base_family = fam) +
  labs(title = "Динаміка денної виручки та ковзні середні", x = "Дата", y = "Виручка (грн)", color = "Показник") +
  theme(legend.position = "bottom")
ggsave("plots/03_ts_daily_ma.png", plot_3, width = 10, height = 5.5, dpi = 150)

# Додатково: тижні та місяці
weekly <- df %>% mutate(Week = floor_date(Date, "week", week_start = 1)) %>%
  group_by(Week) %>% summarise(Revenue = sum(TotalRevenue), Tx = n(), .groups = "drop")
monthly_all <- df %>% mutate(Month = floor_date(Date, "month")) %>%
  group_by(Month) %>% summarise(Revenue = sum(TotalRevenue), Tx = n(), Days = n_distinct(Date), .groups = "drop")
last_days <- tail(monthly_all$Days, 1)
cat("Тижнів:", nrow(weekly), "; місяців:", nrow(monthly_all),
    "; в останньому місяці лише", last_days, "днів -> він виключений з місячного ряду\n")
monthly <- monthly_all %>% filter(Month < max(Month)) %>%
  mutate(MA_3 = rollmean(Revenue, k = 3, fill = NA, align = "right"))
cat("Місячний ряд (", nrow(monthly), " повних місяців), перші 6 і останні 3:\n", sep = "")
print(head(monthly, 6)); print(tail(monthly, 3))
cat("\nТаблиця перших/останніх визначених значень ковзних середніх:\n")
ma_tab <- data.frame(
  Ряд = c("MA_7 (дні)", "MA_30 (дні)", "MA_3 (місяці)"),
  Перше_значення = c(daily_sales$MA_7[7], daily_sales$MA_30[30], monthly$MA_3[3]),
  Останнє_значення = c(tail(daily_sales$MA_7, 1), tail(daily_sales$MA_30, 1), tail(monthly$MA_3, 1)),
  Мін = c(min(daily_sales$MA_7, na.rm = TRUE), min(daily_sales$MA_30, na.rm = TRUE), min(monthly$MA_3, na.rm = TRUE)),
  Макс = c(max(daily_sales$MA_7, na.rm = TRUE), max(daily_sales$MA_30, na.rm = TRUE), max(monthly$MA_3, na.rm = TRUE)))
print(ma_tab, row.names = FALSE, digits = 7)

cat("\nТренд (lm, виручка ~ час):\n")
trend <- function(y, x, label, unit) {
  m <- lm(y ~ x); s <- summary(m)$coefficients
  cat(sprintf("%s: нахил = %.2f грн/день = %.0f грн/рік (%.2f%% середнього за рік), p-value = %.4f, R2 = %.5f, cor(Pearson) = %.4f\n",
              label, s[2, 1], s[2, 1] * 365.25, 100 * s[2, 1] * 365.25 / mean(y), s[2, 4], summary(m)$r.squared, cor(y, as.numeric(x))))
}
trend(daily_sales$Daily_Revenue, as.numeric(daily_sales$Date), "Денна виручка", "день")
trend(weekly$Revenue, as.numeric(weekly$Week), "Тижнева виручка", "день")
trend(monthly$Revenue, as.numeric(monthly$Month), "Місячна виручка", "день")
cat("Середня місячна виручка:", round(mean(monthly$Revenue)), " SD:", round(sd(monthly$Revenue)),
    " CV(%):", round(100 * sd(monthly$Revenue) / mean(monthly$Revenue), 1), "\n")
cat("Макс/мін місячної виручки:", round(max(monthly$Revenue)), "/", round(min(monthly$Revenue)), "\n")
cat("SD денної виручки:", round(sd(daily_sales$Daily_Revenue)), " SD MA_30:", round(sd(daily_sales$MA_30, na.rm = TRUE)), "\n")

plot_4 <- ggplot(monthly, aes(x = Month)) +
  geom_line(aes(y = Revenue, color = "Місячна виручка"), alpha = 0.6) +
  geom_point(aes(y = Revenue, color = "Місячна виручка"), size = 0.8, alpha = 0.6) +
  geom_line(aes(y = MA_3, color = "3-місячне ковзне середнє"), linewidth = 1.1) +
  geom_smooth(aes(y = Revenue), method = "lm", se = FALSE, color = "black", linetype = "dashed", linewidth = 0.6) +
  scale_color_manual(values = c("Місячна виручка" = "gray50", "3-місячне ковзне середнє" = "red")) +
  theme_minimal(base_family = fam) +
  labs(title = "Місячна виручка, 3-місячне ковзне середнє та лінійний тренд",
       x = "Місяць", y = "Виручка (грн)", color = "Показник") +
  theme(legend.position = "bottom")
ggsave("plots/04_ts_monthly_ma.png", plot_4, width = 10, height = 5.5, dpi = 150)

cat("Готово.\n")
