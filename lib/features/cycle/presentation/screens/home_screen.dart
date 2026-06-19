import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mycycle/core/constants/app_colors.dart';
import 'package:mycycle/core/providers/app_providers.dart';
import 'package:mycycle/core/router/app_router.dart';
import 'package:mycycle/core/utils/date_utils.dart';
import 'package:mycycle/features/cycle/domain/entities/cycle.dart';
import 'package:mycycle/features/cycle/domain/entities/cycle_prediction.dart';
import 'package:mycycle/shared/widgets/app_card.dart';

/// Главный экран с обзором цикла.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final predictionAsync = ref.watch(cyclePredictionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MyCycle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () => _showMenu(context),
          ),
        ],
      ),
      body: predictionAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: 'Не удалось загрузить данные',
          onRetry: () => ref.invalidate(cyclePredictionProvider),
        ),
        data: (prediction) => _HomeContent(prediction: prediction),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: const Text('Закономерности'),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.patterns);
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Для парня'),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.partner);
              },
            ),
            ListTile(
              leading: const Icon(Icons.volunteer_activism),
              title: const Text('Поддержка'),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.support);
              },
            ),
            ListTile(
              leading: const Icon(Icons.card_giftcard),
              title: const Text('Мои хотелки'),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.wishes);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Настройки'),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.settings);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.prediction});

  final CyclePrediction prediction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _PeriodQuickAction(),
        const SizedBox(height: 16),
        AppCard(
          color: AppColors.pink.withValues(alpha: 0.3),
          child: Column(
            children: [
              Text(
                'День ${prediction.currentCycleDay}',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.pinkDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                prediction.phase.label,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                prediction.phase.description,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: AppCard(
                child: Column(
                  children: [
                    const Icon(Icons.water_drop, color: AppColors.period),
                    const SizedBox(height: 8),
                    Text(
                      prediction.daysUntilNextPeriod != null
                          ? '${prediction.daysUntilNextPeriod}'
                          : '—',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const Text('дней до месячных'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppCard(
                child: Column(
                  children: [
                    const Icon(Icons.loop, color: AppColors.purpleDark),
                    const SizedBox(height: 8),
                    Text(
                      '${prediction.averageCycleLength}',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const Text('средний цикл'),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const SectionTitle('Ближайшие события'),
        if (prediction.nextPeriodDate != null)
          AppCard(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.period,
                child: Text('🔴', style: TextStyle(fontSize: 16)),
              ),
              title: const Text('Следующие месячные'),
              subtitle: Text(AppDateUtils.formatDate(prediction.nextPeriodDate!)),
            ),
          ),
        if (prediction.ovulationDate != null) ...[
          const SizedBox(height: 8),
          AppCard(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.ovulation,
                child: Text('🟣', style: TextStyle(fontSize: 16)),
              ),
              title: const Text('Овуляция'),
              subtitle: Text(AppDateUtils.formatDate(prediction.ovulationDate!)),
            ),
          ),
        ],
        if (prediction.fertileWindowStart != null &&
            prediction.fertileWindowEnd != null) ...[
          const SizedBox(height: 8),
          AppCard(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.fertile,
                child: Text('🟢', style: TextStyle(fontSize: 16)),
              ),
              title: const Text('Фертильное окно'),
              subtitle: Text(
                '${AppDateUtils.formatShortDate(prediction.fertileWindowStart!)} — '
                '${AppDateUtils.formatShortDate(prediction.fertileWindowEnd!)}',
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => context.push(AppRoutes.cycleHistory),
          icon: const Icon(Icons.history),
          label: const Text('История циклов'),
        ),
      ],
    );
  }
}

/// Карточка быстрой отметки начала/окончания месячных.
class _PeriodQuickAction extends ConsumerWidget {
  const _PeriodQuickAction();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cyclesAsync = ref.watch(cyclesProvider);
    return cyclesAsync.maybeWhen(
      data: (cycles) => _build(context, ref, cycles),
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _build(BuildContext context, WidgetRef ref, List<Cycle> cycles) {
    final ongoing = _ongoingCycle(cycles);
    final isOngoing = ongoing != null;

    return AppCard(
      color: AppColors.pink.withValues(alpha: 0.18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isOngoing ? 'Месячные идут' : 'Быстрая отметка',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => isOngoing
                ? _endPeriod(context, ref, ongoing)
                : _startPeriod(context, ref),
            icon: Icon(
              isOngoing ? Icons.stop_circle_outlined : Icons.water_drop,
            ),
            label: Text(
              isOngoing
                  ? 'Отметить окончание'
                  : 'Отметить начало месячных',
            ),
          ),
        ],
      ),
    );
  }

  /// Возвращает незавершённый недавний цикл (месячные ещё идут), иначе null.
  Cycle? _ongoingCycle(List<Cycle> cycles) {
    Cycle? latest;
    for (final c in cycles) {
      if (latest == null || c.startDate.isAfter(latest.startDate)) {
        latest = c;
      }
    }
    if (latest == null || latest.endDate != null) return null;

    final daysSince = AppDateUtils.daysBetween(latest.startDate, DateTime.now());
    // Запись старше 12 дней без окончания считаем завершённой давно.
    if (daysSince < 0 || daysSince > 12) return null;
    return latest;
  }

  Future<void> _startPeriod(BuildContext context, WidgetRef ref) async {
    final today = AppDateUtils.dateOnly(DateTime.now());
    await ref.read(cycleRepositoryProvider).addCycle(startDate: today);
    await _afterChange(ref);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Отмечено начало месячных')),
      );
    }
  }

  Future<void> _endPeriod(
    BuildContext context,
    WidgetRef ref,
    Cycle cycle,
  ) async {
    final today = AppDateUtils.dateOnly(DateTime.now());
    await ref
        .read(cycleRepositoryProvider)
        .updateCycle(cycle.copyWith(endDate: today));
    await _afterChange(ref);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Отмечено окончание месячных')),
      );
    }
  }

  Future<void> _afterChange(WidgetRef ref) async {
    invalidateAllData(ref);
    final settings = ref.read(settingsServiceProvider);
    final prediction = await ref.read(cycleRepositoryProvider).getPrediction();
    await ref.read(notificationServiceProvider).scheduleReminders(
          settings: settings.reminderSettings,
          prediction: prediction,
        );
  }
}
