# ЛР13: Аналіз результатів НМТ-2025 засобами R. Запуск з папки submission/:
#   Rscript lab13.R > results/console_output.txt 2>&1
# Великий файл (401 МБ) не входить до submission/, шлях задано змінною data_path.

# ---- Завдання 1. Підключення бібліотек ----
library(readr)
library(dplyr)
library(tidyr)
library(ggplot2)

options(width = 140, tibble.width = Inf, pillar.sigfig = 5)
dir.create("plots", showWarnings = FALSE)
dir.create("results", showWarnings = FALSE)
fam <- "Arial Unicode MS"  # коректна кирилиця на macOS
theme_set(theme_minimal(base_size = 12, base_family = fam))

# ---- Завдання 2. Перевірка наявності файлу ----
data_path <- "../data/Odata2025File.csv"
if (!file.exists(data_path)) {
  stop(paste0("\nФайл ", data_path, " не знайдено.\n",
              "Розмістіть Odata2025File.csv у папці ../data/ (відносно submission/).\n"))
}

# ---- Завдання 3. Завантаження даних ----
# Файл 2025: UTF-8, роздільник ';', десяткова кома, пропуски записані як "null"
nmt <- read_csv2(data_path,
                 locale = locale(encoding = "UTF-8"),
                 na = c("", "NA", "null"),
                 show_col_types = FALSE)

# ---- Завдання 4. Первинне дослідження ----
cat("Кількість рядків:", nrow(nmt), "\n")
cat("Кількість стовпців:", ncol(nmt), "\n")
cat("\nНазви змінних:\n")
print(names(nmt))
# Персональні поля (ідентифікатор, рік народження, назва закладу) не друкуємо і не аналізуємо
cat("\nПерші 6 рядків (лише вибрані стовпці):\n")
print(head(nmt[, c("RegName", "Test", "UkrBlockBall100", "HistBlockBall100", "MathBlockBall100")]))
cat("\nТипи вибраних стовпців (str):\n")
str(nmt[, c("RegName", "Test", "TestDate", "UkrBlockBall100", "HistBlockBall100", "MathBlockBall100")],
    give.attr = FALSE)
cat("\nsummary для чотирьох потрібних стовпців:\n")
print(summary(nmt[, c("RegName", "UkrBlockBall100", "HistBlockBall100", "MathBlockBall100")]))
cat("\nПеревірка Test (чи всі записи - НМТ):\n")
print(table(nmt$Test, useNA = "ifany"))
cat("Кількість різних дат тестування:", n_distinct(nmt$TestDate),
    "; від", format(min(as.Date(nmt$TestDate, "%d.%m.%Y"))),
    "до", format(max(as.Date(nmt$TestDate, "%d.%m.%Y"))), "\n")

# ---- Завдання 5. Перевірка необхідних змінних ----
required_columns <- c("RegName", "UkrBlockBall100", "HistBlockBall100", "MathBlockBall100")
missing_columns <- setdiff(required_columns, names(nmt))
if (length(missing_columns) > 0) {
  stop(paste("У файлі відсутні необхідні змінні:", paste(missing_columns, collapse = ", ")))
}
cat("\nУсі необхідні змінні присутні.\n")

# Залишаємо лише потрібні стовпці (решта, зокрема персональні, далі не використовується)
nmt <- nmt %>% select(all_of(c("RegName", "Test", "TestDate", required_columns[-1])))

# ---- Завдання 6. Перетворення даних ----
cat("\nКласи стовпців після read_csv2 (десяткова кома оброблена автоматично):\n")
print(sapply(nmt[, required_columns[-1]], class))
nmt <- nmt %>%
  mutate(UkrBlockBall100 = as.numeric(UkrBlockBall100),
         HistBlockBall100 = as.numeric(HistBlockBall100),
         MathBlockBall100 = as.numeric(MathBlockBall100))
cat("\nДіапазони балів (min, max):\n")
print(sapply(nmt[, required_columns[-1]], range, na.rm = TRUE))
cat("Кількість нульових балів: ",
    paste(names(nmt)[4:6], colSums(nmt[, 4:6] == 0, na.rm = TRUE), collapse = "; "), "\n")

# ---- Завдання 7. Перевірка пропущених значень ----
cat("\nПропущені значення у вибраних стовпцях:\n")
print(colSums(is.na(nmt)))
cat("Рядків без жодного з трьох балів:",
    sum(rowSums(!is.na(nmt[, 4:6])) == 0), "\n")
