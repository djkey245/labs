# Відповіді на контрольні запитання

**1. У чому полягає основна різниця між MongoDB і SQL-базами даних?**
- **Модель даних.** SQL-бази зберігають дані в таблицях із жорсткою схемою: стовпці й типи задаються заздалегідь. MongoDB — документно-орієнтована база: дані лежать у колекціях документів, і документи однієї колекції можуть мати різний набір полів (гнучка схема).
- **Зв'язки.** У SQL дані нормалізують, розносять по таблицях і поєднують через `JOIN`. У MongoDB пов'язані дані частіше вкладають в один документ: вкладені об'єкти й масиви. Аналог `JOIN` теж є — стадія `$lookup`, але зазвичай без неї можна обійтися.
- **Мова запитів.** У SQL-баз це SQL. У MongoDB запити описують JSON-подібними об'єктами (`find({...})`), а для складної обробки є конвеєр агрегації (`aggregate([...])`).
- **Масштабування.** SQL-бази переважно масштабують вертикально, тобто потужнішим сервером. MongoDB від початку розрахована на горизонтальне масштабування: шардинг і репліка-сети.
- **Транзакції.** У SQL-базах ACID-транзакції є завжди. У MongoDB операція над одним документом атомарна, а багатодокументні транзакції з'явилися з версії 4.0.

**2. Який формат даних використовується у MongoDB?**
Документи зберігаються у форматі **BSON** (Binary JSON). Це двійкове представлення JSON. Порівняно з JSON воно має додаткові типи: `ObjectId`, `Date`, `Decimal128`, `int32`/`int64`, двійкові дані. Користувач бачить і передає документи як JSON-подібні об'єкти. Кожен документ має унікальне поле `_id`, за замовчуванням типу `ObjectId`. Обмін даними з іншими системами йде через JSON або CSV (`mongoimport`/`mongoexport`).

**3. Як виконати фільтрацію документів за кількома умовами?**
- Кілька полів в одному фільтрі автоматично поєднуються через логічне «І»: `db.students.find({ "major": "Computer Science", "age": { $gte: 21 } })`.
- Явні логічні оператори: `$and`, `$or`, `$nor`, `$not`:
  `db.students.find({ $or: [ { "gpa": { $gt: 3.8 } }, { "age": { $lt: 20 } } ] })`.
- Оператори порівняння: `$eq`, `$ne`, `$gt`, `$gte`, `$lt`, `$lte`, `$in`, `$nin`. Для одного поля їх можна поєднати: `{ "age": { $gte: 20, $lte: 22 } }`.
- У Python (pymongo) синтаксис такий самий, тільки оператори записуються рядками: `collection.find({"age": {"$gte": 21}, "major": {"$in": ["Computer Science", "Data Science"]}})`.

**4. Як імпортувати та експортувати дані у MongoDB?**
Для цього є утиліти з пакета MongoDB Database Tools:
- імпорт JSON-масиву: `mongoimport --db university --collection students --file students.json --jsonArray`;
- імпорт CSV: `mongoimport --db university --collection students --type=csv --headerline --file students.csv`;
- експорт у CSV, де треба перелічити поля: `mongoexport --db university --collection students --type=csv --fields name,age,major,gpa --out students.csv`;
- експорт у JSON: `mongoexport --db university --collection students --jsonArray --out students.json`.
Те саме можна зробити з Python (`insert_many` після `json.load`/`pd.read_csv`, а `find` → `DataFrame.to_csv`) або через графічний інтерфейс MongoDB Compass. Для повних резервних копій у BSON використовують `mongodump`/`mongorestore`.

**5. Як підключитися до MongoDB з Python і виконати запит?**
Через бібліотеку `pymongo`:
```python
from pymongo import MongoClient

client = MongoClient("mongodb://localhost:27017/")   # підключення до сервера
db = client["university"]                            # база даних
collection = db["students"]                          # колекція

for doc in collection.find({"gpa": {"$gt": 3.6}}, {"_id": 0}).sort("gpa", -1):
    print(doc)

print(collection.count_documents({}))                # кількість документів
client.close()
```
`find()` повертає курсор, який можна перебирати або перетворити на `list` і далі на `pandas.DataFrame`. Агрегацію виконує `collection.aggregate([...])`.
