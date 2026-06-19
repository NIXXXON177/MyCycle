import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mycycle/core/enums/wish_priority.dart';
import 'package:mycycle/core/providers/app_providers.dart';
import 'package:mycycle/features/wishes/domain/entities/wish.dart';
import 'package:mycycle/shared/widgets/app_card.dart';

/// Экран списка желаний «Мои хотелки».
class WishesScreen extends ConsumerWidget {
  const WishesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishesAsync = ref.watch(wishesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Мои хотелки')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showWishDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: wishesAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: 'Ошибка загрузки',
          onRetry: () => ref.invalidate(wishesProvider),
        ),
        data: (wishes) {
          if (wishes.isEmpty) {
            return const EmptyView(
              message: 'Пока нет хотелок.\nДобавь первую!',
              icon: Icons.card_giftcard,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: wishes.length,
            itemBuilder: (context, index) {
              final wish = wishes[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  child: ListTile(
                    title: Text(wish.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (wish.description != null)
                          Text(wish.description!),
                        if (wish.link != null)
                          Text(wish.link!, style: const TextStyle(fontSize: 12)),
                        Chip(
                          label: Text(wish.priority.label),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showWishDialog(context, ref, wish: wish);
                        } else if (value == 'delete') {
                          _deleteWish(context, ref, wish);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
                        const PopupMenuItem(value: 'delete', child: Text('Удалить')),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showWishDialog(
    BuildContext context,
    WidgetRef ref, {
    Wish? wish,
  }) async {
    final titleController = TextEditingController(text: wish?.title);
    final descController = TextEditingController(text: wish?.description);
    final linkController = TextEditingController(text: wish?.link);
    var priority = wish?.priority ?? WishPriority.medium;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(wish == null ? 'Новая хотелка' : 'Редактировать'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Название'),
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Описание'),
                  maxLines: 2,
                ),
                TextField(
                  controller: linkController,
                  decoration: const InputDecoration(labelText: 'Ссылка (необязательно)'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<WishPriority>(
                  value: priority,
                  decoration: const InputDecoration(labelText: 'Приоритет'),
                  items: WishPriority.values
                      .map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(p.label),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => priority = v);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () async {
                final title = titleController.text.trim();
                if (title.isEmpty) return;

                final repo = ref.read(wishRepositoryProvider);
                if (wish == null) {
                  await repo.create(
                    title: title,
                    description: descController.text.trim().isEmpty
                        ? null
                        : descController.text.trim(),
                    link: linkController.text.trim().isEmpty
                        ? null
                        : linkController.text.trim(),
                    priority: priority,
                  );
                } else {
                  await repo.update(wish.copyWith(
                    title: title,
                    description: descController.text.trim().isEmpty
                        ? null
                        : descController.text.trim(),
                    clearDescription: descController.text.trim().isEmpty,
                    link: linkController.text.trim().isEmpty
                        ? null
                        : linkController.text.trim(),
                    clearLink: linkController.text.trim().isEmpty,
                    priority: priority,
                  ));
                }
                ref.invalidate(wishesProvider);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteWish(
    BuildContext context,
    WidgetRef ref,
    Wish wish,
  ) async {
    await ref.read(wishRepositoryProvider).delete(wish.id);
    ref.invalidate(wishesProvider);
  }
}
