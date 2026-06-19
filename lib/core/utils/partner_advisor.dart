import 'dart:math';

import 'package:mycycle/core/enums/cycle_phase.dart';
import 'package:mycycle/core/enums/energy_level.dart';
import 'package:mycycle/core/enums/mood_level.dart';
import 'package:mycycle/core/enums/pain_level.dart';
import 'package:mycycle/core/enums/support_event_type.dart';
import 'package:mycycle/core/enums/wish_priority.dart';
import 'package:mycycle/core/utils/date_utils.dart';
import 'package:mycycle/features/cycle/domain/entities/cycle_prediction.dart';
import 'package:mycycle/features/support/domain/entities/support_event.dart';
import 'package:mycycle/features/wellbeing/domain/entities/wellbeing_entry.dart';
import 'package:mycycle/features/wishes/domain/entities/wish.dart';

/// Упрощённый эмоциональный индикатор для партнёра.
class PartnerEmotionalState {
  const PartnerEmotionalState({
    required this.emoji,
    required this.label,
    required this.hint,
  });

  final String emoji;
  final String label;
  final String hint;
}

/// Статистика запросов поддержки за месяц.
class SupportMonthSummary {
  const SupportMonthSummary({required this.lines});

  final List<String> lines;

  bool get isEmpty => lines.isEmpty;
}

/// План на сегодня для партнёра.
class PartnerTodayPlan {
  const PartnerTodayPlan({
    required this.canDo,
    required this.betterToday,
  });

  final List<String> canDo;
  final List<String> betterToday;
}

/// Локальный советник для режима «Для парня».
class PartnerAdvisor {
  const PartnerAdvisor();

  /// Короткое название фазы простым языком.
  String phaseLabel(CyclePhase phase) {
    return switch (phase) {
      CyclePhase.menstruation => 'Идут месячные',
      CyclePhase.follicular => 'Спокойная фаза',
      CyclePhase.ovulation => 'Активная фаза',
      CyclePhase.luteal => 'Чувствительная фаза',
      CyclePhase.premenstrual => 'Перед месячными',
    };
  }

  /// Развёрнутый совет по текущей фазе.
  String phaseAdvice(CyclePhase phase) {
    return switch (phase) {
      CyclePhase.menstruation =>
        'Сейчас может быть дискомфорт и усталость. Предложи тепло, '
            'чай и возможность отдохнуть. Не жди большой активности — '
            'забота сейчас важнее планов.',
      CyclePhase.follicular =>
        'Энергия постепенно возвращается. Хорошее время для совместных '
            'планов, прогулок и лёгких свиданий. Настроение обычно '
            'становится лучше.',
      CyclePhase.ovulation =>
        'Обычно много энергии и хорошее настроение. Отличное время '
            'для романтики, новых идей и активных совместных дел.',
      CyclePhase.luteal =>
        'Возможна повышенная чувствительность и усталость. Сегодня '
            'лучше избегать лишнего стресса и оставить время на отдых.',
      CyclePhase.premenstrual =>
        'Возможны перепады настроения и усталость. Будь терпелив — '
            'мелкие знаки внимания, вкусная еда и уют сейчас '
            'особенно важны.',
    };
  }

  /// Индикатор настроения без раскрытия подробных записей.
  PartnerEmotionalState emotionalState(
    List<WellbeingEntry> wellbeing, {
    CyclePhase? fallbackPhase,
  }) {
    final recent = _recentEntries(wellbeing, days: 5);
    if (recent.isEmpty) {
      return PartnerEmotionalState(
        emoji: '💬',
        label: 'Нет недавних отметок',
        hint: fallbackPhase != null
            ? _phaseMoodHint(fallbackPhase)
            : 'Спроси, как она себя чувствует',
      );
    }

    final avgMood =
        recent.map((e) => e.mood.value).reduce((a, b) => a + b) / recent.length;

    if (avgMood >= 4) {
      return const PartnerEmotionalState(
        emoji: '😊',
        label: 'Хорошее настроение',
        hint: 'По последним отметкам — настроение в плюсе',
      );
    }
    if (avgMood >= 2.5) {
      return const PartnerEmotionalState(
        emoji: '😐',
        label: 'Обычное состояние',
        hint: 'Всё относительно спокойно — будь рядом',
      );
    }
    return const PartnerEmotionalState(
      emoji: '😔',
      label: 'Непростой день',
      hint: 'Будь особенно внимателен и не дави с планами',
    );
  }

  /// Сводка поддержки за текущий месяц.
  SupportMonthSummary supportSummary(
    List<SupportEvent> events, {
    DateTime? reference,
  }) {
    final now = reference ?? DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final monthEnd = DateTime(now.year, now.month + 1);

    final counts = <SupportEventType, int>{};
    for (final event in events) {
      final at = event.createdAt;
      if (at.isBefore(monthStart) || !at.isBefore(monthEnd)) continue;
      counts[event.type] = (counts[event.type] ?? 0) + 1;
    }

    final lines = <String>[];
    void add(SupportEventType type, String label) {
      final count = counts[type];
      if (count != null && count > 0) {
        lines.add('$label $count ${_timesWord(count)}');
      }
    }

    add(SupportEventType.needSupport, '❤️ Поддержка запрашивалась');
    add(SupportEventType.tired, '😴 Усталость отмечалась');
    add(SupportEventType.unwell, '🤕 Плохое самочувствие отмечалось');
    add(SupportEventType.sad, '💔 Грусть отмечалась');

    return SupportMonthSummary(lines: lines);
  }

