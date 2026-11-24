# ЛР7: Кластерний аналіз у R (iris). Запуск з папки submission/:
#   Rscript lab07.R > results/console_output.txt 2>&1
dir.create("plots", showWarnings = FALSE); dir.create("results", showWarnings = FALSE)
fam <- "Arial Unicode MS"  # коректна кирилиця на macOS
save_gg <- function(p, name, w = 8, h = 5.5) {
  ggsave(file.path("plots", name), p + theme(text = element_text(family = fam)),
         width = w, height = h, dpi = 150)
}
open_png <- function(name, w = 8, h = 6)
  png(file.path("plots", name), width = w, height = h, units = "in", res = 150, family = fam)
# У пакетному запуску print(g) малює в Rplots.pdf, де кирилиця не підтримується;
# тому екранні копії графіків направляємо в тимчасовий PNG (у RStudio не діє).
if (!interactive()) options(device = function(...) png(tempfile(fileext = ".png"), family = fam))

# ===================================================
# ЛАБОРАТОРНА РОБОТА: КЛАСТЕРНИЙ АНАЛІЗ У R
# Завдання 1. Підготовка даних
# ===================================================
# Пакет cluster потрібний для силуетного аналізу.
if (!requireNamespace("cluster", quietly = TRUE)) {
  install.packages("cluster")
}

library(cluster)
library(ggplot2)

# Завантажуємо набір даних
data(iris)

cat("КЛАСТЕРНИЙ АНАЛІЗ ДАНИХ IRIS\n")
cat("====================================\n")
cat("Кількість об'єктів:", nrow(iris), "\n")
cat("Кількість ознак у повному наборі:", ncol(iris),
    "\n\n")

cat("Перші шість записів:\n")
print(head(iris))
cat("\nСтруктура набору даних:\n")
str(iris)
cat("\nКількість об'єктів кожного виду:\n")
print(table(iris$Species))

# Вибираємо лише числові ознаки
iris_features <- iris[, 1:4]

cat("\nОписові статистики числових ознак:\n")
print(summary(iris_features))

# Перевірка пропущених значень
cat("\nКількість пропущених значень за стовпцями:\n")
print(colSums(is.na(iris_features)))

# ===================================================
# ЗАВДАННЯ 2. ПОПЕРЕДНІЙ АНАЛІЗ
# ===================================================
# Попарні діаграми числових ознак
open_png("01_pairs.png")
pairs(
  iris_features,
  main = "Попарні залежності між ознаками Iris",
  pch = 19
)
dev.off()
# Коробкові діаграми для порівняння масштабів і розподілів
iris_long <- data.frame(
  value = unlist(iris_features),
  feature = rep(names(iris_features),
                each = nrow(iris_features))
)
g <- ggplot(iris_long, aes(x = feature, y = value)) +
  geom_boxplot() +
  labs(
    title = "Розподіл значень числових ознак",
    x = "Ознака",
    y = "Значення"
  ) +
  theme_minimal()
print(g); save_gg(g, "02_boxplot.png")

# ==================================================
# ЗАВДАННЯ 3. СТАНДАРТИЗАЦІЯ
# ===================================================

iris_scaled <- scale(iris_features)

cat("Перші шість стандартизованих записів:\n")
print(head(iris_scaled))

cat("\nСередні значення після стандартизації:\n")

print(round(colMeans(iris_scaled), 4))

cat("\nСтандартні відхилення після стандартизації:\n")
print(round(apply(iris_scaled, 2, sd), 4))

# ===================================================
# ЗАВДАННЯ 4. АЛГОРИТМ K-MEANS
# ===================================================

# У першому експерименті використовуємо три кластери
k <- 3
set.seed(123)

km_result <- kmeans(
  iris_scaled,
  centers = k,
  nstart = 25
)

cat("РЕЗУЛЬТАТ КЛАСТЕРИЗАЦІЇ K-MEANS\n")
cat("====================================\n")
cat("\nКількість об'єктів у кластерах:\n")
print(km_result$size)

cat("\nЦентри кластерів у стандартизованому просторі:\n")
print(round(km_result$centers, 3))

cat("\nСума квадратів усередині кластерів:\n")
print(km_result$tot.withinss)

cat("\nМіжкластерна сума квадратів:\n")
print(km_result$betweenss)

cat("\nЗагальна сума квадратів:\n")
print(km_result$totss)

