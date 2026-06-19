# MyCycle

Персональное приложение для отслеживания менструального цикла.

## Автообновление

При каждом push в ветку `main` GitHub Actions:

1. Собирает release APK
2. Публикует его в [Releases](https://github.com/NIXXXON177/MyCycle/releases)

Приложение при запуске проверяет последний релиз на GitHub и предлагает обновиться. Установка идёт **поверх** текущей версии — все данные сохраняются.

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
