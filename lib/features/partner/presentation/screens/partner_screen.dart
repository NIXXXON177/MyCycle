import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mycycle/core/constants/app_colors.dart';
import 'package:mycycle/core/providers/app_providers.dart';
import 'package:mycycle/core/utils/insights_generator.dart';
import 'package:mycycle/shared/widgets/app_card.dart';

/// Режим для партнёра — простые подсказки без медицинских терминов.
class PartnerScreen extends ConsumerWidget {
  const PartnerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final predictionAsync = ref.watch(cyclePredictionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Для парня')),
      body: predictionAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: 'Ошибка загрузки',
          onRetry: () => ref.invalidate(cyclePredictionProvider),
        ),
        data: (prediction) {
          final generator = const PartnerTipsGenerator();
          final tips = generator.generateTips(prediction);
          final wellbeing = generator.approximateWellbeing(prediction);
          final phaseLabel =
              generator.phaseLabelForPartner(prediction.phase);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppCard(
                color: AppColors.purple.withValues(alpha: 0.3),
                child: Column(
                  children: [
                    const Text('💕', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 8),
                    Text(
                      phaseLabel,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      wellbeing,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (prediction.daysUntilNextPeriod != null)
                AppCard(
                  child: ListTile(
                    leading: const Icon(Icons.water_drop, color: AppColors.period),
                    title: Text(
                      prediction.daysUntilNextPeriod! > 0
                          ? 'До начала месячных осталось '
                              '${prediction.daysUntilNextPeriod} дн.'
                          : prediction.daysUntilNextPeriod == 0
                              ? 'Месячные могут начаться сегодня'
                              : 'Сейчас идут месячные',
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              const SectionTitle('Подсказки'),
              ...tips.map(
                (tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    child: Row(
                      children: [
                        const Icon(Icons.lightbulb_outline,
                            color: AppColors.pinkDark),
                        const SizedBox(width: 12),
                        Expanded(child: Text(tip)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