cat("\nЧастка міжкластерної суми квадратів:\n")
print(round(km_result$betweenss /
              km_result$totss, 4))

# Додаємо номер кластера до початкових даних
iris_clustered <- iris

iris_clustered$Cluster <- factor(km_result$cluster)

cat("\nКількість об'єктів за кластерами:\n")
print(table(iris_clustered$Cluster))

# ===================================================
# ЗАВДАННЯ 5. ВІЗУАЛІЗАЦІЯ КЛАСТЕРІВ
# ===================================================

pca_result <- prcomp(
  iris_scaled,
  center = FALSE,
  scale. = FALSE
)

pca_data <- data.frame(
  PC1 = pca_result$x[, 1],
  PC2 = pca_result$x[, 2],
  Cluster = factor(km_result$cluster),
  Species = iris$Species
)

variance_explained <- summary(pca_result)$importance[2, ]

cat("Частка поясненої варіації першою компонентою:",
    round(variance_explained[1] * 100, 2), "%\n")

cat("Частка поясненої варіації другою компонентою:",
    round(variance_explained[2] * 100, 2), "%\n")

cat("Сумарна частка варіації двох компонент:",
    round(sum(variance_explained[1:2]) * 100, 2),
    "%\n")

g <- ggplot(pca_data, aes(x = PC1, y = PC2, color = Cluster)) +
  geom_point(size = 3, alpha = 0.85) +
  labs(
    title = "Кластери Iris у просторі головних компонентів",
    subtitle = "Кластеризація k-means, візуалізація PCA",
    x = "Перша головна компонента",
    y = "Друга головна компонента",
    color = "Кластер"
  ) +
  theme_minimal()
print(g); save_gg(g, "03_pca_kmeans.png")

# ===================================================
# ЗАВДАННЯ 6. МЕТОД ЛІКТЯ
# ===================================================

set.seed(123)
k_values <- 1:10

wss <- sapply(k_values, function(k) {
  kmeans(
    iris_scaled,
    centers = k,
    nstart = 25
  )$tot.withinss
})

elbow_data <- data.frame(
  k = k_values,
  WSS = wss
)

cat("Таблиця методу ліктя:\n")
print(elbow_data)

g <- ggplot(elbow_data, aes(x = k, y = WSS)) +
  geom_line() +
  geom_point(size = 3) +
  scale_x_continuous(breaks = k_values) +
  labs(
    title = "Визначення кількості кластерів методом ліктя",
    x = "Кількість кластерів k",
    y = "Внутрішньокластерна сума квадратів"
  ) +
  theme_minimal()
print(g); save_gg(g, "04_elbow.png")

# ===================================================
# ЗАВДАННЯ 7. СИЛУЕТНИЙ АНАЛІЗ
# ==================================================

distance_matrix <- dist(iris_scaled)

silhouette_results <- lapply(2:10, function(k) {
  set.seed(123)

  fit <- kmeans(
    iris_scaled,
    centers = k,
    nstart = 25
  )

  sil <- silhouette(
    fit$cluster,
    distance_matrix
  )

  data.frame(
    k = k,
    mean_silhouette = mean(sil[, "sil_width"])
  )
})

silhouette_data <- do.call(rbind, silhouette_results)

cat("Середні коефіцієнти силуету:\n")
print(silhouette_data)

best_k_silhouette <- silhouette_data$k[
  which.max(silhouette_data$mean_silhouette)
]

cat("\nКількість кластерів із найбільшим середнім силуетом:",
    best_k_silhouette, "\n")

g <- ggplot(
  silhouette_data,
  aes(x = k, y = mean_silhouette)
) +
  geom_line() +
  geom_point(size = 3) +
  scale_x_continuous(breaks = 2:10) +
  labs(
    title = "Вибір кількості кластерів за силуетом",
    x = "Кількість кластерів k",
    y = "Середній коефіцієнт силуету"
  ) +
  theme_minimal()
print(g); save_gg(g, "05_silhouette.png")

# ==================================================
# ЗАВДАННЯ 8. ІЄРАРХІЧНА КЛАСТЕРИЗАЦІЯ
# ==================================================
# Евклідова відстань між об'єктами
d <- dist(iris_scaled, method = "euclidean")

# Метод Ward.D2 намагається формувати компактні кластери
hc_result <- hclust(
  d,
  method = "ward.D2"
)

