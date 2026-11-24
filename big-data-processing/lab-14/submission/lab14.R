# ЛР14: Аналіз новин HuffPost у R (JSON Lines). Запуск з папки submission/:
#   Rscript lab14.R > results/console_output.txt 2>&1
# Установлення пакетів виконується один раз
# install.packages(c("jsonlite","dplyr","ggplot2","lubridate","stringr","tidyr","scales"))

# ===== Завдання 1. Завантаження даних і підготовка середовища =====
library(jsonlite)
library(dplyr)
library(ggplot2)
library(lubridate)
library(stringr)
library(tidyr)
library(scales)

dir.create("plots", showWarnings = FALSE); dir.create("results", showWarnings = FALSE)
fam <- "Arial Unicode MS"  # коректна кирилиця на macOS
# збереження графіка у PNG (кирилиця через шрифт fam)
save_plot <- function(p, name, w = 8, h = 5.5) {
  ggsave(file.path("plots", paste0(name, ".png")),
         p + theme(text = element_text(family = fam)),
         width = w, height = h, dpi = 150)
  invisible(p)
}

# Вибір файлу даних (замість file.choose() - фіксований шлях)
file_path <- "../data/News_Category_Dataset_v3.json"

# Завантаження JSON Lines
news <- jsonlite::stream_in(
  file(file_path, open = "r"),
  verbose = FALSE
)

cat("ПЕРШІ П'ЯТЬ ЗАПИСІВ\n")
print(head(news, 5))

cat("\nСТРУКТУРА ДАНИХ\n")
str(news)

cat("\nКількість записів:", nrow(news), "\n")
cat("Кількість полів:", ncol(news), "\n")

# ===== Завдання 2. Первинний аналіз якості даних =====
cat("ТИПИ ПОЛІВ\n")
print(sapply(news, class))

cat("\nПРОПУЩЕНІ ЗНАЧЕННЯ\n")
print(colSums(is.na(news)))

text_fields <- c(
  "link", "headline", "category",
  "short_description", "authors"
)

empty_fields <- sapply(text_fields, function(field) {
  sum(is.na(news[[field]]) |
        trimws(news[[field]]) == "")
})

cat("\nПОРОЖНІ ТЕКСТОВІ ПОЛЯ\n")
print(empty_fields)

cat("\nПовністю однакових рядків:",
    sum(duplicated(news)), "\n")

cat("Унікальних категорій:",
    n_distinct(news$category), "\n")

# Перетворення дати
news <- news %>%
  mutate(
    date = as.Date(date),
    year = year(date),
    month = month(date),
    month_name = month(date, label = TRUE, abbr = TRUE)
  )

cat("\nПеріод дослідження:\n")
cat("Від:", as.character(min(news$date, na.rm = TRUE)), "\n")
cat("До:", as.character(max(news$date, na.rm = TRUE)), "\n")
cat("Клас поля date:", class(news$date), "\n")

# ===== Завдання 3. Кількість новин за категоріями =====
category_stats <- news %>%
  count(category, name = "news_count", sort = TRUE) %>%
  mutate(share_percent = 100 * news_count / sum(news_count))

cat("СТАТИСТИКА ЗА КАТЕГОРІЯМИ\n")
print(as.data.frame(category_stats), row.names = FALSE)
write.csv(category_stats, "results/category_stats.csv", row.names = FALSE)

top_categories <- category_stats %>%
  slice_max(order_by = news_count, n = 10, with_ties = FALSE)

cat("\nТОП-10 КАТЕГОРІЙ\n")
print(top_categories)

g1 <- ggplot(
  top_categories,
  aes(x = reorder(category, news_count), y = news_count)
) +
  geom_col(fill = "steelblue") +
  geom_text(aes(label = comma(news_count)), hjust = -0.1, size = 3.5) +
  coord_flip() +
  scale_y_continuous(labels = comma, expand = expansion(mult = c(0, 0.15))) +
  labs(
    title = "ТОП-10 категорій новин HuffPost",
    subtitle = "Кількість публікацій у кожній категорії",
    x = "Категорія",
    y = "Кількість новин"
  ) +
  theme_minimal(base_size = 12)
