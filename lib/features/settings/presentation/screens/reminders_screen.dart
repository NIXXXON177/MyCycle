import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:florea/core/providers/app_providers.dart';
import 'package:florea/core/services/settings_service.dart';
import 'package:florea/shared/widgets/app_card.dart';

/// Экран настройки локальных напоминаний.
class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  ReminderSettings? _settings;

  @override
  Widget build(BuildContext context) {
    _settings ??= ref.read(settingsServiceProvider).reminderSettings;
    final settings = _settings!;

    return Scaffold(
      appBar: AppBar(title: const Text('Напоминания')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Приближение месячных'),
                  subtitle: const Text('За 2 дня до начала'),
                  value: settings.periodApproaching,
                  onChanged: (v) => setState(
                    () => _settings = settings.copyWith(periodApproaching: v),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Начало месячных'),
                  value: settings.periodStart,
                  onChanged: (v) => setState(
                    () => _settings = settings.copyWith(periodStart: v),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Ежедневная отметка самочувствия'),
                  value: settings.dailyWellbeing,
                  onChanged: (v) => setState(
                    () => _settings = settings.copyWith(dailyWellbeing: v),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Время уведомлений'),
              subtitle: Text(
                '${settings.hour.toString().padLeft(2, '0')}:'
                '${settings.minute.toString().padLeft(2, '0')}',
              ),
              onTap: _pickTime,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _save,
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime() async {
    final settings = _settings!;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: settings.hour, minute: settings.minute),
    );
    if (time != null) {
      setState(() => _settings = settings.copyWith(
            hour: time.hour,
            minute: time.minute,
          ));
    }
  }

  Future<void> _save() async {
    final settings = _settings!;
    await ref.read(notificationServiceProvider).requestPermission();
    await ref.read(settingsServiceProvider).saveReminderSettings(settings);

    final prediction = await ref.read(cycleRepositoryProvider).getPrediction();
    await ref.read(notificationServiceProvider).scheduleReminders(
          settings: settings,
          prediction: prediction,
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Напоминания настроены')),
      );
    }
  }
}