  /// До [count] случайных желаний.
  List<Wish> pickRandomWishes(List<Wish> all, int count) {
    if (all.isEmpty) return [];
    final shuffled = List<Wish>.from(all)..shuffle(Random());
    return shuffled.take(count).toList();
  }

  /// До [count] желаний с высоким приоритетом.
  List<Wish> pickHighPriorityWishes(List<Wish> all, int count) {
    final high = all
        .where((w) => w.priority == WishPriority.high)
        .toList();
    return high.take(count).toList();
  }

  /// Что можно / лучше сегодня — по фазе и самочувствию.
  PartnerTodayPlan todayPlan(
    CyclePrediction prediction,
    List<WellbeingEntry> wellbeing,
  ) {
    final recent = _recentEntries(wellbeing, days: 3);
    final latest = recent.isNotEmpty ? recent.first : null;

    final canDo = <String>[];
    final betterToday = <String>[];

    switch (prediction.phase) {
      case CyclePhase.menstruation:
        canDo.addAll([
          'согреть пледом или чаем',
          'посмотреть фильм дома',
          'заказать любимую еду',
        ]);
        betterToday.addAll([
          'больше отдыхать',
          'не перегружать планами',
        ]);
      case CyclePhase.follicular:
        canDo.addAll([
          'прогуляться вместе',
          'сходить в кафе',
          'обсудить новые планы',
        ]);
        betterToday.add('не торопить с решениями');
      case CyclePhase.ovulation:
        canDo.addAll([
          'устроить свидание',
          'сделать комплимент',
          'предложить активность на свежем воздухе',
        ]);
        betterToday.add('не откладывать знаки внимания');
      case CyclePhase.luteal:
        canDo.addAll([
          'побудить рядом без лишних вопросов',
          'приготовить что-то вкусное',
          'предложить тихий вечер',
        ]);
        betterToday.addAll([
          'избегать лишнего стресса',
          'не спорить по мелочам',
        ]);
      case CyclePhase.premenstrual:
        canDo.addAll([
          'заказать любимую еду',
          'посмотреть что-то лёгкое',
          'сделать маленький сюрприз',
        ]);
        betterToday.addAll([
          'больше отдыхать',
          'не перегружаться',
          'быть терпеливым',
        ]);
    }

    if (latest != null) {
      if (latest.energy == EnergyLevel.low) {
        _ensure(betterToday, 'дать время на отдых');
        canDo.removeWhere(
          (s) => s.contains('активность') || s.contains('свидание'),
        );
      }
      if (latest.pain.value >= PainLevel.moderate.value) {
        _ensure(betterToday, 'не планировать ничего утомительного');
        _ensure(canDo, 'обеспечить комфорт и тепло');
      }
      if (latest.mood.value <= MoodLevel.bad.value) {
        _ensure(betterToday, 'быть особенно внимательным');
        _ensure(canDo, 'просто побудь рядом');
      }
    }

    return PartnerTodayPlan(
      canDo: canDo.take(4).toList(),
      betterToday: betterToday.take(3).toList(),
    );
  }

  List<String> extraTips(CyclePrediction prediction) {
    final tips = <String>[];

    if (prediction.daysUntilNextPeriod != null) {
      final days = prediction.daysUntilNextPeriod!;
      if (days > 0) {
        tips.add('До начала месячных осталось $days ${_dayWord(days)}');
      } else if (days == 0) {
        tips.add('Месячные могут начаться сегодня — будь готов помочь');
      }
    }

    switch (prediction.phase) {
      case CyclePhase.menstruation:
        tips.add('Грелка, чай и спокойный вечер — отличная идея');
      case CyclePhase.follicular:
        tips.add('Хорошее время предложить совместные планы');
      case CyclePhase.ovulation:
        tips.add('Часто повышенная энергия — используй для романтики');
      case CyclePhase.luteal:
        tips.add('Меньше критики, больше поддержки');
      case CyclePhase.premenstrual:
        tips.add('Сладости или любимая еда могут поднять настроение');
    }

    return tips;
  }

  List<WellbeingEntry> _recentEntries(List<WellbeingEntry> all, {int days = 5}) {
    final cutoff = AppDateUtils.dateOnly(
      DateTime.now().subtract(Duration(days: days)),
    );
    return all
        .where((e) => !AppDateUtils.dateOnly(e.date).isBefore(cutoff))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  String _phaseMoodHint(CyclePhase phase) {
    return switch (phase) {
      CyclePhase.menstruation => 'Сейчас может быть непросто — спроси бережно',
      CyclePhase.follicular => 'Скорее всего настроение нормальное',
      CyclePhase.ovulation => 'Обычно хороший период для общения',
      CyclePhase.luteal => 'Возможна повышенная чувствительность',
      CyclePhase.premenstrual => 'Может понадобиться больше поддержки',
    };
  }

  void _ensure(List<String> list, String item) {
    if (!list.contains(item)) list.add(item);
  }

  String _dayWord(int days) {
    final mod10 = days % 10;
    final mod100 = days % 100;
    if (mod100 >= 11 && mod100 <= 19) return 'дней';
    if (mod10 == 1) return 'день';
    if (mod10 >= 2 && mod10 <= 4) return 'дня';
    return 'дней';
  }

  String _timesWord(int n) {
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (mod10 == 1 && mod100 != 11) return 'раз';
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) {
      return 'раза';
    }
    return 'раз';
  }
}
