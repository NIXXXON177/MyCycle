import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mycycle/core/constants/app_colors.dart';
import 'package:mycycle/core/providers/app_providers.dart';
import 'package:mycycle/core/utils/date_utils.dart';
import 'package:mycycle/core/utils/partner_advisor.dart';
import 'package:mycycle/features/cycle/domain/entities/cycle_prediction.dart';
import 'package:mycycle/features/important_dates/domain/entities/important_date.dart';
import 'package:mycycle/features/support/domain/entities/support_event.dart';
import 'package:mycycle/features/wellbeing/domain/entities/wellbeing_entry.dart';
import 'package:mycycle/features/wishes/domain/entities/wish.dart';
import 'package:mycycle/shared/widgets/app_card.dart';

/// Режим для партнёра 2.0 — советы, поддержка, хотелки и важные даты.
class PartnerScreen extends ConsumerStatefulWidget {
  const PartnerScreen({super.key});

  @override
  ConsumerState<PartnerScreen> createState() => _PartnerScreenState();
}

class _PartnerScreenState extends ConsumerState<PartnerScreen> {
  static const _advisor = PartnerAdvisor();

  @override
  Widget build(BuildContext context) {
    final predictionAsync = ref.watch(cyclePredictionProvider);
    final wellbeingAsync = ref.watch(wellbeingListProvider);
    final supportAsync = ref.watch(supportEventsProvider);
    final wishesAsync = ref.watch(wishesProvider);
    final datesAsync = ref.watch(upcomingImportantDatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Для парня'),
        actions: [
          IconButton(
            icon: const Icon(Icons.event_outlined),
            tooltip: 'Важные даты',
            onPressed: () => _showDatesManager(context),
          ),
        ],
      ),
      body: predictionAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: 'Ошибка загрузки',
          onRetry: () => ref.invalidate(cyclePredictionProvider),
        ),
        data: (prediction) {
          final wellbeing = wellbeingAsync.valueOrNull ?? <WellbeingEntry>[];
          final support = supportAsync.valueOrNull ?? <SupportEvent>[];
          final wishes = wishesAsync.valueOrNull ?? <Wish>[];
          final upcoming = datesAsync.valueOrNull ?? <UpcomingImportantDate>[];

          final emotional = _advisor.emotionalState(
            wellbeing,
            fallbackPhase: prediction.phase,
          );
          final todayPlan = _advisor.todayPlan(prediction, wellbeing);
          final supportSummary = _advisor.supportSummary(support);
          final randomWishes = _advisor.pickRandomWishes(wishes, 3);
          final priorityWishes = _advisor.pickHighPriorityWishes(wishes, 3);
          final tips = _advisor.extraTips(prediction);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _PhaseCard(
                phaseLabel: _advisor.phaseLabel(prediction.phase),
                advice: _advisor.phaseAdvice(prediction.phase),
              ),
              const SizedBox(height: 12),
              _EmotionalCard(state: emotional),
              const SizedBox(height: 12),
              _TodayPlanCard(plan: todayPlan),
              const SizedBox(height: 16),
              if (prediction.daysUntilNextPeriod != null)
                AppCard(
                  child: ListTile(
                    leading: const Icon(Icons.water_drop, color: AppColors.period),
                    title: Text(_periodLine(prediction)),
                  ),
                ),
              const SizedBox(height: 16),
              const SectionTitle('Важные даты'),
              if (upcoming.isEmpty)
                const AppCard(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Нет ближайших дат. Нажми 📅 вверху, чтобы добавить.',
                    ),
                  ),
                )
              else
                ...upcoming.map((item) {
                  final days = item.daysUntil(
                    AppDateUtils.dateOnly(DateTime.now()),
                  );
                  final when = days == 0
                      ? 'сегодня'
                      : days == 1
                          ? 'завтра'
                          : 'через $days дн.';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      child: ListTile(
                        leading: const Icon(Icons.celebration_outlined),
                        title: Text(item.entry.title),
                        subtitle: Text(
                          '${AppDateUtils.formatDate(item.occurrence)} · $when'
                          '${item.entry.repeatYearly ? ' · ежегодно' : ''}',
                        ),
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 16),
              const SectionTitle('🎁 Возможные идеи подарка'),
              if (randomWishes.isEmpty && priorityWishes.isEmpty)
                const AppCard(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Хотелки пока не добавлены'),
                  ),
                )
              else ...[
                if (priorityWishes.isNotEmpty) ...[
                  Text(
                    'Высокий приоритет',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  ...priorityWishes.map(
                    (w) => _WishTile(wish: w, highlight: true),
                  ),
                  const SizedBox(height: 8),
                ],
                if (randomWishes.isNotEmpty) ...[
                  Text(
                    'Случайные идеи',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  ...randomWishes.map((w) => _WishTile(wish: w)),
                ],
              ],
              const SizedBox(height: 16),
              const SectionTitle('История поддержки'),
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: supportSummary.isEmpty
                      ? const Text('За этот месяц поддержка не запрашивалась')
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'За месяц:',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            ...supportSummary.lines.map(Text.new),
                          ],
                        ),
                ),
              ),
              if (tips.isNotEmpty) ...[
                const SizedBox(height: 16),
                const SectionTitle('Ещё подсказки'),
                ...tips.map(
                  (tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lightbulb_outline,
                            color: AppColors.pinkDark,
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(tip)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  String _periodLine(CyclePrediction prediction) {
    final days = prediction.daysUntilNextPeriod!;
    if (days > 0) return 'До начала месячных осталось $days дн.';
    if (days == 0) return 'Месячные могут начаться сегодня';
    return 'Сейчас идут месячные';
  }

  Future<void> _showDatesManager(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _DatesManagerSheet(
        onChanged: () {
          ref.invalidate(importantDatesListProvider);
          ref.invalidate(upcomingImportantDatesProvider);
        },
      ),
    );
  }
}

class _PhaseCard extends StatelessWidget {
  const _PhaseCard({required this.phaseLabel, required this.advice});

  final String phaseLabel;
  final String advice;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.purple.withValues(alpha: 0.28),
      child: Column(
        children: [
          const Text('💕', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          Text(
            phaseLabel,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            advice,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _EmotionalCard extends StatelessWidget {
  const _EmotionalCard({required this.state});

  final PartnerEmotionalState state;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Text(state.emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  state.hint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayPlanCard extends StatelessWidget {
  const _TodayPlanCard({required this.plan});

  final PartnerTodayPlan plan;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.pink.withValues(alpha: 0.15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Что можно сегодня',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          ...plan.canDo.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('✅ '),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Лучше сегодня',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          ...plan.betterToday.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('✅ '),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WishTile extends StatelessWidget {
  const _WishTile({required this.wish, this.highlight = false});

  final Wish wish;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        color: highlight
            ? AppColors.pink.withValues(alpha: 0.2)
            : null,
        child: ListTile(
          leading: const Text('🎁', style: TextStyle(fontSize: 22)),
          title: Text(wish.title),
          subtitle: wish.description != null ? Text(wish.description!) : null,
        ),
      ),
    );
  }
}

class _DatesManagerSheet extends ConsumerStatefulWidget {
  const _DatesManagerSheet({required this.onChanged});

  final VoidCallback onChanged;

  @override
  ConsumerState<_DatesManagerSheet> createState() =>
      _DatesManagerSheetState();
}

class _DatesManagerSheetState extends ConsumerState<_DatesManagerSheet> {
  @override
  Widget build(BuildContext context) {
    final datesAsync = ref.watch(importantDatesListProvider);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Важные даты',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => _showDateDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            datesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Ошибка загрузки'),
              data: (dates) {
                if (dates.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Добавь день рождения, годовщину или важное событие',
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.45,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: dates.length,
                    itemBuilder: (context, index) {
                      final date = dates[index];
                      return ListTile(
                        title: Text(date.title),
                        subtitle: Text(
                          '${AppDateUtils.formatDate(date.date)}'
                          '${date.repeatYearly ? ' · ежегодно' : ''}',
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'edit') {
                              await _showDateDialog(context, existing: date);
                            } else if (value == 'delete') {
                              await ref
                                  .read(importantDateRepositoryProvider)
                                  .delete(date.id);
                              widget.onChanged();
                              ref.invalidate(importantDatesListProvider);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'edit', child: Text('Изменить')),
                            PopupMenuItem(value: 'delete', child: Text('Удалить')),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDateDialog(
    BuildContext context, {
    ImportantDate? existing,
  }) async {
    final titleController = TextEditingController(text: existing?.title);
    var date = existing?.date ?? DateTime.now();
    var repeatYearly = existing?.repeatYearly ?? true;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Новая дата' : 'Изменить дату'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Название',
                  hintText: 'Годовщина, день рождения...',
                ),
              ),
              ListTile(
                title: const Text('Дата'),
                subtitle: Text(AppDateUtils.formatDate(date)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: dialogContext,
                    initialDate: date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                    locale: const Locale('ru'),
                  );
                  if (picked != null) {
                    setDialogState(() => date = picked);
                  }
                },
              ),
              SwitchListTile(
                title: const Text('Повторять каждый год'),
                value: repeatYearly,
                onChanged: (v) => setDialogState(() => repeatYearly = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () async {
                final title = titleController.text.trim();
                if (title.isEmpty) return;

                final repo = ref.read(importantDateRepositoryProvider);
                if (existing == null) {
                  await repo.create(
                    title: title,
                    date: date,
                    repeatYearly: repeatYearly,
                  );
                } else {
                  await repo.update(
                    existing.copyWith(
                      title: title,
                      date: date,
                      repeatYearly: repeatYearly,
                    ),
                  );
                }
                widget.onChanged();
                ref.invalidate(importantDatesListProvider);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}
