# Countdown — минималистичный таймер

Обратный отсчёт от 1 до 5 минут для **Android** и **iOS** на Flutter. Интерфейс адаптивный: телефоны (iPhone 12 mini → iPhone 17), любой Android, Z Fold (узкий и раскрытый экран), окно Windows при разработке.

## Возможности

- Три концентрических кольца с прогрессом и анимациями: пульсация на последних 10 секундах, затухание и появление после завершения.
- Тап по кругу — старт; тап во время отсчёта — сброс. Пауза намеренно не предусмотрена.
- Таймер продолжает идти после сворачивания и перезапуска приложения.
- Уведомление о завершении (Android / iOS, toast на Windows), с настройкой звука и вибрации.
- Статистика: число запусков, серия дней подряд, лента активности за 30 дней, значки (10 / 25 / 50 / 100 запусков) и достижения (рекорд дня, серия, возвращение после перерыва).
- Языки RU / EN, темы: тёмная, светлая, неоновая.

## Интерфейс

| Зона | Элемент |
|------|---------|
| **Центр** | Круглая кнопка с `MM:SS` и кольцами прогресса — старт / сброс |
| **Справа сверху** | «⋯» — меню: статистика и настройки |
| **Настройки → таймер** | Минуты: пресеты 1–5, ±, слайдер |
| **Настройки → настройки** | Язык, тема, звук и вибрация уведомлений |

Размеры считаются от доступной ширины и высоты экрана, а не от одной модели. На широких экранах (Z Fold раскрыт, планшет, большое окно Windows) блок по центру не растягивается на всю ширину.

## Первая настройка

```powershell
cd countdown
.\setup.ps1
```

Скрипт создаёт недостающие платформы (**Android, iOS, Windows**) и выполняет `flutter pub get`.

## Разработка (всё с Windows)

### 1. Windows — быстрые итерации

```powershell
flutter run -d windows
```

Меняйте размер окна — круг и кнопки пересчитываются.

### 2. Android

1. Android Studio → **Device Manager** → создать эмулятор (Pixel или Fold).
2. Запустить эмулятор.
3. В терминале:

```powershell
flutter devices
flutter run -d <android_id>
```

Для Z Fold выберите в Device Manager профиль **Foldable**.

### 3. iOS (нужен Mac)

Сборка и запуск на iPhone — только на macOS с Xcode:

```bash
flutter run          # на подключённом iPhone или симуляторе
flutter build ios --release
```

### Проверки

```powershell
flutter analyze
flutter test
```

То же самое выполняет CI (GitHub Actions) на каждый push и pull request.

---

## Android — сборка и выпуск

### Требования

- **Android SDK:** API 33+ (Android 13 — для `POST_NOTIFICATIONS`).
- **Gradle:** встроен в Flutter.
- Точное время уведомления о завершении: разрешение `USE_EXACT_ALARM` (Android 13+). Если система его не даёт, уведомление планируется неточно и может немного опоздать.

### APK (для тестирования)

```powershell
flutter build apk --release
```

Файл: `build/app/outputs/flutter-apk/app-release.apk`. Установка на подключённый телефон — `flutter install`.

### AAB (для Google Play)

```powershell
flutter build appbundle --release
```

Файл: `build/app/outputs/bundle/release/app-release.aab`.

### Подпись

Создайте keystore:

```powershell
keytool -genkey -v -keystore my-release-key.jks `
  -keyalg RSA -keysize 2048 -validity 10000 `
  -alias my-key-alias
```

Создайте `android/key.properties` (файл в `.gitignore`, в репозиторий не попадает):

```ini
storePassword=<пароль от keystore>
keyPassword=<пароль от ключа>
keyAlias=my-key-alias
storeFile=<путь к my-release-key.jks относительно android/app>
```

Если `key.properties` нет, release-сборка подписывается debug-ключом — для теста подходит, для Google Play нет.

### Чек-лист перед публикацией

- [ ] Уведомления работают на Android 13+ (разрешение `POST_NOTIFICATIONS` запрашивается)
- [ ] Уведомление о завершении приходит вовремя при свёрнутом приложении
- [ ] Статистика и минуты сохраняются после перезапуска
- [ ] Никаких крашей при повороте экрана
- [ ] Работает на узких и широких экранах (телефон, планшет, Z Fold)
- [ ] Звук и вибрация включаются / выключаются в настройках
- [ ] Проверено на Android 13, 14, 15

### Полезные ссылки

- [Flutter: публикация Android](https://docs.flutter.dev/deployment/android)
- [Google Play Console](https://play.google.com/console)

## Структура кода

См. [`CODE_STRUCTURE.md`](CODE_STRUCTURE.md).
