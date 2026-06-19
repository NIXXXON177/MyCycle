import 'package:mycycle/core/utils/date_utils.dart';
import 'package:mycycle/features/diary/domain/entities/diary_entry.dart';
import 'package:mycycle/features/diary/domain/entities/diary_image.dart';

/// Параметры фильтрации списка дневника.
class DiaryListQuery {
  const DiaryListQuery({
    this.text = '',
    this.favoritesOnly = false,
    this.from,
    this.to,
  });

  final String text;
  final bool favoritesOnly;
  final DateTime? from;
  final DateTime? to;

  DiaryListQuery copyWith({
    String? text,
    bool? favoritesOnly,
    DateTime? from,
    DateTime? to,
    bool clearFrom = false,
    bool clearTo = false,
  }) {
    return DiaryListQuery(
      text: text ?? this.text,
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
      from: clearFrom ? null : (from ?? this.from),
      to: clearTo ? null : (to ?? this.to),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DiaryListQuery &&
        other.text == text &&
        other.favoritesOnly == favoritesOnly &&
        _sameDay(other.from, from) &&
        _sameDay(other.to, to);
  }

  @override
  int get hashCode => Object.hash(
        text,
        favoritesOnly,
        from?.millisecondsSinceEpoch,
        to?.millisecondsSinceEpoch,
      );

  static bool _sameDay(DateTime? a, DateTime? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return AppDateUtils.isSameDay(a, b);
  }
}

/// Запись дневника с прикреплёнными фото (для галереи).
class DiaryMemoryItem {
  const DiaryMemoryItem({
    required this.entry,
    required this.images,
  });

  final DiaryEntry entry;
  final List<DiaryImage> images;
}
