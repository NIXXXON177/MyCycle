import 'package:florea/core/enums/cycle_phase.dart';
import 'package:florea/core/enums/energy_level.dart';
import 'package:florea/core/enums/mood_level.dart';
import 'package:florea/core/enums/pain_level.dart';
import 'package:florea/core/enums/pms_symptom.dart';
import 'package:florea/core/utils/cycle_calculator.dart';
import 'package:florea/core/utils/date_utils.dart';
import 'package:florea/features/cycle/domain/entities/cycle.dart';
import 'package:florea/features/wellbeing/domain/entities/wellbeing_entry.dart';

/// Период для графика индекса.
enum IndexChartPeriod {
  days7('7 дней'),
  days30('30 дней'),
  currentCycle('Цикл'),
  all('Всё время');

  const IndexChartPeriod(this.label);

  final String label;
}

/// Уровень индекса самочувствия.
class WellbeingIndexLevel {
  const WellbeingIndexLevel(this.label, this.minScore);

  final String label;
  final int minScore;

  static const levels = [
    WellbeingIndexLevel('Отличное', 80),
    WellbeingIndexLevel('Хорошее', 60),
    WellbeingIndexLevel('Среднее', 40),
    WellbeingIndexLevel('Низкое', 20),
    WellbeingIndexLevel('Очень низкое', 0),
  ];

  static String labelFor(int index) {
    final value = index.clamp(0, 100);
    for (final level in levels) {
      if (value >= level.minScore) return level.label;
    }
    return levels.last.label;
  }
}

/// Точка на графике индекса.
class IndexChartPoint {
  const IndexChartPoint({
    required this.date,
    required this.index,
    this.cycleDay,
  });

  final DateTime date;
  final int index;
  final int? cycleDay;
}

/// Самый частый симптом ПМС.
class TopSymptomInsight {
  const TopSymptomInsight({
    required this.symptom,
    required this.count,
  });

  final PmsSymptom symptom;
  final int count;
}

/// Результат анализа закономерностей.
class PatternAnalysisResult {
  const PatternAnalysisResult({
    required this.insights,
    this.topSymptom,
    this.bestDaysRange,
    this.hardestDaysRange,
  });

  final List<String> insights;
  final TopSymptomInsight? topSymptom;
  final String? bestDaysRange;
  final String? hardestDaysRange;
}

/// Расчёт индекса самочувствия (0–100) и аналитика.
abstract final class WellbeingIndexCalculator {
  static const disclaimer =
      'Индекс рассчитывается на основе ваших отметок и служит '
      'только для личного наблюдения.';

  static int calculate(WellbeingEntry entry) {
    final mood = _moodScore(entry.mood);
    final energy = _energyScore(entry.energy);
    final pain = _painScore(entry.pain);
    final pms = _pmsScore(entry.pmsSymptoms);

    final raw = mood * 0.4 + energy * 0.3 + pain * 0.2 + pms * 0.1;
    return raw.round().clamp(0, 100);
  }

  static double averageIndex(List<WellbeingEntry> entries) {
    if (entries.isEmpty) return 0;
    final sum = entries.fold<int>(0, (s, e) => s + calculate(e));
    return sum / entries.length;
  }

  static List<IndexChartPoint> chartPoints({
    required List<WellbeingEntry> wellbeing,
    required List<Cycle> cycles,
    required CycleCalculator calculator,
    required IndexChartPeriod period,
  }) {
    final filtered = _filterByPeriod(
      wellbeing: wellbeing,
      cycles: cycles,
      period: period,
    );
    final sorted = List<WellbeingEntry>.from(filtered)
      ..sort((a, b) => a.date.compareTo(b.date));

    return sorted.map((entry) {
      final day = cycles.isEmpty
          ? null
          : calculator.currentCycleDay(cycles, entry.date);
      return IndexChartPoint(
        date: entry.date,
        index: calculate(entry),
        cycleDay: day != null && day > 0 ? day : null,
      );
    }).toList();
  }

