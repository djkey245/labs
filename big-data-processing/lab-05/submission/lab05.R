# ЛР5: Графічні можливості RStudio (ggplot2, mtcars). Запуск з папки submission/
library(ggplot2)
dir.create("plots", showWarnings = FALSE); dir.create("results", showWarnings = FALSE)
sink("results/console_output.txt", split = TRUE)

print(head(mtcars))
str(mtcars)

fam <- "Arial Unicode MS"  # коректна кирилиця на macOS

# Завдання 1
mtcars$cyl <- factor(mtcars$cyl)
plot_1 <- ggplot(data = mtcars,
                 mapping = aes(x = hp, y = mpg, color = cyl)) +
  geom_point(size = 3) +
  geom_smooth(method = "lm", se = FALSE) +
  labs(title = "Залежність пробігу від потужності (mtcars)",
       x = "Потужність двигуна (hp)",
       y = "Пробіг (mpg)",
       color = "Кількість\nциліндрів") +
  theme_minimal()
print(plot_1)

# Завдання 2
plot_2 <- ggplot(data = mtcars,
                 mapping = aes(x = wt)) +
  geom_histogram(binwidth = 0.5,
                 fill = "lightblue",
                 color = "black") +
  labs(title = "Розподіл ваги автомобілів",
       x = "Вага (тис. фунтів)",
       y = "Кількість авто") +
  theme_classic()
plot_3 <- ggplot(mtcars, aes(x = wt)) +
  geom_density(fill = "orange", alpha = 0.5) +
  labs(title = "Оцінка щільності розподілу ваги",
       x = "Вага (тис. фунтів)")
print(plot_2)
print(plot_3)

# Завдання 3
mtcars$am <- factor(mtcars$am,
                    labels = c("Автомат", "Механіка"))
plot_4 <- ggplot(data = mtcars,
                 mapping = aes(x = am, y = mpg, fill = am)) +
  geom_boxplot() +
  geom_jitter(width = 0.2, alpha = 0.6) +
  labs(title = "Порівняння пробігу за типом трансмісії",
       x = "Тип трансмісії",
       y = "Пробіг (mpg)") +
  theme_bw() +
  theme(legend.position = "none")
print(plot_4)

# Завдання 4
plot_5 <- ggplot(data = mtcars,
                 mapping = aes(x = hp, y = mpg)) +
  geom_point(aes(color = cyl), size = 2) +
  facet_wrap(~ am, scales = "free") +
  labs(title = "Залежність пробігу від потужності, розбита за трансмісією",
       x = "Потужність двигуна (hp)",
       y = "Пробіг (mpg)") +
  theme_gray()
print(plot_5)

# Збереження
plots <- list(plot_1, plot_2, plot_3, plot_4, plot_5)
for (i in seq_along(plots)) {
  p <- plots[[i]] + theme(text = element_text(family = fam))
  ggsave(file.path("plots", paste0("plot_", i, ".png")), p,
         width = 8, height = 5.5, dpi = 150)
}

# Base R для порівняння
png("plots/base_r_scatter.png", width = 8, height = 5.5, units = "in", res = 150, family = fam)
plot(mtcars$hp, mtcars$mpg, pch = 19, xlab = "Потужність двигуна (hp)", ylab = "Пробіг (mpg)",
     main = "Base R: пробіг від потужності")
dev.off()

# Числа для висновків
d <- mtcars; d$cyl <- factor(d$cyl); d$am <- factor(d$am)
cat("\n=== ЧИСЛА ДЛЯ ВИСНОВКІВ ===\n")
cat("cor(hp, mpg) =", round(cor(d$hp, d$mpg), 3), "\n")
print(round(tapply(d$mpg, d$cyl, mean), 2))
print(round(tapply(d$mpg, d$am, mean), 2))
print(round(tapply(d$mpg, d$am, median), 2))
cat("wt: mean =", round(mean(d$wt), 3), " median =", round(median(d$wt), 3),
    " min =", min(d$wt), " max =", max(d$wt), "\n")
print(table(cut(d$wt, seq(1, 6, 0.5))))
for (g in levels(d$cyl)) {
  m <- lm(mpg ~ hp, data = d[d$cyl == g, ])
  cat("cyl", g, "n =", sum(d$cyl == g), " slope =", round(coef(m)[2], 4), "\n")
}
for (g in levels(d$am)) {
  s <- d[d$am == g, ]
  cat("am", g, "n =", nrow(s), " cor(hp,mpg) =", round(cor(s$hp, s$mpg), 3),
      " hp range", range(s$hp), "\n")
}
sink()
