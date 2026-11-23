# План: ЛР1 Unity + Vuforia, Image Targets

## Середовище (стан 20.11.2026)

- Unity 6000.6.10f1 (Apple Silicon), шлях `/Applications/Unity/Hub/Editor/6000.6.10f1`.
- Модулі: WebGL (6.3 ГБ, не потрібен), Documentation (1.2 ГБ, не потрібна). **Android-модуля немає** — додати через Hub (Android Build Support + OpenJDK + SDK & NDK Tools).
- Вільно на диску ~13 ГБ — впритул. Android-модуль ~5–6 ГБ, проєкт ~2 ГБ.

## Перевірено (20.11.2026)

- WebGL/Documentation видалено, Android-модуль встановлено (SDK/NDK/OpenJDK вбудовані).
- Проєкт створено: `submission/AR_Lab1` (Built-in RP, порожній). Vuforia 11.4.4 підключена як `file:../Vuforia/com.ptc.vuforia.engine-11.4.4.tgz`, компілюється на 6000.6.10f1 без помилок.
- API (з `Vuforia.Unity.Engine.XML`):
  - `VuforiaBehaviour.Instance.ObserverFactory.CreateImageTarget(Texture2D texture, float widthInMeters, string name)` → `ImageTargetBehaviour`; текстура ≤ 2048 px.
  - `VuforiaApplication.Instance.OnVuforiaStarted` (event `Action`).
  - `VuforiaConfiguration.Instance.Vuforia.LicenseKey`, `.MaxSimultaneousImageTargets`; `VuforiaConfiguration.Instance.PlayMode.PlayModeType = PlayModeType.WEBCAM`.
- Ліцензійний ключ: користувач кладе у `AR_Lab1/vuforia_license.txt` (в `.gitignore`). `SceneBuilder` читає файл і пише в конфіг перед білдом. Ключ у чат/git не потрапляє.

## Рішення

Один застосунок, одна сцена, дві цілі-зображення (Max Simultaneous Image Targets = 2):

1. **Завдання 1 (аналог заняття):** маркер `stones1.png` → 3D-модель Robot Kyle стоїть на маркері.
2. **Завдання 2:** фото купюри 100 грн → поверх неї Quad з текстурою 1000 грн, ті самі розміри й орієнтація, зсув над площиною y = 0.001. Купюра «підміняється».

Цілі створюються **з коду в рантаймі** (`ObserverFactory.CreateImageTarget(texture, widthMeters, name)`), без Target Manager і без бази `.xml/.dat`. Так менше ручної роботи в редакторі й порталі Vuforia. Інтерфейсу Vuforia в редакторі немає — сцену будує editor-скрипт.

## Структура

```
lab-01/
├── src/                      # завантажені вихідні ресурси (купюри, Robot Kyle, vuforia .unitypackage)
└── submission/
    ├── AR_Lab1/              # Unity-проєкт (без Library/, Temp/, Logs/, UserSettings/)
    │   ├── Assets/
    │   │   ├── Editor/SceneBuilder.cs   # меню AR Lab/Build Scene + BuildAndroid() для batchmode
    │   │   ├── Scripts/RuntimeTargets.cs
    │   │   ├── Textures/ stones.png, uah100.jpg, uah1000.jpg
    │   │   ├── Models/RobotKyle/
    │   │   └── Scenes/Main.unity
    │   ├── Packages/manifest.json       # + "com.ptc.vuforia.engine": "file:../Vuforia/com.ptc.vuforia.engine-<ver>.tgz"
    │   ├── Vuforia/com.ptc.vuforia.engine-<ver>.tgz
    │   └── .gitignore
    ├── build/AR_Lab1.apk
    ├── media/                # скріни, відео з телефону
    └── report.md (+ .docx/.pdf за потреби)
```

## Кроки

