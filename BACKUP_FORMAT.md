# Формат резервной копии MyCycle

## Backup v2 (с версии 1.7.5)

Файл: `MyCycle_Backup_YYYY-MM-DD.zip`

```
MyCycle_Backup_2026-06-19.zip
├── manifest.json
├── settings.json
├── mycycle.db
└── diary_images/
    ├── 0.jpg
    ├── 1.jpg
    └── ...
```

### manifest.json

| Поле | Тип | Описание |
|------|-----|----------|
| `appVersion` | string | Версия приложения при экспорте |
| `backupVersion` | int | Версия формата (сейчас `2`) |
| `createdAt` | ISO 8601 UTC | Время создания |
| `photosCount` | int | Число файлов в `diary_images/` |
| `databaseVersion` | int | Версия схемы SQLite |
| `devicePlatform` | string | Платформа при экспорте: `android`, `ios` или `unknown` |

### settings.json

Экспортируются настройки из SharedPreferences:

- `theme` — `light` / `dark` / `system`
- `pinEnabled`, `pinHash`, `biometricEnabled` (флаг экспортируется, но при Restore биометрия **не** восстанавливается)
- `defaultCycleLength`, `defaultPeriodLength`
- `notificationsEnabled` (агрегат напоминаний)
- `reminderPeriodApproaching`, `reminderPeriodStart`, `reminderDailyWellbeing`
- `reminderHour`, `reminderMinute`

> PIN в архиве хранится как SHA-256-хэш (`pinHash`), не в открытом виде. Архив всё равно нужно хранить в безопасном месте.

**Политика Restore:** PIN восстанавливается по хэшу; биометрия после Restore **выключается** (ключи привязаны к устройству). См. `RELEASE_PROCESS.md`.

> **Frozen until v2.0:** формат Backup v2 не менять без плана миграции. См. `RELEASE_PROCESS.md` → Frozen until v2.0.


### mycycle.db

Полная копия SQLite-базы приложения. Перед экспортом выполняется `PRAGMA integrity_check`.

### diary_images/

Фотографии дневника в порядке записей БД. Имена: `0.jpg`, `1.png`, …  
При восстановлении пути в БД пересоздаются под новое устройство.

## Legacy Backup v1 (до 1.7.5)

Файл: `mycycle_backup_<timestamp>.db`

Содержит только SQLite. **Фото и настройки не включаются.**

При импорте приложение предупреждает пользователя.

## Восстановление

1. Проверка `manifest.json` и `backupVersion`
2. Проверка целостности `mycycle.db`
3. Резервная копия текущих данных (откат)
4. Замена БД → очистка фото → копирование из архива → обновление путей
5. Восстановление `settings.json`
6. При любой ошибке — полный откат

## Версии схемы БД

| Версия | Изменения |
|--------|-----------|
| 1 | Базовые таблицы |
| 2 | `wellbeing.intimacy` |
| 3 | `wellbeing.pms_symptoms` |
| 4 | `important_dates` |
| 5 | `diary.is_favorite`, `diary_images` |
