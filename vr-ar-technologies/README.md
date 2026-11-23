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
| [lab-02](lab-02/) | AR Mobile Template (AR Foundation, XR Simulation) | умову зібрано |

## Як відкрити проєкт ЛР1

1. Unity Hub → Add → `lab-01/submission/AR_Lab1`, редактор Unity 6000.6.10f1 (Android Build Support).
2. Пакет Vuforia Engine 11.4.4 не зберігається в репозиторії (власницький SDK, понад 100 МБ): завантажити `add-vuforia-package-11-x.unitypackage` з developer.vuforia.com, дістати з нього `com.ptc.vuforia.engine-11.4.4.tgz` і покласти в `lab-01/submission/AR_Lab1/Vuforia/`.
3. Власний ліцензійний ключ Vuforia вписати в `Window → Vuforia Engine → Configuration → App License Key`.
4. Звіт: `lab-01/submission/report.md`, готовий `.apk`: `lab-01/submission/build/AR_Lab1.apk`.
