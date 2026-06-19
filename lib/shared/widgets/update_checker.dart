import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mycycle/core/constants/update_config.dart';
import 'package:mycycle/core/providers/app_providers.dart';
import 'package:mycycle/core/services/update_service.dart';

/// Проверяет обновления при запуске и показывает диалог.
class UpdateChecker extends ConsumerStatefulWidget {
  const UpdateChecker({super.key, required this.child});

  final Widget? child;

  @override
  ConsumerState<UpdateChecker> createState() => _UpdateCheckerState();
}

class _UpdateCheckerState extends ConsumerState<UpdateChecker> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    if (UpdateConfig.isEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
    }
  }

  Future<void> _checkForUpdate() async {
    if (_checked || !mounted) return;
    _checked = true;

    try {
      final update = await ref.read(updateServiceProvider).checkForUpdate();
      if (update == null || !mounted) return;
      await showUpdateDialog(context, ref, update);
    } catch (e) {
      debugPrint('Auto update check failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child ?? const SizedBox.shrink();
}

Future<void> showUpdateDialog(
  BuildContext context,
  WidgetRef ref,
  AppUpdateInfo update,
) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Доступно обновление'),
      content: Text(
        'Версия ${update.versionName} (сборка ${update.versionCode})\n\n'
        '${update.notes ?? 'Установить обновление? Все данные сохранятся.'}',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Позже'),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.pop(dialogContext);
            if (!context.mounted) return;

            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const AlertDialog(
                content: Row(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 20),
                    Expanded(child: Text('Скачивание обновления...')),
                  ],
                ),
              ),
            );

            try {
              await ref.read(updateServiceProvider).downloadAndInstall(update);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ошибка обновления: $e')),
                );
              }
            } finally {
              if (context.mounted) {
                Navigator.of(context, rootNavigator: true).pop();
              }
            }
          },
          child: const Text('Обновить'),
        ),
      ],
    ),
  );
}
