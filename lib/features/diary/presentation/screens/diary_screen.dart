import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mycycle/core/providers/app_providers.dart';
import 'package:mycycle/core/router/app_router.dart';
import 'package:mycycle/core/utils/date_utils.dart';
import 'package:mycycle/features/diary/domain/entities/diary_entry.dart';
import 'package:mycycle/shared/widgets/app_card.dart';

/// Экран дневника с поиском.
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

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
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
        content: const Text('Это действие нельзя отменить.'),
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
    ref.invalidate(diaryListProvider);
    if (_query.isNotEmpty) {
      ref.invalidate(diarySearchProvider(_query));
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Запись удалена')),
      );
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = _query.isEmpty
        ? ref.watch(diaryListProvider)
        : ref.watch(diarySearchProvider(_query));

    return Scaffold(
      appBar: AppBar(title: const Text('Дневник')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.diaryEdit),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
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
          Expanded(
            child: entriesAsync.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(
                message: 'Ошибка загрузки',
                onRetry: () => ref.invalidate(diaryListProvider),
              ),
              data: (entries) {
                if (entries.isEmpty) {
                  return EmptyView(
                    message: _query.isEmpty
                        ? 'Пока нет записей.\nНажми + чтобы добавить.'
                        : 'Ничего не найдено',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Dismissible(
                        key: ValueKey(entry.id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) => _confirmDelete(entry),
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
                          onTap: () => context.push(
                            '${AppRoutes.diaryEdit}?id=${entry.id}',
                          ),
                          child: ListTile(
                            leading: Text(
                              entry.mood.emoji,
                              style: const TextStyle(fontSize: 28),
                            ),
                            title: Text(
                              entry.text,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle:
                                Text(AppDateUtils.formatDate(entry.date)),
                          ),
                        ),
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
}
