import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mycycle/core/constants/app_colors.dart';
import 'package:mycycle/core/providers/app_providers.dart';
import 'package:mycycle/core/utils/wellbeing_index.dart';
import 'package:mycycle/shared/widgets/app_card.dart';

/// Экран автоматических закономерностей.
class PatternsScreen extends ConsumerWidget {
  const PatternsScreen({super.key});

  /// Иконки для инсайтов — чередуются, чтобы карточки не сливались.
  static const _icons = ['✨', '🌙', '💡', '🌸', '📈', '💜', '🌿'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cyclesAsync = ref.watch(cyclesProvider);
    final wellbeingAsync = ref.watch(wellbeingListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Закономерности')),
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
            final calculator = ref.read(cycleCalculatorProvider);
            final result = SmartPatternsAnalyzer.analyze(
              cycles: cycles,
              wellbeing: wellbeing,
              averageCycleLength: repo.averageCycleLength(cycles),
              averagePeriodLength: repo.averagePeriodLength(cycles),
              calculator: calculator,
            );

            if (result.insights.isEmpty && result.topSymptom == null) {
              return const EmptyView(
                message: 'Пока недостаточно данных для выводов.\n'
                    'Отмечай цикл и самочувствие — закономерности '
                    'появятся позже.',
                icon: Icons.auto_awesome,
              );
            }

            final extraCards = (result.topSymptom != null ? 1 : 0) +
                (result.bestDaysRange != null ? 1 : 0) +
                (result.hardestDaysRange != null ? 1 : 0);
            final filteredInsights = result.insights.where((text) {
              if (result.bestDaysRange != null &&
                  text.contains('Лучшее самочувствие')) {
                return false;
              }
              if (result.hardestDaysRange != null &&
                  text.contains('Самые сложные дни')) {
                return false;
              }
              return true;
            }).toList();

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredInsights.length + 1 + extraCards,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12, left: 4),
                    child: Text(
                      'На основе ${cycles.length} '
                      '${_cyclesWord(cycles.length)} и ${wellbeing.length} '
                      '${_entriesWord(wellbeing.length)} самочувствия',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.gray,
                          ),
                    ),
                  );
                }

                var offset = 1;

                if (result.topSymptom != null) {
                  if (index == offset) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TopSymptomCard(insight: result.topSymptom!),
                    );
                  }
                  offset++;
                }

                if (result.bestDaysRange != null) {
                  if (index == offset) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard(
                        color: AppColors.pink.withValues(alpha: 0.25),
                        child: Row(
                          children: [
                            const Text('🌟', style: TextStyle(fontSize: 28)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Лучшее самочувствие обычно наблюдается '
                                'на ${result.bestDaysRange} день цикла',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  offset++;
                }

                if (result.hardestDaysRange != null) {
                  if (index == offset) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard(
                        color: AppColors.purple.withValues(alpha: 0.25),
                        child: Row(
                          children: [
                            const Text('🌧️', style: TextStyle(fontSize: 28)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Самые сложные дни: '
                                '${result.hardestDaysRange} день цикла',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  offset++;
                }

                final i = index - offset;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    color: i.isEven
                        ? AppColors.pink.withValues(alpha: 0.2)
                        : AppColors.purple.withValues(alpha: 0.2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 12, top: 2),
                          child: Text(
                            _icons[i % _icons.length],
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            filteredInsights[i],
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  static String _cyclesWord(int n) {
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (mod10 == 1 && mod100 != 11) return 'цикла';
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) {
      return 'циклов';
    }
    return 'циклов';
  }

  static String _entriesWord(int n) {
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (mod10 == 1 && mod100 != 11) return 'записи';
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) {
      return 'записей';
    }
    return 'записей';
  }
}

class _TopSymptomCard extends StatelessWidget {
  const _TopSymptomCard({required this.insight});

  final TopSymptomInsight insight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      color: AppColors.moodNormal.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Наиболее частый симптом',
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.purpleDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${insight.symptom.emoji} ${insight.symptom.label}',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Отмечен ${insight.count} ${_timesWord(insight.count)}',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.gray),
          ),
        ],
      ),
    );
  }

  static String _timesWord(int n) {
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (mod10 == 1 && mod100 != 11) return 'раз';
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) {
      return 'раза';
    }
    return 'раз';
  }
}