cat("Рядків з усіма трьома балами:",
    sum(rowSums(!is.na(nmt[, 4:6])) == 3), "\n")

# Перевірка назв регіонів
cat("\nКількість записів за RegName:\n")
print(as.data.frame(sort(table(nmt$RegName), decreasing = TRUE)), row.names = FALSE)
cat("Порожніх/NA в RegName:", sum(is.na(nmt$RegName) | nmt$RegName %in% c("", "null")), "\n")
# Рішення: "Інші країни" - не область (учасники, що складали тест за кордоном), тому з
# регіонального аналізу виключаємо; "м.Київ" - місто з особливим статусом, залишаємо.
n_abroad <- sum(nmt$RegName == "Інші країни")
cat("Записів 'Інші країни' (виключено з регіональних таблиць):", n_abroad, "\n")
nmt_all <- nmt                                   # вся вибірка (для підсумків по вибірці)
nmt <- nmt %>% filter(!RegName %in% c("Інші країни", "null") & !is.na(RegName))
cat("Рядків після відбору регіонів:", nrow(nmt), "; регіонів:", n_distinct(nmt$RegName), "\n")

cat("\nКількість непропущених значень за областями:\n")
n_by_region <- nmt %>%
  group_by(RegName) %>%
  summarise(N_total = n(),
            N_Math = sum(!is.na(MathBlockBall100)),
            N_History = sum(!is.na(HistBlockBall100)),
            N_Ukrainian = sum(!is.na(UkrBlockBall100)), .groups = "drop")
print(n_by_region, n = Inf)

# ---- Завдання 8. Середні результати ----
region_results <- nmt %>%
  group_by(RegName) %>%
  summarise(Math = mean(MathBlockBall100, na.rm = TRUE),
            History = mean(HistBlockBall100, na.rm = TRUE),
            Ukrainian = mean(UkrBlockBall100, na.rm = TRUE),
            .groups = "drop")

# ---- Завдання 9. Округлення ----
region_results <- region_results %>%
  mutate(Math = round(Math, 2), History = round(History, 2), Ukrainian = round(Ukrainian, 2))

# ---- Завдання 10. Виведення результатів ----
cat("\nСередні результати НМТ-2025 за областями:\n\n")
print(region_results, n = Inf)
cat("\nМатематика - максимум:\n");  print(slice_max(region_results, Math, n = 1))
cat("Математика - мінімум:\n");     print(slice_min(region_results, Math, n = 1))
cat("Історія - максимум:\n");       print(slice_max(region_results, History, n = 1))
cat("Історія - мінімум:\n");        print(slice_min(region_results, History, n = 1))
cat("Українська - максимум:\n");    print(slice_max(region_results, Ukrainian, n = 1))
cat("Українська - мінімум:\n");     print(slice_min(region_results, Ukrainian, n = 1))

# ---- Завдання 11. Порівняння предметів ----
region_results <- region_results %>%
  mutate(MaxSubject = pmax(Math, History, Ukrainian, na.rm = TRUE),
         MinSubject = pmin(Math, History, Ukrainian, na.rm = TRUE),
         Difference = round(MaxSubject - MinSubject, 2))
cat("\nТаблиця з MaxSubject, MinSubject, Difference:\n")
print(region_results, n = Inf)
cat("\nОбласть з найбільшою Difference:\n"); print(slice_max(region_results, Difference, n = 1))
cat("Область з найменшою Difference:\n");   print(slice_min(region_results, Difference, n = 1))

# ---- Завдання 12. Довгий формат ----
region_long <- region_results %>%
  pivot_longer(cols = c(Math, History, Ukrainian),
               names_to = "Subject", values_to = "Average")

# ---- Завдання 13. Перейменування категорій ----
region_long <- region_long %>%
  mutate(Subject = recode(Subject,
                          Math = "Математика",
                          History = "Історія України",
                          Ukrainian = "Українська мова"))
cat("\nДовгий формат (перші 9 рядків):\n")
print(head(region_long[, c("RegName", "Subject", "Average")], 9))
cat("Рядків у довгій таблиці:", nrow(region_long), "\n")