print(g1); save_plot(g1, "01_top10_categories")

top10_share <- sum(top_categories$news_count) / nrow(news) * 100
cat("\nЧастка ТОП-10 категорій:", round(top10_share, 2), "%\n")

# ===== Завдання 4. Динаміка публікацій за роками =====
year_stats <- news %>%
  filter(!is.na(year)) %>%
  count(year, name = "news_count") %>%
  arrange(year)

cat("КІЛЬКІСТЬ НОВИН ЗА РОКАМИ\n")
print(as.data.frame(year_stats), row.names = FALSE)
write.csv(year_stats, "results/year_stats.csv", row.names = FALSE)

peak_year <- year_stats %>%
  slice_max(news_count, n = 1, with_ties = FALSE)

cat("\nРік із найбільшою кількістю записів:\n")
print(peak_year)

g2 <- ggplot(year_stats, aes(x = year, y = news_count)) +
  geom_line(color = "steelblue", linewidth = 1) +
  geom_point(color = "darkred", size = 2) +
  scale_x_continuous(breaks = pretty(year_stats$year)) +
  scale_y_continuous(labels = comma) +
  labs(
    title = "Динаміка кількості новин",
    subtitle = "Кількість записів у наборі за роками",
    x = "Рік",
    y = "Кількість новин"
  ) +
  theme_minimal(base_size = 12)
print(g2); save_plot(g2, "02_yearly")

# ===== Завдання 5. Категорії в часі =====
top6 <- category_stats %>%
  slice_max(order_by = news_count, n = 6, with_ties = FALSE) %>%
  pull(category)
cat("\nТОП-6:", top6, "\n")

category_year_stats <- news %>%
  filter(category %in% top6, !is.na(year)) %>%
  count(year, category, name = "news_count")
write.csv(category_year_stats, "results/category_year_top6.csv", row.names = FALSE)

g3 <- ggplot(
  category_year_stats %>% complete(category, year = 2012:2022, fill = list(news_count = 0)),  # роки без записів = 0
  aes(x = year, y = news_count, color = category)
) +
  geom_line(linewidth = 0.9) +
  geom_point(size = 1.5) +
  scale_x_continuous(breaks = 2012:2022) +
  scale_y_continuous(labels = comma) +
  labs(
    title = "Динаміка публікацій за основними категоріями",
    x = "Рік",
    y = "Кількість новин",
    color = "Категорія"
  ) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom")
print(g3); save_plot(g3, "03_top6_trend")

# Теплова карта
heatmap_data <- news %>%
  filter(category %in% top6, !is.na(year)) %>%
  count(category, year, name = "news_count")

g4 <- ggplot(
  heatmap_data,
  aes(x = factor(year), y = reorder(category, news_count, FUN = sum), fill = news_count)
) +
  geom_tile(color = "white", linewidth = 0.2) +
  scale_fill_gradient(low = "white", high = "darkblue", labels = comma) +
  labs(
    title = "Теплова карта публікацій",
    x = "Рік",
    y = "Категорія",
    fill = "Кількість"
  ) +
  theme_minimal(base_size = 11)
print(g4); save_plot(g4, "04_heatmap")

cat("\nКатегорія-лідер за роками (серед ТОП-6):\n")
print(category_year_stats %>% group_by(year) %>% slice_max(news_count, n = 1, with_ties = FALSE) %>% as.data.frame())

# ===== Завдання 6. Довжина заголовків і коротких описів =====
news <- news %>%
  mutate(
    headline_chars = str_length(headline),
    headline_words = str_count(str_trim(headline), "\\S+"),
    description_chars = str_length(short_description),
    description_words = str_count(str_trim(short_description), "\\S+")
  )

