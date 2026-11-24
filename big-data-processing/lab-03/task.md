# Лабораторна робота №3 — Робота з NoSQL (MongoDB): імпорт, експорт, фільтрація даних

Оригінал: [L3.pdf](L3.pdf). Цього разу текст у PDF цілий (коментарі в коді — транслітом).

## Мета
Ознайомитися з MongoDB: створення БД і колекцій, імпорт/експорт JSON і CSV, фільтрація, сортування, агрегація.

## Практична частина
1. Середовище: MongoDB Community + mongosh + database tools; `pip install pymongo pandas`.
2. БД `university`, колекція `students`, `insertMany` трьох документів (Ivan Petrenko / Olena Ivanenko / Petro Kovalchuk).
3. `mongoimport ... --file students.json --jsonArray`; `mongoexport ... --type=csv --fields name,age,major,gpa --out students.csv`.
4. Запити: `find()`, фільтр за `major`, `gpa > 3.6`, сортування за `gpa` спадно, `countDocuments()`.
5. Python: `MongoClient` → `find({}, {"_id": 0})` → DataFrame → `gpa > 3.7`.

## Самостійне завдання
1. Імпортувати дані про 10 студентів з CSV або JSON.
2. Фільтрація за віком і спеціальністю.
3. Середній GPA для кожної спеціальності.
4. Зберегти результати в нову колекцію `results`.
5. Експортувати `results` у CSV.

## Контрольні запитання
1. У чому полягає основна різниця між MongoDB і SQL-базами даних?
2. Який формат даних використовується у MongoDB?
3. Як виконати фільтрацію документів за кількома умовами?
4. Як імпортувати та експортувати дані у MongoDB?
5. Як підключитися до MongoDB з Python і виконати запит?
