import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:florea/core/constants/app_colors.dart';
import 'package:florea/core/enums/support_event_type.dart';
import 'package:florea/core/providers/app_providers.dart';
import 'package:florea/core/utils/date_utils.dart';
import 'package:florea/shared/widgets/app_card.dart';

/// Экран кнопок поддержки.
class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(supportEventsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Поддержка')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Нажми, если нужна поддержка — это сохранится в истории',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.gray,
                  ),
            ),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(16),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: SupportEventType.values.map((type) {
                return AppCard(
                  color: AppColors.pink.withValues(alpha: 0.2),
                  onTap: () => _recordEvent(context, ref, type),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(type.emoji, style: const TextStyle(fontSize: 40)),
                      const SizedBox(height: 8),
                      Text(
                        type.label,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SectionTitle('История'),
          Expanded(
            flex: 2,
            child: eventsAsync.when(
              loading: () => const LoadingView(),
              error: (e, _) => const ErrorView(message: 'Ошибка'),
              data: (events) {
                if (events.isEmpty) {
                  return const EmptyView(message: 'Пока нет событий');
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return ListTile(
                      leading: Text(event.type.emoji,
                          style: const TextStyle(fontSize: 24)),
                      title: Text(event.type.label),
                      subtitle: Text(
                        AppDateUtils.formatDate(event.createdAt),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _recordEvent(
    BuildContext context,
    WidgetRef ref,
    SupportEventType type,
  ) async {
    await ref.read(supportRepositoryProvider).recordEvent(type);
    ref.invalidate(supportEventsProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${type.emoji} Записано. Ты не одна!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
