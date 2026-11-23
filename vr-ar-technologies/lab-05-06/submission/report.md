# Звіт з лабораторної роботи № 5-6

**Дисципліна:** Технології VR/AR
**Тема:** Доповнена реальність. Vuforia Engine. Об'єкти на поверхні землі й у просторі (Ground Plane, Mid Air).
**Виконав:** Ковальчук Дмитро Олексійович, група ПІ-23

## Мета роботи

Створити два AR-застосунки на Unity з Vuforia Engine: **Ground Plane** (віртуальний об'єкт розміщується на горизонтальній поверхні за дотиком) і **Mid Air** (об'єкт розміщується в довільній точці простору перед камерою), налаштувати вихід з програми по Escape та зібрати обидва під Android (IL2CPP, ARM64, minSdk 30).

## Середовище

| Компонент | Версія |
|---|---|
| Unity | 6000.6.10f1 (Apple Silicon, Built-in Render Pipeline) |
| Vuforia Engine | 11.4.4 |
| Цільова платформа | Android (IL2CPP, ARM64, minSdk 30, OpenGLES3) |
| Тест у редакторі | Vuforia Play Mode, вебкамера Mac + шаблон Emulator Ground Plane |

## Хід роботи

1. **Проєкт.** Один 3D-проєкт `AR_Lab56` з двома сценами: `Assets/Scenes/GroundPlane.unity` і `Assets/Scenes/MidAir.unity`. Пакет `com.ptc.vuforia.engine` 11.4.4 підключено локальним `.tgz`; ліцензійний ключ у репозиторії не зберігається. Сцени будує editor-скрипт `Assets/Editor/SceneBuilder.cs`.
2. **Завдання 1: Ground Plane** (`com.lab.arlab5`).
   - `ARCamera` (`VuforiaBehaviour`, `DefaultInitializationErrorHandler`, `QuitApp`), `Directional Light`.
   - `Plane Finder` (`AnchorInputListenerBehaviour` + `PlaneFinderBehaviour` + `ContentPositioningBehaviour`): дотик на екран запускає hit-test по знайденій площині.
   - `Ground Plane Stage` (`AnchorBehaviour`) з моделлю **Race Car** (зібрана з примітивів: кузов, кабіна, 4 колеса, ≈ 0,25 м). `Duplicate Stage` = true: кожен дотик створює нову копію машини, попередні залишаються.
3. **Завдання 2: Mid Air** (`com.lab.arlab6`).
   - `Mid Air Positioner` (`AnchorInputListenerBehaviour` + `MidAirPositionerBehaviour` + `ContentPositioningBehaviour`) із зеленим індикатором-кулею: показує точку в просторі на заданій відстані від камери.
   - `Mid Air Stage` з моделлю **LowPolyAircraft** (корпус, крила, хвіст, кабіна, пропелер ≈ 0,4 м). Скрипт `RotateScript` крутить пропелер навколо осі (720°/с, `transform.Rotate`).
4. **Вихід по Escape.** Скрипт `QuitApp` у `Update` перевіряє `Input.GetKeyDown(KeyCode.Escape)` і викликає `Application.Quit()` (на Android Escape = кнопка «Назад»).
5. **Налаштування збірки.** minSdk 30, IL2CPP, ARM64, OpenGLES3; два APK з різними `applicationId` збираються командою `Unity -batchmode -quit -projectPath AR_Lab56 -buildTarget Android -executeMethod SceneBuilder.BuildAll`; результат `build result Succeeded` для обох.
6. **Перевірка в Play Mode.** Vuforia Play Mode не вміє знаходити площину з вебкамери без шаблону, тому використано офіційний шаблон **Emulator Ground Plane** (з пакета Vuforia, `media/emulator_ground_plane_template.png`), відкритий на екрані телефона перед камерою Mac (друку немає). Дотик у редакторі імітується скриптом `Assets/Editor/SimulateTap.cs` (меню *AR Lab → Simulate Tap*), бо клік у Game view у цьому режимі не передавався.
   - **Ground Plane:** шаблон розпізнано (`media/groundplane-template.png`), після «дотику» машина з'являється на шаблоні (`media/groundplane-car.png`).
   - **Mid Air:** зелений індикатор-куля в точці перед камерою (`media/midair-template-pointer.png`), після «дотику» літак фіксується в цій точці, пропелер обертається (`media/midair-aircraft.png`).

## Результати

- Зібрані застосунки: `build/AR_Lab5_GroundPlane.apk` (≈ 52 МБ) і `build/AR_Lab6_MidAir.apk` (≈ 52 МБ).
- Скріни з Play Mode: `media/`.
- Проєкт Unity: `AR_Lab56/`.

**Обмеження.**
- APK зібрано, але на Android не запускався (немає телефона з ARCore), тому вихід по Escape і розміщення на реальній підлозі перевірено лише за кодом.
- У Play Mode поверхню замінює шаблон Emulator Ground Plane, а тап імітується з редактора. Тому машина на скріні показана в масштабі шаблону. Для Mid Air розмір літака підібрано умовно (≈ 0,4 м), відстань до камери в редакторі мала, тож літак займає більшу частину кадру.
- Моделі зібрані з примітивів Unity, готових моделей з Asset Store не використано.
- Розпізнано одну копію машини; створення кількох копій забезпечується `Duplicate Stage`, але на скріні окремо не показано.

## Висновки

**Особливості створення AR-застосунків.** Застосунок складається з AR-камери, яка бере відеопотік і оцінює положення пристрою, та контенту, прив'язаного до якоря. У Ground Plane якір створюється через hit-test: `Plane Finder` шукає горизонтальну поверхню, а `Ground Plane Stage` ставиться в точці дотику за допомогою `ContentPositioningBehaviour`. У Mid Air поверхні не потрібні: `Mid Air Positioner` показує точку на фіксованій відстані від камери, а `Mid Air Stage` фіксується в цій точці. Потрібні ліцензійний ключ, дозвіл на камеру, а для Android Vuforia 11.4.4 вимагає minSdk ≥ 29 (за методичкою 30). Для тестів у редакторі Ground Plane потребує шаблону Emulator Ground Plane. Вихід із застосунку реалізується через `Application.Quit()` по Escape.

**Розробка ігрових середовищ у Unity.** Сцена — ієрархія `GameObject` із компонентами (`Transform`, `Renderer`, скрипти); дочірні об'єкти успадковують трансформацію батька, тому модель рухається разом зі `Stage`. Моделі можна складати з примітивів, анімація робиться скриптом (`RotateScript`, `transform.Rotate` × `Time.deltaTime`), поведінка сцени задається компонентами. Сцену можна будувати вручну або editor-скриптом, а Play Mode дозволяє перевіряти її без збірки.

**Реалізація фізики в Unity.** Фізику забезпечують `Rigidbody` (маса, гравітація, швидкість) і `Collider` (форма для зіткнень), обчислення йдуть у `FixedUpdate`. Одиниця Unity = 1 м, тож розміри моделей мають відповідати реальним (машина ≈ 0,25 м, літак ≈ 0,4 м). У цій роботі фізика не використовується: об'єкти без `Rigidbody`, анімація суто візуальна; щоб машина «їхала» по підлозі, її потрібно було б доповнити `Rigidbody` і `Collider`.

## Посилання

Репозиторій з проєктом: https://github.com/djkey245/labs/tree/main/vr-ar-technologies/lab-05-06/submission
Проєкт Unity: `AR_Lab56/`, застосунки: `build/AR_Lab5_GroundPlane.apk`, `build/AR_Lab6_MidAir.apk`, скріни: `media/`.
