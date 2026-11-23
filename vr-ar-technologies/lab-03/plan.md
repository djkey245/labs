# План: ЛР3 Vuforia Cylinder Target

## Підхід

Проєкт копіюємо за структурою ЛР1 (`submission/AR_Lab3`, Vuforia 11.4.4 з `.tgz`, Unity 6000.6.10f1, Built-in RP, Android IL2CPP/ARM64, OpenGLES3). Сцену збирає editor-скрипт `SceneBuilder`, збірка в batchmode — як у ЛР1.

**Відмінність від ЛР1:** циліндрична ціль будується з **бази Target Manager** (`.dat` + `.xml`). Уточнення після реалізації: `ObserverFactory.CreateCylinderTarget(databasePath, targetName)` у 11.4.4 існує, але використано компонент `CylinderTargetBehaviour` (поля `mDataSetPath`, `mTrackableName` через `SerializedObject`). **minSdk = 29** (Vuforia 11.4.4 не збирається з 26).

## Що робить користувач (потрібен логін на developer.vuforia.com)

1. Скачати `stones_for_cylinder_target.jpg` (Drive id `1eh8jzxS5o3xoBSp5PhK7NqEHQOzPeE9G`) у `lab-03/src/`.
2. Target Manager → Add Database `AR_VF_CylinderDB` (Device) → Add Target → Cylinder `cylinder_target`, 0.048 / 0.048 / 0.1 м, зображення — те саме jpg.
3. Download Database (All) → Unity Editor → `AR_VF_CylinderDB.unitypackage` у `lab-03/src/`.
4. Ліцензійний ключ — `../vuforia_license.txt` (спільний).

Якщо зручніше — Claude може пройти портал у Chrome (потрібні вхід користувача й окремий дозвіл на завантаження файлів).

## Кроки реалізації (lab-worker)

1. Створити `submission/AR_Lab3` (копія каркаса AR_Lab1 без `Library/`, `Temp/`, `Logs/`, Assets, build), `Vuforia/com.ptc.vuforia.engine-11.4.4.tgz` взяти з lab-01.
2. Розпакувати `AR_VF_CylinderDB.unitypackage` (tar.gz: `<guid>/asset`, `<guid>/pathname`) у `Assets/`: `StreamingAssets/Vuforia/AR_VF_CylinderDB.{dat,xml}`, `Editor/Vuforia/CylinderTargetTextures/...`.
3. `Editor/SceneBuilder.cs`: нова сцена, Main Camera + `VuforiaBehaviour` + `DefaultInitializationErrorHandler`, Directional Light, `CylinderTargetBehaviour` (Database=`AR_VF_CylinderDB`, Target=`cylinder_target`; можна через `VuforiaBehaviour.Instance.ObserverFactory` не вийде — використати компонент і `CylinderTargetBehaviour.InitializeCylinderTarget`/поля через серіалізацію; **перевірити API по `Vuforia.Unity.Engine.XML`**), `DefaultObserverEventHandler`, дочірній контент: напр. Robot Kyle з ЛР1 або примітив-«кришка»/сфера над циліндром; Max Simultaneous Cylinder Targets = 1. Зберегти `Scenes/Main.unity`, додати в Build Settings.
4. `PlayerSettings` і `BuildAndroid()` — як у lab-01 (`com.lab.arlab3`, IL2CPP, ARM64, minSdk 26, Landscape).
5. Збірка:
   ```bash
   /Applications/Unity/Hub/Editor/6000.6.10f1/Unity.app/Contents/MacOS/Unity -batchmode -quit -projectPath submission/AR_Lab3 -buildTarget Android -executeMethod SceneBuilder.BuildAll -logFile build.log
   ```
6. Перевірка: Play Mode з вебкамерою (Vuforia Play Mode = WEBCAM); показати циліндр (банка/склянка з роздрукованим або екранним зображенням, обгорнутим навколо) на камеру; скріни у `submission/media/`. Для Play Mode можна також використати Image-ціль-заглушку не буде — циліндр потребує реального/роздрукованого обгорнутого зображення.
7. `submission/report.md`: назва, мета, хід (Target Manager, імпорт DB, сцена, збірка), висновки (як у ЛР1: AR/трекінг і якість цілей, ігрові середовища/сцена/префаби, фізика: Rigidbody/Collider/FixedUpdate, масштаб 1 юніт = 1 м; специфіка циліндра — розмір у метрах має збігатися з реальним, обгортка зображення, діаметри верх/низ). ПІБ і група — як у ЛР1. Лінк на репозиторій.

## Ризики

- API `CylinderTargetBehaviour` у 11.4.4 — звірити з XML перед кодом.
- Без Android-телефона перевірка тільки в Play Mode з вебкамерою; `.apk` зібрати, запуск не перевірити.
- Методичка стор. 14–25 не читалась — після отримання `.unitypackage` перечитати їх (налаштування Inspector, збірка).
- Диск ~13 ГБ: перед копіюванням проєкту чистити `Library/` старих лаб.
