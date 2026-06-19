import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mycycle/core/constants/app_colors.dart';
import 'package:mycycle/core/providers/app_providers.dart';
import 'package:mycycle/core/router/app_router.dart';
import 'package:mycycle/core/utils/date_utils.dart';
import 'package:mycycle/core/utils/emotional_timeline.dart';
import 'package:mycycle/features/diary/domain/entities/diary_entry.dart';
import 'package:mycycle/features/diary/domain/entities/diary_list_query.dart';
import 'package:mycycle/shared/widgets/app_card.dart';

enum _DateFilter { all, today, week, month, custom }

/// Экран дневника с поиском, фильтрами и эмоциональной лентой.
class DiaryScreen extends ConsumerStatefulWidget {
  const DiaryScreen({super.key});

  @override
  ConsumerState<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends ConsumerState<DiaryScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _input = '';
  Timer? _debounce;
  _DateFilter _dateFilter = _DateFilter.all;
  bool _favoritesOnly = false;
  DateTime? _customFrom;
  DateTime? _customTo;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  DiaryListQuery get _listQuery {
    final today = AppDateUtils.dateOnly(DateTime.now());
    DateTime? from;
    DateTime? to;

    switch (_dateFilter) {
      case _DateFilter.today:
        from = today;
        to = today;
      case _DateFilter.week:
        from = today.subtract(Duration(days: today.weekday - 1));
        to = today;
      case _DateFilter.month:
        from = DateTime(today.year, today.month);
        to = today;
      case _DateFilter.custom:
        from = _customFrom;
        to = _customTo ?? _customFrom;
      case _DateFilter.all:
        break;
    }

    return DiaryListQuery(
      text: _query,
      favoritesOnly: _favoritesOnly,
      from: from,
      to: to,
    );
  }

  void _onSearchChanged(String value) {
    setState(() => _input = value);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() {
      _input = '';
      _query = '';
    });
  }

  Future<bool> _confirmDelete(DiaryEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить запись?'),
        content: const Text('Фото тоже будут удалены.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirm != true) return false;

    await ref.read(diaryRepositoryProvider).delete(entry.id);
    invalidateAllData(ref);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Запись удалена')),
      );
    }
    return true;
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final from = await showDatePicker(
      context: context,
      initialDate: _customFrom ?? now,
      firstDate: DateTime(2020),
      lastDate: now,
      locale: const Locale('ru'),
    );
    if (from == null || !mounted) return;

    final to = await showDatePicker(
      context: context,
      initialDate: _customTo ?? from,
      firstDate: from,
      lastDate: now,
      locale: const Locale('ru'),
    );
    if (to == null) return;

    setState(() {
      _dateFilter = _DateFilter.custom;
      _customFrom = from;
      _customTo = to;
    });
  }

  @override
  Widget build(BuildContext context) {
    final listQuery = _listQuery;
    final entriesAsync = ref.watch(diaryQueryProvider(listQuery));
    final wellbeing = ref.watch(wellbeingListProvider).valueOrNull ?? [];
    final cycles = ref.watch(cyclesProvider).valueOrNull ?? [];
    final calculator = ref.read(cycleCalculatorProvider);
    final emotional = EmotionalTimelineAnalyzer.analyze(
      wellbeing: wellbeing,
      cycles: cycles,
      calculator: calculator,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Дневник'),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library_outlined),
            tooltip: 'Воспоминания',
            onPressed: () => context.push(AppRoutes.memories),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.diaryEdit),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск по записям...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _input.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : null,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _filterChip('Все', _DateFilter.all),
                _filterChip('Сегодня', _DateFilter.today),
                _filterChip('Неделя', _DateFilter.week),
                _filterChip('Месяц', _DateFilter.month),
                FilterChip(
                  label: const Text('Диапазон'),
                  selected: _dateFilter == _DateFilter.custom,
                  onSelected: (_) => _pickCustomRange(),
                ),
                FilterChip(
                  label: const Text('⭐ Избранное'),
                  selected: _favoritesOnly,
                  onSelected: (v) => setState(() => _favoritesOnly = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: entriesAsync.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(
                message: 'Ошибка загрузки',
                onRetry: () => ref.invalidate(diaryQueryProvider(listQuery)),
              ),
              data: (entries) {
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    if (_query.isEmpty && !_favoritesOnly)
                      _EmotionalTimelineCard(summary: emotional),
                    if (entries.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: EmptyView(
                          message: _emptyMessage(),
                        ),
                      )
                    else
                      ...entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _DiaryListTile(
                            entry: entry,
                            onDelete: () => _confirmDelete(entry),
                            onTap: () => context.push(
                              '${AppRoutes.diaryEdit}?id=${entry.id}',
                            ),
                          ),
                        );
                      }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, _DateFilter filter) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: _dateFilter == filter && !_favoritesOnly,
        onSelected: (_) => setState(() {
          _dateFilter = filter;
          _favoritesOnly = false;
        }),
      ),
    );
  }

  String _emptyMessage() {
    if (_favoritesOnly) return 'Нет избранных записей';
    if (_query.isNotEmpty) return 'Ничего не найдено';
    return 'Пока нет записей.\nНажми + чтобы добавить.';
  }
}

class _EmotionalTimelineCard extends StatelessWidget {
  const _EmotionalTimelineCard({required this.summary});

  final EmotionalTimelineSummary summary;

  @override
  Widget build(BuildContext context) {
    final total = summary.goodDays + summary.normalDays + summary.badDays;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        color: AppColors.purple.withValues(alpha: 0.15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Эмоциональная лента · 30 дней',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            if (total == 0)
              const Text('Отмечай самочувствие — здесь появится статистика')
            else ...[
              Text('😊 ${summary.goodDays} дней'),
              Text('😐 ${summary.normalDays} дней'),
              Text('😔 ${summary.badDays} дней'),
              if (summary.insight != null) ...[
                const SizedBox(height: 8),
                Text(
                  summary.insight!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _DiaryListTile extends ConsumerWidget {
  const _DiaryListTile({
    required this.entry,
    required this.onDelete,
    required this.onTap,
  });

  final DiaryEntry entry;
  final Future<bool> Function() onDelete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imagesAsync = ref.watch(diaryImagesProvider(entry.id));

    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: AppCard(
        onTap: onTap,
        child: ListTile(
          leading: Text(
            entry.mood.emoji,
            style: const TextStyle(fontSize: 28),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  entry.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (entry.isFavorite)
                const Icon(Icons.star, color: Colors.amber, size: 18),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppDateUtils.formatDate(entry.date)),
              imagesAsync.when(
                data: (images) {
                  if (images.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SizedBox(
                      height: 48,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: images.take(3).map((img) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.file(
                                File(img.imagePath),
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
