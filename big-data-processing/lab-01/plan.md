# План — Лаба 1

Робоча папка: `big-data-processing/lab-01/`. Усі шляхи нижче — відносно неї.

## 1. Середовище
- Створити venv: `python3 -m venv ../.venv` (у папці предмету, спільний для всіх лаб).
- `../.venv/bin/pip install pandas numpy matplotlib jupyter nbconvert nbformat ipykernel`.
- Записати версії в `../requirements.txt` (`pip freeze` лише для pandas, numpy, matplotlib, jupyter — або повний freeze, на розсуд).

## 2. Дані
`students.csv` (UTF-8). Імена в PDF втрачено — використати:
```
name,age,grade
Іван,20,85
Марія,19,92
Петро,21,78
Олена,20,88
```
`sales.csv` (самостійне завдання) — 6–8 товарів, **деякі товари повторюються** у кількох рядках (щоб групування мало сенс), стовпці `product,quantity,price`. Наприклад: Ноутбук, Мишка, Клавіатура, Монітор, Навушники.

## 3. Ноутбук `lab1.ipynb`
Генерувати скриптом `src/build_notebook.py` через `nbformat` (щоб можна було перезібрати), потім виконати:
`../.venv/bin/jupyter nbconvert --to notebook --execute --inplace lab1.ipynb`.
Ноутбук має містити **збережені виводи**. Робоча директорія виконання — `lab-01/`.

Структура (markdown-заголовки українською + code-комірки, код як у методичці):
1. Титул: «Лабораторна робота №1. Ознайомлення з інструментами обробки даних: Python, Pandas, Jupyter», мета роботи.
2. **Крок 2** — перевірка середовища: `sys.version`, `pd.__version__`, також `np.__version__`.
3. **Крок 3** — `df = pd.read_csv("students.csv")`, `print(df)`, `df.describe()`, `df.info()`.
4. **Крок 4**:
   - `high_scores = df[df["grade"] > 85]`;
   - `df["level"] = np.where(df["grade"] >= 90, "Відмінно", np.where(df["grade"] >= 80, "Добре", "Задовільно"))`;
   - `avg = df["grade"].mean()`; `print("Середній бал:", avg)`.
5. **Крок 5** — `plt.bar(df["name"], df["grade"], color="skyblue")`, title «Оцінки студентів», xlabel «Ім'я студента», ylabel «Оцінка». Перед `plt.show()` — `plt.savefig("students_grades.png", dpi=150, bbox_inches="tight")`. Додати `%matplotlib inline`.
6. **Крок 6** — `df.to_csv("students_processed.csv", index=False)`.
7. **Контрольні питання** — markdown-комірка з вмістом `answers.md`.
8. **Самостійне завдання**:
   - `sales = pd.read_csv("sales.csv")`, показати;
   - `sales["revenue"] = sales["quantity"] * sales["price"]`;
   - `summary = sales.groupby("product", as_index=False).agg(total_quantity=("quantity","sum"), total_revenue=("revenue","sum")).sort_values("total_revenue", ascending=False)`;
   - стовпчикова діаграма `total_revenue` по товарах, підписи українською, зберегти `sales_revenue.png`;
   - `summary.to_csv("sales_summary.csv", index=False)`.
9. **Висновки** — 3–4 речення: що освоєно (завантаження CSV, describe/info, фільтрація, нові стовпці, groupby, візуалізація, збереження).

## 4. Перевірка (обов'язково)
- Ноутбук виконується без помилок через nbconvert.
- Існують: `students.csv`, `students_processed.csv` (зі стовпцем `level`), `sales.csv`, `sales_summary.csv`, `students_grades.png`, `sales_revenue.png`.
- Очікувано: середній бал = 85.75; `grade > 85` → Марія, Олена; рівні: Іван/Олена — Добре, Марія — Відмінно, Петро — Задовільно.
- Кирилиця на графіках відображається (не квадратики) — переглянути PNG.
- Перевірити суми в `sales_summary.csv` вручну хоча б для одного товару.
