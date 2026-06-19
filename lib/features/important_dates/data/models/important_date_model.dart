import 'package:mycycle/core/utils/date_utils.dart';
import 'package:mycycle/features/important_dates/domain/entities/important_date.dart';

abstract final class ImportantDateModel {
  static ImportantDate fromMap(Map<String, dynamic> map) {
    return ImportantDate(
      id: map['id'] as String,
      title: map['title'] as String,
      date: AppDateUtils.fromIso(map['date'] as String),
      repeatYearly: (map['repeat_yearly'] as int? ?? 0) == 1,
      createdAt: AppDateUtils.fromIso(map['created_at'] as String),
    );
  }

  static Map<String, dynamic> toMap(ImportantDate entry) {
    return {
      'id': entry.id,
      'title': entry.title,
      'date': AppDateUtils.dateToIso(entry.date),
      'repeat_yearly': entry.repeatYearly ? 1 : 0,
      'created_at': AppDateUtils.dateToIso(entry.createdAt),
    };
  }
}
