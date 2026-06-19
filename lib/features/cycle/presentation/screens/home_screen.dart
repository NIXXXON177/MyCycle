import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mycycle/core/constants/app_colors.dart';
import 'package:mycycle/core/providers/app_providers.dart';
import 'package:mycycle/core/router/app_router.dart';
import 'package:mycycle/core/utils/date_utils.dart';
import 'package:mycycle/features/cycle/domain/entities/cycle.dart';
import 'package:mycycle/features/cycle/domain/entities/cycle_prediction.dart';
import 'package:mycycle/core/enums/mood_level.dart';
import 'package:mycycle/core/utils/prediction_accuracy.dart';
import 'package:mycycle/core/utils/wellbeing_index.dart';
import 'package:mycycle/features/wellbeing/domain/entities/wellbeing_entry.dart';
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

class _HomeContent extends ConsumerWidget {
  const _HomeContent({required this.prediction});

  final CyclePrediction prediction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final today = AppDateUtils.dateOnly(DateTime.now());
    final wellbeingAsync = ref.watch(wellbeingByDateProvider(today));
    final wellbeingListAsync = ref.watch(wellbeingListProvider);
    final cyclesAsync = ref.watch(cyclesProvider);

    final accuracy = cyclesAsync.maybeWhen(
      data: (cycles) {
        final regularity =
            ref.read(cycleRepositoryProvider).cycleRegularity(cycles);
        return PredictionAccuracy.evaluate(cycles, regularity);
      },
      orElse: () => PredictionAccuracyLevel.insufficient,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _PeriodQuickAction(),
        const SizedBox(height: 16),
        _TodayCard(
          prediction: prediction,
          todayEntry: wellbeingAsync.valueOrNull,
          accuracy: accuracy,
        ),
        const SizedBox(height: 16),
        _IndexForecastCard(
          todayEntry: wellbeingAsync.valueOrNull,
          allWellbeing: wellbeingListAsync.valueOrNull ?? const [],
        ),
        const SizedBox(height: 16),
        const _QuickMoodCheckIn(),
        const SizedBox(height: 16),
        cyclesAsync.maybeWhen(
          data: (cycles) {
            final wellbeing = wellbeingListAsync.valueOrNull ?? const [];
            if (cycles.isEmpty && wellbeing.isEmpty) {
              return const SizedBox.shrink();
            }
            return _CycleInNumbersCard(
              cycles: cycles,
              wellbeing: wellbeing,
              prediction: prediction,
            );
          },
          orElse: () => const SizedBox.shrink(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: AppCard(
                child: Column(
                  children: [
                    Icon(
                      Icons.insights_outlined,
                      color: _accuracyColor(accuracy),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      accuracy.label,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Text('точность прогноза'),
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

  Color _accuracyColor(PredictionAccuracyLevel level) {
    return switch (level) {
      PredictionAccuracyLevel.high => Colors.green.shade700,
      PredictionAccuracyLevel.medium => Colors.orange.shade700,
      PredictionAccuracyLevel.low => Colors.red.shade400,
      PredictionAccuracyLevel.insufficient => AppColors.gray,
    };
  }
}

/// Карточка прогноза индекса самочувствия на сегодня.
class _IndexForecastCard extends StatelessWidget {
  const _IndexForecastCard({
    required this.todayEntry,
    required this.allWellbeing,
  });

  final WellbeingEntry? todayEntry;
  final List<WellbeingEntry> allWellbeing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final comparison = WellbeingIndexCalculator.compareToday(
      today: todayEntry,
      all: allWellbeing,
    );

    if (!comparison.hasToday) {
      return AppCard(
        color: AppColors.purple.withValues(alpha: 0.15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Индекс самочувствия',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.purpleDark,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Отметь самочувствие, чтобы увидеть индекс'),
            const SizedBox(height: 6),
            Text(
              WellbeingIndexCalculator.disclaimer,
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.gray),
            ),
          ],
        ),
      );
    }

    final score = comparison.todayScore;
    final level = WellbeingIndexLevel.labelFor(score);

    return AppCard(
      color: AppColors.purple.withValues(alpha: 0.15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Сегодня индекс самочувствия',
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.purpleDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$score',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.purpleDark,
                ),
              ),
              Text(
                '/100',
                style: theme.textTheme.titleMedium?.copyWith(color: AppColors.gray),
              ),
              const Spacer(),
              if (comparison.trendLabel != null)
                Text(
                  comparison.trendLabel!,
                  style: theme.textTheme.titleSmall,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$level состояние',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            WellbeingIndexCalculator.disclaimer,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.gray),
          ),
        ],
      ),
    );
  }
}

/// Сводка цикла в цифрах без перехода в статистику.
class _CycleInNumbersCard extends ConsumerWidget {
  const _CycleInNumbersCard({
    required this.cycles,
    required this.wellbeing,
    required this.prediction,
  });

  final List<Cycle> cycles;
  final List<WellbeingEntry> wellbeing;
  final CyclePrediction prediction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final repo = ref.read(cycleRepositoryProvider);
    final calculator = ref.read(cycleCalculatorProvider);
    final avgCycle = repo.averageCycleLength(cycles);
    final regularity = repo.cycleRegularity(cycles);
    final patterns = SmartPatternsAnalyzer.analyze(
      cycles: cycles,
      wellbeing: wellbeing,
      averageCycleLength: avgCycle,
      averagePeriodLength: repo.averagePeriodLength(cycles),
      calculator: calculator,
    );

