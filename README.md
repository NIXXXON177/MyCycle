# MyCycle

Персональное приложение для отслеживания менструального цикла.

## Автообновление

При каждом push в ветку `main` GitHub Actions собирает APK и публикует его в [Releases](https://github.com/NIXXXON177/MyCycle/releases).

**Перед каждым push** обновите файл `release_notes/whats_new.txt` — этот текст увидит пользователь в диалоге обновления на телефоне.

Пример:
```
Что исправлено и добавлено:
• Исправлен белый экран
• Добавлен новый календарь
```

Приложение при запуске проверяет GitHub и предлагает обновиться.

## Разработка

```bash
flutter pub get
flutter run
```

## Сборка APK локально

Keystore хранится локально в `android/mycycle-release.jks` (не в git).  
Переменные для подписи совпадают с секретами в GitHub Actions.

```powershell
$env:ANDROID_KEYSTORE_PATH = "mycycle-release.jks"
$env:ANDROID_KEYSTORE_PASSWORD = "<из GitHub Secrets>"
$env:ANDROID_KEY_ALIAS = "mycycle"
$env:ANDROID_KEY_PASSWORD = "<из GitHub Secrets>"
flutter build apk --release
```

## Репозиторий

https://github.com/NIXXXON177/MyCycle
