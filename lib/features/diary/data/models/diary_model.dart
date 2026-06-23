import 'package:florea/core/enums/mood_level.dart';
import 'package:florea/core/utils/date_utils.dart';
import 'package:florea/features/diary/domain/entities/diary_entry.dart';

abstract final class DiaryModel {
  static DiaryEntry fromMap(Map<String, dynamic> map) {
    return DiaryEntry(
      id: map['id'] as String,
      date: AppDateUtils.fromIso(map['date'] as String),
      text: map['text'] as String,
      mood: MoodLevel.fromValue(map['mood'] as int),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
    );
  }

  static Map<String, dynamic> toMap(DiaryEntry entry) {
    return {
      'id': entry.id,
      'date': AppDateUtils.dateToIso(entry.date),
      'text': entry.text,
      'mood': entry.mood.value,
      'created_at': entry.createdAt.toIso8601String(),
      'updated_at': entry.updatedAt.toIso8601String(),
      'is_favorite': entry.isFavorite ? 1 : 0,
    };
  }
}