  static List<WellbeingEntry> _filterByPeriod({
    required List<WellbeingEntry> wellbeing,
    required List<Cycle> cycles,
    required IndexChartPeriod period,
  }) {
    final today = AppDateUtils.dateOnly(DateTime.now());

    return switch (period) {
      IndexChartPeriod.days7 => wellbeing
          .where(
            (e) => !AppDateUtils.dateOnly(e.date).isBefore(
              today.subtract(const Duration(days: 6)),
            ),
          )
          .toList(),
      IndexChartPeriod.days30 => wellbeing
          .where(
            (e) => !AppDateUtils.dateOnly(e.date).isBefore(
              today.subtract(const Duration(days: 29)),
            ),
          )
          .toList(),
      IndexChartPeriod.currentCycle => _currentCycleEntries(wellbeing, cycles),
      IndexChartPeriod.all => wellbeing,
    };
  }

  static List<WellbeingEntry> _currentCycleEntries(
    List<WellbeingEntry> wellbeing,
    List<Cycle> cycles,
  ) {
    if (cycles.isEmpty) return [];
    final sorted = List<Cycle>.from(cycles)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    final latest = sorted.firstWhere(
      (c) => !c.startDate.isAfter(DateTime.now()),
      orElse: () => sorted.first,
    );
    final start = AppDateUtils.dateOnly(latest.startDate);
    return wellbeing
        .where((e) => !AppDateUtils.dateOnly(e.date).isBefore(start))
        .toList();
  }

  static int _moodScore(MoodLevel mood) => switch (mood) {
        MoodLevel.excellent => 100,
        MoodLevel.good => 80,
        MoodLevel.normal => 60,
        MoodLevel.bad => 40,
        MoodLevel.veryBad => 20,
      };

  static int _energyScore(EnergyLevel energy) => switch (energy) {
        EnergyLevel.high => 100,
        EnergyLevel.medium => 60,
        EnergyLevel.low => 20,
      };

  static int _painScore(PainLevel pain) => switch (pain) {
        PainLevel.none => 100,
        PainLevel.mild => 75,
        PainLevel.moderate => 50,
        PainLevel.severe => 25,
      };

  static int _pmsScore(List<PmsSymptom> symptoms) {
    final penalty = symptoms.length * 5;
    return (100 - penalty).clamp(0, 100);
  }

  static IndexComparison compareToday({
    required WellbeingEntry? today,
    required List<WellbeingEntry> all,
  }) {
    if (today == null) {
      return IndexComparison(
        todayIndex: -1,
        personalAverage: averageIndex(all),
      );
    }
    return IndexComparison(
      todayIndex: calculate(today),
      personalAverage: averageIndex(all),
    );
  }
}

/// Сравнение сегодняшнего индекса с личной средней.
class IndexComparison {
  const IndexComparison({
    required this.todayIndex,
    required this.personalAverage,
  });

  final int todayIndex;
  final double personalAverage;

  bool get hasToday => todayIndex >= 0;

  int get todayScore => todayIndex.clamp(0, 100);

  String? get trendLabel {
    if (!hasToday || personalAverage <= 0) return null;
    final diff = todayScore - personalAverage;
    if (diff >= 8) return '📈 лучше обычного';
    if (diff <= -8) return '📉 хуже обычного';
    return '➡️ как обычно';
  }
}

/// Умные закономерности с процентами.
abstract final class SmartPatternsAnalyzer {
  static PatternAnalysisResult analyze({
    required List<Cycle> cycles,
    required List<WellbeingEntry> wellbeing,
    required int averageCycleLength,
    required int averagePeriodLength,
    required CycleCalculator calculator,
  }) {
    final insights = <String>[];

    if (cycles.length >= 2) {
      insights.add(
        'Средний цикл составляет $averageCycleLength '
        '${_dayWord(averageCycleLength)}',
      );
      insights.add(
        'Средняя длительность месячных — $averagePeriodLength '
        '${_dayWord(averagePeriodLength)}',
      );
    }

    final moodInsight = _moodBeforePeriodPercent(cycles, wellbeing);
    if (moodInsight != null) insights.add(moodInsight);

    final energyInsight = _lowEnergyLutealPercent(
      cycles,
      wellbeing,
      averageCycleLength,
      calculator,
    );
    if (energyInsight != null) insights.add(energyInsight);

    final painInsight = _painEarlyCyclePercent(cycles, wellbeing);
    if (painInsight != null) insights.add(painInsight);

    final pmsInsight = _pmsSymptomPercent(cycles, wellbeing);
    if (pmsInsight != null) insights.add(pmsInsight);

    final bestRange = _bestDayRange(cycles, wellbeing, calculator);
    final hardRange = _hardestDayRange(cycles, wellbeing, calculator);
    final topSymptom = _topSymptom(wellbeing);

    if (bestRange != null) {
      insights.add(
        'Лучшее самочувствие обычно наблюдается на $bestRange день цикла',
      );
    }
    if (hardRange != null) {
      insights.add('Самые сложные дни: $hardRange день цикла');
    }

    if (insights.length <= 2 && wellbeing.length < 5) {
      insights.add(
        'Пока недостаточно данных. Продолжай отмечать самочувствие — '
        'закономерности появятся!',
      );
    }

    return PatternAnalysisResult(
      insights: insights,
      topSymptom: topSymptom,
      bestDaysRange: bestRange,
      hardestDaysRange: hardRange,
    );
  }

