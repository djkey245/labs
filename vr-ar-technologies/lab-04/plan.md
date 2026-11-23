# План: ЛР4 Vuforia Multi Target (MarsBox)

## Підхід

Як ЛР3: проєкт `submission/AR_Lab4` (каркас AR_Lab1/AR_Lab3, Vuforia 11.4.4 з tgz, Unity 6000.6.10f1, Built-in RP, IL2CPP/ARM64/OpenGLES3, minSdk 29), сцену й збірку робить editor-скрипт `SceneBuilder` у batchmode. Ціль — **база з Target Manager** (`.dat`/`.xml`) → `MultiTargetBehaviour` (Database + Target). Контент — дочірній до Multi-Target: Robot Kyle з ЛР1 або примітив/модель на верхній грані (Toy Car з Asset Store недоступний без акаунта Unity — замінюємо; пояснити у звіті).

## Потрібне від користувача / дозволи

1. Завантаження з Drive 6 текстур `MarsBox.*_scaled.jpg` і `Розгортка_mars_box.pdf` у `lab-04/src/` (потрібен явний дозвіл на завантаження файлів).
2. Target Manager (Chrome, вхід користувача): база `AR_VF_MultiDB` (Device), ціль Multi Target `marsbox`; розміри брати з розгортки (визначити з PDF/пропорцій граней), 6 текстур; Download Database → Unity Editor → `.unitypackage` у `lab-04/src/` (як у ЛР3).
3. Ліцензійний ключ — `../vuforia_license.txt`.
4. Для Play Mode потрібна фізична коробка або розгортка на екрані/друк: на камеру показати склеєну коробку (або хоча б одну грань на телефоні — Multi Target трекається і по одній грані).

## Кроки реалізації

1. Скопіювати каркас проєкту з AR_Lab3 (без Library/Temp/Logs/build), id `com.lab.arlab4`.
2. Розпакувати `.unitypackage` у `Assets/` (StreamingAssets/Vuforia + Editor/Vuforia/...).
3. `SceneBuilder`: Main Camera + VuforiaBehaviour, світло, `MultiTargetBehaviour` (звірити API по `Vuforia.Unity.Engine.XML`), `DefaultObserverEventHandler`, дочірній контент зверху коробки; Max Simultaneous Multi Targets = 1.
4. Збірка `SceneBuilder.BuildAll` → `submission/build/AR_Lab4.apk`.
5. Play Mode (вебкамера, дозвіл TCC — запуск Unity через `open -n`), скріни у `submission/media/` (AutoShots як у ЛР1).
6. `submission/report.md` (як ЛР1–2; висновки + відповіді на контрольні запитання), README, коміт; пуш лише з підтвердження.

## Ризики

- Multi Target у 11.4.4: звірити API; minSdk 29.
- Без Android-телефона APK не перевіряється.
- Диск: чистити `Library/` старих лаб перед копіюванням.
