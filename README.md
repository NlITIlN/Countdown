# Countdown
Обратный отсчет
=======
# Countdown — минималистичный таймер

Обратный отсчёт для **Android** и **iOS** на Flutter. Интерфейс **адаптивный**: телефоны (iPhone 12 mini → iPhone 17), любой Android, Z Fold (узкий и раскрытый экран), Windows при разработке.

## Интерфейс

| Зона | Элемент |
|------|---------|
| **Центр** | Круглая кнопка с `MM:SS` и кольцом прогресса — старт / пауза |
| **Справа сверху** | Настройки: язык RU/EN, тема — «скоро» |
| **Справа снизу** | «⋯» — минуты (±, слайдер 1–120) |

Размеры считаются от доступной ширины и высоты экрана, а не от одной модели. На широких экранах (Z Fold раскрыт, планшет, большое окно Windows) блок по центру не растягивается на всю ширину.

## Порядок разработки (всё с Windows)

### 1. Windows — первая проверка

```powershell
cd C:\Users\durba\countdown
.\setup.ps1
flutter run -d windows
```

Меняйте размер окна — круг и кнопки пересчитываются. Так удобно проверять логику до эмулятора.

### 2. Android — Android Studio

1. Android Studio → **Device Manager** → создать эмулятор (Pixel или Fold).
2. Запустить эмулятор.
3. В терминале:

```powershell
flutter devices
flutter run -d <android_id>
```

Для Z Fold: в Device Manager выберите профиль **Foldable** или устройство с широким внутренним экраном.

### 3. iOS — позже (нужен Mac)

Сборка и запуск на iPhone только на macOS с Xcode:

```bash
flutter build ios
# или flutter run на подключённом iPhone
```

На Windows можно готовить код; финальный тест на iPhone — на Mac или в CI.

---

## Android — полная сборка и выпуск

### Требования

- **Android SDK:** API level 33+ (Android 13 — для POST_NOTIFICATIONS)
- **Gradle:** встроен в Flutter
- **Подпись:** создайте keystore для release-версии

### Выпуск APK (для тестирования)

```powershell
flutter build apk --release
```

APK появится в `build/app/outputs/flutter-apk/app-release.apk`.

**Установка на телефон:**

```powershell
flutter install  # если подключён физический телефон
# или в Android Studio: Build → Build Bundles(s) / APK(s) → Build APK(s)
```

### Выпуск AAB (для Google Play)

```powershell
flutter build appbundle --release
```

AAB (App Bundle) появится в `build/app/outputs/bundle/release/app-release.aab`.

**Загрузка в Google Play Console:** используйте AAB для лучшей оптимизации размера по устройствам.

### Подпись и ключи

Перед первым выпуском создайте keystore:

```powershell
keytool -genkey -v -keystore my-release-key.jks `
  -keyalg RSA -keysize 2048 -validity 10000 `
  -alias my-key-alias
```

Укажите пароль и другие реквизиты.

Затем отредактируйте `android/key.properties`:

```ini
storePassword=<пароль от keystore>
keyPassword=<пароль от ключа>
keyAlias=my-key-alias
storeFile=<путь к my-release-key.jks>
```

### Чек-лист перед публикацией

- [ ] Уведомления работают на Android 13+ (разрешение POST_NOTIFICATIONS запрашивается)
- [ ] Таймер продолжает отсчёт при свёрнутом приложении
- [ ] Статистика и минуты сохраняются после перезапуска
- [ ] Никаких крашей при ротации экрана
- [ ] Работает на узких и широких экранах (телефон, планшет, Z Fold)
- [ ] Звук и вибрация включаются/выключаются в настройках
- [ ] Проверена вёрстка на разных версиях Android (13, 14, 15)

### Тестирование перед release

```powershell
flutter devices  # проверьте, виден ли эмулятор или телефон
flutter run -d <device_id>  # запустите в debug
flutter build apk --release  # проверьте release-сборку
```

На release-сборке нет debug-логов и оптимизирован код.

### Помощь

- [Flutter: Публикация Android](https://docs.flutter.dev/deployment/android)
- [Google Play Console](https://play.google.com/console)

## Первая настройка проекта

```powershell
cd C:\Users\durba\countdown
.\setup.ps1
```

Скрипт создаёт платформы **Android, iOS, Windows** и выполняет `flutter pub get`.

Дополнительная документация:
- `ROADMAP.md` — дорожная карта проекта и текущий статус.
- `CODE_STRUCTURE.md` — структура кода и назначение основных файлов.

## Сборка релиза

```powershell
flutter build apk --release
flutter build appbundle --release
```

iOS (на Mac): `flutter build ios --release`