# Побудова дендрограми
open_png("06_dendrogram.png", 9, 6)
plot(
  hc_result,
  labels = FALSE,
  hang = -1,
  main = "Дендрограма ієрархічної кластеризації",
  xlab = "Об'єкти",
  ylab = "Висота об'єднання"
)
rect.hclust(hc_result, k = 3, border = c("red", "darkgreen", "blue"))
dev.off()

# Відокремлюємо три кластери
hc_clusters <- cutree(
  hc_result,
  k = 3
)

cat("\nКількість об'єктів в ієрархічних кластерах:\n")
print(table(hc_clusters))

# Додаємо номери кластерів
iris_clustered$Hierarchical_Cluster <-
  factor(hc_clusters)

# Порівняння розмірів кластерів
cat("\nРозподіл об'єктів між двома методами:\n")
print(table(
  KMeans = iris_clustered$Cluster,
  Hierarchical = iris_clustered$Hierarchical_Cluster
))

# ===================================================
# ЗАВДАННЯ 9. ЗОВНІШНЯ ІНТЕРПРЕТАЦІЯ
# ===================================================
cat("\nПорівняння кластерів k-means із видами Iris:\n")

species_cluster_table <- table(
  Species = iris$Species,
  Cluster = km_result$cluster
)

print(species_cluster_table)

cat("\nЧастка кожного виду в кожному кластері:\n")
print(round(
  prop.table(species_cluster_table, margin = 2),
  3
))

# Візуальне порівняння
g <- ggplot(
  pca_data,
  aes(x = PC1, y = PC2, color = Species)
) +
  geom_point(size = 3, alpha = 0.85) +
  labs(
    title = "Види квіток Iris у просторі PCA",
    subtitle = "Відомі види для інтерпретації структури даних",
    x = "Перша головна компонента",
    y = "Друга головна компонента",
    color = "Вид"
  ) +
  theme_minimal()
print(g); save_gg(g, "07_pca_species.png")

# ===================================================
# ЗАВДАННЯ 10. ПРОФІЛІ КЛАСТЕРІВ
# ===================================================
library(dplyr)
profile_data <- iris_clustered %>%
  group_by(Cluster) %>%
  summarise(
    Кількість = n(),
    Довжина_чашолистика =
      mean(Sepal.Length),
    Ширина_чашолистика =
      mean(Sepal.Width),
    Довжина_пелюстки =
      mean(Petal.Length),
    Ширина_пелюстки =
      mean(Petal.Width),
    .groups = "drop"
  )

cat("\nПРОФІЛІ КЛАСТЕРІВ У ПОЧАТКОВИХ ОДИНИЦЯХ\n")
print(profile_data)

# Порівняння середньої довжини пелюстки
g <- ggplot(
  profile_data,
  aes(x = Cluster, y = Довжина_пелюстки)
) +
  geom_col() +
  labs(
    title = "Середня довжина пелюстки за кластерами",
    x = "Кластер",
    y = "Середня довжина пелюстки"
  ) +
  theme_minimal()
print(g); save_gg(g, "08_profile_petal.png")

# ===================================================
# ДОДАТКОВІ ЕКСПЕРИМЕНТИ
# ===================================================
# Допоміжна: відповідність кластерів видам за найбільшим збігом
# (кожному кластеру ставимо вид, якого в ньому найбільше)
match_species <- function(cl) {
  tb <- table(Cluster = cl, Species = iris$Species)
  maj <- colnames(tb)[apply(tb, 1, which.max)]
  correct <- sum(apply(tb, 1, max))
  list(table = tb, majority = maj, correct = correct)
}

# ---------- Експеримент 1: вплив стандартизації ----------
cat("\n\n=========== ЕКСПЕРИМЕНТ 1: СТАНДАРТИЗАЦІЯ ===========\n")
set.seed(123)
km_raw <- kmeans(iris_features, centers = 3, nstart = 25)
cat("Розміри (без стандартизації):", km_raw$size, "\n")
cat("Розміри (зі стандартизацією):", km_result$size, "\n")
cat("tot.withinss без масштабування:", km_raw$tot.withinss,
    " betweenss/totss:", round(km_raw$betweenss / km_raw$totss, 4), "\n")
cat("\nЦентри без стандартизації (початкові одиниці):\n")
print(round(km_raw$centers, 3))
cat("\nЦентри зі стандартизацією, перераховані в початкові одиниці:\n")
centers_scaled_orig <- aggregate(iris_features,
                                 by = list(Cluster = km_result$cluster), FUN = mean)
