# Звіт з лабораторної роботи № 3

**Дисципліна:** Технології VR/AR
**Тема:** Вступ у Unity Engine. Доповнена реальність. Використання Vuforia Engine. Циліндричні цілі (Cylinder Targets).
**Виконав:** Ковальчук Дмитро Олексійович, група ПІ-23

## Мета роботи

Ознайомитися зі створенням AR-застосунку у Unity з Vuforia Engine на основі 3D-цілей — **циліндричної цілі** (Cylinder Target): підготувати ціль у Vuforia Target Manager, імпортувати базу даних у проєкт, розмістити на цілі віртуальний 3D-контент і зібрати застосунок під Android.

## Середовище

| Компонент | Версія |
|---|---|
| Unity | 6000.6.10f1 (Apple Silicon, Built-in Render Pipeline) |
| Vuforia Engine | 11.4.4 |
| Цільова платформа | Android (IL2CPP, ARM64, minSdk 29, OpenGLES3, Landscape Left) |
| Тест у редакторі | Vuforia Play Mode, вебкамера Mac |

## Хід роботи

1. **Target Manager.** На порталі developer.vuforia.com створено базу `AR_VF_CylinderDB` (тип Device) і в ній ціль `cylinder_target` типу **Cylinder**: Top Diameter 0,048 м, Bottom Diameter 0,048 м, Length 0,1 м. Зображення бічної поверхні — `stones_for_cylinder_target.jpg` (`media/stones_for_cylinder_target.jpg`). Статус цілі — Active. Базу завантажено як `AR_VF_CylinderDB.unitypackage` (Download Database, платформа Unity Editor).
2. **Імпорт бази.** Вміст пакета: `Assets/StreamingAssets/Vuforia/AR_VF_CylinderDB.dat` та `.xml`, `Assets/Editor/Vuforia/CylinderTargetTextures/AR_VF_CylinderDB/...`. У `.xml`: `CylinderTarget name="cylinder_target" sideLength="0.1" topDiameter="0.048" bottomDiameter="0.048"`.
3. **Проєкт.** 3D-проєкт `AR_Lab3`, пакет `com.ptc.vuforia.engine` 11.4.4 підключено у `Packages/manifest.json` локальним `.tgz` (`Vuforia/`). Ліцензійний ключ записується в `VuforiaConfiguration` скриптом `SceneBuilder` і в репозиторії не зберігається.
4. **Сцена `Main`** (будується editor-скриптом `Assets/Editor/SceneBuilder.cs`):
   - `ARCamera` з `VuforiaBehaviour` і `DefaultInitializationErrorHandler`;
   - `Directional Light`;
   - `CylinderTarget` (`CylinderTargetBehaviour`, створений командою *GameObject → Vuforia Engine → Cylinder Target*): база `Vuforia/AR_VF_CylinderDB.xml`, ціль `cylinder_target`, Side Length 0,1 м, діаметри 0,048 / 0,048 м; доданий `DefaultObserverEventHandler` (показує дочірній контент, коли ціль знайдено, ховає — коли втрачено);
   - дочірній об'єкт — модель **Robot Kyle**, масштабована до висоти 0,08 м і поставлена на верхню основу циліндра (1 одиниця Unity = 1 м, тож розмір контенту відповідає розміру цілі 0,1 м).
5. **Налаштування збірки.** `com.lab.arlab3`, IL2CPP, ARM64, OpenGLES3, Landscape Left, Vuforia Play Mode = WEBCAM. Мінімальний рівень Android — **API 29**: Vuforia 11.4.4 вимагає щонайменше Android 10 (з рівнем 26, як у ЛР1, збірка падала з помилкою `Vuforia Engine requires a Minimum Android API level of Android 10.0`).
6. **Збірка.** `build/AR_Lab3.apk` (≈ 56 МБ), команда `Unity -batchmode -quit -projectPath AR_Lab3 -buildTarget Android -executeMethod SceneBuilder.BuildAll`; результат `build result Succeeded`.
7. **Перевірка в Play Mode.** Vuforia створює з бази спостерігач `CylinderTargetBehaviour 'cylinder_target'`, помилок завантаження бази немає. Вебкамера Mac підключена після дозволу macOS (меню *AR Lab → Request Camera Access*). Як ціль використано зображення `stones_for_cylinder_target.jpg`, відкрите на екрані телефона перед камерою (див. зауваження нижче). Результат: у статус-рядку Unity `Target status: cylinder_target TRACKED -- NORMAL`, а модель Robot Kyle з'являється на цілі й супроводжує її під час руху телефона (`media/cylinder-tracked.png`).

