# Звіт з лабораторної роботи № 7

**Дисципліна:** Технології VR/AR
**Тема:** Вступ у Unity Engine. Доповнена реальність. Використання шаблону AR Mobile Template. Розпізнавання обличчя та фільтри для обличчя.
**Виконав:** Ковальчук Дмитро Олексійович, група ПІ-23

## Мета роботи

Створити на основі шаблону AR Mobile Template застосунки для відстеження обличчя: базовий фільтр (зелена маска за методичкою) та інтерактивний фільтр з вибором окулярів і їхнього кольору (за путівником Unity Learn), налаштувати фронтальну камеру і зібрати APK під Android.

## Середовище

| Компонент | Версія |
|---|---|
| Unity | 6000.6.10f1 (Apple Silicon) |
| AR Foundation / ARCore XR Plugin | 6.6.2 (з шаблону AR Mobile) |
| Цільова платформа | Android (IL2CPP, ARM64, minSdk 26, OpenGLES3) |
| Пакети ресурсів | `BasicFaceFilterAssets.unitypackage`, `Interactive_Face_Filter_Assets` (`interactivefacefilterassets.unitypackage`) |

## Хід роботи

1. **Проєкт.** `AR_Lab7` створено на основі проєкту ЛР2 (AR Mobile Template: XR Origin, AR Session, шаблонний UI), сцени ЛР2 прибрано. Сцени збираються editor-скриптом `Assets/Editor/FaceSceneBuilder.cs`.
2. **Завдання 1: `Basic_Face_Filter`** (`com.lab.arlab7a`), за кроками методички:
   - Імпортовано `BasicFaceFilterAssets.unitypackage` (`Assets/_BasicFaceFilter`).
   - Створено **AR Default Face** (*GameObject → XR → AR Default Face*), на нього призначено матеріал **Face Debug MAT** (зелений), збережено префаб `AR Default Face.prefab`, екземпляр зі сцени видалено.
   - На `XR Origin` додано **AR Face Manager** із Face Prefab = `AR Default Face` (`media/basic-scene-setup.png`). Cube зі сцени видалено.
   - У `AR Camera Manager` головної камери **Facing Direction = User** (фронтальна камера).
3. **Завдання 2: `InteractiveFilter`** (`com.lab.arlab7b`), за путівником «Create an interactive face filter»:
   - Імпортовано пакет `Interactive_Face_Filter_Assets`: п'ять пар окулярів (меші), префаб `AR_Canvas`, спрайти.
   - Обрано три пари: **Cat, Stars, Mask**; вони складені в префаб **GlassesGroup** (позиція 0,0,0) з компонентом **AR Face** і тегами `cat`, `stars`, `mask`. Префаб призначено як Face Prefab в **AR Face Manager** на `XR Origin`. Окуляри за замовчуванням невидимі (вимкнені Mesh Renderer).
   - `AR_Canvas` (Screen Space Overlay): ряд із трьох кнопок окулярів (іконки зі спрайт-листа `UI_Icon_Glasses`) і ряд із трьох кнопок кольорів (червоний, синій, жовтий; матеріали `Glasses_Red/Blue/Yellow`).
   - Логіка: скрипт `GlassesSelector` (на `AR_Canvas`) приймає натискання кнопок, зберігає вибір окулярів і кольору в `PlayerPrefs` і викликає подію; `GlassesGroupController` на префабі `GlassesGroup` вмикає потрібну пару окулярів за тегом, вимикає решту й підставляє матеріал вибраного кольору. Після запуску застосунку останній вибір відновлюється.
