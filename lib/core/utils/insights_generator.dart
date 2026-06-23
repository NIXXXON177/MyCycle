import 'package:florea/core/enums/cycle_phase.dart';
import 'package:florea/core/enums/energy_level.dart';
import 'package:florea/core/enums/pms_symptom.dart';
import 'package:florea/core/utils/date_utils.dart';
import 'package:florea/features/cycle/domain/entities/cycle.dart';
import 'package:florea/features/cycle/domain/entities/cycle_prediction.dart';
import 'package:florea/features/wellbeing/domain/entities/wellbeing_entry.dart';

/// Генератор текстов для режима партнёра.
///
/// Использует простой, понятный язык без медицинских терминов.
class PartnerTipsGenerator {
  const PartnerTipsGenerator();

  List<String> generateTips(CyclePrediction prediction) {
    final tips = <String>[];

    if (prediction.daysUntilNextPeriod != null) {
      final days = prediction.daysUntilNextPeriod!;
      if (days > 0) {
        tips.add('До начала месячных осталось $days ${_dayWord(days)}');
      } else if (days == 0) {
        tips.add('Месячные могут начаться сегодня');
      } else {
        tips.add('Месячные уже идут');
      }
    }

    switch (prediction.phase) {
      case CyclePhase.menstruation:
        tips.add('Сейчас может быть дискомфорт — предложи тепло и заботу');
        tips.add('Лучше не планировать ничего слишком активного');
      case CyclePhase.follicular:
        tips.add('Настроение обычно улучшается — хорошее время для совместных планов');
        tips.add('Энергии становится больше');
      case CyclePhase.ovulation:
        tips.add('Сейчас часто много энергии и хорошее настроение');
        tips.add('Отличное время для романтики');
      case CyclePhase.luteal:
        tips.add('Возможна повышенная чувствительность');
        tips.add('Сегодня лучше избегать лишнего стресса');
      case CyclePhase.premenstrual:
        tips.add('Возможны перепады настроения — будь терпелив');
        tips.add('Маленькие знаки внимания сейчас особенно важны');
        tips.add('Предложи что-то вкусное или уютное');
    }

    return tips;
  }

  String approximateWellbeing(CyclePrediction prediction) {
    switch (prediction.phase) {
      case CyclePhase.menstruation:
        return 'Возможен дискомфорт и усталость';
      case CyclePhase.follicular:
        return 'Скорее всего хорошее самочувствие';
      case CyclePhase.ovulation:
        return 'Обычно отличное настроение и энергия';
      case CyclePhase.luteal:
        return 'Возможна повышенная чувствительность';
      case CyclePhase.premenstrual:
        return 'Может быть усталость или капризное настроение';
    }
  }

  String phaseLabelForPartner(CyclePhase phase) {
    switch (phase) {
      case CyclePhase.menstruation:
        return 'Идут месячные';
      case CyclePhase.follicular:
        return 'Спокойная фаза';
      case CyclePhase.ovulation:
        return 'Активная фаза';
      case CyclePhase.luteal:
        return 'Чувствительная фаза';
      case CyclePhase.premenstrual:
        return 'Перед месячными';
    }
  }

  String _dayWord(int days) {
    final mod10 = days % 10;
    final mod100 = days % 100;
    if (mod100 >= 11 && mod100 <= 19) return 'дней';
    if (mod10 == 1) return 'день';
    if (mod10 >= 2 && mod10 <= 4) return 'дня';
    return 'дней';
  }
}

/// Генератор инсайтов для экрана «Закономерности».
class PatternsAnalyzer {
  const PatternsAnalyzer();

  List<String> analyze({
    required List<Cycle> cycles,
    required List<WellbeingEntry> wellbeing,
    required int averageCycleLength,
    required int averagePeriodLength,
  }) {
    final insights = <String>[];

    if (cycles.length >= 2) {
      insights.add(
        'Средний цикл составляет $averageCycleLength ${_dayWord(averageCycleLength)}',
      );
    }

    if (cycles.length >= 2) {
      insights.add(
        'Средняя длительность месячных — $averagePeriodLength ${_dayWord(averagePeriodLength)}',
      );
    }

    final moodInsight = _analyzeMoodBeforePeriod(cycles, wellbeing);
    if (moodInsight != null) insights.add(moodInsight);

    final painInsight = _analyzePainOnCycleDay(cycles, wellbeing);
    if (painInsight != null) insights.add(painInsight);

    final energyInsight = _analyzeEnergyByPhase(cycles, wellbeing, averageCycleLength);
    if (energyInsight != null) insights.add(energyInsight);

    final pmsInsight = _analyzePmsSymptoms(cycles, wellbeing);
    if (pmsInsight != null) insights.add(pmsInsight);

    if (insights.isEmpty) {
      insights.add(
        'Пока недостаточно данных. Продолжай отмечать самочувствие — закономерности появятся!',
      );
    }

    return insights;
  }

