# Технології VR/AR

- Курс у Moodle: https://edu.regi.rovno.ua/course/view.php?id=9966
- Викладач: Тетяна Шроль (власниця методичок на Google Диску).
- Інструменти: Unity 6.0 LTS (6000.0.x, рекомендовано) або 2022.3 LTS, Vuforia Engine, збірка під Android (.apk).
- Формат здачі: звіт (назва, мета, висновки) + лінк на репозиторій (GitHub/GitLab) або папку `AR_VR\ЛР1` на Google Диску з проєктом, `.apk`/`.ipa`, скрінами/відео запуску.
- Середовище на Mac: Unity 6000.6.10f1 (Apple Silicon) + Android Build Support; Vuforia 11.4.4 (tgz у проєкті). Ключ Vuforia — `vuforia_license.txt` у цій папці (спільний для всіх лаб, не комітити). Збірка: `SceneBuilder.BuildAll` у batchmode.
- Диск майже повний (~13 ГБ вільно) — перед новими лабами чистити `Library/` старих проєктів.

| Лаба | Тема | Статус |
|------|------|--------|
| [lab-01](lab-01/) | Unity + Vuforia, Image Targets (AR) | APK зібрано; AR перевірено в Play Mode з вебкамерою (скріни в `submission/media/`); звіт `submission/report.md` написано — лишилось вписати ПІБ і лінк на репозиторій та здати. На Android не запускали (немає телефона) |
| [lab-02](lab-02/) | AR Mobile Template (AR Foundation, XR Simulation) | Проєкт за шаблоном AR Mobile, Android-налаштування, APK зібрано, XR Simulation у Play Mode (скріни в `submission/media/`); звіт `submission/report.md` написано. На Android не запускали |
| [lab-03](lab-03/) | Vuforia Cylinder Target | База з Target Manager імпортована, сцена з трьома цілями (картинка, балон, труба з листівки) + Robot Kyle, APK зібрано (`submission/build/AR_Lab3.apk`, minSdk 29). Розпізнавання перевірено в Play Mode з вебкамерою (`cylinder_target` з екрана телефона, `can_target` — реальний балон, `card_target` — труба з листівки, усі `TRACKED`; скріни в `submission/media/`). На Android не запускали |
| [lab-04](lab-04/) | Vuforia Multi Target (коробка MarsBox) | База `AR_VF_MultiDB` з Target Manager, сцена з Multi Target `marsbox` + Robot Kyle, APK зібрано (`submission/build/AR_Lab4.apk`, minSdk 29). Відстеження перевірено в Play Mode з вебкамерою (`TRACKED`, скріни в `submission/media/`); звіт `submission/report.md`. Показано одну грань (Front) з екрана телефона. На Android не запускали |
| [lab-05-06](lab-05-06/) | Vuforia Ground Plane + Mid Air | Два застосунки в одному проєкті `AR_Lab56`: Ground Plane (Race Car, Duplicate Stage) і Mid Air (літак з обертовим пропелером), вихід по Escape; APK зібрано (`submission/build/AR_Lab5_GroundPlane.apk`, `AR_Lab6_MidAir.apk`, minSdk 30). Перевірено в Play Mode з вебкамерою та шаблоном Emulator Ground Plane (скріни в `submission/media/`), звіт `submission/report.md`. На Android не запускали |
| [lab-07](lab-07/) | Фільтри для обличчя (AR Face, AR Mobile Template) | Проєкт `AR_Lab7`: `Basic_Face_Filter` (зелена маска AR Default Face, фронтальна камера) і `InteractiveFilter` (три пари окулярів Cat/Stars/Mask, UI-кнопки вибору окулярів і кольору, збереження вибору). Логіка на C# (без Visual Scripting), ocean-фільтр не робився. APK зібрано (`submission/build/AR_Lab7_BasicFaceFilter.apk`, `AR_Lab7_InteractiveFilter.apk`, minSdk 26). Перевірено в Play Mode на тестовій сцені (кліки по кнопках з меню редактора), на Android не запускали; звіт `submission/report.md` |

## Як відкрити проєкт ЛР1

1. Unity Hub → Add → `lab-01/submission/AR_Lab1`, редактор Unity 6000.6.10f1 (Android Build Support).
2. Пакет Vuforia Engine 11.4.4 не зберігається в репозиторії (власницький SDK, понад 100 МБ): завантажити `add-vuforia-package-11-x.unitypackage` з developer.vuforia.com, дістати з нього `com.ptc.vuforia.engine-11.4.4.tgz` і покласти в `lab-01/submission/AR_Lab1/Vuforia/`.
3. Власний ліцензійний ключ Vuforia вписати в `Window → Vuforia Engine → Configuration → App License Key`.
4. Звіт: `lab-01/submission/report.md`, готовий `.apk`: `lab-01/submission/build/AR_Lab1.apk`.

## Як відкрити проєкт ЛР2

1. Unity Hub → Add → `lab-02/submission/Kovalchuk_AR_Project`, редактор Unity 6000.6.10f1 (Android Build Support). Пакети (AR Foundation тощо) підтягнуться з реєстру Unity.
2. Сцени: `Assets/Scenes/AR Template Scene.unity` (з шаблону) і `Manual AR Scene.unity` (AR Session + XR Origin вручну).
3. Звіт: `lab-02/submission/report.md`, готовий `.apk`: `lab-02/submission/build/Kovalchuk_AR_Project.apk`.

## Як відкрити проєкт ЛР3

1. Unity Hub → Add → `lab-03/submission/AR_Lab3`, редактор Unity 6000.6.10f1 (Android Build Support).
2. Пакет Vuforia Engine 11.4.4 (`com.ptc.vuforia.engine-11.4.4.tgz`) лежить у `lab-03/submission/AR_Lab3/Vuforia/` (як у ЛР1). База цілі: `Assets/StreamingAssets/Vuforia/AR_VF_CylinderDB.{dat,xml}`.
3. Власний ліцензійний ключ Vuforia вписати в `Window → Vuforia Engine → Configuration → App License Key` (або покласти `vuforia_license.txt` у цю папку й виконати `AR Lab → Build Scene` / `SceneBuilder.BuildAll`).
4. Сцена `Assets/Scenes/Main.unity` будується скриптом `Assets/Editor/SceneBuilder.cs`. Звіт: `lab-03/submission/report.md`, готовий `.apk`: `lab-03/submission/build/AR_Lab3.apk`.

## Як відкрити проєкт ЛР4

1. Unity Hub → Add → `lab-04/submission/AR_Lab4`, редактор Unity 6000.6.10f1 (Android Build Support).
2. Пакет Vuforia Engine 11.4.4 (`com.ptc.vuforia.engine-11.4.4.tgz`) покласти в `lab-04/submission/AR_Lab4/Vuforia/` (не в репозиторії, власницький SDK). База цілі: `Assets/StreamingAssets/Vuforia/AR_VF_MultiDB.{dat,xml}`.
3. Власний ліцензійний ключ Vuforia вписати в `Window → Vuforia Engine → Configuration → App License Key` (або покласти `vuforia_license.txt` у цю папку й виконати `AR Lab → Build Scene` / `SceneBuilder.BuildAll`).
4. Сцена `Assets/Scenes/Main.unity`. Звіт: `lab-04/submission/report.md`, готовий `.apk`: `lab-04/submission/build/AR_Lab4.apk`.
