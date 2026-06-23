import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:florea/core/constants/app_colors.dart';
import 'package:florea/core/enums/intimacy_type.dart';
import 'package:florea/core/enums/pain_level.dart';
import 'package:florea/core/providers/app_providers.dart';
import 'package:florea/core/router/app_router.dart';
import 'package:florea/core/utils/date_utils.dart';
import 'package:florea/features/cycle/data/repositories/cycle_repository.dart';
import 'package:florea/features/cycle/domain/entities/cycle.dart';
import 'package:florea/features/cycle/domain/entities/cycle_prediction.dart';
import 'package:florea/features/wellbeing/domain/entities/wellbeing_entry.dart';
import 'package:florea/shared/widgets/app_card.dart';
import 'package:table_calendar/table_calendar.dart';

/// Календарь цикла с цветовой маркировкой дней.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarFormat _format = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final cyclesAsync = ref.watch(cyclesProvider);
    final predictionAsync = ref.watch(cyclePredictionProvider);
    final wellbeingAsync = ref.watch(wellbeingListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Календарь')),
      body: cyclesAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: 'Ошибка загрузки',
          onRetry: () => ref.invalidate(cyclesProvider),
        ),
        data: (cycles) => predictionAsync.when(
          loading: () => const LoadingView(),
          error: (e, _) => const ErrorView(message: 'Ошибка прогноза'),
          data: (prediction) => wellbeingAsync.when(
            loading: () => const LoadingView(),
            error: (e, _) => _buildCalendar(cycles, prediction, []),
            data: (wellbeing) =>
                _buildCalendar(cycles, prediction, wellbeing),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar(
    List<Cycle> cycles,
    CyclePrediction prediction,
    List<WellbeingEntry> wellbeing,
  ) {
    final repo = ref.read(cycleRepositoryProvider);

    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime(2020),
          lastDay: DateTime.now().add(const Duration(days: 365)),
          focusedDay: _focusedDay,
          calendarFormat: _format,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          locale: 'ru_RU',
          startingDayOfWeek: StartingDayOfWeek.monday,
          onDaySelected: (selected, focused) {
            setState(() {
              _selectedDay = selected;
              _focusedDay = focused;
            });
            _showDayCard(selected, cycles, prediction, wellbeing);
          },
          onFormatChanged: (format) => setState(() => _format = format),
          onPageChanged: (focused) => _focusedDay = focused,
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            selectedDecoration: const BoxDecoration(
              color: AppColors.pinkDark,
              shape: BoxShape.circle,
            ),
            markerDecoration: const BoxDecoration(
              color: AppColors.pinkDark,
              shape: BoxShape.circle,
            ),
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) {
              final color = _dayColor(day, cycles, prediction, repo);
              if (color == null) return null;
              return Container(
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      color: color == AppColors.normal
                          ? Theme.of(context).colorScheme.onSurface
                          : Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _LegendItem(color: AppColors.period, label: '🔴 Месячные'),
              _LegendItem(color: AppColors.ovulation, label: '🟣 Овуляция'),
              _LegendItem(color: AppColors.fertile, label: '🟢 Фертильное'),
              _LegendItem(color: AppColors.normal, label: '⚪ Обычный'),
            ],
          ),
        ),
      ],
    );
  }

  Color? _dayColor(
    DateTime day,
    List<Cycle> cycles,
    CyclePrediction prediction,
    dynamic repo,
  ) {
    if (repo.isPeriodDay(cycles, day)) return AppColors.period;
    if (repo.isOvulationDay(prediction, day)) return AppColors.ovulation;
    if (repo.isFertileDay(prediction, day)) return AppColors.fertile;
    return null;
  }

  void _showDayCard(
    DateTime day,
    List<Cycle> cycles,
    CyclePrediction prediction,
    List<WellbeingEntry> wellbeing,
  ) {
    final repo = ref.read(cycleRepositoryProvider);
    final entry = wellbeing.where(
      (w) => AppDateUtils.isSameDay(w.date, day),
    );
    final cycleDay = _cycleDayFor(day, cycles);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    AppDateUtils.formatDate(day),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (cycleDay != null)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: AppColors.pink.withValues(alpha: 0.3),
                    label: Text('День $cycleDay цикла'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (repo.isPeriodDay(cycles, day))
              const Chip(
                avatar: Text('🔴'),
                label: Text('Месячные'),
              ),
            if (repo.isOvulationDay(prediction, day))
              const Chip(
                avatar: Text('🟣'),
                label: Text('Овуляция'),
              ),
            if (repo.isFertileDay(prediction, day))
              const Chip(
                avatar: Text('🟢'),
                label: Text('Фертильное окно'),
              ),
            if (entry.isNotEmpty) ...[
              const SizedBox(height: 8),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.first.mood.emoji} ${entry.first.mood.label}',
                    ),
                    Text(
                      '${entry.first.energy.emoji} ${entry.first.energy.label}',
                    ),
                    if (entry.first.pain != PainLevel.none)
                      Text(
                        '${entry.first.pain.emoji} ${entry.first.pain.label}',
                      ),
                    if (entry.first.intimacy != IntimacyType.none)
                      Text(
                        '${entry.first.intimacy.emoji} ${entry.first.intimacy.label}',
                      ),
                    if (entry.first.pmsSymptoms.isNotEmpty)
                      Text(
                        entry.first.pmsSymptoms
                            .map((s) => '${s.emoji} ${s.label}')
                            .join(', '),
                      ),
                    if (entry.first.note != null)
                      Text(entry.first.note!),
                  ],
                ),
              ),
            ] else
              const Text('Самочувствие не отмечено'),
            const SizedBox(height: 12),
            Text(
              'Месячные',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ..._buildPeriodActions(
              sheetContext: sheetContext,
              day: day,
              cycles: cycles,
              repo: repo,
            ),
            const SizedBox(height: 12),
            Text(
              'Близость',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: IntimacyType.loggable.map((type) {
                final selected = entry.isNotEmpty &&
                    entry.first.intimacy == type;
                return FilterChip(
                  label: Text(
                    type == IntimacyType.none
                        ? type.label
                        : '${type.emoji} ${type.label}',
                  ),
                  selected: selected,
                  onSelected: (_) => _saveIntimacy(
                    sheetContext,
                    day,
                    type,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _openWellbeing(day);
                },
                icon: Icon(
                  entry.isEmpty ? Icons.add : Icons.edit_outlined,
                ),
                label: Text(
                  entry.isEmpty
                      ? 'Записать самочувствие'
                      : 'Изменить самочувствие',
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  List<Widget> _buildPeriodActions({
    required BuildContext sheetContext,
    required DateTime day,
    required List<Cycle> cycles,
    required CycleRepository repo,
  }) {
    final date = AppDateUtils.dateOnly(day);
    final today = AppDateUtils.dateOnly(DateTime.now());

    if (date.isAfter(today)) {
      return [
        Text(
          'Отметки доступны только за прошедшие дни',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ];
    }

    if (repo.isPeriodDay(cycles, day)) {
      return [
        const Text('Этот день уже отмечен как месячные'),
      ];
    }

    final ongoing = _ongoingCycleForEnd(cycles, date);
    final widgets = <Widget>[];

    if (ongoing != null) {
      widgets.add(
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _endPeriodOnDay(sheetContext, date, ongoing),
            icon: const Icon(Icons.stop_circle_outlined),
            label: const Text('Окончание в этот день'),
          ),
        ),
      );
    } else {
      widgets.add(
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _startPeriodOnDay(sheetContext, date),
            icon: const Icon(Icons.water_drop_outlined),
            label: const Text('Начало в этот день'),
          ),
        ),
      );
    }

    return widgets;
  }

  /// Незавершённый цикл, который можно закрыть в [day].
  Cycle? _ongoingCycleForEnd(List<Cycle> cycles, DateTime day) {
    final target = AppDateUtils.dateOnly(day);
    Cycle? best;
    for (final c in cycles) {
      final start = AppDateUtils.dateOnly(c.startDate);
      if (start.isAfter(target)) continue;
      if (c.endDate != null) continue;
      if (best == null || start.isAfter(AppDateUtils.dateOnly(best.startDate))) {
        best = c;
      }
    }
    return best;
  }

  Future<void> _startPeriodOnDay(
    BuildContext sheetContext,
    DateTime day,
  ) async {
    await ref.read(cycleRepositoryProvider).addCycle(startDate: day);
    await _afterCycleChange();
    if (!mounted || !sheetContext.mounted) return;
    Navigator.pop(sheetContext);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Начало месячных: ${AppDateUtils.formatDate(day)}',
        ),
      ),
    );
  }

  Future<void> _endPeriodOnDay(
    BuildContext sheetContext,
    DateTime day,
    Cycle cycle,
  ) async {
    await ref
        .read(cycleRepositoryProvider)
        .updateCycle(cycle.copyWith(endDate: day));
    await _afterCycleChange();
    if (!mounted || !sheetContext.mounted) return;
    Navigator.pop(sheetContext);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Окончание месячных: ${AppDateUtils.formatDate(day)}',
        ),
      ),
    );
  }

  Future<void> _afterCycleChange() async {
    invalidateAllData(ref);
    final settings = ref.read(settingsServiceProvider);
    final prediction = await ref.read(cycleRepositoryProvider).getPrediction();
    await ref.read(notificationServiceProvider).scheduleReminders(
          settings: settings.reminderSettings,
          prediction: prediction,
        );
  }

  /// Открывает экран самочувствия для конкретного дня.
  void _openWellbeing(DateTime day) {
    final date = AppDateUtils.dateOnly(day);
    context.push(
      '${AppRoutes.wellbeingDay}?date=${date.millisecondsSinceEpoch}',
    );
  }

  Future<void> _saveIntimacy(
    BuildContext sheetContext,
    DateTime day,
    IntimacyType intimacy,
  ) async {
    final date = AppDateUtils.dateOnly(day);
    await ref
        .read(wellbeingRepositoryProvider)
        .setIntimacyForDate(date, intimacy);
    invalidateAllData(ref);
    ref.invalidate(wellbeingByDateProvider(date));
    if (mounted && sheetContext.mounted) {
      Navigator.pop(sheetContext);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            intimacy == IntimacyType.none
                ? 'Отметка близости снята'
                : 'Сохранено: ${intimacy.label}',
          ),
        ),
      );
    }
  }

  /// Номер дня цикла для произвольной даты (1 = день начала месячных).
  /// null, если до даты ещё не было ни одного отмеченного цикла.
  int? _cycleDayFor(DateTime day, List<Cycle> cycles) {
    final target = AppDateUtils.dateOnly(day);
    Cycle? current;
    for (final c in cycles) {
      final start = AppDateUtils.dateOnly(c.startDate);
      if (start.isAfter(target)) continue;
      if (current == null ||
          start.isAfter(AppDateUtils.dateOnly(current.startDate))) {
        current = c;
      }
    }
    if (current == null) return null;
    final dayNumber = AppDateUtils.daysBetween(current.startDate, target) + 1;
    // Не показываем нереалистично большие значения (между циклами пропуск).
    if (dayNumber < 1 || dayNumber > 60) return null;
    return dayNumber;
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