  String? _analyzeMoodBeforePeriod(
    List<Cycle> cycles,
    List<WellbeingEntry> wellbeing,
  ) {
    if (cycles.length < 3 || wellbeing.isEmpty) return null;

    final badMoodDays = <int>[];
    for (final cycle in cycles) {
      for (var daysBefore = 1; daysBefore <= 5; daysBefore++) {
        final date = cycle.startDate.subtract(Duration(days: daysBefore));
        final entry = wellbeing.where(
          (w) => AppDateUtils.isSameDay(w.date, date),
        );
        if (entry.isNotEmpty && entry.first.mood.value <= 2) {
          badMoodDays.add(daysBefore);
        }
      }
    }

    if (badMoodDays.length < 2) return null;

    final counts = <int, int>{};
    for (final d in badMoodDays) {
      counts[d] = (counts[d] ?? 0) + 1;
    }
    final mostCommon = counts.entries.reduce((a, b) => a.value > b.value ? a : b);

    return 'За последние ${cycles.length} циклов плохое настроение '
        'чаще всего появлялось за ${mostCommon.key} ${_dayWord(mostCommon.key)} '
        'до месячных';
  }

  String? _analyzePainOnCycleDay(
    List<Cycle> cycles,
    List<WellbeingEntry> wellbeing,
  ) {
    if (cycles.isEmpty || wellbeing.isEmpty) return null;

    final painDays = <int>[];
    for (final cycle in cycles) {
      for (var day = 1; day <= 5; day++) {
        final date = cycle.startDate.add(Duration(days: day - 1));
        final entry = wellbeing.where(
          (w) => AppDateUtils.isSameDay(w.date, date),
        );
        if (entry.isNotEmpty && entry.first.pain.value >= 2) {
          painDays.add(day);
        }
      }
    }

    if (painDays.length < 2) return null;

    final counts = <int, int>{};
    for (final d in painDays) {
      counts[d] = (counts[d] ?? 0) + 1;
    }
    final mostCommon = counts.entries.reduce((a, b) => a.value > b.value ? a : b);

    return 'Боль чаще отмечается на ${mostCommon.key}-й день цикла';
  }

  String? _analyzeEnergyByPhase(
    List<Cycle> cycles,
    List<WellbeingEntry> wellbeing,
    int avgCycleLength,
  ) {
    if (wellbeing.length < 10) return null;

    var lowEnergyCount = 0;
    var totalPremenstrual = 0;

    for (final cycle in cycles) {
      for (var d = avgCycleLength - 5; d <= avgCycleLength; d++) {
        if (d <= 0) continue;
        final date = cycle.startDate.add(Duration(days: d - 1));
        final entry = wellbeing.where(
          (w) => AppDateUtils.isSameDay(w.date, date),
        );
        if (entry.isNotEmpty) {
          totalPremenstrual++;
          if (entry.first.energy == EnergyLevel.low) lowEnergyCount++;
        }
      }
    }

    if (totalPremenstrual < 3) return null;
    final percent = (lowEnergyCount / totalPremenstrual * 100).round();
    if (percent >= 50) {
      return 'Перед месячными низкая энергия отмечается в $percent% случаев';
    }
    return null;
  }

  String? _analyzePmsSymptoms(
    List<Cycle> cycles,
    List<WellbeingEntry> wellbeing,
  ) {
    if (cycles.length < 2 || wellbeing.isEmpty) return null;

    final counts = <PmsSymptom, int>{};
    for (final cycle in cycles) {
      for (var daysBefore = 1; daysBefore <= 7; daysBefore++) {
        final date = cycle.startDate.subtract(Duration(days: daysBefore));
        final entry = wellbeing.where(
          (w) => AppDateUtils.isSameDay(w.date, date),
        );
        if (entry.isEmpty) continue;
        for (final symptom in entry.first.pmsSymptoms) {
          counts[symptom] = (counts[symptom] ?? 0) + 1;
        }
      }
    }

    if (counts.isEmpty) return null;
    final top = counts.entries.reduce((a, b) => a.value > b.value ? a : b);
    if (top.value < 2) return null;

    return 'Перед месячными чаще всего отмечается: '
        '${top.key.emoji} ${top.key.label}';
  }

  String _dayWord(int days) {
    final mod10 = days % 10;
    final mod100 = days % 100;
    if (mod100 >= 11 && mod100 <= 19) return 'дней';
    if (mod10 == 1) return 'день';
    if (mod10 >= 2 && mod10 <= 4) return 'дня';
    return 'дней';
  }
}
