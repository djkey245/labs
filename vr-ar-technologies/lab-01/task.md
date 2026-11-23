# Лабораторна робота 1

Джерело: https://edu.regi.rovno.ua/mod/assign/view.php?id=320438
Початок приймання: 13.10.2026. Статус на 20.11.2026: не подано.

**Тема:** Вступ у Unity Engine. Доповнена реальність. Використання Vuforia Engine. Цілі «зображення» (Image Targets).

## Завдання

1. Створити застосунок з елементами доповненої реальності (за аналогією із заняттям) і зробити Build під Android.
   Версія редактора: Unity 2022.3 LTS або (краще) Unity 6.0 (6000.0.84f1) і вище.
2. Реалізувати AR: при наведенні камери на зображення купюри **100 гривень** на її місці одразу з'являється зображення купюри **1000 гривень**.

## Звіт

- Назва та мета лабораторної роботи.
- Висновки щодо особливостей створення AR-застосунків, розробки ігрових середовищ і реалізації фізики в Unity.
- Лінк на репозиторій (GitHub/GitLab) або папку `AR_VR\ЛР1` на Google Диску: файли проєкту, зібраний `.apk`/`.ipa`, скріни/відео запуску.

## Ресурси

Туторіали:
- https://library.vuforia.com/getting-started/getting-started-vuforia-engine-unity
- https://library.vuforia.com/objects/image-targets-api-overview
- https://library.vuforia.com/objects/best-practices-designing-and-developing-image-based-targets
- Покроково: https://developer.vuforia.com/library/vuforia-engine/getting-started/development-environments/getting-started-vuforia-engine-unity/#intro
- Build APK, Unity 2022.3: https://docs.unity3d.com/2022.3/Documentation/Manual/android-BuildProcess.html
- Build APK, Unity 6.0: https://docs.unity3d.com/6000.0/Documentation/Manual/android-BuildProcess.html

Assets:
- Vuforia Engine (Asset Store): https://assetstore.unity.com/packages/templates/packs/vuforia-engine-163598
- Безкоштовні персонажі: https://assetstore.unity.com/listing?f-ec_category=3d+%3E+characters&nf-ec_price_filter=0...0
- Google Диск викладача: https://drive.google.com/drive/folders/1HI7GF7svolLDUlzGxFAADa_ItGLRuPlp
  - `Lab_16_Доповнена реаільність.pdf` — методичка (скріни, Unity 2020.3 + Vuforia 10.x)
  - `ForLab16/`: папка `Robot Kyle` (модель), `stones1.png`, `stones1.pdf`, `stones_wight_10.pdf` (маркер)
- Відеолекція вбудована на сторінці завдання (YouTube).

## Кроки з методички (Lab_16)

1. Зареєструватися на developer.vuforia.com.
2. Імпортувати Vuforia Engine: `.unitypackage` з порталу або з Asset Store.
3. Сцена: видалити Main Camera, додати `GameObject → Vuforia Engine → AR Camera`.
4. License Manager → Get Development Key → вставити ключ у Vuforia Configuration (App License Key).
5. Play Mode = WEBCAM для тесту з вебкамерою.
6. Додати `Vuforia Engine → Image Target`:
   - спосіб 1: Type = From Image, вибрати текстуру напряму;
   - спосіб 2: Target Manager → Create Database (Device) → Add Target (Single Image, width) → Download Database (Unity Editor) → імпорт → Type = From Database.
7. Дочірнім об'єктом Image Target покласти 3D-модель (Robot Kyle) — з'являється при розпізнаванні.
8. Build Settings → Android → Switch Platform → Add Open Scenes → Build (потрібні Android SDK/NDK/JDK з Unity Hub).

## Ідея для п.2

Image Target = фото 100 грн (контрастна сторона, багато деталей). Дочірній об'єкт — Quad з текстурою 1000 грн, розмір і пропорції як у таргета, трохи над площиною (y ≈ 0.001), повернутий паралельно таргету. Тоді при наведенні 1000 грн повністю перекриває 100 грн.
