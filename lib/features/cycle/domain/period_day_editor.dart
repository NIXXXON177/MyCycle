import 'package:florea/core/utils/date_utils.dart';
import 'package:florea/features/cycle/domain/entities/cycle.dart';

/// Операция изменения цикла после toggle дня месячных.
sealed class PeriodDayOp {
  const PeriodDayOp();
}

/// Создать новый цикл с явными границами.
class PeriodDayCreate extends PeriodDayOp {
  const PeriodDayCreate({
    required this.startDate,
    required this.endDate,
  });

  final DateTime startDate;
  final DateTime endDate;
}

/// Обновить существующий цикл.
class PeriodDayUpdate extends PeriodDayOp {
  const PeriodDayUpdate(this.cycle);

  final Cycle cycle;
}

/// Удалить цикл по id.
class PeriodDayDelete extends PeriodDayOp {
  const PeriodDayDelete(this.id);

  final String id;
}

/// Результат переключения дня месячных.
class PeriodDayEditResult {
  const PeriodDayEditResult({
    required this.ops,
    required this.isPeriodDay,
  });

  final List<PeriodDayOp> ops;

  /// Статус дня после применения операций.
  final bool isPeriodDay;
}

/// Чистая логика: день месячных ↔ диапазоны [Cycle].
abstract final class PeriodDayEditor {
  /// Переключает [day]: если день уже в периоде — снимает, иначе ставит.
  static PeriodDayEditResult toggle({
    required List<Cycle> cycles,
    required DateTime day,
    int defaultPeriodLength = 5,
  }) {
    final target = AppDateUtils.dateOnly(day);
    final ranges = cycles
        .map((c) => _Range.fromCycle(c, defaultPeriodLength))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    final covering = ranges.where((r) => r.contains(target)).toList();
    if (covering.isNotEmpty) {
      return PeriodDayEditResult(
        ops: _removeDay(ranges, covering.first, target),
        isPeriodDay: false,
      );
    }

    return PeriodDayEditResult(
      ops: _addDay(ranges, target),
      isPeriodDay: true,
    );
  }

  static List<PeriodDayOp> _addDay(List<_Range> ranges, DateTime day) {
    final prevDay = day.subtract(const Duration(days: 1));
    final nextDay = day.add(const Duration(days: 1));

    _Range? left;
    _Range? right;
    for (final r in ranges) {
      if (r.end == prevDay) left = r;
      if (r.start == nextDay) right = r;
    }

    if (left != null && right != null) {
      return [
        PeriodDayUpdate(
          left.cycle.copyWith(
            startDate: left.start,
            endDate: right.end,
          ),
        ),
        PeriodDayDelete(right.cycle.id),
      ];
    }

    if (left != null) {
      return [
        PeriodDayUpdate(
          left.cycle.copyWith(
            startDate: left.start,
            endDate: day,
          ),
        ),
      ];
    }

    if (right != null) {
      return [
        PeriodDayUpdate(
          right.cycle.copyWith(
            startDate: day,
            endDate: right.end,
          ),
        ),
      ];
    }

    return [
      PeriodDayCreate(startDate: day, endDate: day),
    ];
  }

  static List<PeriodDayOp> _removeDay(
    List<_Range> ranges,
    _Range covering,
    DateTime day,
  ) {
    final start = covering.start;
    final end = covering.end;

    if (AppDateUtils.isSameDay(start, end)) {
      return [PeriodDayDelete(covering.cycle.id)];
    }

    if (AppDateUtils.isSameDay(day, start)) {
      return [
        PeriodDayUpdate(
          covering.cycle.copyWith(
            startDate: day.add(const Duration(days: 1)),
            endDate: end,
          ),
        ),
      ];
    }

    if (AppDateUtils.isSameDay(day, end)) {
      return [
        PeriodDayUpdate(
          covering.cycle.copyWith(
            startDate: start,
            endDate: day.subtract(const Duration(days: 1)),
          ),
        ),
      ];
    }

    // Середина: левая часть остаётся, правая — новый цикл.
    return [
      PeriodDayUpdate(
        covering.cycle.copyWith(
          startDate: start,
          endDate: day.subtract(const Duration(days: 1)),
        ),
      ),
      PeriodDayCreate(
        startDate: day.add(const Duration(days: 1)),
        endDate: end,
      ),
    ];
  }
}

class _Range {
  const _Range({
    required this.cycle,
    required this.start,
    required this.end,
  });

  final Cycle cycle;
  final DateTime start;
  final DateTime end;

  factory _Range.fromCycle(Cycle cycle, int defaultPeriodLength) {
    final start = AppDateUtils.dateOnly(cycle.startDate);
    final end = cycle.endDate != null
        ? AppDateUtils.dateOnly(cycle.endDate!)
        : start.add(Duration(days: defaultPeriodLength - 1));
    return _Range(cycle: cycle, start: start, end: end);
  }

  bool contains(DateTime day) {
    return !day.isBefore(start) && !day.isAfter(end);
  }
}
