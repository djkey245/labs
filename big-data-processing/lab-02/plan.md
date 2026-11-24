# План — Лаба 2

Папка лаби: `big-data-processing/lab-02/`. Середовище — `../.venv` (вже існує; `sqlite3` вбудований, SQLite 3.51). Зразок підходу — `../lab-01/src/build_notebook.py`.

## Здача (≤ 4 файли) — `submission/`
1. `lab2.ipynb` — виконаний, з виводами.
2. `university.db` — створюється ноутбуком.
3. `report.csv` — звіт самостійного завдання (п.3).
4. `course_avg.csv` — середня оцінка по курсах (п.4).

Більше нічого в `submission/` бути не повинно (жодних PNG, проміжних файлів).

## Збірка
`src/build_notebook.py` (nbformat) пише `submission/lab2.ipynb`, вміст контрольних питань — з `answers.md`. Виконання з `submission/` як cwd:
`../../.venv/bin/jupyter nbconvert --to notebook --execute --inplace lab2.ipynb`.

## Відновлені дані (кирилицю в PDF втрачено)
```python
students_data = [
    ("Іван Петренко", 20, "КН-21"),
    ("Марія Коваленко", 19, "КН-22"),
    ("Петро Шевченко", 21, "КН-21"),
    ("Олена Бондаренко", 20, "КН-22"),
]
grades_data = [
    (1, "Математика", 90),
    (1, "Програмування", 85),
    (2, "Математика", 92),
    (3, "Програмування", 78),
    (4, "Математика", 88),
    (4, "Програмування", 91),
]
```
Повідомлення `print`: «Таблиці створено успішно.», «Дані додано.», «З'єднання закрито.».

## Структура ноутбука
1. Титул, мета.
2. **Крок 1** — `import sqlite3`, коментарі українською. Щоб ноутбук можна було перезапускати: перед `CREATE TABLE` виконати `DROP TABLE IF EXISTS grades; DROP TABLE IF EXISTS students; DROP TABLE IF EXISTS courses;` (через `executescript`) і `PRAGMA foreign_keys = ON`. Далі `CREATE TABLE` дослівно як у методичці.
3. **Крок 2** — `executemany` з даними вище, `commit`.
4. **Крок 3** — три запити з методички (`SELECT *`; `age > 19`; JOIN з `WHERE g.subject = 'Програмування'`). Додатково показати сортування: `SELECT name, age FROM students ORDER BY age DESC, name` (мета роботи згадує сортування).
5. **Крок 4** — `AVG(grade) GROUP BY subject`. Також гарно показати результат через `pd.read_sql_query(...)` (pandas є в venv) — як таблицю.
6. **Самостійне завдання** (до `conn.close()`!):
   - `CREATE TABLE courses (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE NOT NULL, hours INTEGER)`.
   - Курси: `("Математика", 120), ("Програмування", 150), ("Бази даних", 90)`. «Бази даних» — без оцінок навмисно, щоб показати різницю INNER/LEFT JOIN.
   - Звіт (INNER JOIN трьох таблиць, `grades.subject = courses.name`), відсортований за ім'ям і курсом:
     ```sql
     SELECT s.name AS "Ім'я", c.name AS "Курс", g.grade AS "Оцінка", c.hours AS "Години"
     FROM students s
     JOIN grades g ON s.id = g.student_id
     JOIN courses c ON g.subject = c.name
     ORDER BY s.name, c.name
     ```
     Вивести у форматі `Ім'я | Курс | Оцінка | Години` (рядок-заголовок + рядки, вирівняні через f-string), а також як DataFrame.
   - Середня по курсах — `LEFT JOIN` від `courses`, `ROUND(AVG(g.grade), 2) AS avg_grade`, `COUNT(g.id) AS grades_count`, `GROUP BY c.id ORDER BY c.name`. «Бази даних» → avg NULL, count 0. Коротка markdown-примітка, чому так (LEFT JOIN).
   - Збереження: модулем `csv` (stdlib), `encoding="utf-8-sig"` (щоб Excel відкривав кирилицю), `report.csv` і `course_avg.csv` з заголовками.
7. **Крок 5** — `conn.close()`, print.
8. Контрольні питання — markdown з `answers.md`.
9. Висновки — 3–4 речення.

## Перевірка
- Ноутбук виконується без помилок двічі поспіль (перезапуск не падає на `CREATE TABLE`).
- `submission/` містить рівно 4 файли зі списку.
- Очікувано:
  - `age > 19` → Іван (20), Петро (21), Олена (20);
  - Програмування → Іван 85, Петро 78, Олена 91;
  - AVG по предметах: Математика 90.0, Програмування 84.67 (≈84.666…);
  - `report.csv` — 6 рядків даних; `course_avg.csv` — 3 рядки, «Бази даних» з порожнім avg і count 0.
- Відкрити обидва CSV і переконатися, що кирилиця коректна.