cat("ОПИСОВА СТАТИСТИКА ДОВЖИНИ ТЕКСТІВ\n")
print(
  news %>%
    summarise(
      Середня_довжина_заголовка = mean(headline_chars, na.rm = TRUE),
      Медіана_довжини_заголовка = median(headline_chars, na.rm = TRUE),
      Мінімум_слів_у_заголовку = min(headline_words, na.rm = TRUE),
      Максимум_слів_у_заголовку = max(headline_words, na.rm = TRUE),
      Середня_кількість_слів_в_описі = mean(description_words, na.rm = TRUE)
    )
)

g5 <- ggplot(news, aes(x = headline_chars)) +
  geom_histogram(bins = 40, fill = "steelblue", color = "white") +
  labs(
    title = "Розподіл довжини заголовків новин",
    subtitle = "Довжина вимірюється кількістю символів",
    x = "Кількість символів",
    y = "Кількість заголовків"
  ) +
  theme_minimal(base_size = 12)
print(g5); save_plot(g5, "05_hist_headline")

length_by_category <- news %>%
  group_by(category) %>%
  summarise(
    кількість = n(),
    середня_довжина = mean(headline_chars, na.rm = TRUE),
    медіана_довжини = median(headline_chars, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(кількість >= 100) %>%
  arrange(desc(середня_довжина))

cat("ДОВЖИНА ЗАГОЛОВКІВ ЗА КАТЕГОРІЯМИ\n")
print(length_by_category, n = Inf)
write.csv(length_by_category, "results/length_by_category.csv", row.names = FALSE)

g6 <- ggplot(
  length_by_category,
  aes(x = reorder(category, середня_довжина), y = середня_довжина)
) +
  geom_col(fill = "darkcyan") +
  coord_flip() +
  labs(
    title = "Середня довжина заголовків за категоріями",
    x = "Категорія",
    y = "Середня кількість символів"
  ) +
  theme_minimal(base_size = 11)
print(g6); save_plot(g6, "06_headline_len_by_cat", h = 7.5)

# ===== Завдання 7. Активність авторів =====
author_stats <- news %>%
  mutate(author_name = str_trim(authors)) %>%
  filter(!is.na(author_name), author_name != "") %>%
  count(author_name, name = "news_count", sort = TRUE)

cat("КІЛЬКІСТЬ УНІКАЛЬНИХ ЗНАЧЕНЬ ПОЛЯ АВТОРА:", nrow(author_stats), "\n")
cat("\nТОП-10 ЗНАЧЕНЬ ПОЛЯ AUTHORS\n")
print(head(author_stats, 10))
write.csv(head(author_stats, 15), "results/author_stats_top15.csv", row.names = FALSE)

top_authors <- author_stats %>%
  slice_max(order_by = news_count, n = 10, with_ties = FALSE)

g7 <- ggplot(top_authors, aes(x = reorder(author_name, news_count), y = news_count)) +
  geom_col(fill = "coral3") +
  coord_flip() +
  labs(
    title = "ТОП-10 авторських записів",
    subtitle = "Кількість новин, пов'язаних із кожним записом",
    x = "Авторський запис",
    y = "Кількість публікацій"
  ) +
  theme_minimal(base_size = 11)
print(g7); save_plot(g7, "07_top_authors")

# ===== Завдання 8. Зв'язок довжини заголовка й опису =====
# Увага: у методичці nrow(data) - змінної data немає; виправлено на nrow(.)
set.seed(123)
news_sample <- news %>%
  filter(headline_chars > 0, description_chars > 0) %>%
  slice_sample(n = min(3000, nrow(.)))

g8 <- ggplot(news_sample, aes(x = headline_chars, y = description_chars)) +
  geom_point(alpha = 0.3, color = "steelblue") +
  geom_smooth(method = "lm", se = FALSE, color = "darkred") +
  labs(
    title = "Зв'язок між довжиною заголовка й опису",
    subtitle = "Випадкова вибірка до 3000 новин",
    x = "Довжина заголовка, символів",
    y = "Довжина короткого опису, символів"
  ) +
  theme_minimal(base_size = 12)
print(g8); save_plot(g8, "08_scatter_len")

correlation <- cor.test(
  news_sample$headline_chars,
  news_sample$description_chars,
  method = "pearson"
)
cat("КОРЕЛЯЦІЯ ДОВЖИНИ ТЕКСТІВ\n")
print(correlation)
cat("Розмір вибірки:", nrow(news_sample), "\n")

# ===== Додаткове завдання. Публікації за місяцями =====
monthly_stats <- news %>%
  filter(!is.na(date)) %>%
  count(month, name = "news_count") %>%
  complete(month = 1:12, fill = list(news_count = 0)) %>%
  mutate(
    month_name = factor(
      month, levels = 1:12,
      labels = c("Січ", "Лют", "Бер", "Кві", "Тра", "Чер",
                 "Лип", "Сер", "Вер", "Жов", "Лис", "Гру")
    )
  )
print(monthly_stats)
write.csv(monthly_stats, "results/monthly_stats.csv", row.names = FALSE)

g9 <- ggplot(monthly_stats, aes(x = month_name, y = news_count, group = 1)) +
  geom_line(color = "steelblue", linewidth = 1) +
  geom_point(color = "darkred", size = 2.5) +
  scale_y_continuous(labels = comma) +
  labs(
    title = "Розподіл новин за місяцями року",
    subtitle = "Сумарна кількість публікацій за всі роки",
    x = "Місяць",
    y = "Кількість новин"
  ) +
  theme_minimal(base_size = 12)
print(g9); save_plot(g9, "09_monthly")

# ===================== САМОСТІЙНІ ЗАВДАННЯ =====================

# ----- Самостійне 1. Порівняння категорій (позиції 11-15 за кількістю) -----
cat("\n===== САМОСТІЙНЕ 1 =====\n")
s1_cats <- category_stats %>% slice(11:15)
print(as.data.frame(s1_cats), row.names = FALSE)
write.csv(s1_cats, "results/s1_categories.csv", row.names = FALSE)

s1 <- ggplot(s1_cats, aes(x = reorder(category, news_count), y = news_count)) +
  geom_col(fill = "seagreen") +
  geom_text(aes(label = paste0(comma(news_count), " (", round(share_percent, 2), "%)")),
            hjust = -0.05, size = 3.3) +
  coord_flip() +
  scale_y_continuous(labels = comma, expand = expansion(mult = c(0, 0.3))) +
  labs(title = "П'ять категорій поза ТОП-10 (позиції 11-15)",
       x = "Категорія", y = "Кількість новин") +
  theme_minimal(base_size = 12)
print(s1); save_plot(s1, "s1_categories")

# ----- Самостійне 2. Часова динаміка трьох категорій -----
cat("\n===== САМОСТІЙНЕ 2 =====\n")
s2_cats <- c("POLITICS", "WELLNESS", "ENTERTAINMENT")
s2_data <- news %>%
  filter(category %in% s2_cats) %>%
  count(category, year, name = "news_count") %>%
  complete(category, year = 2012:2022, fill = list(news_count = 0))  # роки без записів = 0
print(as.data.frame(s2_data %>% tidyr::pivot_wider(names_from = category, values_from = news_count)))
write.csv(s2_data, "results/s2_category_year.csv", row.names = FALSE)

s2_extreme <- s2_data %>%
  group_by(category) %>%
  summarise(
    рік_макс = year[which.max(news_count)], макс = max(news_count),
    рік_мін = year[which.min(news_count)], мін = min(news_count),
    .groups = "drop"
  )
cat("Роки max/min (2022 неповний):\n"); print(as.data.frame(s2_extreme))
s2_extreme_full <- s2_data %>% filter(year < 2022) %>%
  group_by(category) %>%
  summarise(
    рік_макс = year[which.max(news_count)], макс = max(news_count),
    рік_мін = year[which.min(news_count)], мін = min(news_count),
    .groups = "drop"
  )
cat("Роки max/min без неповного 2022:\n"); print(as.data.frame(s2_extreme_full))

s2 <- ggplot(s2_data, aes(x = year, y = news_count, color = category)) +
  geom_line(linewidth = 1) + geom_point(size = 2) +
  scale_x_continuous(breaks = 2012:2022) +
  scale_y_continuous(labels = comma) +
  labs(title = "Динаміка публікацій: POLITICS, WELLNESS, ENTERTAINMENT",
       x = "Рік", y = "Кількість новин", color = "Категорія") +
  theme_minimal(base_size = 11) + theme(legend.position = "bottom")
print(s2); save_plot(s2, "s2_trend")

# ----- Самостійне 3. Слова в заголовках для п'яти категорій -----
cat("\n===== САМОСТІЙНЕ 3 =====\n")
s3_cats <- c("POLITICS", "WELLNESS", "ENTERTAINMENT", "TRAVEL", "STYLE & BEAUTY")
s3_stats <- news %>%
  filter(category %in% s3_cats) %>%
  group_by(category) %>%
  summarise(
    кількість = n(),
    середня_слів = mean(headline_words),
    медіана_слів = median(headline_words),
    .groups = "drop"
  ) %>% arrange(desc(медіана_слів))
print(as.data.frame(s3_stats))
write.csv(s3_stats, "results/s3_words_stats.csv", row.names = FALSE)
cat("Найбільша медіана:", s3_stats$category[which.max(s3_stats$медіана_слів)], "\n")
cat("Найменша медіана:", s3_stats$category[which.min(s3_stats$медіана_слів)], "\n")

s3 <- ggplot(s3_stats, aes(x = reorder(category, середня_слів), y = середня_слів)) +
  geom_col(fill = "darkorange") +
  geom_text(aes(label = round(середня_слів, 2)), hjust = -0.1, size = 3.5) +
  coord_flip() +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(title = "Середня кількість слів у заголовках",
       x = "Категорія", y = "Середня кількість слів") +
  theme_minimal(base_size = 12)
print(s3); save_plot(s3, "s3_words")

# ----- Самостійне 4. Авторські записи -----
cat("\n===== САМОСТІЙНЕ 4 =====\n")
top15_authors <- head(author_stats, 15)
print(as.data.frame(top15_authors), row.names = FALSE)
no_author <- sum(is.na(news$authors) | trimws(news$authors) == "")
cat("Новин без автора:", no_author, " (", round(100 * no_author / nrow(news), 2), "% )\n")

s4 <- ggplot(top15_authors, aes(x = reorder(author_name, news_count), y = news_count)) +
  geom_col(fill = "slateblue") +
  coord_flip() +
  labs(title = "15 найчастіших значень поля authors",
       x = "Авторський запис", y = "Кількість публікацій") +
  theme_minimal(base_size = 11)
print(s4); save_plot(s4, "s4_top15_authors")

# ----- Самостійне 5. Довжина текстів: символи й слова -----
cat("\n===== САМОСТІЙНЕ 5 =====\n")
len_summary <- news %>%
  summarise(
    across(c(headline_chars, headline_words, description_chars, description_words),
           list(mean = ~mean(.x, na.rm = TRUE), median = ~median(.x, na.rm = TRUE),
                max = ~max(.x, na.rm = TRUE)))
  )
print(as.data.frame(t(len_summary)))
cat("Порожніх описів (0 слів):", sum(news$description_words == 0), "\n")
write.csv(as.data.frame(t(len_summary)), "results/s5_length_summary.csv")

long_len <- news %>%
  select(headline_chars, headline_words, description_chars, description_words) %>%
  pivot_longer(everything(), names_to = "metric", values_to = "value") %>%
  mutate(metric = factor(metric,
    levels = c("headline_chars", "headline_words", "description_chars", "description_words"),
    labels = c("Заголовок: символи", "Заголовок: слова", "Опис: символи", "Опис: слова")))

s5 <- ggplot(long_len, aes(x = value)) +
  geom_histogram(bins = 40, fill = "steelblue", color = "white") +
  facet_wrap(~ metric, scales = "free") +
  scale_y_continuous(labels = comma) +
  labs(title = "Розподіл довжини заголовків і описів",
       x = "Значення", y = "Кількість новин") +
  theme_minimal(base_size = 11)
print(s5); save_plot(s5, "s5_hist_lengths", w = 9, h = 6.5)

cat("Кореляція слів заголовка й опису (повна вибірка, Пірсон):\n")
cor_words <- cor.test(news$headline_words, news$description_words, method = "pearson")
print(cor_words)
cat("r (слова, повна вибірка) =", round(cor_words$estimate, 4), "\n")
cat("r (символи, повна вибірка) =",
    round(cor(news$headline_chars, news$description_chars), 4), "\n")
news_nonempty <- news %>% filter(headline_words > 0, description_words > 0)
cat("r (слова, лише непорожні описи) =",
    round(cor(news_nonempty$headline_words, news_nonempty$description_words), 4),
    " n =", nrow(news_nonempty), "\n")

# ----- Самостійне 6. Мініпроєкт: категорія WELLNESS -----
cat("\n===== САМОСТІЙНЕ 6 (WELLNESS) =====\n")
wl <- news %>% filter(category == "WELLNESS")
cat("Записів WELLNESS:", nrow(wl), "\n")
wl_year <- wl %>% count(year, name = "news_count") %>%
  complete(year = 2012:2022, fill = list(news_count = 0)) %>% arrange(year)
print(as.data.frame(wl_year), row.names = FALSE)
write.csv(wl_year, "results/s6_wellness_year.csv", row.names = FALSE)

s6a <- ggplot(wl_year, aes(x = year, y = news_count)) +
  geom_line(color = "seagreen", linewidth = 1) + geom_point(color = "darkred", size = 2) +
  scale_x_continuous(breaks = 2012:2022) + scale_y_continuous(labels = comma) +
  labs(title = "WELLNESS: кількість публікацій за роками", x = "Рік", y = "Кількість новин") +
  theme_minimal(base_size = 12)
print(s6a); save_plot(s6a, "s6_wellness_year")

cat("Довжина заголовків WELLNESS: середнє символів =", round(mean(wl$headline_chars), 2),
    " медіана =", median(wl$headline_chars),
    " середнє слів =", round(mean(wl$headline_words), 2),
    " (усі новини: ", round(mean(news$headline_chars), 2), "символів )\n")
wl_len_year <- wl %>% group_by(year) %>%
  summarise(середня_довжина = mean(headline_chars), .groups = "drop")
print(as.data.frame(wl_len_year))
write.csv(wl_len_year, "results/s6_wellness_len_year.csv", row.names = FALSE)

s6b <- ggplot(wl, aes(x = headline_chars)) +
  geom_histogram(bins = 40, fill = "seagreen", color = "white") +
  geom_vline(xintercept = mean(news$headline_chars), color = "darkred", linetype = "dashed") +
  labs(title = "WELLNESS: розподіл довжини заголовків",
       subtitle = "Пунктир - середня довжина по всьому набору",
       x = "Кількість символів", y = "Кількість заголовків") +
  theme_minimal(base_size = 12)
print(s6b); save_plot(s6b, "s6_wellness_len_hist")

wl_authors <- wl %>% mutate(author_name = str_squish(str_replace_all(authors, "\\n", " | "))) %>%
  filter(author_name != "") %>%
  count(author_name, name = "news_count", sort = TRUE) %>% head(10)
cat("ТОП-10 авторських записів у WELLNESS:\n"); print(as.data.frame(wl_authors))
cat("WELLNESS без автора:", sum(trimws(wl$authors) == ""), "\n")
write.csv(wl_authors, "results/s6_wellness_authors.csv", row.names = FALSE)

s6c <- ggplot(wl_authors, aes(x = reorder(str_trunc(author_name, 40), news_count), y = news_count)) +
  geom_col(fill = "coral3") + coord_flip() +
  labs(title = "WELLNESS: ТОП-10 авторських записів",
       subtitle = "Довгі підписи скорочено до 40 символів (повні - у results/s6_wellness_authors.csv)",
       x = "Авторський запис", y = "Кількість публікацій") +
  theme_minimal(base_size = 11) + theme(plot.title.position = "plot")
print(s6c); save_plot(s6c, "s6_wellness_authors")

invisible(file.remove("Rplots.pdf")[file.exists("Rplots.pdf")])
cat("\nГотово.\n")
