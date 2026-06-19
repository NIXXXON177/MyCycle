import 'package:mycycle/core/utils/date_utils.dart';

/// Сущность менструального цикла.
class Cycle {
  const Cycle({
    required this.id,
    required this.startDate,
    this.endDate,
    required this.createdAt,
  });

  final String id;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime createdAt;

  int get periodLength {
    if (endDate == null) return 0;
    return AppDateUtils.daysBetween(startDate, endDate!) + 1;
  }

  Cycle copyWith({
    String? id,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    bool clearEndDate = false,
  }) {
    return Cycle(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
