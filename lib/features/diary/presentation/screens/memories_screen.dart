import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mycycle/core/providers/app_providers.dart';
import 'package:mycycle/core/router/app_router.dart';
import 'package:mycycle/core/utils/date_utils.dart';
import 'package:mycycle/features/diary/domain/entities/diary_entry.dart';
import 'package:mycycle/features/diary/domain/entities/diary_image.dart';
import 'package:mycycle/shared/widgets/app_card.dart';

/// Галерея воспоминаний — записи и фото в хронологическом порядке.
class MemoriesScreen extends ConsumerWidget {
  const MemoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(diaryListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Воспоминания')),
      body: entriesAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: 'Ошибка загрузки',
          onRetry: () => ref.invalidate(diaryListProvider),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return const EmptyView(
              message: 'Пока нет воспоминаний.\nДобавь запись с фото в дневнике.',
              icon: Icons.photo_library_outlined,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _MemoryCard(entry: entry);
            },
          );
        },
      ),
    );
  }
}

class _MemoryCard extends ConsumerWidget {
  const _MemoryCard({required this.entry});

  final DiaryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imagesAsync = ref.watch(diaryImagesProvider(entry.id));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: () => context.push('${AppRoutes.diaryEdit}?id=${entry.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(entry.mood.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppDateUtils.formatDate(entry.date),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (entry.isFavorite)
                  const Icon(Icons.star, color: Colors.amber, size: 18),
              ],
            ),
            const SizedBox(height: 8),
            Text(entry.text),
            imagesAsync.when(
              data: (images) => _ImageGrid(images: images),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageGrid extends StatelessWidget {
  const _ImageGrid({required this.images});

  final List<DiaryImage> images;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: images.map((img) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(img.imagePath),
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          );
        }).toList(),
      ),
    );
  }
}
