import 'package:florea/core/enums/mood_level.dart';

/// Запись дневника.
class DiaryEntry {
  const DiaryEntry({
    required this.id,
    required this.date,
    required this.text,
    required this.mood,
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
  });

  final String id;
  final DateTime date;
  final String text;
  final MoodLevel mood;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;

  DiaryEntry copyWith({
    String? id,
    DateTime? date,
    String? text,
    MoodLevel? mood,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      text: text ?? this.text,
      mood: mood ?? this.mood,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
