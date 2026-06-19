import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mycycle/core/constants/app_colors.dart';
import 'package:mycycle/core/providers/app_providers.dart';
import 'package:mycycle/core/utils/insights_generator.dart';
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
            const analyzer = PatternsAnalyzer();
            final insights = analyzer.analyze(
              cycles: cycles,
              wellbeing: wellbeing,
              averageCycleLength: repo.averageCycleLength(cycles),
              averagePeriodLength: repo.averagePeriodLength(cycles),
            );

            if (insights.isEmpty) {
              return const EmptyView(
                message: 'Пока недостаточно данных для выводов.\n'
                    'Отмечай цикл и самочувствие — закономерности '
                    'появятся позже.',
                icon: Icons.auto_awesome,
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: insights.length + 1,
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

                final i = index - 1;
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
                            insights[i],
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
