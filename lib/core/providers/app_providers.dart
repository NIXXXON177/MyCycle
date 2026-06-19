import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mycycle/core/database/app_database.dart';
import 'package:mycycle/core/router/app_router.dart';
import 'package:mycycle/core/services/backup_service.dart';
import 'package:mycycle/core/services/biometric_service.dart';
import 'package:mycycle/core/services/demo_data_seeder.dart';
import 'package:mycycle/core/services/notification_service.dart';
import 'package:mycycle/core/services/settings_service.dart';
import 'package:mycycle/core/services/update_service.dart';
import 'package:mycycle/core/utils/cycle_calculator.dart';
import 'package:mycycle/features/cycle/data/datasources/cycle_local_datasource.dart';
import 'package:mycycle/features/cycle/data/repositories/cycle_repository.dart';
import 'package:mycycle/features/cycle/domain/entities/cycle.dart';
import 'package:mycycle/features/cycle/domain/entities/cycle_prediction.dart';
import 'package:mycycle/features/diary/data/datasources/diary_local_datasource.dart';
import 'package:mycycle/features/diary/data/repositories/diary_repository.dart';
import 'package:mycycle/features/diary/domain/entities/diary_entry.dart';
import 'package:mycycle/features/support/data/datasources/support_local_datasource.dart';
import 'package:mycycle/features/support/data/repositories/support_repository.dart';
import 'package:mycycle/features/support/domain/entities/support_event.dart';
import 'package:mycycle/features/wellbeing/data/datasources/wellbeing_local_datasource.dart';
import 'package:mycycle/features/wellbeing/data/repositories/wellbeing_repository.dart';
import 'package:mycycle/features/wellbeing/domain/entities/wellbeing_entry.dart';
import 'package:mycycle/features/wishes/data/datasources/wish_local_datasource.dart';
import 'package:mycycle/features/wishes/data/repositories/wish_repository.dart';
import 'package:mycycle/features/wishes/domain/entities/wish.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Core ---

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden');
});

final appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase.instance);

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService(ref.watch(sharedPreferencesProvider));
});

final cycleCalculatorProvider = Provider<CycleCalculator>((ref) {
  final settings = ref.watch(settingsServiceProvider);
  return CycleCalculator(
    defaultCycleLength: settings.defaultCycleLength,
    defaultPeriodLength: settings.defaultPeriodLength,
  );
});

final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService());

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref.watch(appDatabaseProvider));
});

final updateServiceProvider = Provider<UpdateService>((ref) => UpdateService());

final biometricServiceProvider =
    Provider<BiometricService>((ref) => BiometricService());

// --- Data sources ---

final cycleDataSourceProvider = Provider<CycleLocalDataSource>((ref) {
  return CycleLocalDataSource(ref.watch(appDatabaseProvider));
});

final wellbeingDataSourceProvider = Provider<WellbeingLocalDataSource>((ref) {
  return WellbeingLocalDataSource(ref.watch(appDatabaseProvider));
});

final diaryDataSourceProvider = Provider<DiaryLocalDataSource>((ref) {
  return DiaryLocalDataSource(ref.watch(appDatabaseProvider));
});

final supportDataSourceProvider = Provider<SupportLocalDataSource>((ref) {
  return SupportLocalDataSource(ref.watch(appDatabaseProvider));
});

final wishDataSourceProvider = Provider<WishLocalDataSource>((ref) {
  return WishLocalDataSource(ref.watch(appDatabaseProvider));
});

// --- Repositories ---

final cycleRepositoryProvider = Provider<CycleRepository>((ref) {
  return CycleRepository(
    ref.watch(cycleDataSourceProvider),
    ref.watch(cycleCalculatorProvider),
  );
});

final wellbeingRepositoryProvider = Provider<WellbeingRepository>((ref) {
  return WellbeingRepository(ref.watch(wellbeingDataSourceProvider));
});

final diaryRepositoryProvider = Provider<DiaryRepository>((ref) {
  return DiaryRepository(ref.watch(diaryDataSourceProvider));
});

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  return SupportRepository(ref.watch(supportDataSourceProvider));
});

final wishRepositoryProvider = Provider<WishRepository>((ref) {
  return WishRepository(ref.watch(wishDataSourceProvider));
});

final demoDataSeederProvider = Provider<DemoDataSeeder>((ref) {
  return DemoDataSeeder(
    cycleRepo: ref.watch(cycleRepositoryProvider),
    wellbeingRepo: ref.watch(wellbeingRepositoryProvider),
    diaryRepo: ref.watch(diaryRepositoryProvider),
    supportRepo: ref.watch(supportRepositoryProvider),
    wishRepo: ref.watch(wishRepositoryProvider),
    settings: ref.watch(settingsServiceProvider),
  );
});

// --- State ---

final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ref.watch(settingsServiceProvider).themeMode;
});

final cyclesProvider = FutureProvider<List<Cycle>>((ref) async {
  return ref.watch(cycleRepositoryProvider).getAllCycles();
});

final cyclePredictionProvider = FutureProvider<CyclePrediction>((ref) async {
  ref.watch(cyclesProvider);
  return ref.watch(cycleRepositoryProvider).getPrediction();
});

final wellbeingListProvider =
    FutureProvider<List<WellbeingEntry>>((ref) async {
  return ref.watch(wellbeingRepositoryProvider).getAll();
});

final wellbeingByDateProvider =
    FutureProvider.family<WellbeingEntry?, DateTime>((ref, date) async {
  return ref.watch(wellbeingRepositoryProvider).getByDate(date);
});

final diaryListProvider = FutureProvider<List<DiaryEntry>>((ref) async {
  return ref.watch(diaryRepositoryProvider).getAll();
});

final diarySearchProvider =
    FutureProvider.family<List<DiaryEntry>, String>((ref, query) async {
  return ref.watch(diaryRepositoryProvider).search(query);
});

final supportEventsProvider =
    FutureProvider<List<SupportEvent>>((ref) async {
  return ref.watch(supportRepositoryProvider).getAll();
});

final wishesProvider = FutureProvider<List<Wish>>((ref) async {
  return ref.watch(wishRepositoryProvider).getAll();
});

final goRouterProvider = Provider<GoRouter>((ref) {
  final pinRequired = ref.read(settingsServiceProvider).pinEnabled;
  return createRouter(pinRequired: pinRequired);
});

/// Инвалидирует все провайдеры данных после изменений.
void invalidateAllData(WidgetRef ref) {
  ref.invalidate(cyclesProvider);
  ref.invalidate(cyclePredictionProvider);
  ref.invalidate(wellbeingListProvider);
  ref.invalidate(diaryListProvider);
  ref.invalidate(supportEventsProvider);
  ref.invalidate(wishesProvider);
}
