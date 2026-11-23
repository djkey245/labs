# План: ЛР2 Unity + AR Mobile Template (AR Foundation, XR Simulation)

## Умова коротко

Створити проєкт за шаблоном **AR Mobile** (методичка «Лабораторна робота 2»), налаштувати Android, дослідити AR-сцену (XR Origin, AR Session), запустити її в **XR Simulation**, зібрати `.apk`. Звіт: назва й мета, висновки, лінк на репозиторій зі скрінами/відео та `.apk`. Android-телефона немає, тож перевірка тільки в XR Simulation; `.apk` збирається, але не запускається.

## Середовище

- Unity 6000.6.10f1 (Apple Silicon), Android Build Support вже встановлено в ЛР1.
- Шаблон AR Mobile в Hub не завантажено, але він є в публічному реєстрі Unity: `com.unity.template.ar-mobile` **2.1.3** (для Unity 6000.0+). Завантажено в `lab-02/src/template/ar-mobile-2.1.3.tgz` (86 МБ, поза `submission/`). Усередині `package/ProjectData~/` (Assets, Packages, ProjectSettings), саме це Hub копіює в новий проєкт.
- Пакети шаблону: AR Foundation 6.5.0, ARCore XR Plugin 6.5.0, ARKit XR Plugin 6.5.0, XR Plugin Management 4.6.0, XR Interaction Toolkit 3.5.1, URP.
- Диск: ~9 ГБ вільно. Для ЛР1 `Library/` займає 4,8 ГБ; чистити її тільки за потреби, коли Unity закрито (регенерується).

## Рішення

1. Проєкт називаємо за методичкою: `Kovalchuk_AR_Project` у `submission/`.
2. Проєкт створюємо без Hub: Unity `-createProject`, потім копіюємо вміст `ProjectData~` (без `Library/`) з шаблону. Версію редактора фіксує `ProjectVersion.txt`, який створить Unity.
3. Усе, що методичка робить мишею, робимо editor-скриптом `Assets/Editor/Lab2Builder.cs` + запуск у batchmode, а скріни для звіту знімаємо з XR Simulation через `ScreenCapture` (як `AutoShots` в ЛР1) і через `app_screenshot` вікна Unity.
4. Ліцензійних ключів тут немає (AR Foundation безкоштовний), доступ до камери macOS не потрібен (XR Simulation не використовує вебкамеру).

## Кроки

1. **Проєкт.** `Unity -batchmode -quit -createProject submission/Kovalchuk_AR_Project`, потім `tar -xzf ar-mobile-2.1.3.tgz` у тимчасову теку й копіювання `ProjectData~/{Assets,Packages,ProjectSettings}` поверх, без `Library/`. Перший імпорт у batchmode (resolve пакетів із реєстру, мережа потрібна).
2. **Пакети (крок 3 методички).** Переконатися в Package Manager (`packages-lock.json`), що в проєкті є AR Foundation, Google ARCore XR Plugin, Apple ARKit XR Plugin, XR Plugin Management. Для звіту записати роль кожного пакета.
3. **Android-налаштування (крок 4).** Player → Android: прибрати Vulkan (залишити OpenGLES3), мінімальний API відповідно до ARCore (≥ 24; брати з шаблону), IL2CPP, ARM64. XR Plug-in Management → Android: ARCore увімкнено. Зробити скрін налаштувань.
4. **Сцена (крок 5).** Нова сцена з шаблону **AR** (через `SceneTemplate`/дефолт шаблону), зберегти як `Assets/Scenes/AR Template Scene.unity`; додати в Build Settings.
5. **Дослідження сцени (крок 6).** Описати для звіту й зробити скріни Hierarchy/Inspector: **XR Origin (AR Rig)** (Camera з тегом MainCamera, Tracked Pose Driver, AR Camera Manager, AR Camera Background) і **AR Session**.
6. **XR Simulation (крок 7).** Увімкнути XR Simulation у XR Plug-in Management (Standalone/Editor), Play: симульоване середовище, огляд правою кнопкою миші через SimulationCamera; `XRInteractionManager`, Trackables (площини/точки) лише в Play Mode. Скріни Game/Scene під час Play, за можливості короткий запис екрана.
7. **Додаток (крок 8).** Показати, як створити AR Session і XR Origin (Mobile AR) вручну через Hierarchy → XR, у новій порожній сцені `Manual AR Scene.unity`; скрін.
8. **Збірка.** `SceneBuilder`-подібний метод `Lab2Builder.BuildAndroid` → `submission/build/Kovalchuk_AR_Project.apk` (batchmode, `-buildTarget Android`). Ідентифікатор `com.lab.arlab2`.
9. **Звіт `submission/report.md`.** Назва, мета, хід роботи зі скрінами, висновки (AR-застосунки: трекінг площин, AR Foundation як абстракція над ARCore/ARKit, XR Simulation; ігрові середовища: сцена, XR Origin, префаби; фізика: Rigidbody/Collider, в AR 1 одиниця = 1 м, спавн об'єктів із шаблону має фізику взаємодії), лінк на репозиторій. Чесно вказати: `.apk` зібрано, на пристрої не запускався.
10. **Git.** Додати `lab-02/submission/` у репозиторій (`.gitignore`: `Library/`, `Temp/`, `Logs/`, `UserSettings/`, `*.csproj`, `*.sln*`, `src/`), оновити README предмета, коміт і (з дозволу) пуш.

## Ризики

- Unity 6000.6 новіша за 6000.0, для якої зібрано шаблон 2.1.3: можливі попередження/оновлення API; якщо пакети не збираються, взяти AR Foundation 6.x, сумісний з 6000.6.
- Шаблон тягне пакети з реєстру Unity: потрібен доступ до мережі; перший імпорт довгий.
- Підписаний пакет (`.signature`) — копіюємо тільки `ProjectData~`, самого пакета шаблону в проєкті немає, це нормально.
- XR Simulation вимагає увімкненого Editor-провайдера в XR Plug-in Management; у шаблоні налаштовано, перевірити після імпорту.
- Місце на диску: перед збіркою `df -h /`, за потреби очистити `Library/` ЛР1.