8. **Реальний об'єкт — труба з листівки-конверта.** У базу додано ціль `card_target` (Cylinder, діаметри 0,04 м, Side Length 0,18 м). Конверт розгорнули, сфотографували плоско, виправили перспективу (`src/card/rectify.py`) і обрізали по ширині до довжини кола π·D = 12,57 см (пропорція 0,698 = 12,57/18). Результат — `media/card_unwrap.jpg` — завантажено як Side-зображення. Лист згорнули в трубу діаметром ≈ 4 см і висотою 18 см. Ціль `can_target` аналогічно зібрана зі зшитих 4 фото балона (`media/can_unwrap.jpg`). У сцену додано три цілі (`MaxSimultaneousImageTargets` = 3). Результат у Play Mode з вебкамерою Mac: `Target status: card_target TRACKED -- NORMAL`, далі `EXTENDED_TRACKED`; Robot Kyle з'являється на трубі (`media/card-tracked-2.png`); при `EXTENDED_TRACKED`, коли ціль частково поза кадром, положення моделі неточне. Балон `can_target` теж розпізнано (`TRACKED`, `media/can-tracked.png`).

## Результати

- Зображення цілі: `media/stones_for_cylinder_target.jpg`.
- Розпізнавання в Play Mode: `media/cylinder-tracked.png`: ціль `TRACKED`, модель Robot Kyle відображається на цілі.
- Реальна труба з листівки: `media/card-tracked-2.png`; балон: `media/can-tracked.png`; ціль `card_target` розпізнана (`TRACKED`), зображення цілі `media/card_unwrap.jpg`.
- Зібраний застосунок: `build/AR_Lab3.apk` (3 цілі).

**Обмеження.**
- Під час `EXTENDED_TRACKED` (ціль частково поза кадром) положення Robot Kyle неточне. Положення вирівнювання контенту під справжню трубу не підганялося.
- Перевірку з першою ціллю виконано з екраном телефона (плоска поверхня), а не з роздруківкою, обгорнутою навколо циліндра: друку немає. Трекінг працює, але для найкращої точності зображення має бути обгорнуте навколо реального циліндра діаметром 48 мм.
- APK зібрано, але на Android не запускався (немає телефона).

## Висновки

**Особливості створення AR-застосунків.** AR-застосунок складається з AR-камери, що отримує відеопотік і визначає позу цілей, та віртуального контенту, прив'язаного до цілі. Циліндрична ціль відрізняється від плоскої: зображення обгортається навколо циліндра або конуса (різні верхній і нижній діаметри), тож трекер розпізнає його під будь-яким кутом огляду навколо осі. У Target Manager потрібно задати **реальні розміри в метрах** (діаметри основ, довжину бічної поверхні), інакше контент матиме хибний масштаб і положення. Якість трекінгу залежить від зображення (контраст, детальність, відсутність повторюваних візерунків і симетрії) та від його точного обгортання бічної поверхні. База з Target Manager (`.dat` + `.xml`) імпортується в `StreamingAssets`, ціль у сцені вибирається за назвою бази й цілі. Потрібен ліцензійний ключ, на macOS — дозвіл на камеру для Unity; Vuforia 11.4.4 для Android вимагає minSdk ≥ 29.

**Розробка ігрових середовищ у Unity.** Сцена складається з ієрархії `GameObject`, поведінку задають компоненти (`Transform`, `Camera`, `Renderer`, скрипти). Дочірні об'єкти успадковують трансформацію батька, тому контент, прив'язаний до цілі, рухається разом із нею; моделі й префаби (Robot Kyle) використовуються повторно. Сцену можна збирати вручну або editor-скриптом; Play Mode дозволяє перевіряти результат без збірки.

**Реалізація фізики в Unity.** Фізику забезпечують `Rigidbody` (маса, гравітація, швидкість) і `Collider` (форма для зіткнень), обчислення йдуть з фіксованим кроком (`FixedUpdate`). Одиниця Unity = 1 м, тож розміри цілі, контенту й колайдерів мають відповідати реальним. У цій роботі фізика не використовується: колайдери Robot Kyle видалено, контент суто візуальний.

## Посилання

Репозиторій з проєктом: https://github.com/djkey245/labs/tree/main/vr-ar-technologies/lab-03/submission
Проєкт Unity: `AR_Lab3/`, застосунок: `build/AR_Lab3.apk`, зображення цілі: `media/`.
