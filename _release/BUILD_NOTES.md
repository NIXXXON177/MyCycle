# Локальная сборка Florea 1.8.1 (2026-06-23)

Коммит: b9f1aa3 (release/1.7.5-rc1)
Пакет: com.florea.app

| Файл | Размер | SHA-256 |
|------|--------|---------|
| Florea.apk | 59.89 MB | 60824E5CA431FEF2354D36D3189D795ED39F1BE7F2749DB2A786157398096CAD |

## Опубликовать обновление на GitHub

```powershell
cd d:\Site-portfolio\MyCycle
git checkout main
git merge release/1.7.5-rc1
git push origin main
```

CI соберёт подписанный APK и создаст Release с `Florea.apk` + `manifest.json`.

## Установка на телефон

1. Скопировать `d:\Site-portfolio\Florea.apk` на устройство
2. Установить (если была **MyCycle** — это **новое** приложение, данные через Backup v2)
3. Если уже **Florea 1.8.0** — установить поверх

## Сайт портфолио

```powershell
cd d:\Site-portfolio
git push origin main
```
