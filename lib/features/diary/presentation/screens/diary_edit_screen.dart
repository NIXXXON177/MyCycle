import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mycycle/core/enums/mood_level.dart';
import 'package:mycycle/core/providers/app_providers.dart';
import 'package:mycycle/core/utils/date_utils.dart';
import 'package:mycycle/features/diary/domain/entities/diary_entry.dart';

/// Экран создания/редактирования записи дневника.
class DiaryEditScreen extends ConsumerStatefulWidget {
  const DiaryEditScreen({super.key, this.entryId});

  final String? entryId;

  @override
  ConsumerState<DiaryEditScreen> createState() => _DiaryEditScreenState();
}

class _DiaryEditScreenState extends ConsumerState<DiaryEditScreen> {
  final _textController = TextEditingController();
  DateTime _date = DateTime.now();
  MoodLevel _mood = MoodLevel.normal;
  DiaryEntry? _existing;
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
      _existing =
          await ref.read(diaryRepositoryProvider).getById(widget.entryId!);
      if (_existing != null) {
        _textController.text = _existing!.text;
        _date = _existing!.date;
        _mood = _existing!.mood;
      }
    }
    setState(() => _loaded = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_existing == null ? 'Новая запись' : 'Редактировать'),
        actions: [
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
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _save,
                  child: const Text('Сохранить'),
                ),
              ],
            ),
    );
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
      await repo.add(date: _date, text: text, mood: _mood);
    } else {
      await repo.update(_existing!.copyWith(
        date: _date,
        text: text,
        mood: _mood,
      ));
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