# ---- Завдання 14. Стовпчикова діаграма ----
rev_levels <- rev(sort(unique(region_long$RegName)))
long_plot <- region_long %>% mutate(RegName = factor(RegName, levels = rev_levels))
p_bar <- ggplot(long_plot, aes(x = RegName, y = Average, fill = Subject)) +
  geom_col(position = "dodge") +
  coord_flip() +
  labs(title = "Середні результати НМТ-2025 за областями",
       subtitle = "Математика, історія України та українська мова",
       x = "Область", y = "Середній бал", fill = "Предмет") +
  theme_minimal(base_size = 12, base_family = fam) +
  theme(plot.title = element_text(face = "bold"),
        axis.text.y = element_text(size = 9),
        legend.position = "bottom")
ggsave("plots/01_bar_by_region.png", p_bar, width = 10, height = 9, dpi = 150)

# ---- Завдання 15. Лінійний графік ----
p_line <- ggplot(region_long, aes(x = RegName, y = Average, group = Subject, color = Subject)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  labs(title = "Середні результати НМТ-2025 за областями",
       subtitle = "Математика, історія України та українська мова",
       x = "Область", y = "Середній бал", color = "Предмет") +
  theme_minimal(base_size = 12, base_family = fam) +
  theme(plot.title = element_text(face = "bold"),
        axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "bottom")
ggsave("plots/02_line_by_region.png", p_line, width = 12, height = 7, dpi = 150)

# ---- Завдання 16. Три найкращі області за предметами ----
cat("\nТоп-3 з математики:\n");        print(region_results %>% arrange(desc(Math)) %>% slice_head(n = 3))
cat("\nТоп-3 з історії:\n");           print(region_results %>% arrange(desc(History)) %>% slice_head(n = 3))
cat("\nТоп-3 з української мови:\n");  print(region_results %>% arrange(desc(Ukrainian)) %>% slice_head(n = 3))
cat("\nРозмах (max - min) середніх по областях:\n")
print(region_results %>% summarise(Math = max(Math) - min(Math),
                                   History = max(History) - min(History),
                                   Ukrainian = max(Ukrainian) - min(Ukrainian)))

# ---- Завдання 17. Середні по всій вибірці ----
cat("\nСередні по вибірці (області, без 'Інші країни'):\n")
overall_mean <- nmt %>%
  summarise(Math = mean(MathBlockBall100, na.rm = TRUE),
            History = mean(HistBlockBall100, na.rm = TRUE),
            Ukrainian = mean(UkrBlockBall100, na.rm = TRUE))
print(overall_mean)
cat("Середні по всіх 317091 записах (включно з 'Інші країни'):\n")
print(nmt_all %>%
        summarise(Math = mean(MathBlockBall100, na.rm = TRUE),
                  History = mean(HistBlockBall100, na.rm = TRUE),
                  Ukrainian = mean(UkrBlockBall100, na.rm = TRUE)))

# ---- Завдання 18. Стандартне відхилення ----
cat("\nСтандартне відхилення по вибірці (області):\n")
overall_sd <- nmt %>%
  summarise(Math_SD = sd(MathBlockBall100, na.rm = TRUE),
            History_SD = sd(HistBlockBall100, na.rm = TRUE),
            Ukrainian_SD = sd(UkrBlockBall100, na.rm = TRUE))
print(overall_sd)
cat("SD середніх по областях (між регіонами):\n")
print(region_results %>% summarise(Math = sd(Math), History = sd(History), Ukrainian = sd(Ukrainian)))
cat("Відхилення середнього області від середнього по вибірці (макс. за модулем):\n")
print(c(Math = max(abs(region_results$Math - overall_mean$Math)),
        History = max(abs(region_results$History - overall_mean$History)),
        Ukrainian = max(abs(region_results$Ukrainian - overall_mean$Ukrainian))))

# ---- Контрольне завдання ----
region_results_final <- region_results %>%
  mutate(Average = rowMeans(select(., Math, History, Ukrainian), na.rm = TRUE),
         MaxSubject = pmax(Math, History, Ukrainian, na.rm = TRUE),
         MinSubject = pmin(Math, History, Ukrainian, na.rm = TRUE),
         Difference = round(MaxSubject - MinSubject, 2)) %>%
  select(RegName, Math, History, Ukrainian, Average, MaxSubject, MinSubject, Difference) %>%
  mutate(Average = round(Average, 2))
cat("\nregion_results_final:\n")
print(region_results_final, n = Inf)
cat("\nТоп-5 за Average:\n")
print(region_results_final %>% arrange(desc(Average)) %>% slice_head(n = 5))
cat("Найнижчі 3 за Average:\n")
print(region_results_final %>% arrange(Average) %>% slice_head(n = 3))

# ---- Завдання 19. Вдосконалений графік ----
ord <- region_results_final %>% arrange(Average) %>% pull(RegName)   # від меншого до більшого
long_ord <- region_long %>% mutate(RegName = factor(RegName, levels = ord))
mean_all <- mean(region_long$Average, na.rm = TRUE)
cat("\nСереднє значення всіх Average у довгій таблиці (лінія на графіку):", round(mean_all, 2), "\n")
p_improved <- ggplot(long_ord, aes(x = RegName, y = Average, fill = Subject)) +
  geom_col(position = position_dodge(width = 0.85), width = 0.8) +
  geom_text(aes(label = sprintf("%.1f", Average)),
            position = position_dodge(width = 0.85), hjust = -0.1, size = 2.3, family = fam) +
  geom_hline(yintercept = mean_all, linetype = "dashed", color = "red", linewidth = 0.7) +
  annotate("text", x = 0.3, y = mean_all, label = paste0("Середнє: ", round(mean_all, 1)),
           hjust = -0.05, vjust = 0.5, color = "red", size = 3.5, family = fam) +
  coord_flip(ylim = c(0, max(long_ord$Average) * 1.08), xlim = c(0.3, length(ord)), clip = "off") +
  labs(title = "Середні результати НМТ-2025 за областями (упорядковано за середнім трьох предметів)",
       subtitle = "Пунктир - середнє всіх значень таблиці",
       x = "Область", y = "Середній бал", fill = "Предмет") +
  theme_minimal(base_size = 14, base_family = fam) +
  theme(plot.title = element_text(face = "bold", size = 14),
        axis.text.y = element_text(size = 10),
        legend.position = "bottom")
ggsave("plots/03_improved.png", p_improved, width = 12, height = 8, dpi = 300)

# ---- Завдання 20. Експорт ----
write_csv(region_results, "results/NMT2025_average_by_region.csv")
write_csv(region_long, "results/NMT2025_average_long.csv")
write_csv(region_results_final, "results/region_results_final.csv")
write_csv(n_by_region, "results/n_by_region.csv")
ggsave("plots/NMT2025_average_by_region.png", plot = p_improved, width = 12, height = 8, dpi = 300)
cat("\nЕкспортовано CSV у results/ та PNG у plots/.\n")

# ---- Індивідуальне завдання - варіант 6: окремі графіки для кожного предмета ----
# Для кожного предмета: горизонтальні стовпчики середнього балу за областями,
# порядок областей - за середнім саме з цього предмета; пунктир - середнє по областях.
var6_plot <- function(col, title, fname, fillc, label) {
  d <- region_results %>% select(RegName, Value = all_of(col)) %>% arrange(Value)
  m <- mean(d$Value)
  d$RegName <- factor(d$RegName, levels = d$RegName)
  cat("\n", label, ": середнє по областях =", round(m, 2), "\n", sep = "")
  cat("  ТОП-3:\n");        print(as.data.frame(d %>% arrange(desc(Value)) %>% slice_head(n = 3)  %>% mutate(RegName = as.character(RegName))), row.names = FALSE)
  cat("  Останні 3:\n");    print(as.data.frame(d %>% arrange(Value)       %>% slice_head(n = 3)  %>% mutate(RegName = as.character(RegName))), row.names = FALSE)
  cat("  Розмах (max - min):", round(max(d$Value) - min(d$Value), 2), "; SD між областями:", round(sd(d$Value), 2), "\n")
  p <- ggplot(d, aes(x = RegName, y = Value)) +
    geom_col(fill = fillc, width = 0.8) +
    geom_text(aes(y = 0, label = sprintf("%.1f", Value)), hjust = -0.3, size = 3.8, color = "white",
              fontface = "bold", family = fam) +   # підписи біля основи стовпця - пунктир їх не перекриває
    geom_hline(yintercept = m, linetype = "dashed", color = "red", linewidth = 0.7) +
    annotate("text", x = 0.3, y = m, label = paste0("Середнє: ", round(m, 1)),
             hjust = -0.05, vjust = 0.5, color = "red", size = 4, family = fam) +
    coord_flip(ylim = c(0, max(d$Value) * 1.1), xlim = c(0.3, nrow(d)), clip = "off") +
    labs(title = title, subtitle = "Області впорядковано за середнім балом з цього предмета; пунктир - середнє по областях",
         x = "Область", y = "Середній бал") +
    theme_minimal(base_size = 13, base_family = fam) +
    theme(plot.title = element_text(face = "bold"), axis.text.y = element_text(size = 10))
  ggsave(fname, p, width = 10, height = 8, dpi = 200)
  invisible(d)
}
cat("\n==== Індивідуальне завдання (варіант 6): окремі графіки по предметах ====\n")
var6_plot("Math",      "Середній бал з математики за областями (НМТ-2025)",
          "plots/07_var6_math.png", "#00BA38", "Математика")
var6_plot("History",   "Середній бал з історії України за областями (НМТ-2025)",
          "plots/07_var6_hist.png", "#F8766D", "Історія України")
var6_plot("Ukrainian", "Середній бал з української мови за областями (НМТ-2025)",
          "plots/07_var6_ukr.png",  "#619CFF", "Українська мова")

# ======================= ДОДАТКОВИЙ АНАЛІЗ =======================
# ---- Додатково: варіант 8 (boxplot областей) ----
nmt_long <- nmt %>%
  select(RegName, Math = MathBlockBall100, History = HistBlockBall100, Ukrainian = UkrBlockBall100) %>%
  pivot_longer(-RegName, names_to = "Subject", values_to = "Score") %>%
  filter(!is.na(Score))
box_plot <- function(var, title, fname, fillc) {
  d <- nmt_long %>% filter(Subject == var)
  d$RegName <- reorder(d$RegName, d$Score, FUN = median)
  p <- ggplot(d, aes(x = RegName, y = Score)) +
    geom_boxplot(fill = fillc, outlier.size = 0.3, outlier.alpha = 0.3) +
    coord_flip() +
    labs(title = title, subtitle = "Області упорядковано за медіаною",
         x = "Область", y = "Бал") +
    theme_minimal(base_size = 12, base_family = fam) +
    theme(plot.title = element_text(face = "bold"))
  ggsave(fname, p, width = 9, height = 8, dpi = 150)
}
box_plot("Math", "Розподіл балів з математики за областями", "plots/04_boxplot_math.png", "#9ecae1")
box_plot("History", "Розподіл балів з історії України за областями", "plots/04_boxplot_hist.png", "#a1d99b")
box_plot("Ukrainian", "Розподіл балів з української мови за областями", "plots/04_boxplot_ukr.png", "#fdae6b")

cat("\nМедіана та міжквартильний розмах по областях (області з найбільшою/найменшою медіаною):\n")
med_tab <- nmt_long %>%
  group_by(Subject, RegName) %>%
  summarise(Median = median(Score), IQR = IQR(Score), .groups = "drop")
for (s in c("Math", "History", "Ukrainian")) {
  d <- med_tab %>% filter(Subject == s) %>% arrange(desc(Median))
  cat(s, ": макс. медіана -", d$RegName[1], d$Median[1], "; мін. медіана -",
      d$RegName[nrow(d)], d$Median[nrow(d)], "; середній IQR =", round(mean(d$IQR), 1), "\n")
}

# ---- Додатково: варіант 10 (середнє vs медіана) ----
cat("\nСереднє vs медіана по всій вибірці (області):\n")
mm_overall <- nmt_long %>%
  group_by(Subject) %>%
  summarise(N = n(), Mean = mean(Score), Median = median(Score),
            Diff = Mean - Median, SD = sd(Score), .groups = "drop")
print(mm_overall)
mm_region <- nmt_long %>%
  group_by(Subject, RegName) %>%
  summarise(N = n(), Mean = mean(Score), Median = median(Score),
            Diff = Mean - Median, .groups = "drop")
cat("\nСередня різниця (Mean - Median) по областях та межі:\n")
print(mm_region %>% group_by(Subject) %>%
        summarise(MeanDiff = mean(Diff), MinDiff = min(Diff), MaxDiff = max(Diff),
                  RegionsMeanBelowMedian = sum(Diff < 0), .groups = "drop"))
cat("\nСереднє vs медіана по областях (повна таблиця):\n")
print(mm_region %>% mutate(across(c(Mean, Diff), ~ round(.x, 2))), n = Inf)
write_csv(mm_overall, "results/mean_vs_median_overall.csv")
write_csv(mm_region %>% mutate(Mean = round(Mean, 2), Diff = round(Diff, 2)),
          "results/mean_vs_median_by_region.csv")

# Асиметрія (за Пірсоном: (mean - median) / sd) та гістограма-ознака
cat("\nКоефіцієнт асиметрії (за Пірсоном 3*(mean-median)/sd):\n")
print(mm_overall %>% mutate(PearsonSkew = round(3 * Diff / SD, 3)) %>% select(Subject, PearsonSkew))

mm_plot <- mm_region %>%
  mutate(Subject = recode(Subject, Math = "Математика", History = "Історія України",
                          Ukrainian = "Українська мова"))
p_mm <- ggplot(mm_plot, aes(x = reorder(RegName, Diff), y = Diff, fill = Subject)) +
  geom_col(position = "dodge") +
  geom_hline(yintercept = 0, color = "black") +
  coord_flip() +
  labs(title = "Різниця між середнім і медіаною балів за областями",
       subtitle = "Mean - Median: від'ємне значення означає лівий хвіст розподілу",
       x = "Область", y = "Середнє - медіана (бали)", fill = "Предмет") +
  theme_minimal(base_size = 12, base_family = fam) +
  theme(plot.title = element_text(face = "bold"), legend.position = "bottom")
ggsave("plots/06_mean_vs_median.png", p_mm, width = 10, height = 9, dpi = 150)

# ---- Додаткове завдання: кореляції ----
cat("\nКореляційний аналіз (use = 'complete.obs'):\n")
pairs_list <- list(c("MathBlockBall100", "UkrBlockBall100", "Математика - Українська мова"),
                   c("MathBlockBall100", "HistBlockBall100", "Математика - Історія"),
                   c("UkrBlockBall100", "HistBlockBall100", "Українська мова - Історія"))
cor_tab <- bind_rows(lapply(pairs_list, function(pr) {
  d <- nmt[, c(pr[1], pr[2])]
  data.frame(Pair = pr[3],
             r = cor(d[[1]], d[[2]], use = "complete.obs"),
             n_pairs = sum(complete.cases(d)))
}))
cor_tab$r <- round(cor_tab$r, 4)
print(cor_tab)
cat("Рядків з усіма трьома балами:", sum(complete.cases(nmt[, 4:6])), "\n")
cat("Кореляція Спірмена для порівняння:\n")
for (pr in pairs_list) {
  d <- nmt[, c(pr[1], pr[2])]
  cat(" ", pr[3], ":", round(cor(d[[1]], d[[2]], use = "complete.obs", method = "spearman"), 4), "\n")
}
write_csv(cor_tab, "results/correlations.csv")

# Діаграма розсіювання: регресія на повних даних, точки - випадкова вибірка 20000
set.seed(2025)
sc <- nmt %>% filter(!is.na(MathBlockBall100), !is.na(UkrBlockBall100))
fit <- lm(UkrBlockBall100 ~ MathBlockBall100, data = sc)
cat("\nlm(Ukr ~ Math) на", nrow(sc), "парах: intercept =", round(coef(fit)[1], 3),
    "; slope =", round(coef(fit)[2], 4), "; R2 =", round(summary(fit)$r.squared, 4), "\n")
sc_s <- sc %>% slice_sample(n = 20000)
p_sc <- ggplot(sc_s, aes(x = MathBlockBall100, y = UkrBlockBall100)) +
  geom_point(alpha = 0.3, size = 0.8, color = "#3182bd") +
  geom_abline(intercept = coef(fit)[1], slope = coef(fit)[2], color = "red", linewidth = 1) +
  labs(title = "Зв'язок результатів з математики та української мови",
       subtitle = paste0("Точки: випадкова вибірка 20000 з ", format(nrow(sc), big.mark = " "),
                         " пар; лінія lm - за всіма парами; r = ", cor_tab$r[1]),
       x = "Математика", y = "Українська мова") +
  theme_minimal(base_size = 12, base_family = fam) +
  theme(plot.title = element_text(face = "bold"))
ggsave("plots/05_scatter_math_ukr.png", p_sc, width = 8, height = 6, dpi = 150)

cat("\nГотово.\n")
