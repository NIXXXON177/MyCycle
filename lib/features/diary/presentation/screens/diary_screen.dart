import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mycycle/core/providers/app_providers.dart';
import 'package:mycycle/core/router/app_router.dart';
import 'package:mycycle/core/utils/date_utils.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() => _query = value),
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
                          subtitle: Text(AppDateUtils.formatDate(entry.date)),
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
