import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mycycle/core/constants/app_colors.dart';
import 'package:mycycle/core/providers/app_providers.dart';
import 'package:mycycle/core/utils/insights_generator.dart';
import 'package:mycycle/shared/widgets/app_card.dart';

/// Экран автоматических закономерностей.
class PatternsScreen extends ConsumerWidget {
  const PatternsScreen({super.key});

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
            final analyzer = const PatternsAnalyzer();
            final insights = analyzer.analyze(
              cycles: cycles,
              wellbeing: wellbeing,
              averageCycleLength: repo.averageCycleLength(cycles),
              averagePeriodLength: repo.averagePeriodLength(cycles),
            );

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: insights.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    color: index.isEven
                        ? AppColors.pink.withValues(alpha: 0.2)
                        : AppColors.purple.withValues(alpha: 0.2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(right: 12, top: 2),
                          child: Text('✨', style: TextStyle(fontSize: 24)),
                        ),
                        Expanded(
                          child: Text(
                            insights[index],
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
}
