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

Используйте тот же keystore, что и в CI (`android/mycycle-release.jks`):

```powershell
$env:ANDROID_KEYSTORE_PATH = "android/mycycle-release.jks"
$env:ANDROID_KEYSTORE_PASSWORD = "MyCycle2026!"
$env:ANDROID_KEY_ALIAS = "mycycle"
$env:ANDROID_KEY_PASSWORD = "MyCycle2026!"
flutter build apk --release
```

## Репозиторий

https://github.com/NIXXXON177/MyCycle
