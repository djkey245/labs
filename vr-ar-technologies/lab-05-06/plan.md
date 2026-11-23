# План: ЛР5-6 Vuforia Ground Plane + Mid Air

## Підхід

Один Unity-проєкт `submission/AR_Lab56` (Unity 6000.6.10f1, Vuforia 11.4.4, Built-in RP), **дві сцени** і **два `.apk`**:
- `Assets/Scenes/GroundPlane.unity` → `build/AR_Lab5_GroundPlane.apk` (`com.lab.arlab5`);
- `Assets/Scenes/MidAir.unity` → `build/AR_Lab6_MidAir.apk` (`com.lab.arlab6`).

Каркас береться з ЛР3 (`../lab-03/submission/AR_Lab3`): `Packages/`, `ProjectSettings/`, `Vuforia/*.tgz`, `Assets/Editor/{CameraAccess,PlayTest,AutoShots}.cs`, збірка editor-скриптом у batchmode. **Без** `Library/`, `Temp/`, `Logs/`, `UserSettings/`, `build/`, `QCAR/`, `Assets/Models`, `Assets/StreamingAssets`, `Assets/Scenes`, `Assets/Resources` (конфіг Vuforia створюється скриптом). Ліцензійний ключ — `../vuforia_license.txt` (як у ЛР3; ключ не логувати й не коммітити, `Assets/Resources/VuforiaConfiguration.asset*` у `.gitignore`).

Моделей з Asset Store немає, тому **модель машини й літака збираються з примітивів** (Cube/Cylinder/Sphere з Standard-матеріалами) в editor-скрипті — це «low-poly».

## Реалізація (lab-worker)

1. Створити каркас проєкту (див. вище), `ProjectVersion.txt` не міняти. Переконатися, що нема процесів Unity з цим проєктом.
2. `Assets/Scripts/QuitApp.cs`: `Update(){ if (Input.GetKey("escape")) Application.Quit(); }`. Якщо проєкт використовує New Input System (`Input.GetKey` кидає `InvalidOperationException`) — виставити `PlayerSettings.activeInputHandler` = Both (як у ЛР3, звірити з `ProjectSettings.asset`).
3. `Assets/Scripts/RotateScript.cs`: публічна `Vector3 axis = Vector3.forward; float speed = 720f;` → `transform.Rotate(axis, speed * Time.deltaTime)`.
4. `Assets/Editor/SceneBuilder.cs` (за зразком ЛР3):
   - `ConfigurePlayer()` — ліцензія, PlayMode WEBCAM, IL2CPP, ARM64, OpenGLES3, **minSdk = AndroidApiLevel30**, Target Automatic, Landscape, input handler Both; `PlayerSettings.SetApplicationIdentifier` і `productName` ставити залежно від сцени (див. 7).
   - `BuildGroundPlane()`: ARCamera (`VuforiaBehaviour`, `DefaultInitializationErrorHandler`, `QuitApp`), Directional Light, **Plane Finder** + **Ground Plane Stage**. Створювати тими ж пунктами меню через `EditorApplication.ExecuteMenuItem("GameObject/Vuforia Engine/Ground Plane/Plane Finder")` / `.../Ground Plane Stage` (так вони самі підключають `AnchorInputListenerBehaviour`, `PlaneFinderBehaviour`, `ContentPositioningBehaviour`); якщо в batchmode пункти меню недоступні — повторити їх код вручну (подивитись у `Vuforia/Editor` пакета, `Library/PackageCache/com.ptc.vuforia.engine@*`). Далі: `ContentPositioningBehaviour.AnchorStage` = Ground Plane Stage, **`DuplicateStage = true`**. Модель **Race Car** (примітиви: кузов, кабіна, 4 колеса-циліндри; ~0,25 м завдовжки, колеса торкаються площини y=0) — дочірня до Ground Plane Stage. Зберегти `Assets/Scenes/GroundPlane.unity`.
   - `BuildMidAir()`: те саме камера/світло/QuitApp; **Mid Air Positioner** і **Mid Air Stage** (меню `GameObject/Vuforia Engine/Mid Air/...`), Positioner → ContentPositioningBehaviour.AnchorStage = Mid Air Stage. Модель **Low-poly aircraft** (фуселяж-циліндр/капсула, крила й хвіст-кубики, пропелер-куб `Propeller` на носі з `RotateScript`, вісь = поздовжня вісь літака) — дочірня до Mid Air Stage, Scale підібрати під візуальні межі стейджу. Зберегти `Assets/Scenes/MidAir.unity`.
   - Перевірити в Vuforia API (XML/DLL у пакеті), що саме так називаються типи й поля; **не вгадувати**.
5. `BuildAll()`: послідовно будує обидві сцени й два APK (`../build/AR_Lab5_GroundPlane.apk`, `../build/AR_Lab6_MidAir.apk`), для кожного виставляє свій bundle id і productName; `EditorApplication.Exit(1)` при помилці. `PrepareOnly(string scene)` — лише сцена + налаштування (для Play Mode).
6. Команда збірки (Unity не запущений, інакше проєкт заблокований):
   ```bash
   /Applications/Unity/Hub/Editor/6000.6.10f1/Unity.app/Contents/MacOS/Unity -batchmode -quit -projectPath submission/AR_Lab56 -buildTarget Android -executeMethod SceneBuilder.BuildAll -logFile src/build.log
   ```
7. Перевірка: у логу `build result Succeeded` для обох, 0 `error CS`, в обох `.unity` є потрібні компоненти (`PlaneFinderBehaviour`, `MidAirPositionerBehaviour`, `DuplicateStage: 1`, AnchorStage заповнений).

## Перевірка (Opus)

Play Mode з вебкамерою Mac (Vuforia Play Mode = WEBCAM): Ground Plane емулятор у Game view (tap/клік по сцені → модель; з Duplicate Stage — кілька копій), Mid Air (green pointer, клік фіксує літак, пропелер крутиться). Скріни без обличчя в `submission/media/`. На Android-пристрої — не запускалось (немає телефона), це зазначити.

## Звіт

`submission/report.md` у форматі ЛР3 (назва, мета, хід, результати, обмеження, висновки про AR-застосунки, ігрові середовища, фізику); лінк `https://github.com/djkey245/labs/tree/main/vr-ar-technologies/lab-05-06/submission`. Окремо — короткий текст для Moodle за шаблоном з пам'яті.

## Ризики

- Меню Vuforia в batchmode; API 11.4.4 для Ground/Mid Air; Ground Plane у Play Mode потребує Vuforia emulator ground plane (відображається як `emulator_ground_plane`).
- Мінімум API 30 > 29: Vuforia дозволяє.
- Два APK по ~60 МБ: комміт у межах 100 МБ на файл, але GitHub попереджає про >50 МБ (як у ЛР3).
