# Лабораторна робота 3

Джерело: https://edu.regi.rovno.ua/mod/assign/view.php?id=321876
Початок приймання: 13.10.2026. Статус на 23.11.2026: не подано.

**Тема:** Вступ у Unity Engine. Доповнена реальність. Використання Vuforia Engine. Циліндричні цілі (Cylinder Targets).

## Завдання

Створити застосунок із Vuforia, використовуючи цільові 3D-об'єкти — **циліндричну ціль** (приклад: зображення `stones_for_cylinder_target.jpg`).
Версія: Unity 2022.3 LTS або (краще) Unity 6.0 (6000.0.84f1) LTS і вище.

## Звіт

- Назва та мета.
- Висновки щодо особливостей створення AR-застосунків, розробки ігрових середовищ і реалізації фізики в Unity.
- Лінк на репозиторій (GitHub/GitLab) або папку `AR_VR\ЛР3` на Google Диску: проєкт, зібраний `.apk`/`.ipa`, скріни/відео запуску.

## Ресурси

- https://library.vuforia.com/getting-started/getting-started-vuforia-engine-unity
- https://developer.vuforia.com/library/vuforia-engine/images-and-objects/cylinder-targets/cylinder-targets/
- https://library.vuforia.com/objects/best-practices-designing-and-developing-image-based-targets
- https://developer.vuforia.com/library/vuforia-engine/images-and-objects/sample-apps-target-pdfs/
- Методичка (Google Диск, 25 стор.): `Лабораторна робота №3_Циліндрична ціль.pdf`, id `1VQfUAGfX2unCLXZyvJDtSve3WocN_VW1`
- Зображення циліндра: `stones_for_cylinder_target.jpg`, id `1eh8jzxS5o3xoBSp5PhK7NqEHQOzPeE9G`

## Кроки з методички (стор. 1–13 переглянуто; 14–25 — збірка сцени/запуск, не переглядались)

1. Проєкт Universal 3D (Unity 6000.0.x).
2. Видалити зі сцени Main Camera.
3. Імпортувати Vuforia Engine SDK (Asset Store / пакет).
4. Developer Portal → Target Manager → **Add Database** `AR_VF_CylinderDB`, Type: Device.
5. Add Target → тип **Cylinder**, назва `cylinder_target`; розміри в метрах: **Top Diameter 0.048, Bottom Diameter 0.048, Length 0.1**; завантажити зображення (бічна поверхня) — верх/низ необов'язкові. Статус «Active».
6. **Download Database (All)** → платформа **Unity Editor** → `AR_VF_CylinderDB.unitypackage` (містить `StreamingAssets/Vuforia/AR_VF_CylinderDB.dat/.xml` та `Editor/Vuforia/CylinderTargetTextures/...`).
7. Assets → Import Package → Custom Package → імпортувати все.
8. У сцені: AR Camera (Vuforia), Cylinder Target (GameObject → Vuforia Engine → Cylinder Target), у Inspector вибрати Database `AR_VF_CylinderDB` і ціль `cylinder_target`, дочірній 3D-контент, ліцензійний ключ, Build Android.
