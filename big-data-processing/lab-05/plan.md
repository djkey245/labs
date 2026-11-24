# План ЛР5 — виконавець: lab-worker
Мова звіту укр., автор: Ковальчук Дмитро Олексійович, ПІ-23. Rscript 4.6.2, ggplot2 встановлено (dplyr теж). Методичка: pdftotext -layout task.pdf -.

## src/lab05.R (копія в submission/lab05.R; запуск з submission/)
Код 5 графіків ТОЧНО за методичкою (розд. 3.2): 1) scatter hp–mpg за cyl + geom_smooth(lm); 2) гістограма ваги wt (binwidth 0.5) + 3) density (це plot_2 і plot_3, разом 5 графіків: plot_1..plot_5 з нумерацією методички); 4) boxplot mpg за am + jitter; 5) facet_wrap(~am, scales="free").
Також head(mtcars), str(mtcars) → results/console_output.txt. Збереження кожного графіка ggsave() у submission/plots/plot_1.png … plot_5.png (width 8, height 5.5, dpi 150). Українські підписи мають відображатись коректно (на macOS: theme(text=element_text(family="Helvetica")) або перевір результат візуально/розмірами; якщо квадратики — спробуй ragg/Arial Unicode).
Для висновків: порахуй з реальних даних (cor(hp,mpg), середні mpg за cyl і за am, середня/медіана wt, нахили lm по групах cyl) і використай ці числа в текстах висновків.
Додатково (проти base R): збережи для порівняння 1 графік у base R (plot(hp,mpg)) як plots/base_r_scatter.png.

## src/build_report.py → submission/Lab05_Kovalchuk.docx
Шаблон: ../lab-04/src/build_report.py (python-docx, ../../.venv/bin/python). Розділи: Тема і мета; Теоретичні відомості (дві графічні системи, компоненти ggplot2); Хід роботи (код кожного графіка + рисунок + короткий висновок з числами); Загальний висновок (переваги ggplot2 vs base R, з посиланням на порівняльний рисунок); Відповіді на 5 контрольних питань (Grammar of Graphics; labs(); facet_wrap vs facet_grid; geom_smooth(method="lm") = лінійна регресія МНК; збереження графіка в RStudio: Export у вкладці Plots і ggsave()).

## Перевірка
Rscript submission/lab05.R без помилок; усі PNG існують; docx містить 5 рисунків + 1 порівняльний. Звітувати файлами, ключовими числами та проблемами.
