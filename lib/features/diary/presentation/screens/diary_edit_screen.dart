import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mycycle/core/enums/mood_level.dart';
import 'package:mycycle/core/providers/app_providers.dart';
import 'package:mycycle/core/utils/date_utils.dart';
import 'package:mycycle/features/diary/domain/entities/diary_entry.dart';
import 'package:mycycle/features/diary/domain/entities/diary_image.dart';
import 'package:mycycle/shared/widgets/diary_image_preview.dart';

/// Экран создания/редактирования записи дневника.
class DiaryEditScreen extends ConsumerStatefulWidget {
  const DiaryEditScreen({super.key, this.entryId});

  final String? entryId;

  @override
  ConsumerState<DiaryEditScreen> createState() => _DiaryEditScreenState();
}

class _DiaryEditScreenState extends ConsumerState<DiaryEditScreen> {
  final _textController = TextEditingController();
  final _picker = ImagePicker();
  DateTime _date = DateTime.now();
  MoodLevel _mood = MoodLevel.normal;
  bool _isFavorite = false;
  DiaryEntry? _existing;
  List<DiaryImage> _savedImages = [];
  final List<String> _pendingPaths = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (widget.entryId != null) {
      final repo = ref.read(diaryRepositoryProvider);
      _existing = await repo.getById(widget.entryId!);
      if (_existing != null) {
        _textController.text = _existing!.text;
        _date = _existing!.date;
        _mood = _existing!.mood;
        _isFavorite = _existing!.isFavorite;
        _savedImages = await repo.getImages(_existing!.id);
      }
    }
    if (mounted) setState(() => _loaded = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_existing == null ? 'Новая запись' : 'Редактировать'),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.star : Icons.star_border,
              color: _isFavorite ? Colors.amber : null,
            ),
            tooltip: 'В избранное',
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
          ),
          if (_existing != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ListTile(
                  title: const Text('Дата'),
                  subtitle: Text(AppDateUtils.formatDate(_date)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      locale: const Locale('ru'),
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                ),
                const SizedBox(height: 8),
                const Text('Настроение'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: MoodLevel.values.map((m) {
                    return ChoiceChip(
                      label: Text('${m.emoji} ${m.label}'),
                      selected: _mood == m,
                      onSelected: (_) => setState(() => _mood = m),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _textController,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    hintText: 'О чём хочется написать...',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Фотографии',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    TextButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: const Text('Добавить'),
                    ),
                  ],
                ),
                if (_savedImages.isNotEmpty || _pendingPaths.isNotEmpty)
                  SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        ..._savedImages.map(_savedImageTile),
                        ..._pendingPaths.map(_pendingImageTile),
                      ],
                    ),
                  )
                else
                  Text(
                    'Можно прикрепить несколько фото',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _save,
                  child: const Text('Сохранить'),
                ),
              ],
            ),
    );
  }

  Widget _savedImageTile(DiaryImage image) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: DiaryImagePreview(
              path: image.imagePath,
              width: 100,
              height: 100,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeSavedImage(image),
              child: const CircleAvatar(
                radius: 12,
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pendingImageTile(String path) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: DiaryImagePreview(
              path: path,
              width: 100,
              height: 100,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => setState(() => _pendingPaths.remove(path)),
              child: const CircleAvatar(
                radius: 12,
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImages() async {
    final files = await _picker.pickMultiImage(imageQuality: 85);
    if (files.isEmpty) return;
    setState(() {
      for (final file in files) {
        _pendingPaths.add(file.path);
      }
    });
  }

  Future<void> _removeSavedImage(DiaryImage image) async {
    await ref.read(diaryRepositoryProvider).deleteImage(image);
    setState(() => _savedImages.remove(image));
    if (_existing != null) {
      ref.invalidate(diaryImagesProvider(_existing!.id));
    }
  }

  Future<void> _save() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите текст записи')),
      );
      return;
    }

    final repo = ref.read(diaryRepositoryProvider);
    if (_existing == null) {
      final entry = await repo.add(
        date: _date,
        text: text,
        mood: _mood,
        isFavorite: _isFavorite,
        imageSourcePaths: _pendingPaths,
      );
      ref.invalidate(diaryImagesProvider(entry.id));
    } else {
      await repo.update(_existing!.copyWith(
        date: _date,
        text: text,
        mood: _mood,
        isFavorite: _isFavorite,
      ));
      for (final path in _pendingPaths) {
        await repo.addImage(diaryId: _existing!.id, sourcePath: path);
      }
      ref.invalidate(diaryImagesProvider(_existing!.id));
    }

    invalidateAllData(ref);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Запись сохранена')),
      );
      context.pop();
    }
  }

  Future<void> _delete() async {
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

    if (confirm == true && _existing != null) {
      await ref.read(diaryRepositoryProvider).delete(_existing!.id);
      invalidateAllData(ref);
      if (mounted) context.pop();
    }
  }
}
