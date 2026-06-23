import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:florea/core/providers/app_providers.dart';
import 'package:florea/core/utils/date_utils.dart';
import 'package:florea/features/cycle/domain/entities/cycle.dart';
import 'package:florea/shared/widgets/app_card.dart';

/// Экран истории и редактирования циклов.
class CycleHistoryScreen extends ConsumerStatefulWidget {
  const CycleHistoryScreen({super.key});

  @override
  ConsumerState<CycleHistoryScreen> createState() =>
      _CycleHistoryScreenState();
}

class _CycleHistoryScreenState extends ConsumerState<CycleHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final cyclesAsync = ref.watch(cyclesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('История циклов')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCycleDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
      body: cyclesAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: 'Ошибка загрузки',
          onRetry: () => ref.invalidate(cyclesProvider),
        ),
        data: (cycles) {
          if (cycles.isEmpty) {
            return const EmptyView(
              message: 'Пока нет записей о циклах.\nДобавь первую!',
              icon: Icons.water_drop_outlined,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cycles.length,
            itemBuilder: (context, index) {
              final cycle = cycles[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  child: ListTile(
                    title: Text(
                      AppDateUtils.formatDate(cycle.startDate),
                    ),
                    subtitle: Text(
                      cycle.endDate != null
                          ? 'До ${AppDateUtils.formatDate(cycle.endDate!)} '
                              '(${cycle.periodLength} дн.)'
                          : 'Окончание не указано',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showCycleDialog(context, cycle: cycle);
                        } else if (value == 'delete') {
                          _deleteCycle(cycle);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Редактировать'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Удалить'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showCycleDialog(BuildContext context, {Cycle? cycle}) async {
    var startDate = cycle?.startDate ?? DateTime.now();
    DateTime? endDate = cycle?.endDate;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(cycle == null ? 'Новый цикл' : 'Редактировать'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Начало'),
                subtitle: Text(AppDateUtils.formatDate(startDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: startDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    locale: const Locale('ru'),
                  );
                  if (picked != null) {
                    setDialogState(() => startDate = picked);
                  }
                },
              ),
              ListTile(
                title: const Text('Окончание'),
                subtitle: Text(
                  endDate != null
                      ? AppDateUtils.formatDate(endDate!)
                      : 'Не указано',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: endDate ?? startDate,
                    firstDate: startDate,
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                    locale: const Locale('ru'),
                  );
                  if (picked != null) {
                    setDialogState(() => endDate = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () async {
                final repo = ref.read(cycleRepositoryProvider);
                if (cycle == null) {
                  await repo.addCycle(
                    startDate: startDate,
                    endDate: endDate,
                  );
                } else {
                  await repo.updateCycle(
                    cycle.copyWith(
                      startDate: startDate,
                      endDate: endDate,
                    ),
                  );
                }
                invalidateAllData(ref);
                await _rescheduleNotifications();
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCycle(Cycle cycle) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить запись?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(cycleRepositoryProvider).deleteCycle(cycle.id);
      invalidateAllData(ref);
      await _rescheduleNotifications();
    }
  }

  Future<void> _rescheduleNotifications() async {
    final settings = ref.read(settingsServiceProvider);
    final prediction = await ref.read(cycleRepositoryProvider).getPrediction();
    await ref.read(notificationServiceProvider).scheduleReminders(
          settings: settings.reminderSettings,
          prediction: prediction,
        );
  }
}
