import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mycycle/core/constants/app_colors.dart';
import 'package:mycycle/core/enums/pain_level.dart';
import 'package:mycycle/core/providers/app_providers.dart';
import 'package:mycycle/core/utils/date_utils.dart';
import 'package:mycycle/features/cycle/domain/entities/cycle.dart';
import 'package:mycycle/features/cycle/domain/entities/cycle_prediction.dart';
import 'package:mycycle/features/wellbeing/domain/entities/wellbeing_entry.dart';
import 'package:mycycle/shared/widgets/app_card.dart';
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
        Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: const [
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

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppDateUtils.formatDate(day),
              style: Theme.of(context).textTheme.titleLarge,
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
                    if (entry.first.note != null)
                      Text(entry.first.note!),
                  ],
                ),
              ),
            ] else
              const Text('Самочувствие не отмечено'),
          ],
        ),
      ),
    );
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