4. **Налаштування збірки.** IL2CPP, ARM64, OpenGLES3, minSdk 26; XR Simulation для Windows/Mac/Linux вимкнено (для face-фільтрів не підходить). Два APK збираються командою `Unity -batchmode -quit -projectPath AR_Lab7 -buildTarget Android -executeMethod FaceSceneBuilder.BuildAll`; результат `Build succeeded` для обох.
5. **Перевірка в Play Mode.** Face-трекінг у редакторі на Mac не емулюється, тому, як і в путівнику, перевірено окремою сценою `InteractiveFilter_EditorTest`: екземпляр префаба `GlassesGroup` на відстані 0,4 м перед камерою й `AR_Canvas`. Натискання кнопок виконувалось з editor-меню (*AR Lab → Click Glasses N / Click Color N*, `ExecuteEvents.pointerClickHandler`). Результат: на кожну кнопку окулярів з'являється потрібна пара (Cat, Stars, Mask), старі зникають, кнопка кольору перефарбовує окуляри (`media/interactive-cat-blue.png`, `media/interactive-mask-yellow.png`).

## Результати

- Застосунки: `build/AR_Lab7_BasicFaceFilter.apk` (≈ 38,6 МБ) і `build/AR_Lab7_InteractiveFilter.apk` (≈ 38,7 МБ).
- Скріни: `media/` (налаштування сцени завдання 1, робота інтерактивного фільтра в Play Mode).
- Проєкт Unity: `AR_Lab7/`.

**Обмеження.** Лабораторну виконано не повністю: завдання 1 і 2 реалізовано та зібрано, але розпізнавання обличчя на пристрої не перевірено, а завдання з підводним фільтром не виконувалось.
- APK зібрано, але на Android не запускався (немає телефона з підтримкою ARCore Face), тому розпізнавання обличчя й посадка окулярів на реальному обличчі не перевірені; зелена маска завдання 1 у роботі не показана, перевірено лише налаштування сцени.
- Логіку кнопок виконано **на C#**, а не у Visual Scripting, як у путівнику: пакета Visual Scripting у проєкті немає. Функціонально це те саме (вибір окулярів, колір, збереження вибору).
- Фінальний фільтр з путівника (ocean-themed, підводний) не виконувався.
- Кліки по кнопках у Play Mode імітувались з меню редактора, а не пальцем.

## Висновки

**Особливості створення AR-застосунків.** Для відстеження обличчя використовується AR Foundation: на `XR Origin` додається **AR Face Manager**, який створює екземпляр призначеного **Face Prefab** на кожному виявленому обличчі та супроводжує його (компонент **AR Face** на префабі). Контент, що має сидіти на обличчі (маска, окуляри), робиться префабом, а його меші мають бути вирівняні за еталонною сіткою обличчя. Для фільтрів потрібна фронтальна камера: `AR Camera Manager → Facing Direction = User`. Перевіряти фільтри в редакторі на Mac можна лише через тестовий екземпляр префаба, справжній трекінг доступний тільки на пристрої з ARCore (Android) або ARKit (iOS).

**Розробка ігрових середовищ у Unity.** Сцена складається з `GameObject` із компонентами. Повторно використовувані об'єкти оформлюються префабами, а префаб, який створюється в рантаймі (`GlassesGroup`), не має прямих посилань зі сцени, тому зв'язок із UI йде через події. UI будується на Canvas (uGUI): кнопки, спрайти зі спрайт-листа, `EventSystem`. Теги й матеріали дозволяють знаходити об'єкти й міняти вигляд без зміни меша; налаштування зберігаються через `PlayerPrefs`.

**Реалізація фізики в Unity.** Фізику забезпечують `Rigidbody` (маса, гравітація, швидкість) і `Collider` (форма для зіткнень), розрахунок іде у `FixedUpdate`; 1 одиниця Unity = 1 м, тож розміри мають відповідати реальним (окуляри на лиці ≈ 0,14 м). У цій роботі фізика не використовується: окуляри — суто візуальний контент, прив'язаний до обличчя компонентом AR Face.

## Посилання

Репозиторій з проєктом: https://github.com/djkey245/labs/tree/main/vr-ar-technologies/lab-07/submission
Проєкт Unity: `AR_Lab7/`, застосунки: `build/AR_Lab7_BasicFaceFilter.apk`, `build/AR_Lab7_InteractiveFilter.apk`, скріни: `media/`.
