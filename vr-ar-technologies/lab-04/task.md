# Лабораторна робота 4

Джерело: https://edu.regi.rovno.ua/mod/assign/view.php?id=321787
Статус на 23.11.2026: подання не подано.

**Тема:** Доповнена реальність. Використання Vuforia Engine. Мультицілі (Multi Targets, «об'ємні багатогранні цілі»).

## Завдання

Створити застосунок із Vuforia, використовуючи **Multi Target** (коробка з 6 граней). Unity 6000.0.84f1 і вище.
Додаткові матеріали: «Розгортка та картинки» — Google Диск, папка `1htpdrGq5NfZ-S3fqu8AnnkPQIGEp25pW` (`Розгортка_mars_box.pdf`, шість `MarsBox.{Front,Back,Left,Right,Top,Bottom}_scaled.jpg`, ще `greyscale-image.jpg`, `Oxygen/Fissura/Astronaut/Drone_scaled.jpg`).

## Звіт

- Назва та мета.
- Висновки щодо особливостей створення AR-застосунків, розробки ігрових середовищ і реалізації фізики в Unity.
- Лінк на репозиторій / папку `AR_VR\ЛР4` на Google Диску: проєкт, `.apk`/`.ipa`, скріни/відео.

## Ресурси

- https://library.vuforia.com/getting-started/getting-started-vuforia-engine-unity
- https://developer.vuforia.com/library/vuforia-engine/images-and-objects/multi-targets/multi-targets/
- .../multi-targets/recommendations-designing-multi-targets/
- .../multi-targets/multi-targets-api-overview/
- Методичка (3 стор.): `Лабораторна робот №4.pdf`, Drive id `1fbSG059r1aqvZZq7Pj3E8uU1bmE7b8Om`

## Кроки з методички (прочитано повністю)

1. Сцена: видалити Main Camera, додати AR Camera (Vuforia), перевірити ліцензійний ключ.
2. Target Manager → Add Database (Device) → Add Target → **Multi Target**: розміри коробки в метрах (напр. куб 0.15), ім'я цілі.
3. Для цілі завантажити текстури граней Front/Back/Left/Right/Top/Bottom; **співвідношення сторін картинки = співвідношення сторін грані**; перевірити рейтинг; Download Database → Unity Editor (`.unitypackage`).
4. Імпорт пакета; GameObject → Vuforia Engine → Multi-Target; Multi Target Behaviour: Database + Multi Target.
5. 3D-модель (у відео — Toy Car) — **дочірній об'єкт** Multi-Target; Position/Scale так, щоб лежала на верхній грані.
6. Фізичний макет: друкована розгортка (`Assets/Editor/Vuforia/ForPrint/MultiTarget/` або `Розгортка_mars_box.pdf`), склеїти коробку.
7. Android: minSdk ≥ 8.0, IL2CPP, ARM64; Build → APK.

## Контрольні запитання

1. Що таке Multi Target і які переваги порівняно з одиночним Image Target?
2. Чому текстури граней мають відповідати aspect ratio розмірів коробки?
3. Де в ієрархії розміщувати 3D-модель відносно Multi-Target?
4. Практичні сценарії (ритейл, промисловість, освіта).