print(round(centers_scaled_orig, 3))
cat("\nСтандартні відхилення ознак (початкові одиниці):\n")
print(round(apply(iris_features, 2, sd), 3))
cat("\nПерехресна таблиця: без стандартизації (рядки) vs зі стандартизацією (стовпці):\n")
tab_e1 <- table(Raw = km_raw$cluster, Scaled = km_result$cluster)
print(tab_e1)
cat("Збіг двох розбиттів (найкраще зіставлення кластерів):",
    sum(apply(tab_e1, 1, max)), "з 150 (",
    round(100 * sum(apply(tab_e1, 1, max)) / 150, 1), "%)\n")
cat("\nЗбіг з Species (без стандартизації):\n")
print(table(Species = iris$Species, Cluster = km_raw$cluster))
cat("Правильно зіставлено (raw):", match_species(km_raw$cluster)$correct, "з 150\n")
cat("Правильно зіставлено (scaled):", match_species(km_result$cluster)$correct, "з 150\n")
sil_raw <- mean(silhouette(km_raw$cluster, dist(iris_features))[, "sil_width"])
sil_sc <- mean(silhouette(km_result$cluster, distance_matrix)[, "sil_width"])
cat("Середній силует raw (у власному просторі):", round(sil_raw, 4),
    " scaled (у власному просторі):", round(sil_sc, 4), "\n")

pc_raw <- prcomp(iris_features, center = TRUE, scale. = FALSE)
e1_df <- rbind(
  data.frame(Petal.Length = iris$Petal.Length, Petal.Width = iris$Petal.Width,
             Cluster = factor(km_raw$cluster), Variant = "Без стандартизації"),
  data.frame(Petal.Length = iris$Petal.Length, Petal.Width = iris$Petal.Width,
             Cluster = factor(km_result$cluster), Variant = "Зі стандартизацією")
)
g <- ggplot(e1_df, aes(x = Petal.Length, y = Petal.Width, color = Cluster)) +
  geom_point(size = 2.5, alpha = 0.85) +
  facet_wrap(~ Variant) +
  labs(title = "Експеримент 1: k-means без та зі стандартизацією",
       x = "Довжина пелюстки", y = "Ширина пелюстки", color = "Кластер") +
  theme_minimal()
print(g); save_gg(g, "09_exp1_scaling.png", 10, 5)

# ---------- Експеримент 2: вплив k ----------
cat("\n\n=========== ЕКСПЕРИМЕНТ 2: КІЛЬКІСТЬ КЛАСТЕРІВ ===========\n")
for (kk in 2:5) {
  set.seed(123)
  fit <- kmeans(iris_scaled, centers = kk, nstart = 25)
  sil <- silhouette(fit$cluster, distance_matrix)
  cat("\n--- k =", kk, "---\n")
  cat("Розміри:", fit$size, "\n")
  cat("tot.withinss:", round(fit$tot.withinss, 3),
      " betweenss/totss:", round(fit$betweenss / fit$totss, 4), "\n")
  cat("Середній силует:", round(mean(sil[, "sil_width"]), 4), "\n")
  prof <- aggregate(iris_features, by = list(Cluster = fit$cluster), FUN = mean)
  prof$n <- fit$size
  cat("Середні ознаки за кластерами (початкові одиниці):\n")
  print(round(prof, 3))
  cat("Таблиця Species x Cluster:\n")
  print(table(Species = iris$Species, Cluster = fit$cluster))
}

# ---------- Експеримент 3: початкові центри ----------
cat("\n\n=========== ЕКСПЕРИМЕНТ 3: SEED І NSTART ===========\n")
set.seed(123)
ref <- kmeans(iris_scaled, centers = 3, nstart = 25)
cat("Еталон (seed 123, nstart 25): tot.withinss =", ref$tot.withinss,
    " розміри:", sort(ref$size), "\n")
e3 <- data.frame()
for (ns in c(1, 25)) for (sd_ in c(1, 42, 123, 2024, 777)) {
  set.seed(sd_)
  fit <- kmeans(iris_scaled, centers = 3, nstart = ns)
  tb <- table(Ref = ref$cluster, New = fit$cluster)
  agree <- sum(apply(tb, 1, max))
  e3 <- rbind(e3, data.frame(
    seed = sd_, nstart = ns,
    tot_withinss = round(fit$tot.withinss, 4),
    sizes = paste(sort(fit$size), collapse = "/"),
    agree_with_ref = agree,
    identical_partition = (nrow(tb) == 3 && all(apply(tb > 0, 1, sum) == 1) &&
                             all(apply(tb > 0, 2, sum) == 1))))
}
print(e3, row.names = FALSE)
cat("\nМіжкластерні розбіжності (centers у scaled-просторі) для nstart=1, seed 1:\n")
set.seed(1); f1 <- kmeans(iris_scaled, 3, nstart = 1); print(round(f1$centers, 3))
cat("Еталонні центри:\n"); print(round(ref$centers, 3))

