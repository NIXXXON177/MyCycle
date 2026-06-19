import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mycycle/core/constants/app_colors.dart';
import 'package:mycycle/core/providers/app_providers.dart';
import 'package:mycycle/features/wellbeing/domain/entities/wellbeing_entry.dart';
import 'package:mycycle/shared/widgets/app_card.dart';

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
