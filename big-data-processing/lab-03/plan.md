# План — Лаба 3 (MongoDB)

Папка лаби: `big-data-processing/lab-03/`. Venv: `../.venv`. Зразок збірки ноутбука — `../lab-02/src/build_notebook.py`.

## Середовище
- MongoDB встановлено через Homebrew: `mongod`, `mongosh`, `mongoimport`, `mongoexport` у `/opt/homebrew/bin`. Перевір `which`.
- `../.venv/bin/pip install pymongo`.
- Сервер **НЕ** через `brew services`, а вручну, лише на час роботи:
  `mkdir -p .mongo-data && mongod --dbpath .mongo-data --logpath .mongo-data/mongod.log --port 27017 --bind_ip 127.0.0.1 --fork`
  (`.mongo-data/` у `lab-03/`, поза `submission/`). Якщо `--fork` не працює на macOS — запусти у фоні через `nohup ... &`.
- Наприкінці роботи **зупини** сервер: `mongosh admin --quiet --eval 'db.shutdownServer()'`.

## Здача (рівно 4 файли) — `submission/`
1. `lab3.ipynb` — виконаний, з виводами.
2. `students.json` — 10 студентів, JSON-масив (вхідні дані для імпорту).
3. `students.csv` — результат `mongoexport` колекції `students`.
4. `results.csv` — результат `mongoexport` колекції `results`.

## Дані `students.json` (створити вручну, 10 документів)
Перші 3 — дослівно з методички (Ivan Petrenko 20 CS 3.8; Olena Ivanenko 22 IS 3.5; Petro Kovalchuk 21 SE 3.9). Ще 7 — латиницею, у тому ж стилі (українські імена транслітом), спеціальності: `Computer Science`, `Information Systems`, `Software Engineering`, `Data Science` — кожна мінімум 2 рази; вік 18–24; gpa 3.0–4.0 з одним знаком після коми. Поля: `name, age, major, gpa`.

## Ноутбук (робоча директорія виконання — `submission/`)
Shell-команди — через IPython `!` (так видно справжні CLI-команди з методички). Наприкінці кожної `!`-комірки додай `--quiet` там, де можливо, щоб вивід був чистий.

1. Титул, мета, коротко теорія (БД / колекція / документ / поле).
2. **Підготовка**: версії (`!mongod --version | head -1`, `!mongosh --version`, `pymongo.version`); `MongoClient(...)`, `client.admin.command("ping")`; для перезапуску — `client.drop_database("university")`.
3. **Крок 2 — створення БД і колекції**: `!mongosh university --quiet --eval '<insertMany з 3 документами з методички>'`, далі `!mongosh university --quiet --eval 'db.students.countDocuments()'` → 3. Пояснення: БД і колекція створюються автоматично при першій вставці.
4. **Крок 3 — імпорт/експорт**:
   - `!mongoimport --db university --collection students --file students.json --jsonArray --drop` — `--drop`, бо 3 перші студенти вже є в колекції (інакше будуть дублікати); пояснити в markdown. Перевірити кількість → 10. Це одночасно п.1 самостійного завдання.
   - `!mongoexport --db university --collection students --type=csv --fields name,age,major,gpa --out students.csv`, показати `pd.read_csv("students.csv")`.
5. **Крок 4 — базові запити**: кожен запит з методички через `mongosh --eval` (щоб показати синтаксис shell; для `find` використати `.toArray()` або `printjson`, `{_id:0}`-проєкцію) **і** той самий через pymongo з виводом у DataFrame: усі; `major == "Computer Science"`; `gpa > 3.6`; сортування `gpa` спадно; `count_documents({})`.
6. **Крок 5 — Python**: код з методички дослівно (MongoClient → DataFrame → `gpa > 3.7`).
7. **Самостійне завдання**:
   - п.2 фільтр за віком і спеціальністю: `{"age": {"$gte": 21}, "major": {"$in": ["Computer Science", "Software Engineering"]}}` + ще приклад з `$or`. Вивести DataFrame.
   - п.3–4 агрегація, що одразу пише в `results`:
     ```python
     pipeline = [
         {"$group": {"_id": "$major", "avg_gpa": {"$avg": "$gpa"}, "students_count": {"$sum": 1}}},
         {"$project": {"_id": 0, "major": "$_id", "avg_gpa": {"$round": ["$avg_gpa", 2]}, "students_count": 1}},
         {"$sort": {"avg_gpa": -1}},
         {"$out": "results"},
     ]
     ```
     Показати вміст `results` (DataFrame). Перевірити середні через pandas `groupby` — мають збігатися (вивести обидва).
   - п.5 `!mongoexport --db university --collection results --type=csv --fields major,avg_gpa,students_count --out results.csv`, показати `pd.read_csv`.
8. `client.close()`.
9. Контрольні запитання — markdown з `answers.md`.
10. Висновки — 3–4 речення.

## Перевірка
- Сервер запущено → ноутбук виконано `nbconvert --execute --inplace` з `submission/` **двічі поспіль** без помилок.
- У `submission/` рівно 4 файли зі списку.
- `students` = 10 документів; `results` = 4 документи (по одному на спеціальність); середні в `results.csv` збігаються з pandas `groupby`.
- Сервер зупинено наприкінці (`lsof -iTCP:27017 -sTCP:LISTEN` нічого не повертає).
