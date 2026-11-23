# Лабораторна робота 2

Джерело: https://edu.regi.rovno.ua/mod/assign/view.php?id=320923
Початок приймання: 13.10.2026.

**Тема:** Вступ у Unity Engine. Доповнена реальність. Використання шаблону AR Mobile Template.

## Завдання

Створити застосунок за шаблоном **AR Mobile** (див. методичку «Лабораторна робота 2»).
Версія: Unity 2022.3 LTS або Unity 6.0 (6000.0.84f1) LTS.

## Звіт

- Назва та мета.
- Висновки щодо особливостей створення AR-застосунків, розробки ігрових середовищ і реалізації фізики в Unity.
- Лінк на репозиторій (GitHub/GitLab) або папку `AR_VR\ЛР2` на Google Диску: проєкт, зібраний `.apk`/`.ipa`, скріни/відео запуску.

## Методичка (Лабораторна робота 2.pdf, Google Диск: 1e052zOk6axtwOcJ0Rx911M6FycBwP7yL)

1. Unity + модуль Android (або iOS + Xcode).
2. Unity Hub → New Project → шаблон **AR Mobile Core** (Download template) → назва `[name]_AR_Project`.
3. Package Manager (In Project): AR Foundation, Google ARCore XR Plugin, Apple ARKit XR Plugin, XR Plugin Management — пояснити роль кожного.
4. Project Settings → Player → Android → Other Settings: Vulkan прибрано (ARCore не підтримує), мінімальний API, IL2CPP, ARM64.
5. File → New Scene → шаблон **AR** → зберегти в `Assets/Scenes` (напр. «AR Template Scene»).
6. Дослідити сцену: **XR Origin (AR Rig)** (Camera з тегом MainCamera, Tracked Pose Driver, AR Camera Manager, AR Camera Background) і **AR Session**.
7. Play → **XR Simulation**: симульоване середовище, огляд правою кнопкою миші через SimulationCamera; XRInteractionManager, Trackables (виявлені площини/точки) — існують лише в Play Mode.
8. Додаток: як створити AR Session і XR Origin (Mobile AR) вручну через Hierarchy → XR.

## Зауваги

- XR Simulation працює в редакторі без телефону й без вебкамери — зручно для скрінів/відео (Android-пристрою немає).
- Вимогу «.apk» виконати збіркою; запуск на пристрої неможливий без Android-телефону.
