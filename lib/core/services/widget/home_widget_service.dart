import 'package:home_widget/home_widget.dart';
import 'package:florea/core/constants/widget_keys.dart';
import 'package:florea/core/database/app_database.dart';
import 'package:florea/core/enums/mood_level.dart';
import 'package:florea/core/utils/cycle_calculator.dart';
import 'package:florea/core/utils/date_utils.dart';
import 'package:florea/core/utils/prediction_accuracy.dart';
import 'package:florea/features/cycle/data/datasources/cycle_local_datasource.dart';
import 'package:florea/features/cycle/data/repositories/cycle_repository.dart';
import 'package:florea/features/important_dates/data/datasources/important_date_local_datasource.dart';
import 'package:florea/features/important_dates/data/repositories/important_date_repository.dart';
import 'package:florea/features/wellbeing/data/datasources/wellbeing_local_datasource.dart';
import 'package:florea/features/wellbeing/data/repositories/wellbeing_repository.dart';
import 'package:florea/core/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Обновляет данные Android-виджета из приложения.
class HomeWidgetService {
  HomeWidgetService({
    required CycleRepository cycleRepo,
    required WellbeingRepository wellbeingRepo,
    required ImportantDateRepository importantDateRepo,
  })  : _cycleRepo = cycleRepo,
        _wellbeingRepo = wellbeingRepo,
        _importantDateRepo = importantDateRepo;

  final CycleRepository _cycleRepo;
  final WellbeingRepository _wellbeingRepo;
  final ImportantDateRepository _importantDateRepo;

  static const _smallProvider = 'FloreaWidgetSmallProvider';
  static const _largeProvider = 'FloreaWidgetLargeProvider';

  /// Синхронизация без Riverpod (для фонового callback).
  static Future<void> syncStandalone() async {
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsService(prefs);
    final db = AppDatabase.instance;
    final calculator = CycleCalculator(
      defaultCycleLength: settings.defaultCycleLength,
      defaultPeriodLength: settings.defaultPeriodLength,
    );
    final service = HomeWidgetService(
      cycleRepo: CycleRepository(CycleLocalDataSource(db), calculator),
      wellbeingRepo: WellbeingRepository(WellbeingLocalDataSource(db)),
      importantDateRepo:
          ImportantDateRepository(ImportantDateLocalDataSource(db)),
    );
    await service.sync();
  }

  Future<void> sync() async {
    final cycles = await _cycleRepo.getAllCycles();
    final prediction = await _cycleRepo.getPrediction();
    final today = AppDateUtils.dateOnly(DateTime.now());
    final wellbeing = await _wellbeingRepo.getByDate(today);
    final regularity = _cycleRepo.cycleRegularity(cycles);
    final accuracy = PredictionAccuracy.evaluate(cycles, regularity);

    String daysUntilText;
    final days = prediction.daysUntilNextPeriod;
    if (days == null) {
      daysUntilText = '—';
    } else if (days > 0) {
      daysUntilText = '$days дн.';
    } else if (days == 0) {
      daysUntilText = 'сегодня';
    } else {
      daysUntilText = 'идут';
    }

    String? nextEvent;
    final upcoming = await _importantDateRepo.getUpcoming(limit: 1);
    if (upcoming.isNotEmpty) {
      final item = upcoming.first;
      final d = item.daysUntil(today);
      final when = d == 0
          ? 'сегодня'
          : d == 1
              ? 'завтра'
              : 'через $d дн.';
      nextEvent = '${item.entry.title} · $when';
    }

    await HomeWidget.saveWidgetData<String>(
      WidgetKeys.cycleDay,
      prediction.currentCycleDay > 0
          ? '${prediction.currentCycleDay}'
          : '—',
    );
    await HomeWidget.saveWidgetData<String>(
      WidgetKeys.phase,
      prediction.phase.label,
    );
    await HomeWidget.saveWidgetData<String>(
      WidgetKeys.daysUntil,
      daysUntilText,
    );
    await HomeWidget.saveWidgetData<String>(
      WidgetKeys.moodEmoji,
      wellbeing?.mood.emoji ?? '—',
    );
    await HomeWidget.saveWidgetData<String>(
      WidgetKeys.moodLabel,
      wellbeing?.mood.label ?? 'не отмечено',
    );
    await HomeWidget.saveWidgetData<String>(
      WidgetKeys.accuracy,
      accuracy.label,
    );
    await HomeWidget.saveWidgetData<String>(
      WidgetKeys.nextEvent,
      nextEvent ?? '—',
    );

    await HomeWidget.updateWidget(
      name: _smallProvider,
      androidName: _smallProvider,
    );
    await HomeWidget.updateWidget(
      name: _largeProvider,
      androidName: _largeProvider,
    );
  }
}

/// Сохраняет настроение из виджета и обновляет данные.
Future<void> saveMoodFromWidget(MoodLevel mood) async {
  final db = AppDatabase.instance;
  final wellbeingRepo = WellbeingRepository(WellbeingLocalDataSource(db));
  final today = AppDateUtils.dateOnly(DateTime.now());
  await wellbeingRepo.setQuickMood(today, mood);
  await HomeWidgetService.syncStandalone();
}
