import 'package:florea/core/enums/mood_level.dart';
import 'package:florea/core/utils/cycle_calculator.dart';
import 'package:florea/core/utils/date_utils.dart';
import 'package:florea/features/cycle/domain/entities/cycle.dart';
import 'package:florea/features/wellbeing/domain/entities/wellbeing_entry.dart';

/// Сводка настроения за период.
class EmotionalTimelineSummary {
  const EmotionalTimelineSummary({
    required this.goodDays,
    required this.normalDays,
    required this.badDays,
    required this.insight,
  });

  final int goodDays;
  final int normalDays;
  final int badDays;
  final String? insight;
}

/// Эмоциональная лента на основе самочувствия.
abstract final class EmotionalTimelineAnalyzer {
  static EmotionalTimelineSummary analyze({
    required List<WellbeingEntry> wellbeing,
    required List<Cycle> cycles,
    required CycleCalculator calculator,
    int days = 30,
  }) {
    final cutoff = AppDateUtils.dateOnly(
      DateTime.now().subtract(Duration(days: days)),
    );

    var good = 0;
    var normal = 0;
    var bad = 0;

    final recent = wellbeing
        .where((e) => !AppDateUtils.dateOnly(e.date).isBefore(cutoff))
        .toList();

    for (final entry in recent) {
      if (entry.mood.value >= MoodLevel.good.value) {
        good++;
      } else if (entry.mood.value >= MoodLevel.normal.value) {
        normal++;
      } else {
        bad++;
      }
    }

    final insight = _cycleInsight(recent, cycles, calculator);

    return EmotionalTimelineSummary(
      goodDays: good,
      normalDays: normal,
      badDays: bad,
      insight: insight,
    );
  }

  static String? _cycleInsight(
    List<WellbeingEntry> recent,
    List<Cycle> cycles,
    CycleCalculator calculator,
  ) {
    if (recent.length < 5 || cycles.isEmpty) return null;

    var goodFirstHalf = 0;
    var goodSecondHalf = 0;
    var firstHalfTotal = 0;
    var secondHalfTotal = 0;

    for (final entry in recent) {
      final day = calculator.currentCycleDay(cycles, entry.date);
      if (day <= 0) continue;

      final avgCycle = calculator.averageCycleLength(cycles);
      final isGood = entry.mood.value >= MoodLevel.good.value;

      if (day <= avgCycle ~/ 2) {
        firstHalfTotal++;
        if (isGood) goodFirstHalf++;
      } else {
        secondHalfTotal++;
        if (isGood) goodSecondHalf++;
      }
    }

    if (firstHalfTotal >= 3 && secondHalfTotal >= 3) {
      final firstRate = goodFirstHalf / firstHalfTotal;
      final secondRate = goodSecondHalf / secondHalfTotal;

      if (firstRate - secondRate >= 0.2) {
        return 'Чаще всего хорошее настроение наблюдалось '
            'в первой половине цикла';
      }
      if (secondRate - firstRate >= 0.2) {
        return 'Чаще всего хорошее настроение наблюдалось '
            'во второй половине цикла';
      }
    }

    if (goodFirstHalf + goodSecondHalf == 0) return null;

    return 'Отмечай настроение чаще — закономерности станут точнее';
  }
}