1. **Vuforia-пакет.** Користувач завантажує `add-vuforia-package-11-x.unitypackage` з developer.vuforia.com (потрібен логін). Дістати з нього `com.ptc.vuforia.engine-*.tgz` (unitypackage = tar.gz; файл лежить у `<guid>/asset`, ім'я в `<guid>/pathname`), покласти в `AR_Lab1/Vuforia/`, прописати в `manifest.json` як `file:`.
2. **Ліцензія.** Користувач сам вставляє ключ у `Assets/Resources/VuforiaConfiguration.asset` (поле App License Key). Ключ не в git: `VuforiaConfiguration.asset` додати в `.gitignore` або перед публікацією стерти ключ.
3. **Текстури.** Купюри 100 і 1000 грн (сайт НБУ, лицьовий бік, висока роздільність). Import settings: Read/Write = on, Compression = None, Non-Power-of-2 = None, формат RGB24/RGBA32 (вимога `CreateImageTarget`). Ширина цілі: 100 грн = 0.150 м (реальна 150×75 мм), 1000 грн — та сама довжина, щоб перекрити повністю. Stones — 0.2 м.
4. **`RuntimeTargets.cs`** (MonoBehaviour на порожньому об'єкті):
   - `VuforiaApplication.Instance.OnVuforiaStarted += Create;`
   - `Create()`: для кожної пари (texture, width, name, contentFactory) → `VuforiaBehaviour.Instance.ObserverFactory.CreateImageTarget(tex, width, name)`; додати `DefaultObserverEventHandler`; дочірній контент.
   - Контент 100 грн: `GameObject.CreatePrimitive(Quad)`, `localRotation = Euler(90,0,0)`, `localScale = (1, aspect, 1)` (ціль нормована за шириною до 1 в локальних координатах — перевірити, інакше масштабувати в метрах), `localPosition.y = 0.001`, матеріал `Unlit/Texture` з uah1000.
   - Контент stones: instantiate prefab Robot Kyle, масштаб під ширину цілі.
5. **`SceneBuilder.cs`** (Editor):
   - нова сцена; Main Camera + `VuforiaBehaviour` + `DefaultInitializationErrorHandler`; Directional Light; об'єкт `Targets` з `RuntimeTargets` і посиланнями на текстури/prefab; зберегти `Scenes/Main.unity`, додати в Build Settings.
   - `PlayerSettings`: companyName/productName, `applicationIdentifier = com.lab.arlab1`, IL2CPP, ARM64, minSdk 26 (перевірити мінімум Vuforia), Graphics API = OpenGLES3 (вимкнути авто), орієнтація Landscape Left, дозвіл камери.
   - `BuildAndroid()`: `BuildPipeline.BuildPlayer` → `../build/AR_Lab1.apk`.
6. **Збірка з терміналу:**
   ```bash
   /Applications/Unity/Hub/Editor/6000.6.10f1/Unity.app/Contents/MacOS/Unity -batchmode -quit -projectPath submission/AR_Lab1 -buildTarget Android -executeMethod SceneBuilder.BuildAll -logFile build.log
   ```
   Перший запуск: створити проєкт `-createProject`, потім імпорт пакета (resolve) і білд.
7. **Перевірка:** Play Mode з вебкамерою Mac (Vuforia Play Mode = WEBCAM) — показати купюру 100 грн на екрані телефону/роздруківці. Потім `.apk` на Android-телефон (`adb install`), запис відео.
8. **Звіт `report.md`:** назва, мета, хід роботи (скріни), висновки: AR-застосунки (трекінг, якість маркерів — контраст, деталі, без симетрії; освітлення; ліцензія), ігрові середовища в Unity (сцена, GameObject/Component, префаби, редактор vs код), фізика в Unity (Rigidbody, Collider, гравітація, FixedUpdate; у AR — масштаб 1 юніт = 1 м). Лінк на GitHub-репозиторій.

## Ризики

- Unity 6000.6 — не LTS; Vuforia може офіційно підтримувати старіші 6000.x. Якщо компіляція пакета падає — поставити Unity 6000.0 LTS.
- Купюра 1000 грн на 100 грн: пропорції різні (1000 грн 160×75 мм) — масштабувати Quad під ширину 100-ки або злегка більше, щоб повністю закрити.
- Диск 13 ГБ вільно — видалити WebGL і Documentation (7.5 ГБ) перед додаванням Android.
