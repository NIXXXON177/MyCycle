import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mycycle/core/providers/app_providers.dart';
import 'package:mycycle/core/router/app_router.dart';
import 'package:mycycle/core/security/security_controller.dart';
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

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await ref.read(updateServiceProvider).currentPackageInfo();
    if (mounted) setState(() => _packageInfo = info);
  }

  @override
  Widget build(BuildContext context) {
    final security = ref.watch(securityProvider);
    final themeMode = ref.watch(themeModeProvider);
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
                  leading: const Icon(Icons.upload_file),
                  title: const Text('Экспорт базы данных'),
                  subtitle: const Text('Сохранить резервную копию'),
                  onTap: () => _export(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('Импорт базы данных'),
                  subtitle: const Text('Восстановить из файла'),
                  onTap: () => _import(context, ref),
                ),
              ],
            ),
          ),
          const SectionTitle('Приложение'),
          AppCard(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Версия'),
                  subtitle: Text(versionLabel),
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
          const SectionTitle('Уведомления'),          AppCard(
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

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    try {
      final path = await ref.read(backupServiceProvider).exportDatabase();
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
          SnackBar(content: Text('Не удалось сохранить: $e')),
        );
      }
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Импорт данных'),
        content: const Text(
          'Текущие данные будут заменены. Продолжить?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Импорт'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final success =
          await ref.read(backupServiceProvider).importDatabase();
      invalidateAllData(ref);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Данные восстановлены' : 'Импорт отменён'),
          ),
        );
      }
    } catch (e) {
      invalidateAllData(ref);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось импортировать: $e')),
        );
      }
    }
  }
}