# ---------- Експеримент 4: k-means vs hclust ----------
cat("\n\n=========== ЕКСПЕРИМЕНТ 4: K-MEANS VS HCLUST (ward.D2) ===========\n")
sil_km <- silhouette(km_result$cluster, distance_matrix)
sil_hc <- silhouette(hc_clusters, distance_matrix)
cat("Розміри k-means:", km_result$size, "\n")
cat("Розміри hclust:", as.integer(table(hc_clusters)), "\n")
cat("Середній силует k-means:", round(mean(sil_km[, "sil_width"]), 4), "\n")
cat("Середній силует hclust:", round(mean(sil_hc[, "sil_width"]), 4), "\n")
cat("Силует за кластерами k-means:\n"); print(round(tapply(sil_km[, "sil_width"], km_result$cluster, mean), 4))
cat("Силует за кластерами hclust:\n"); print(round(tapply(sil_hc[, "sil_width"], hc_clusters, mean), 4))
cat("\nSpecies x hclust:\n")
print(table(Species = iris$Species, Cluster = hc_clusters))
m_km <- match_species(km_result$cluster); m_hc <- match_species(hc_clusters)
cat("Правильно зіставлено з Species: k-means =", m_km$correct,
    "; hclust =", m_hc$correct, "з 150\n")
cat("Відповідність кластер -> вид (k-means):", paste(seq_along(m_km$majority), m_km$majority, sep = "=", collapse = ", "), "\n")
cat("Відповідність кластер -> вид (hclust):", paste(seq_along(m_hc$majority), m_hc$majority, sep = "=", collapse = ", "), "\n")
cat("\nПрофілі hclust (початкові одиниці):\n")
prof_hc <- aggregate(iris_features, by = list(Cluster = hc_clusters), FUN = mean)
prof_hc$n <- as.integer(table(hc_clusters))
print(round(prof_hc, 3))
cat("Профілі k-means (початкові одиниці):\n")
prof_km <- aggregate(iris_features, by = list(Cluster = km_result$cluster), FUN = mean)
prof_km$n <- km_result$size
print(round(prof_km, 3))
cat("Збіг k-means і hclust:",
    sum(apply(table(km_result$cluster, hc_clusters), 1, max)), "з 150\n")

e4 <- rbind(
  data.frame(pca_data[, c("PC1", "PC2")], Cluster = factor(km_result$cluster), Method = "k-means"),
  data.frame(pca_data[, c("PC1", "PC2")], Cluster = factor(hc_clusters), Method = "hclust (ward.D2)")
)
g <- ggplot(e4, aes(PC1, PC2, color = Cluster)) +
  geom_point(size = 2.5, alpha = 0.85) + facet_wrap(~ Method) +
  labs(title = "Експеримент 4: k-means та ієрархічна кластеризація",
       x = "Перша головна компонента", y = "Друга головна компонента", color = "Кластер") +
  theme_minimal()
print(g); save_gg(g, "10_exp4_compare.png", 10, 5)

# ===================================================
# ІНДИВІДУАЛЬНЕ ЗАВДАННЯ — ВАРІАНТ 6
# Характеристики товарів: ціна, попит, рейтинг, частота продажів
# УВАГА: дані СИНТЕТИЧНІ (змодельовані), реального набору для варіанту немає.
# ===================================================
cat("\n\n====================================================\n")
cat("ІНДИВІДУАЛЬНЕ ЗАВДАННЯ — ВАРІАНТ 6 (характеристики товарів)\n")
cat("Дані СИНТЕТИЧНІ: змодельовано 4 приховані сегменти з шумом і перетином.\n")
cat("====================================================\n")
dir.create("data", showWarnings = FALSE)

