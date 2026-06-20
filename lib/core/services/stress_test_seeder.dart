import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:mycycle/core/enums/energy_level.dart';
import 'package:mycycle/core/enums/mood_level.dart';
import 'package:mycycle/core/enums/pain_level.dart';
import 'package:mycycle/core/enums/pms_symptom.dart';
import 'package:mycycle/core/enums/support_event_type.dart';
import 'package:mycycle/core/enums/wish_priority.dart';
import 'package:mycycle/core/services/diary_image_storage.dart';
import 'package:mycycle/features/cycle/data/repositories/cycle_repository.dart';
import 'package:mycycle/features/diary/data/repositories/diary_repository.dart';
import 'package:mycycle/features/important_dates/data/repositories/important_date_repository.dart';
import 'package:mycycle/features/support/data/repositories/support_repository.dart';
import 'package:mycycle/features/support/domain/entities/support_event.dart';
import 'package:mycycle/features/wellbeing/data/repositories/wellbeing_repository.dart';
import 'package:mycycle/features/wellbeing/domain/entities/wellbeing_entry.dart';
import 'package:mycycle/features/wishes/data/repositories/wish_repository.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// Генератор большого объёма тестовых данных для проверки производительности.
class StressTestSeeder {
  StressTestSeeder({
    required this.cycleRepo,
    required this.wellbeingRepo,
    required this.diaryRepo,
    required this.supportRepo,
    required this.wishRepo,
    required this.importantDateRepo,
    required this.imageStorage,
  });

  final CycleRepository cycleRepo;
  final WellbeingRepository wellbeingRepo;
  final DiaryRepository diaryRepo;
  final SupportRepository supportRepo;
  final WishRepository wishRepo;
  final ImportantDateRepository importantDateRepo;
  final DiaryImageStorage imageStorage;

  static const diaryCount = 1000;
  static const wellbeingCount = 500;
  static const photoCount = 300;
  static const wishCount = 200;
  static const supportCount = 300;

  final _uuid = const Uuid();
  final _random = Random(42);

  static final _minimalJpeg = base64Decode(
    '/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEB'
    'AQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEB'
    'AQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/wAALCAABAAEBAREA/8QAFBAB'
    'AAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABPxA=',
  );

  Future<void> generate() async {
    final now = DateTime.now();

    for (var i = 24; i >= 0; i--) {
      final start = now.subtract(Duration(days: 28 * i + 2));
      await cycleRepo.addCycle(
        startDate: start,
        endDate: start.add(Duration(days: 4 + _random.nextInt(2))),
      );
    }

    final moods = MoodLevel.values;
    final symptoms = PmsSymptom.values;
    for (var i = 0; i < wellbeingCount; i++) {
      final date = now.subtract(Duration(days: i));
      await wellbeingRepo.save(
        WellbeingEntry(
          id: _uuid.v4(),
          date: date,
          mood: moods[_random.nextInt(moods.length)],
          energy: EnergyLevel.values[_random.nextInt(3)],
          pain: PainLevel.values[_random.nextInt(PainLevel.values.length)],
          pmsSymptoms: i % 4 == 0
              ? [symptoms[_random.nextInt(symptoms.length)]]
              : [],
          note: i % 7 == 0 ? 'Stress test wellbeing $i' : null,
        ),
      );
    }

    final photoPaths = await _createPlaceholderPhotos(photoCount);
    for (var i = 0; i < diaryCount; i++) {
      final date = now.subtract(Duration(days: i % 400));
      final withPhoto = i < photoCount;
      await diaryRepo.add(
        date: date,
        text: 'Stress test diary entry #$i',
        mood: moods[_random.nextInt(moods.length)],
        isFavorite: i % 11 == 0,
        imageSourcePaths: withPhoto ? [photoPaths[i]] : const [],
      );
    }

    for (var i = 0; i < supportCount; i++) {
      await supportRepo.add(
        SupportEvent(
          id: _uuid.v4(),
          type: SupportEventType.values[
              _random.nextInt(SupportEventType.values.length)],
          createdAt: now.subtract(Duration(days: i % 180)),
        ),
      );
    }

    for (var i = 0; i < wishCount; i++) {
      await wishRepo.create(
        title: 'Хотелка #$i',
        description: 'Stress test wish',
        priority: WishPriority.values[_random.nextInt(3)],
      );
    }

    await importantDateRepo.create(
      title: 'Stress test date',
      date: now.add(const Duration(days: 30)),
      repeatYearly: true,
    );
  }

  Future<List<String>> _createPlaceholderPhotos(int count) async {
    final dir = await imageStorage.imagesDirectory;
    final paths = <String>[];
    for (var i = 0; i < count; i++) {
      final file = File(p.join(dir, 'stress_$i.jpg'));
      await file.writeAsBytes(_minimalJpeg);
      paths.add(file.path);
    }
    return paths;
  }
}
