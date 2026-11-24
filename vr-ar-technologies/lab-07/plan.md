# План ЛР7

Один проєкт `submission/AR_Lab7` (копія AR Mobile Template проєкту з ЛР2 без Library), дві сцени, два APK.

## Підготовка
1. Скопіювати `lab-02/submission/Kovalchuk_AR_Project` (без Library/Temp/Logs/UserSettings/obj) → `submission/AR_Lab7`. Видалити сцени ЛР2 з Build Settings, XR Simulation вимкнути (Edit > Project Settings > XR Plug-in Management > Windows/Mac/Linux). Android: IL2CPP, ARM64, minSdk 26+ (шаблон; для ARCore face достатньо 24+), `applicationId` com.lab.arlab7a / com.lab.arlab7b. Пакет ARCore XR Plugin (com.unity.xr.arcore) уже є; ARCore Face потребує Face Tracking у ARCore Settings (Requirement Optional/Required на вибір).
2. Імпорт `src/BasicFaceFilterAssets.unitypackage` (`Assets/_BasicFaceFilter`) та `Interactive_Face_Filter_Assets.zip` → `InteractiveFaceFilter.unitypackage` (`Assets/_InteractiveFaceFilter`). Імпорт через editor-скрипт: `AssetDatabase.ImportPackage(path, false)`.

## Сцена 1: Basic_Face_Filter
Editor-скрипт `Assets/Editor/FaceSceneBuilder.cs` (методи `BuildBasic`, `BuildInteractive`, `BuildAll`; батч: `-executeMethod`), що за кроками методички:
- Нова сцена з шаблону AR (XR Origin (AR Rig), AR Session, Directional Light), видалити Cube; зберегти `Assets/Scenes/Basic_Face_Filter.unity`.
- Створити AR Default Face (XR > AR Default Face; можна через `EditorApplication.ExecuteMenuItem("GameObject/XR/AR Default Face")`), матеріал `Face Debug MAT`, зберегти префаб `Assets/_BasicFaceFilter/Prefabs/AR Default Face.prefab`, видалити екземпляр зі сцени.
- На XR Origin додати `ARFaceManager`, Face Prefab = префаб. Main Camera → `ARCameraManager.requestedFacingDirection = CameraFacingDirection.User`.
- Опційно: колір Face Debug MAT змінити (легке завдання) — не обов'язково.

## Сцена 2: InteractiveFilter
- Та сама основа; Cube видалити, Facing Direction = User, `ARFaceManager` на XR Origin.
- Три пари окулярів із `_InteractiveFaceFilter/Meshes` (на вибір, напр. Cat, Round, Sunglasses — за іменами в пакеті) в `GlassesGroup` (Position 0,0,0), компонент `ARFace`, префаб `Assets/_InteractiveFaceFilter/Prefabs/GlassesGroup.prefab`, Face Prefab у ARFaceManager. Для тесту в редакторі екземпляр `GlassesGroup` у сцені з Z=0.4 (для збірки його вимкнути, прибрати зі сцени).
- Перетягнути `AR_Canvas` у сцену; іконки кнопок окулярів зі `UI_Icon_Glasses`; три матеріали кольорів (`Assets/_InteractiveFaceFilter/Materials`) і кольори кнопок `Materials Buttons`.
- Мешренд. окулярів вимкнені за замовчуванням; теги (`cat`, `round` тощо) на окулярах.
- Логіка: путівник дає Visual Scripting. Реалізувати C#-еквівалентом `Assets/Scripts/GlassesSelector.cs` (кнопка окулярів → увімкнути MeshRenderer потрібних окулярів, вимкнути інші; кнопка кольору → замінити матеріал на всіх окулярах; вибір зберігається `PlayerPrefs` і відновлюється при старті). Якщо вдасться, додатково зробити Script Graph `MeshChanger` (Visual Scripting пакет є в шаблоні) — інакше в звіті чесно написати, що логіку виконано C#, а не Visual Scripting.
- Ocean-themed фільтр (submission) — не виконувати без потреби; у звіті зазначити як не виконаний.

## Збірка
- Два APK: `build/AR_Lab7_BasicFaceFilter.apk` (сцена Basic_Face_Filter, `com.lab.arlab7a`) і `build/AR_Lab7_InteractiveFilter.apk` (InteractiveFilter, `com.lab.arlab7b`); IL2CPP, ARM64. Команда: `Unity -batchmode -quit -projectPath submission/AR_Lab7 -buildTarget Android -executeMethod FaceSceneBuilder.BuildAll -logFile src/build.log`.
- Unity 6000.6.10f1 як у ЛР1-6; ліцензії Vuforia не потрібні.

## Перевірка (Opus)
- Face-трекінг у Play Mode на Mac не емулюється: перевірка = екземпляр префаба в Game view (як у путівнику) + клік по кнопках UI (editor-меню `AR Lab/Click Button <name>` через `ExecuteEvents.Execute(button, new PointerEventData(EventSystem.current), ExecuteEvents.pointerClickHandler)`). Скріни без обличчя користувача (вебкамера не потрібна).
- На Android не запускалось (немає телефона з ARCore Face) — зазначити у звіті.

## Звіт `submission/report.md` у стилі ЛР3/ЛР5-6
Мета, середовище, хід (завдання 1 і 2), результати, обмеження, висновки (особливості AR-застосунків: AR Face Manager/AR Face, фронтальна камера; ігрові середовища: префаби, UI Canvas, теги, matеріали; фізика: Rigidbody/Collider, 1 одиниця = 1 м; тут не використовується), лінк https://github.com/djkey245/labs/tree/main/vr-ar-technologies/lab-07/submission. Оновити `vr-ar-technologies/README.md` рядком lab-07 і `.gitignore` для AR_Lab7.
