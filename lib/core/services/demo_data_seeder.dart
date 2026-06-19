import 'package:mycycle/core/enums/energy_level.dart';
import 'package:mycycle/core/enums/mood_level.dart';
import 'package:mycycle/core/enums/pain_level.dart';
import 'package:mycycle/core/enums/pain_location.dart';
import 'package:mycycle/core/enums/support_event_type.dart';
import 'package:mycycle/core/enums/wish_priority.dart';
import 'package:mycycle/core/services/settings_service.dart';
import 'package:mycycle/features/cycle/data/repositories/cycle_repository.dart';
import 'package:mycycle/features/diary/data/repositories/diary_repository.dart';
import 'package:mycycle/features/support/data/repositories/support_repository.dart';
import 'package:mycycle/features/support/domain/entities/support_event.dart';
import 'package:mycycle/features/wellbeing/data/repositories/wellbeing_repository.dart';
import 'package:mycycle/features/wellbeing/domain/entities/wellbeing_entry.dart';
import 'package:mycycle/features/wishes/data/repositories/wish_repository.dart';
import 'package:uuid/uuid.dart';

/// Загрузчик демонстрационных данных для тестирования.
class DemoDataSeeder {
  DemoDataSeeder({
    required this.cycleRepo,
    required this.wellbeingRepo,
    required this.diaryRepo,
    required this.supportRepo,
    required this.wishRepo,
    required this.settings,
  });

  final CycleRepository cycleRepo;
  final WellbeingRepository wellbeingRepo;
  final DiaryRepository diaryRepo;
  final SupportRepository supportRepo;
  final WishRepository wishRepo;
  final SettingsService settings;

  final _uuid = const Uuid();

  Future<void> seedIfNeeded() async {
    if (settings.demoDataLoaded) return;

    final existing = await cycleRepo.getAllCycles();
    if (existing.isNotEmpty) {
      await settings.setDemoDataLoaded(true);
      return;
    }

    final now = DateTime.now();

    for (var i = 5; i >= 0; i--) {
      final start = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: 28 * i + 3));
      final end = start.add(const Duration(days: 4));
      await cycleRepo.addCycle(startDate: start, endDate: end);
    }

    final moods = [
      MoodLevel.normal,
      MoodLevel.bad,
      MoodLevel.veryBad,
      MoodLevel.normal,
      MoodLevel.good,
      MoodLevel.excellent,
      MoodLevel.good,
      MoodLevel.normal,
      MoodLevel.bad,
      MoodLevel.normal,
    ];

    for (var d = 30; d >= 0; d--) {
      final date = now.subtract(Duration(days: d));
      final moodIndex = d % moods.length;

      await wellbeingRepo.save(
        WellbeingEntry(
          id: _uuid.v4(),
          date: date,
          mood: moods[moodIndex],
          energy: d % 3 == 0
              ? EnergyLevel.low
              : (d % 2 == 0 ? EnergyLevel.high : EnergyLevel.medium),
          pain: d % 7 == 0 ? PainLevel.moderate : PainLevel.none,
          painLocations: d % 7 == 0 ? [PainLocation.abdomen] : [],
          note: d % 5 == 0 ? 'Заметка за ${date.day}.${date.month}' : null,
        ),
      );
    }

    await diaryRepo.add(
      date: now.subtract(const Duration(days: 2)),
      text: 'Сегодня был хороший день, много энергии!',
      mood: MoodLevel.good,
    );
    await diaryRepo.add(
      date: now.subtract(const Duration(days: 5)),
      text: 'Чувствовала усталость, но настроение нормальное.',
      mood: MoodLevel.normal,
    );
    await diaryRepo.add(
      date: now.subtract(const Duration(days: 10)),
      text: 'Болел живот, лежала дома с пледом.',
      mood: MoodLevel.bad,
    );

    await supportRepo.add(
      SupportEvent(
        id: _uuid.v4(),
        type: SupportEventType.tired,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
    );

    await wishRepo.create(
      title: 'Массаж спины',
      description: 'После рабочей недели было бы здорово',
      priority: WishPriority.high,
    );
    await wishRepo.create(
      title: 'Шоколад',
      description: 'Тёмный, 70%',
      priority: WishPriority.medium,
    );
    await wishRepo.create(
      title: 'Прогулка в парке',
      description: 'Когда будет хорошая погода',
      priority: WishPriority.low,
    );

    await settings.setDemoDataLoaded(true);
  }
}
