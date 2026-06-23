import 'package:florea/core/utils/date_utils.dart';

/// Важная дата (годовщина, день рождения и т.д.).
class ImportantDate {
  const ImportantDate({
    required this.id,
    required this.title,
    required this.date,
    this.repeatYearly = false,
    required this.createdAt,
  });

  final String id;
  final String title;
  final DateTime date;
  final bool repeatYearly;
  final DateTime createdAt;

  ImportantDate copyWith({
    String? id,
    String? title,
    DateTime? date,
    bool? repeatYearly,
    DateTime? createdAt,
  }) {
    return ImportantDate(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      repeatYearly: repeatYearly ?? this.repeatYearly,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Ближайшее наступление даты от [from] (с учётом ежегодного повтора).
  DateTime nextOccurrenceFrom(DateTime from) {
    final today = AppDateUtils.dateOnly(from);
    if (repeatYearly) {
      var occurrence = DateTime(today.year, date.month, date.day);
      if (occurrence.isBefore(today)) {
        occurrence = DateTime(today.year + 1, date.month, date.day);
      }
      return occurrence;
    }
    return AppDateUtils.dateOnly(date);
  }
}

/// Дата с вычисленным ближайшим наступлением.
class UpcomingImportantDate {
  const UpcomingImportantDate({
    required this.entry,
    required this.occurrence,
  });

  final ImportantDate entry;
  final DateTime occurrence;

  int daysUntil(DateTime from) =>
      AppDateUtils.daysBetween(from, occurrence);
}