  static String? _moodBeforePeriodPercent(
    List<Cycle> cycles,
    List<WellbeingEntry> wellbeing,
  ) {
    if (cycles.length < 3) return null;

    var matched = 0;
    var checked = 0;
    for (final cycle in cycles) {
      var hadBadMood = false;
      var hadEntry = false;
      for (var d = 1; d <= 3; d++) {
        final date = cycle.startDate.subtract(Duration(days: d));
        final entry = _entryOn(wellbeing, date);
        if (entry != null) {
          hadEntry = true;
          if (entry.mood.value <= MoodLevel.bad.value) hadBadMood = true;
        }
      }
      if (!hadEntry) continue;
      checked++;
      if (hadBadMood) matched++;
    }

    if (checked < 2) return null;
    final pct = (matched / checked * 100).round();
    if (pct < 40) return null;
    return 'Плохое настроение наблюдалось за 1–3 дня до месячных '
        'в $pct% циклов';
  }

  static String? _lowEnergyLutealPercent(
    List<Cycle> cycles,
    List<WellbeingEntry> wellbeing,
    int avgCycleLength,
    CycleCalculator calculator,
  ) {
    if (wellbeing.length < 8 || cycles.isEmpty) return null;

    var lowInLuteal = 0;
    var totalLuteal = 0;

    for (final entry in wellbeing) {
      final day = calculator.currentCycleDay(cycles, entry.date);
      if (day <= 0) continue;
      final phase = _phaseForDay(day, avgCycleLength);
      if (phase != CyclePhase.luteal && phase != CyclePhase.premenstrual) {
        continue;
      }
      totalLuteal++;
      if (entry.energy == EnergyLevel.low) lowInLuteal++;
    }

    if (totalLuteal < 4) return null;
    final pct = (lowInLuteal / totalLuteal * 100).round();
    if (pct < 45) return null;
    return 'Низкая энергия чаще встречается в лютеиновой фазе ($pct%)';
  }

  static String? _painEarlyCyclePercent(
    List<Cycle> cycles,
    List<WellbeingEntry> wellbeing,
  ) {
    if (cycles.length < 2) return null;

    var matched = 0;
    var checked = 0;
    for (final cycle in cycles) {
      var hadPain = false;
      var hadEntry = false;
      for (var day = 1; day <= 2; day++) {
        final date = cycle.startDate.add(Duration(days: day - 1));
        final entry = _entryOn(wellbeing, date);
        if (entry != null) {
          hadEntry = true;
          if (entry.pain.value >= PainLevel.moderate.value) hadPain = true;
        }
      }
      if (!hadEntry) continue;
      checked++;
      if (hadPain) matched++;
    }

    if (checked < 2) return null;
    final pct = (matched / checked * 100).round();
    if (pct < 40) return null;
    return 'Боль чаще возникает на 1–2 день цикла ($pct%)';
  }

