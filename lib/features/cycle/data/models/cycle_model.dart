import 'package:mycycle/core/utils/date_utils.dart';
import 'package:mycycle/features/cycle/domain/entities/cycle.dart';

/// Маппинг Cycle <-> SQLite Map.
abstract final class CycleModel {
  static Cycle fromMap(Map<String, dynamic> map) {
    return Cycle(
      id: map['id'] as String,
      startDate: AppDateUtils.fromIso(map['start_date'] as String),
      endDate: map['end_date'] != null
          ? AppDateUtils.fromIso(map['end_date'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  static Map<String, dynamic> toMap(Cycle cycle) {
    return {
      'id': cycle.id,
      'start_date': AppDateUtils.dateToIso(cycle.startDate),
      'end_date':
          cycle.endDate != null ? AppDateUtils.dateToIso(cycle.endDate!) : null,
      'created_at': cycle.createdAt.toIso8601String(),
    };
  }
}
