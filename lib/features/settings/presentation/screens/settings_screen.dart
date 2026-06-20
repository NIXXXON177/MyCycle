import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mycycle/core/backup/backup_manifest.dart';
import 'package:mycycle/core/providers/app_providers.dart';
import 'package:mycycle/core/router/app_router.dart';
import 'package:mycycle/shared/widgets/app_card.dart';
import 'package:mycycle/shared/widgets/update_checker.dart';
import 'package:package_info_plus/package_info_plus.dart';
/// Экран настроек приложения.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  PackageInfo? _packageInfo;
  bool _checkingUpdate = false;
  int _versionTapCount = 0;
  bool _generatingStressData = false;
  bool _devModeUnlocked = false;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
    Future.microtask(() {
      final unlocked = ref.read(settingsServiceProvider).developerModeUnlocked;
      if (unlocked && mounted) setState(() => _devModeUnlocked = true);
    });
  }

  Future<void> _loadPackageInfo() async {
    final info = await ref.read(updateServiceProvider).currentPackageInfo();
    if (mounted) setState(() => _packageInfo = info);
  }

  @override
  Widget build(BuildContext context) {
    final security = ref.watch(securityProvider);
    final themeMode = ref.watch(themeModeProvider);
    final devMode = _devModeUnlocked;
    final versionLabel = _packageInfo == null
        ? 'Загрузка...'
        : '${_packageInfo!.version} (${_packageInfo!.buildNumber})';

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionTitle('Тема'),
          AppCard(
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: const Text('Светлая'),
                  value: ThemeMode.light,
                  groupValue: themeMode,
                  onChanged: (v) => _setTheme(ref, v!),
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Тёмная'),
                  value: ThemeMode.dark,
                  groupValue: themeMode,
                  onChanged: (v) => _setTheme(ref, v!),
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Системная'),
                  value: ThemeMode.system,
                  groupValue: themeMode,
                  onChanged: (v) => _setTheme(ref, v!),
                ),
              ],
            ),
          ),
          const SectionTitle('Безопасность'),
          AppCard(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('PIN-код'),
                  subtitle: Text(security.pinEnabled ? 'Включён' : 'Выключен'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showPinDialog(context, ref),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.fingerprint),
                  title: const Text('Вход по биометрии'),
                  subtitle: Text(
                    security.pinEnabled
                        ? 'Отпечаток или лицо вместо PIN'
                        : 'Сначала включите PIN-код',
                  ),
                  value: security.pinEnabled && security.biometricEnabled,
                  onChanged: security.pinEnabled ? _toggleBiometric : null,
                ),
              ],
            ),
          ),
          const SectionTitle('Данные'),
          AppCard(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.archive_outlined),
                  title: const Text('Экспорт резервной копии'),
                  subtitle: const Text(
                    'ZIP: база, фото, настройки (Backup v2)',
                  ),
                  onTap: () => _export(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.unarchive_outlined),
                  title: const Text('Восстановить из копии'),
                  subtitle: const Text('ZIP или старый файл .db'),
                  onTap: () => _showImportOptions(context, ref),
                ),
              ],
            ),
          ),
          if (devMode) ...[
            const SectionTitle('Режим разработчика'),
            AppCard(
              child: ListTile(
                leading: _generatingStressData
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.science_outlined),
                title: const Text('Сгенерировать тестовые данные'),
                subtitle: const Text(
                  '1000 дневник · 500 самочувствие · 300 фото · 200 хотелок',
                ),
                onTap: _generatingStressData
                    ? null
                    : () => _generateStressData(context, ref),
              ),
            ),
          ],
          const SectionTitle('Приложение'),
          AppCard(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Версия'),
                  subtitle: Text(versionLabel),
                  onTap: () => _onVersionTap(ref),
                ),
                ListTile(
                  leading: _checkingUpdate
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.system_update),
                  title: const Text('Проверить обновления'),
                  subtitle: const Text(
                    'С GitHub — установка поверх, данные сохранятся',
                  ),
                  onTap: _checkingUpdate ? null : _checkForUpdate,
                ),
              ],
            ),
          ),
          const SectionTitle('Уведомления'),
          AppCard(
            child: ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Напоминания'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.reminders),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkForUpdate() async {
    setState(() => _checkingUpdate = true);

    try {
      final update =
          await ref.read(updateServiceProvider).checkForUpdate();

      if (!mounted) return;

      if (update == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('У вас установлена последняя версия')),
        );
        return;
      }

      await showUpdateDialog(context, ref, update);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _checkingUpdate = false);
    }
  }

  Future<void> _setTheme(WidgetRef ref, ThemeMode mode) async {
    await ref.read(settingsServiceProvider).setThemeMode(mode);
    ref.read(themeModeProvider.notifier).state = mode;
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      final biometric = ref.read(biometricServiceProvider);
      if (!await biometric.isAvailable()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Биометрия недоступна или не настроена на телефоне'),
            ),
          );
        }
        return;
      }
      final confirmed = await biometric.authenticate();
      if (!confirmed) return;
    }
    await ref.read(securityProvider.notifier).setBiometricEnabled(value);
  }

  Future<void> _showPinDialog(BuildContext context, WidgetRef ref) async {
    final security = ref.read(securityProvider);
    final controller = TextEditingController();
    var enabled = security.pinEnabled;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('PIN-код'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Включить PIN'),
                value: enabled,
                onChanged: (v) => setDialogState(() => enabled = v),
              ),
              if (enabled)
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: '4-значный PIN',
                  ),
                ),
            ],
          ),
          actions: [
            if (security.pinEnabled)
              TextButton(
                onPressed: () async {
                  await ref.read(securityProvider.notifier).disablePin();
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Отключить'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () async {
                if (enabled) {
                  if (controller.text.length != 4) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('PIN должен содержать 4 цифры'),
                        ),
                      );
                    }
                    return;
                  }
                  await ref
                      .read(securityProvider.notifier)
                      .enablePin(controller.text);
                } else {
                  await ref.read(securityProvider.notifier).disablePin();
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onVersionTap(WidgetRef ref) async {
    _versionTapCount++;
    if (_versionTapCount >= 7) {
      await ref.read(settingsServiceProvider).setDeveloperModeUnlocked(true);
      if (mounted) {
        setState(() {
          _versionTapCount = 0;
          _devModeUnlocked = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Режим разработчика включён')),
        );
      }
    }
  }

  Future<void> _generateStressData(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Тестовые данные'),
        content: const Text(
          'Будет добавлено много записей для проверки производительности. '
          'Продолжить?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Сгенерировать'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _generatingStressData = true);
    try {
      await ref.read(stressTestSeederProvider).generate();
      invalidateAllData(ref);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Тестовые данные добавлены')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generatingStressData = false);
    }
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    try {
      final preview = await ref.read(backupServiceProvider).previewExport();
      if (!context.mounted) return;

      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Резервная копия'),
          content: Text(
            'Размер резервной копии: ${preview.formattedSize}\n'
            'Фотографий: ${preview.photos}\n'
            'Записей дневника: ${preview.diaryEntries}\n'
            'Записей самочувствия: ${preview.wellbeingEntries}\n'
            'Циклов: ${preview.cycles}\n\n'
            'Временно потребуется ~${preview.formattedTemporarySpace} '
            'свободного места.\n\n'
            'Будет сохранён ZIP-архив с базой, фото и настройками.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Экспортировать'),
            ),
          ],
        ),
      );
      if (proceed != true || !context.mounted) return;

      final info = _packageInfo ??
          await ref.read(updateServiceProvider).currentPackageInfo();
      final path = await ref.read(backupServiceProvider).exportBackup(
            appVersion: info.version,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              path != null ? 'Сохранено: $path' : 'Экспорт отменён',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_backupErrorMessage(e, 'Не удалось сохранить'))),
        );
      }
    }
  }

  String _backupErrorMessage(Object error, String fallbackPrefix) {
    if (error is BackupException) return error.message;
    return '$fallbackPrefix: $error';
  }

  Future<void> _showImportOptions(BuildContext context, WidgetRef ref) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: const Text('Полная копия (.zip)'),
              subtitle: const Text('База, фото и настройки'),
              onTap: () => Navigator.pop(context, 'zip'),
            ),
            ListTile(
              leading: const Icon(Icons.storage_outlined),
              title: const Text('Старый формат (.db)'),
              subtitle: const Text('Только база данных'),
              onTap: () => Navigator.pop(context, 'db'),
            ),
          ],
        ),
      ),
    );

    if (choice == 'zip') {
      await _importZip(context, ref);
    } else if (choice == 'db') {
      await _importLegacy(context, ref);
    }
  }

  Future<void> _importZip(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Восстановление'),
        content: const Text(
          'Текущие данные будут заменены содержимым резервной копии. '
          'При ошибке восстановления ваши данные останутся без изменений.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Восстановить'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final result =
          await ref.read(backupServiceProvider).importBackupZip();
      await _afterImport(context, ref, result, legacy: false);
    } catch (e) {
      invalidateAllData(ref);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_backupErrorMessage(e, 'Не удалось восстановить'))),
        );
      }
    }
  }

  Future<void> _importLegacy(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Старый формат'),
        content: const Text(
          'Обнаружен архив старого формата.\n'
          'Фотографии и настройки не будут восстановлены.\n\n'
          'Продолжить?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Продолжить'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final result =
          await ref.read(backupServiceProvider).importLegacyDatabase();
      await _afterImport(context, ref, result, legacy: true);
    } catch (e) {
      invalidateAllData(ref);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_backupErrorMessage(e, 'Не удалось импортировать'))),
        );
      }
    }
  }

  Future<void> _afterImport(
    BuildContext context,
    WidgetRef ref,
    BackupImportResult result, {
    required bool legacy,
  }) async {
    if (result == BackupImportResult.cancelled) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Восстановление отменено')),
        );
      }
      return;
    }

    invalidateAllData(ref);
    ref.invalidate(securityProvider);
    ref.read(themeModeProvider.notifier).state =
        ref.read(settingsServiceProvider).themeMode;

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            legacy
                ? 'База восстановлена (старый формат)'
                : 'Данные полностью восстановлены',
          ),
        ),
      );
      if (!legacy && result == BackupImportResult.success) {
        final pinOn = ref.read(settingsServiceProvider).pinEnabled;
        if (pinOn) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Биометрическую аутентификацию необходимо настроить заново.',
              ),
            ),
          );
        }
      }
    }
  }
}