    final regularityLabel = regularity < 2
        ? 'Очень регулярный (±${regularity.toStringAsFixed(1)} дн.)'
        : regularity < 4
            ? 'Умеренно регулярный (±${regularity.toStringAsFixed(1)} дн.)'
            : 'Нерегулярный (±${regularity.toStringAsFixed(1)} дн.)';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Твой цикл в цифрах',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _NumberRow(label: 'Средний цикл', value: '$avgCycle дн.'),
          _NumberRow(label: 'Регулярность', value: regularityLabel),
          if (patterns.bestDaysRange != null)
            _NumberRow(
              label: 'Лучший день',
              value: '${patterns.bestDaysRange} день цикла',
            ),
          if (patterns.hardestDaysRange != null)
            _NumberRow(
              label: 'Сложный день',
              value: '${patterns.hardestDaysRange} день цикла',
            ),
          if (prediction.currentCycleDay > 0)
            _NumberRow(
              label: 'Сейчас',
              value: 'День ${prediction.currentCycleDay}',
            ),
        ],
      ),
    );
  }
}

class _NumberRow extends StatelessWidget {
  const _NumberRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.gray,
                  ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Карточка «Сегодня» — сводка дня в одном месте.
class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.prediction,
    required this.todayEntry,
    required this.accuracy,
  });

  final CyclePrediction prediction;
  final WellbeingEntry? todayEntry;
  final PredictionAccuracyLevel accuracy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cycleDay = prediction.currentCycleDay;
    final daysUntil = prediction.daysUntilNextPeriod;

    String periodLine;
    if (daysUntil == null) {
      periodLine = 'Отметь цикл для прогноза';
    } else if (daysUntil > 0) {
      periodLine = 'До месячных $daysUntil дн.';
    } else if (daysUntil == 0) {
      periodLine = 'Месячные могут начаться сегодня';
    } else {
      periodLine = 'Сейчас идут месячные';
    }

    final moodLine = todayEntry != null
        ? 'Настроение: ${todayEntry!.mood.emoji} ${todayEntry!.mood.label}'
        : 'Настроение ещё не отмечено';

    return AppCard(
      color: AppColors.pink.withValues(alpha: 0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Сегодня',
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.pinkDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (cycleDay > 0)
            Text(
              'День $cycleDay цикла · ${prediction.phase.label}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            )
          else
            Text(
              'Отметь начало месячных',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            prediction.phase.description,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          _TodayRow(icon: Icons.water_drop_outlined, text: periodLine),
          const SizedBox(height: 6),
          _TodayRow(icon: Icons.mood_outlined, text: moodLine),
          const SizedBox(height: 10),
          Chip(
            visualDensity: VisualDensity.compact,
            avatar: Icon(Icons.insights_outlined, size: 16, color: _chipColor()),
            label: Text('Прогноз: ${accuracy.label}'),
          ),
        ],
      ),
    );
  }

  Color _chipColor() {
    return switch (accuracy) {
      PredictionAccuracyLevel.high => Colors.green.shade700,
      PredictionAccuracyLevel.medium => Colors.orange.shade700,
      PredictionAccuracyLevel.low => Colors.red.shade400,
      PredictionAccuracyLevel.insufficient => AppColors.gray,
    };
  }
}

class _TodayRow extends StatelessWidget {
  const _TodayRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.pinkDark),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }
}

/// Быстрый чек-ин настроения одним нажатием.
class _QuickMoodCheckIn extends ConsumerStatefulWidget {
  const _QuickMoodCheckIn();

  @override
  ConsumerState<_QuickMoodCheckIn> createState() =>
      _QuickMoodCheckInState();
}

class _QuickMoodCheckInState extends ConsumerState<_QuickMoodCheckIn> {
  bool _saving = false;

  static const _options = [
    (MoodLevel.good, '🙂', 'Хорошо'),
    (MoodLevel.normal, '😐', 'Норм'),
    (MoodLevel.bad, '😔', 'Плохо'),
  ];

  @override
  Widget build(BuildContext context) {
    final today = AppDateUtils.dateOnly(DateTime.now());
    final entry = ref.watch(wellbeingByDateProvider(today)).valueOrNull;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Как настроение?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (entry != null) ...[
            const SizedBox(height: 4),
            Text(
              'Сейчас: ${entry.mood.emoji} ${entry.mood.label}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: _options.map((option) {
              final (mood, emoji, label) = option;
              final selected = entry?.mood == mood;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilledButton.tonal(
                    onPressed: _saving ? null : () => _saveMood(mood),
                    style: FilledButton.styleFrom(
                      backgroundColor: selected
                          ? AppColors.pink.withValues(alpha: 0.4)
                          : null,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Column(
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 28)),
                        const SizedBox(height: 4),
                        Text(label, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _saveMood(MoodLevel mood) async {
    setState(() => _saving = true);
    final today = AppDateUtils.dateOnly(DateTime.now());
    await ref.read(wellbeingRepositoryProvider).setQuickMood(today, mood);
    invalidateAllData(ref);
    ref.invalidate(wellbeingByDateProvider(today));
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Настроение: ${mood.emoji} ${mood.label}')),
      );
    }
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
