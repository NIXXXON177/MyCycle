import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:florea/core/providers/app_providers.dart';
import 'package:florea/core/services/widget/home_widget_service.dart';

final homeWidgetServiceProvider = Provider<HomeWidgetService>((ref) {
  return HomeWidgetService(
    cycleRepo: ref.watch(cycleRepositoryProvider),
    wellbeingRepo: ref.watch(wellbeingRepositoryProvider),
    importantDateRepo: ref.watch(importantDateRepositoryProvider),
  );
});

/// Обновляет виджет на рабочем столе (fire-and-forget).
void syncHomeWidget(WidgetRef ref) {
  ref.read(homeWidgetServiceProvider).sync();
}
