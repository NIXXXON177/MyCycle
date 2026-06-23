import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:florea/core/constants/app_colors.dart';
import 'package:florea/core/providers/app_providers.dart';
import 'package:florea/core/utils/intimacy_analyzer.dart';
import 'package:florea/core/utils/cycle_calculator.dart';
import 'package:florea/core/utils/wellbeing_index.dart';
import 'package:florea/features/cycle/domain/entities/cycle.dart';
import 'package:florea/features/wellbeing/domain/entities/wellbeing_entry.dart';
import 'package:florea/shared/widgets/app_card.dart';

/// Экран статистики и аналитики.
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cyclesAsync = ref.watch(cyclesProvider);
    final wellbeingAsync = ref.watch(wellbeingListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Статистика')),
      body: cyclesAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: 'Ошибка загрузки',
          onRetry: () => ref.invalidate(cyclesProvider),
        ),
        data: (cycles) => wellbeingAsync.when(
          loading: () => const LoadingView(),
          error: (e, _) => const ErrorView(message: 'Ошибка загрузки'),
          data: (wellbeing) {
            final repo = ref.read(cycleRepositoryProvider);
            final avgCycle = repo.averageCycleLength(cycles);
            final avgPeriod = repo.averagePeriodLength(cycles);
            final regularity = repo.cycleRegularity(cycles);
            final calculator = ref.read(cycleCalculatorProvider);
            final intimacyStats = IntimacyAnalyzer.forMonth(
              wellbeing: wellbeing,
              cycles: cycles,
              calculator: calculator,
            );

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (cycles.length < 3) ...[
                  AppCard(
                    color: AppColors.moodNormal.withValues(alpha: 0.22),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: AppColors.darkGray),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Пока мало данных (${cycles.length} '
                            '${_cycleWord(cycles.length)}). Прогнозы и средние '
                            'значения станут точнее после 3+ циклов.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  children: [
                    Expanded(
                      child: AppCard(
                        child: Column(
                          children: [
                            Text(
                              '$avgCycle',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(color: AppColors.pinkDark),
                            ),
                            const Text('средний цикл'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppCard(
                        child: Column(
                          children: [
                            Text(
                              '$avgPeriod',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(color: AppColors.purpleDark),
                            ),
                            const Text('дней месячных'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle('Регулярность цикла'),
                      Text(
                        regularity < 2
                            ? 'Очень регулярный (±${regularity.toStringAsFixed(1)} дн.)'
                            : regularity < 4
                                ? 'Умеренно регулярный (±${regularity.toStringAsFixed(1)} дн.)'
                                : 'Нерегулярный (±${regularity.toStringAsFixed(1)} дн.)',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle('Близость за месяц'),
                      if (intimacyStats.total == 0)
                        const Text('Нет отметок в этом месяце')
                      else ...[
                        Text(
                          'Всего: ${intimacyStats.total}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Text(
                          '💦 С эякуляцией: ${intimacyStats.withEjaculation}',
                        ),
                        Text(
                          '🤍 Без эякуляции: ${intimacyStats.withoutEjaculation}',
                        ),
                        if (intimacyStats.byPhase.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'По фазам цикла:',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          ...intimacyStats.byPhase.entries.map(
                            (e) => Text('${e.key.label}: ${e.value}'),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _WellbeingIndexChartSection(
                  wellbeing: wellbeing,
                  cycles: cycles,
                  calculator: calculator,
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle('График настроения'),
                      SizedBox(
                        height: 200,
                        child: _MoodChart(entries: wellbeing),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle('График энергии'),
                      SizedBox(
                        height: 200,
                        child: _EnergyChart(entries: wellbeing),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Склонение слова «цикл» для предупреждения.
  static String _cycleWord(int n) {
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (mod10 == 1 && mod100 != 11) return 'цикл';
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) {
      return 'цикла';
    }
    return 'циклов';
  }
}

class _WellbeingIndexChartSection extends StatefulWidget {
  const _WellbeingIndexChartSection({
    required this.wellbeing,
    required this.cycles,
    required this.calculator,
  });

  final List<WellbeingEntry> wellbeing;
  final List<Cycle> cycles;
  final CycleCalculator calculator;

  @override
  State<_WellbeingIndexChartSection> createState() =>
      _WellbeingIndexChartSectionState();
}

class _WellbeingIndexChartSectionState
    extends State<_WellbeingIndexChartSection> {
  IndexChartPeriod _period = IndexChartPeriod.days30;

  @override
  Widget build(BuildContext context) {
    final points = WellbeingIndexCalculator.chartPoints(
      wellbeing: widget.wellbeing,
      cycles: widget.cycles,
      calculator: widget.calculator,
      period: _period,
    );

    final avg = points.isEmpty
        ? 0
        : (points.fold<int>(0, (s, p) => s + p.index) / points.length).round();
    final level = WellbeingIndexLevel.labelFor(avg);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Индекс самочувствия'),
          if (points.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$avg',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.pinkDark,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '/100',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.gray,
                      ),
                ),
                const SizedBox(width: 8),
                Text(
                  level,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          Text(
            WellbeingIndexCalculator.disclaimer,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.gray,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: IndexChartPeriod.values.map((period) {
              final selected = _period == period;
              return ChoiceChip(
                label: Text(period.label),
                selected: selected,
                onSelected: (_) => setState(() => _period = period),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: _IndexChart(points: points),
          ),
        ],
      ),
    );
  }
}

class _IndexChart extends StatelessWidget {
  const _IndexChart({required this.points});

  final List<IndexChartPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Center(child: Text('Нет данных за выбранный период'));
    }

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((spot) {
              final i = spot.x.toInt();
              if (i < 0 || i >= points.length) {
                return const LineTooltipItem('', TextStyle());
              }
              final p = points[i];
              final dayPart = p.cycleDay != null ? ' · день ${p.cycleDay}' : '';
              return LineTooltipItem(
                '${p.date.day}.${p.date.month}: ${spot.y.toInt()}$dayPart',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
        ),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: points.length > 14 ? (points.length / 7).ceilToDouble() : 1,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= points.length) return const SizedBox();
                return Text(
                  '${points[i].date.day}',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 20,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}', style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              points.length,
              (i) => FlSpot(i.toDouble(), points[i].index.toDouble()),
            ),
            isCurved: true,
            color: AppColors.purpleDark,
            barWidth: 3,
            dotData: FlDotData(show: points.length <= 31),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.purple.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodChart extends StatelessWidget {
  const _MoodChart({required this.entries});

  final List<WellbeingEntry> entries;

  @override
  Widget build(BuildContext context) {
    final recent = entries.take(14).toList().reversed.toList();
    if (recent.isEmpty) {
      return const Center(child: Text('Нет данных'));
    }

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((spot) {
              final i = spot.x.toInt();
              final prefix = (i >= 0 && i < recent.length)
                  ? '${recent[i].date.day}.${recent[i].date.month}: '
                  : '';
              return LineTooltipItem(
                '$prefix${spot.y.toInt()}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
        ),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= recent.length) return const SizedBox();
                return Text(
                  '${recent[i].date.day}',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}', style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minY: 1,
        maxY: 5,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              recent.length,
              (i) => FlSpot(i.toDouble(), recent[i].mood.value.toDouble()),
            ),
            isCurved: true,
            color: AppColors.pinkDark,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.pink.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnergyChart extends StatelessWidget {
  const _EnergyChart({required this.entries});

  final List<WellbeingEntry> entries;

  @override
  Widget build(BuildContext context) {
    final recent = entries.take(14).toList().reversed.toList();
    if (recent.isEmpty) {
      return const Center(child: Text('Нет данных'));
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 3,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final i = group.x;
              final prefix = (i >= 0 && i < recent.length)
                  ? '${recent[i].date.day}.${recent[i].date.month}: '
                  : '';
              return BarTooltipItem(
                '$prefix${rod.toY.toInt()}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ),
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= recent.length) return const SizedBox();
                return Text(
                  '${recent[i].date.day}',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}', style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(recent.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: recent[i].energy.value.toDouble(),
                color: AppColors.purpleDark,
                width: 12,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          );
        }),
      ),
    );
  }
}
