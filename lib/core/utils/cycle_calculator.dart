import 'package:mycycle/core/enums/cycle_phase.dart';
import 'package:mycycle/core/utils/date_utils.dart';
import 'package:mycycle/features/cycle/domain/entities/cycle.dart';
import 'package:mycycle/features/cycle/domain/entities/cycle_prediction.dart';

/// Сервис расчёта менструального цикла.
///
/// Использует историю циклов для вычисления средней длины цикла
/// и прогнозирования овуляции, фертильного окна и следующих месячных.
class CycleCalculator {
  const CycleCalculator({
    this.defaultCycleLength = 28,
    this.defaultPeriodLength = 5,
  });

  final int defaultCycleLength;
  final int defaultPeriodLength;

  /// Средняя длина цикла по истории (минимум 2 записи).
  int averageCycleLength(List<Cycle> cycles) {
    if (cycles.length < 2) return defaultCycleLength;

    final sorted = List<Cycle>.from(cycles)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    var total = 0;
    var count = 0;
    for (var i = 1; i < sorted.length; i++) {
      final diff = AppDateUtils.daysBetween(
        sorted[i - 1].startDate,
        sorted[i].startDate,
      );
      if (diff > 15 && diff < 45) {
        total += diff;
        count++;
      }
    }
    return count > 0 ? (total / count).round() : defaultCycleLength;
  }

  /// Средняя длительность месячных.
  int averagePeriodLength(List<Cycle> cycles) {
    final withEnd = cycles.where((c) => c.endDate != null).toList();
    if (withEnd.isEmpty) return defaultPeriodLength;

    var total = 0;
    for (final cycle in withEnd) {
      total += AppDateUtils.daysBetween(cycle.startDate, cycle.endDate!) + 1;
    }
    return (total / withEnd.length).round();
  }

  /// Регулярность цикла (стандартное отклонение в днях).
  double cycleRegularity(List<Cycle> cycles) {
    if (cycles.length < 3) return 0;

    final sorted = List<Cycle>.from(cycles)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    final lengths = <int>[];
    for (var i = 1; i < sorted.length; i++) {
      final diff = AppDateUtils.daysBetween(
        sorted[i - 1].startDate,
        sorted[i].startDate,
      );
      if (diff > 15 && diff < 45) lengths.add(diff);
    }
    if (lengths.length < 2) return 0;

    final avg = lengths.reduce((a, b) => a + b) / lengths.length;
    final variance = lengths
            .map((l) => (l - avg) * (l - avg))
            .reduce((a, b) => a + b) /
        lengths.length;
    return variance.sqrt();
  }

  /// Текущий день цикла (1 = первый день месячных).
  int currentCycleDay(List<Cycle> cycles, DateTime today) {
    final lastStart = _lastPeriodStart(cycles, today);
    if (lastStart == null) return 0;
    return AppDateUtils.daysBetween(lastStart, today) + 1;
  }

  /// Полный прогноз на основе истории.
  CyclePrediction predict(List<Cycle> cycles, DateTime today) {
    final avgCycle = averageCycleLength(cycles);
    final avgPeriod = averagePeriodLength(cycles);
    final lastStart = _lastPeriodStart(cycles, today);
    final cycleDay = lastStart != null
        ? AppDateUtils.daysBetween(lastStart, today) + 1
        : 0;

    DateTime? nextPeriod;
    DateTime? ovulation;
    DateTime? fertileStart;
    DateTime? fertileEnd;

    if (lastStart != null) {
      nextPeriod = lastStart.add(Duration(days: avgCycle));
      ovulation = nextPeriod.subtract(const Duration(days: 14));
      fertileStart = ovulation.subtract(const Duration(days: 5));
      fertileEnd = ovulation.add(const Duration(days: 1));
    }

    final phase = _determinePhase(cycleDay, avgPeriod, avgCycle);
    final daysUntilPeriod = nextPeriod != null
        ? AppDateUtils.daysBetween(today, nextPeriod)
        : null;

    return CyclePrediction(
      currentCycleDay: cycleDay,
      phase: phase,
      averageCycleLength: avgCycle,
      averagePeriodLength: avgPeriod,
      nextPeriodDate: nextPeriod,
      ovulationDate: ovulation,
      fertileWindowStart: fertileStart,
      fertileWindowEnd: fertileEnd,
      daysUntilNextPeriod: daysUntilPeriod,
      lastPeriodStart: lastStart,
    );
  }

  /// Проверяет, попадает ли дата в период месячных.
  bool isPeriodDay(List<Cycle> cycles, DateTime date) {
    for (final cycle in cycles) {
      final start = AppDateUtils.dateOnly(cycle.startDate);
      final end = cycle.endDate != null
          ? AppDateUtils.dateOnly(cycle.endDate!)
          : start.add(Duration(days: defaultPeriodLength - 1));
      if (!date.isBefore(start) && !date.isAfter(end)) return true;
    }
    return false;
  }

  /// Проверяет, является ли день овуляцией.
  bool isOvulationDay(CyclePrediction prediction, DateTime date) {
    if (prediction.ovulationDate == null) return false;
    return AppDateUtils.isSameDay(date, prediction.ovulationDate!);
  }

  /// Проверяет, входит ли день в фертильное окно.
  bool isFertileDay(CyclePrediction prediction, DateTime date) {
    if (prediction.fertileWindowStart == null ||
        prediction.fertileWindowEnd == null) {
      return false;
    }
    final d = AppDateUtils.dateOnly(date);
    return !d.isBefore(prediction.fertileWindowStart!) &&
        !d.isAfter(prediction.fertileWindowEnd!);
  }

  DateTime? _lastPeriodStart(List<Cycle> cycles, DateTime today) {
    if (cycles.isEmpty) return null;
    final sorted = List<Cycle>.from(cycles)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    for (final cycle in sorted) {
      if (!cycle.startDate.isAfter(today)) return cycle.startDate;
    }
    return sorted.last.startDate;
  }

  CyclePhase _determinePhase(int cycleDay, int periodLength, int cycleLength) {
    if (cycleDay <= 0) return CyclePhase.follicular;
    if (cycleDay <= periodLength) return CyclePhase.menstruation;
    if (cycleDay <= 13) return CyclePhase.follicular;
    if (cycleDay <= 16) return CyclePhase.ovulation;
    if (cycleDay >= cycleLength - 5) return CyclePhase.premenstrual;
    return CyclePhase.luteal;
  }
}

extension on double {
  double sqrt() {
    if (this <= 0) return 0;
    var x = this;
    var y = (x + 1) / 2;
    while ((y - x).abs() > 0.001) {
      x = y;
      y = (x + this / x) / 2;
    }
    return x;
  }
}