  static String? _pmsSymptomPercent(
    List<Cycle> cycles,
    List<WellbeingEntry> wellbeing,
  ) {
    if (cycles.length < 2) return null;

    final symptomHits = <PmsSymptom, int>{};
    var cyclesChecked = 0;

    for (final cycle in cycles) {
      var cycleSymptoms = <PmsSymptom>{};
      var hadEntry = false;
      for (var d = 1; d <= 7; d++) {
        final date = cycle.startDate.subtract(Duration(days: d));
        final entry = _entryOn(wellbeing, date);
        if (entry == null || entry.pmsSymptoms.isEmpty) continue;
        hadEntry = true;
        cycleSymptoms.addAll(entry.pmsSymptoms);
      }
      if (!hadEntry) continue;
      cyclesChecked++;
      for (final s in cycleSymptoms) {
        symptomHits[s] = (symptomHits[s] ?? 0) + 1;
      }
    }

    if (cyclesChecked < 2 || symptomHits.isEmpty) return null;
    final top = symptomHits.entries.reduce((a, b) => a.value > b.value ? a : b);
    final pct = (top.value / cyclesChecked * 100).round();
    if (pct < 35) return null;
    return '${top.key.emoji} ${top.key.label} появляется в $pct% циклов '
        'за неделю до месячных';
  }

  static TopSymptomInsight? _topSymptom(List<WellbeingEntry> wellbeing) {
    final counts = <PmsSymptom, int>{};
    for (final entry in wellbeing) {
      for (final s in entry.pmsSymptoms) {
        counts[s] = (counts[s] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return null;
    final top = counts.entries.reduce((a, b) => a.value > b.value ? a : b);
    if (top.value < 2) return null;
    return TopSymptomInsight(symptom: top.key, count: top.value);
  }

  static String? _bestDayRange(
    List<Cycle> cycles,
    List<WellbeingEntry> wellbeing,
    CycleCalculator calculator,
  ) {
    return _dayRangeByIndex(cycles, wellbeing, calculator, findMax: true);
  }

  static String? _hardestDayRange(
    List<Cycle> cycles,
    List<WellbeingEntry> wellbeing,
    CycleCalculator calculator,
  ) {
    return _dayRangeByIndex(cycles, wellbeing, calculator, findMax: false);
  }

  static String? _dayRangeByIndex(
    List<Cycle> cycles,
    List<WellbeingEntry> wellbeing,
    CycleCalculator calculator, {
    required bool findMax,
  }) {
    final dayAvgs = <int, List<int>>{};
    for (final entry in wellbeing) {
      final day = calculator.currentCycleDay(cycles, entry.date);
      if (day < 1 || day > 35) continue;
      dayAvgs.putIfAbsent(day, () => []).add(
            WellbeingIndexCalculator.calculate(entry),
          );
    }

    if (dayAvgs.length < 3) return null;

    const window = 3;
    double? bestAvg;
    int? bestStart;

    for (var start = 1; start <= 33; start++) {
      final scores = <int>[];
      for (var d = start; d < start + window; d++) {
        scores.addAll(dayAvgs[d] ?? []);
      }
      if (scores.length < 2) continue;
      final avg = scores.reduce((a, b) => a + b) / scores.length;
      if (bestAvg == null ||
          (findMax && avg > bestAvg) ||
          (!findMax && avg < bestAvg)) {
        bestAvg = avg;
        bestStart = start;
      }
    }

    if (bestStart == null) return null;
    final end = bestStart + window - 1;
    return bestStart == end ? '$bestStart' : '$bestStart–$end';
  }

  static CyclePhase _phaseForDay(int cycleDay, int avgCycleLength) {
    if (cycleDay <= 5) return CyclePhase.menstruation;
    if (cycleDay <= 13) return CyclePhase.follicular;
    if (cycleDay <= 16) return CyclePhase.ovulation;
    if (cycleDay >= avgCycleLength - 5) return CyclePhase.premenstrual;
    return CyclePhase.luteal;
  }

  static WellbeingEntry? _entryOn(List<WellbeingEntry> all, DateTime date) {
    final match = all.where((w) => AppDateUtils.isSameDay(w.date, date));
    return match.isEmpty ? null : match.first;
  }

  static String _dayWord(int days) {
    final mod10 = days % 10;
    final mod100 = days % 100;
    if (mod100 >= 11 && mod100 <= 19) return 'дней';
    if (mod10 == 1) return 'день';
    if (mod10 >= 2 && mod10 <= 4) return 'дня';
    return 'дней';
  }
}