set.seed(2025)
gen_seg <- function(n, price, demand, rating, freq) {
  data.frame(
    Price     = rlnorm(n, log(price[1]), price[2]),     # ціна, грн (логнормальна)
    Demand    = pmax(rnorm(n, demand[1], demand[2]), 5),# попит, шт/міс
    Rating    = pmin(pmax(rnorm(n, rating[1], rating[2]), 1), 5),
    SalesFreq = pmax(rnorm(n, freq[1], freq[2]), 0.5)   # продажів на тиждень
  )
}
products <- rbind(
  gen_seg(70, c(150, 0.40),  c(400, 100), c(3.9, 0.50), c(35, 9)),   # дешеві ходові
  gen_seg(35, c(1800, 0.30), c(70, 30),   c(4.6, 0.30), c(5, 2.5)),  # преміум
  gen_seg(60, c(600, 0.35),  c(190, 60),  c(4.0, 0.45), c(16, 6)),   # середній
  gen_seg(35, c(450, 0.55),  c(60, 30),   c(2.4, 0.60), c(3, 1.8))   # слабкі
)
products$Price     <- round(products$Price, 0)
products$Demand    <- round(products$Demand, 0)
products$Rating    <- round(products$Rating, 1)
products$SalesFreq <- round(products$SalesFreq, 1)
products <- products[sample(nrow(products)), ]   # перемішуємо рядки
products <- data.frame(ProductID = sprintf("P%03d", 1:nrow(products)), products)
rownames(products) <- NULL
write.csv(products, file.path("data", "products.csv"), row.names = FALSE)

cat("\nКількість товарів:", nrow(products), "\n")
cat("Перші шість записів:\n"); print(head(products))
feat6 <- products[, c("Price", "Demand", "Rating", "SalesFreq")]
cat("\nОписові статистики:\n"); print(summary(feat6))
cat("\nСтандартні відхилення (різні шкали):\n"); print(round(sapply(feat6, sd), 3))
cat("Пропущені значення:", sum(is.na(feat6)), "\n")
cat("\nКореляційна матриця ознак:\n"); print(round(cor(feat6), 3))
cat("\nОбґрунтування: Price (сотні-тисячі грн) і Demand (сотні шт) мають на порядки більший розмах,\n")
cat("ніж Rating (1-5) і SalesFreq; без стандартизації відстані визначали б Price і Demand,\n")
cat("тому застосовуємо scale() (середнє 0, sd 1).\n")

X6 <- scale(feat6)

# --- вибір k: лікоть і середній силует
set.seed(2025)
wss6 <- sapply(1:8, function(k) kmeans(X6, centers = k, nstart = 25)$tot.withinss)
d6 <- dist(X6, method = "euclidean")
sil6 <- sapply(2:8, function(k) {
  set.seed(2025)
  km <- kmeans(X6, centers = k, nstart = 25)
  mean(silhouette(km$cluster, d6)[, "sil_width"])
})
cat("\nМетод ліктя (tot.withinss):\n")
print(data.frame(k = 1:8, tot_withinss = round(wss6, 2)))
cat("\nСередній силует:\n")
print(data.frame(k = 2:8, avg_silhouette = round(sil6, 4)))
cat("k з найбільшим середнім силуетом:", (2:8)[which.max(sil6)], "\n")

g <- ggplot(data.frame(k = 1:8, wss = wss6), aes(k, wss)) +
  geom_line() + geom_point(size = 3) + scale_x_continuous(breaks = 1:8) +
  labs(title = "Варіант 6: метод ліктя", x = "Кількість кластерів k",
       y = "Сумарна внутрішньокластерна сума квадратів") + theme_minimal()
print(g); save_gg(g, "var6_elbow.png")
g <- ggplot(data.frame(k = 2:8, sil = sil6), aes(k, sil)) +
  geom_line() + geom_point(size = 3) + scale_x_continuous(breaks = 2:8) +
  labs(title = "Варіант 6: середній коефіцієнт силуету", x = "Кількість кластерів k",
       y = "Середній силует") + theme_minimal()
print(g); save_gg(g, "var6_silhouette.png")

K6 <- 4   # обрано за ліктем, силуетом і змістовністю (див. звіт)
cat("\nОбране k =", K6, "\n")

# --- алгоритм 1: k-means
set.seed(2025)
km6 <- kmeans(X6, centers = K6, nstart = 25)
cat("\nk-means: розміри кластерів:", km6$size, "\n")
cat("Частка міжкластерної суми квадратів:", round(km6$betweenss / km6$totss, 4), "\n")

