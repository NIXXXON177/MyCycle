import 'package:florea/core/enums/cycle_phase.dart';
import 'package:florea/core/enums/intimacy_type.dart';
import 'package:florea/core/utils/cycle_calculator.dart';
import 'package:florea/core/utils/date_utils.dart';
import 'package:florea/features/cycle/domain/entities/cycle.dart';
import 'package:florea/features/wellbeing/domain/entities/wellbeing_entry.dart';

/// Статистика близости за период.
class IntimacyStats {
  const IntimacyStats({
    required this.total,
    required this.withEjaculation,
    required this.withoutEjaculation,
    required this.byPhase,
  });

  final int total;
  final int withEjaculation;
  final int withoutEjaculation;
  final Map<CyclePhase, int> byPhase;
}

/// Анализ отметок близости по месяцам и фазам цикла.
abstract final class IntimacyAnalyzer {
  static IntimacyStats forMonth({
    required List<WellbeingEntry> wellbeing,
    required List<Cycle> cycles,
    required CycleCalculator calculator,
    DateTime? reference,
  }) {
    final now = reference ?? DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final monthEnd = DateTime(now.year, now.month + 1);

    var total = 0;
    var withEjac = 0;
    var withoutEjac = 0;
    final byPhase = <CyclePhase, int>{};

    for (final entry in wellbeing) {
      if (entry.intimacy == IntimacyType.none) continue;
      final date = AppDateUtils.dateOnly(entry.date);
      if (date.isBefore(monthStart) || !date.isBefore(monthEnd)) continue;

      total++;
      if (entry.intimacy == IntimacyType.withEjaculation) {
        withEjac++;
      } else {
        withoutEjac++;
      }

      final phase = calculator.predict(cycles, date).phase;
      byPhase[phase] = (byPhase[phase] ?? 0) + 1;
    }

    return IntimacyStats(
      total: total,
      withEjaculation: withEjac,
      withoutEjaculation: withoutEjac,
      byPhase: byPhase,
    );
  }
}
