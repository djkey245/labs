# Лабораторна робота 5-6

Джерело: https://edu.regi.rovno.ua/mod/assign/view.php?id=323113
Статус на 23.11.2026: не подано.

**Тема:** Доповнена реальність. Використання Vuforia Engine. Об'єкти на поверхні землі й у просторі (Ground Plane, Mid Air).

## Завдання (з Moodle)

Створити AR-застосунок (застосунки) з Vuforia, використовуючи **Ground Plane** і **Mid Air**. Unity 6.0 (6000.0.84f1) і вище.
Забезпечити вихід із застосунку при натисканні Escape (`Input.GetKey("escape")` → `Application.Quit()`).

## Звіт

- Назва та мета.
- Висновки щодо особливостей створення AR-застосунків, розробки ігрових середовищ і реалізації фізики в Unity.
- Лінк на репозиторій (GitHub/GitLab) або папку `AR_VR\ЛР5-6` на Google Диску: проєкт, зібрані `.apk`/`.ipa`, скріни/відео запуску.

## Ресурси

- Методичка «Лабораторна робота.5.pdf» (Drive id `1KTD9d35GzFcUp470tfaUm1bAlzjVWtmU`, 6 стор.), відео результату: папка Drive `1W1s8fu_dR5h4mQQmefeZfDQznJemGuF6`.
- https://developer.vuforia.com/library/vuforia-engine/environments/ground-plane/ground-plane/
- https://developer.vuforia.com/library/vuforia-engine/environments/ground-plane/introduction-ground-plane-unity/
- Рекомендовані пристрої: https://developer.vuforia.com/library/vuforia-engine/platform-support/recommended-devices/

## Методичка (повністю прочитана)

### Завдання 1 — Ground Plane
1. Сцена з **Plane Finder** і **Ground Plane Stage** (GameObject → Vuforia Engine → Ground Plane).
2. Plane Finder → Content Positioning Behaviour → **Anchor Stage** = Ground Plane Stage.
3. 3D-модель (напр. Race Car) — дочірній об'єкт Ground Plane Stage, підібрати Scale.
4. **Duplicate Stage** (Content Positioning Behaviour): увімкнено — кожен tap створює нову копію; вимкнено — одна копія.
5. Скрипт `QuitApp` (Escape → `Application.Quit()`), на камеру або модель.
6. Android: Minimum API Level 30 (Android 11) або вище, Target API Automatic, IL2CPP, ARM64.
7. Збірка `.apk`, тест на ARCore-смартфоні: камера на підлогу/стіл, tap — модель з'являється.

### Завдання 2 — Mid Air
1. Сцена з **Mid Air Positioner** і **Mid Air Stage** (GameObject → Vuforia Engine → Mid Air); Positioner → Content Positioning Behaviour → **Anchor Stage** = Mid Air Stage.
2. Модель літака (Low-poly aircraft) — дочірній об'єкт Mid Air Stage, підігнати Scale.
3. C#-скрипт `RotateScript` (`transform.Rotate`) — обертання пропелера.
4. `QuitApp` (Escape).
5. Player Settings: Minimum API Level 30, Target Automatic, IL2CPP, ARM64.
6. Збірка `.apk`; на пристрої — зелений вказівник (green pointer), tap фіксує модель у просторі.