# --- алгоритм 2: ієрархічна кластеризація
hc6 <- hclust(d6, method = "ward.D2")
hc6_cl <- cutree(hc6, k = K6)
cat("hclust (ward.D2): розміри кластерів:", as.integer(table(hc6_cl)), "\n")

open_png("var6_dendrogram.png", 10, 6)
plot(hc6, labels = FALSE, hang = -1, main = "Варіант 6: дендрограма (ward.D2)",
     xlab = "Товари", sub = "", ylab = "Висота")
rect.hclust(hc6, k = K6, border = 2:(K6 + 1))
dev.off()

# --- якість
sil_km6 <- silhouette(km6$cluster, d6)
sil_hc6 <- silhouette(hc6_cl, d6)
cat("\nСередній силует: k-means =", round(mean(sil_km6[, "sil_width"]), 4),
    "; hclust =", round(mean(sil_hc6[, "sil_width"]), 4), "\n")
cat("Силует по кластерах (k-means):", round(tapply(sil_km6[, "sil_width"], sil_km6[, "cluster"], mean), 4), "\n")
cat("Силует по кластерах (hclust):", round(tapply(sil_hc6[, "sil_width"], sil_hc6[, "cluster"], mean), 4), "\n")
cat("\nТаблиця збігу (рядки — k-means, стовпці — hclust):\n")
tab6 <- table(kmeans = km6$cluster, hclust = hc6_cl); print(tab6)
cat("Збіг k-means і hclust (за найбільшим перетином):", sum(apply(tab6, 1, max)), "з", nrow(products), "\n")

# --- профілі у вихідних одиницях та назви
prof6 <- aggregate(feat6, by = list(Cluster = km6$cluster), FUN = mean)
prof6$n <- as.integer(table(km6$cluster))
cat("\nПрофілі k-means (середні у вихідних одиницях):\n"); print(round(prof6, 2))
prof6_hc <- aggregate(feat6, by = list(Cluster = hc6_cl), FUN = mean)
prof6_hc$n <- as.integer(table(hc6_cl))
cat("\nПрофілі hclust (середні у вихідних одиницях):\n"); print(round(prof6_hc, 2))

# назви за профілями (правила за середніми кластерів)
nm <- rep(NA_character_, K6)
nm[which.max(prof6$Price)]      <- "Преміум"
nm[which.min(prof6$Rating)]     <- "Слабкі"
rest <- which(is.na(nm))
nm[rest[which.max(prof6$SalesFreq[rest])]] <- "Дешеві ходові"
nm[is.na(nm)] <- "Середній сегмент"
names6 <- paste0(1:K6, ": ", nm)
cat("\nНазви кластерів:", paste(names6, collapse = "; "), "\n")
cat("Медіанна ціна за кластерами:", round(tapply(feat6$Price, km6$cluster, median)), "\n")

# --- PCA-графік
pc6 <- prcomp(X6)
cat("\nPCA: частка дисперсії PC1, PC2:", round(summary(pc6)$importance[2, 1:2], 4), "\n")
df6 <- data.frame(pc6$x[, 1:2], Cluster = factor(names6[km6$cluster], levels = names6))
g <- ggplot(df6, aes(PC1, PC2, color = Cluster)) + geom_point(size = 2.3, alpha = 0.85) +
  labs(title = "Варіант 6: k-means (k = 4) у просторі головних компонент",
       x = "Перша головна компонента", y = "Друга головна компонента", color = "Кластер") +
  theme_minimal()
print(g); save_gg(g, "var6_kmeans_pca.png", 9, 5.5)

# --- профілі (стандартизовані середні за кластерами)
zprof <- aggregate(as.data.frame(X6), by = list(Cluster = km6$cluster), FUN = mean)
zl <- do.call(rbind, lapply(names(feat6), function(v)
  data.frame(Cluster = factor(names6[zprof$Cluster], levels = names6), Feature = v, Z = zprof[[v]])))
zl$Feature <- factor(zl$Feature, levels = names(feat6),
  labels = c("Ціна", "Попит", "Рейтинг", "Частота продажів"))
g <- ggplot(zl, aes(Feature, Z, fill = Cluster)) +
  geom_col(position = "dodge") + geom_hline(yintercept = 0) +
  labs(title = "Варіант 6: профілі кластерів (стандартизовані середні)",
       x = "Ознака", y = "Середнє z-значення", fill = "Кластер") + theme_minimal()
print(g); save_gg(g, "var6_profiles.png", 9, 5.5)
