# ЛР14 (Moodle) — Аналіз новин HuffPost у R (JSON Lines)
Джерело: курс 9640, ЛР14 (task.pdf / task.txt). Окремого завдання в РП немає. Дані: News_Category_Dataset_v3.json (Moodle 323908, zip) → lab-14/data/ (87 МБ, не в submission).
Обсяг: Завдання 1–8 + додаткове (місяці), «Завдання для самостійної роботи» 1–6 (вимога п.9.8 звіту — обов'язкові), 15 контрольних питань, звіт за п.9.
Помилка в методичці: у Завданні 8 `slice_sample(n = min(3000, nrow(data)))` — `data` не існує (nrow(data) → NULL/помилка), виправити на nrow(.) або nrow(news). file.choose() замінити константою file_path.
