import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mycycle/core/database/app_database.dart';
import 'package:mycycle/core/router/app_router.dart';
import 'package:mycycle/core/security/security_controller.dart';
import 'package:mycycle/core/services/backup_service.dart';
import 'package:mycycle/core/services/biometric_service.dart';
import 'package:mycycle/core/services/demo_data_seeder.dart';
import 'package:mycycle/core/services/stress_test_seeder.dart';
import 'package:mycycle/core/services/notification_service.dart';
import 'package:mycycle/core/services/settings_service.dart';
import 'package:mycycle/core/services/update_service.dart';
import 'package:mycycle/core/utils/cycle_calculator.dart';
import 'package:mycycle/features/cycle/data/datasources/cycle_local_datasource.dart';
import 'package:mycycle/features/cycle/data/repositories/cycle_repository.dart';
import 'package:mycycle/features/cycle/domain/entities/cycle.dart';
import 'package:mycycle/features/cycle/domain/entities/cycle_prediction.dart';
import 'package:mycycle/features/important_dates/data/datasources/important_date_local_datasource.dart';
import 'package:mycycle/features/important_dates/data/repositories/important_date_repository.dart';
import 'package:mycycle/features/important_dates/domain/entities/important_date.dart';
import 'package:mycycle/core/services/diary_image_storage.dart';
import 'package:mycycle/features/diary/data/datasources/diary_image_local_datasource.dart';
import 'package:mycycle/features/diary/data/datasources/diary_local_datasource.dart';
import 'package:mycycle/features/diary/data/repositories/diary_repository.dart';
import 'package:mycycle/features/diary/domain/entities/diary_entry.dart';
import 'package:mycycle/features/diary/domain/entities/diary_image.dart';
import 'package:mycycle/features/diary/domain/entities/diary_list_query.dart';
import 'package:mycycle/features/support/data/datasources/support_local_datasource.dart';
import 'package:mycycle/features/support/data/repositories/support_repository.dart';
import 'package:mycycle/features/support/domain/entities/support_event.dart';
import 'package:mycycle/features/wellbeing/data/datasources/wellbeing_local_datasource.dart';
import 'package:mycycle/features/wellbeing/data/repositories/wellbeing_repository.dart';
import 'package:mycycle/features/wellbeing/domain/entities/wellbeing_entry.dart';
import 'package:mycycle/features/wishes/data/datasources/wish_local_datasource.dart';
import 'package:mycycle/features/wishes/data/repositories/wish_repository.dart';
import 'package:mycycle/features/wishes/domain/entities/wish.dart';
import 'package:mycycle/core/services/widget/widget_provider.dart';
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
  return BackupService(
    db: ref.watch(appDatabaseProvider),
    settings: ref.watch(settingsServiceProvider),
    imageStorage: const DiaryImageStorage(),
  );
});

final updateServiceProvider = Provider<UpdateService>((ref) => UpdateService());

final biometricServiceProvider =
    Provider<BiometricService>((ref) => BiometricService());

final securityProvider =
    StateNotifierProvider<SecurityController, SecurityState>((ref) {
  return SecurityController(ref.watch(settingsServiceProvider));
});

final routerRefreshProvider = Provider<RouterRefreshNotifier>((ref) {
  final notifier = RouterRefreshNotifier();
  ref.onDispose(notifier.dispose);
  ref.listen(securityProvider, (_, __) => notifier.refresh());
  return notifier;
});

// --- Data sources ---

final cycleDataSourceProvider = Provider<CycleLocalDataSource>((ref) {
  return CycleLocalDataSource(ref.watch(appDatabaseProvider));
});

final wellbeingDataSourceProvider = Provider<WellbeingLocalDataSource>((ref) {
  return WellbeingLocalDataSource(ref.watch(appDatabaseProvider));
});

final importantDateDataSourceProvider =
    Provider<ImportantDateLocalDataSource>((ref) {
  return ImportantDateLocalDataSource(ref.watch(appDatabaseProvider));
});

final diaryImageDataSourceProvider = Provider<DiaryImageLocalDataSource>((ref) {
  return DiaryImageLocalDataSource(ref.watch(appDatabaseProvider));
});

final diaryImageStorageProvider = Provider<DiaryImageStorage>((ref) {
  return const DiaryImageStorage();
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

final importantDateRepositoryProvider =
    Provider<ImportantDateRepository>((ref) {
  return ImportantDateRepository(ref.watch(importantDateDataSourceProvider));
});

final diaryRepositoryProvider = Provider<DiaryRepository>((ref) {
  return DiaryRepository(
    ref.watch(diaryDataSourceProvider),
    ref.watch(diaryImageDataSourceProvider),
    ref.watch(diaryImageStorageProvider),
  );
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
    importantDateRepo: ref.watch(importantDateRepositoryProvider),
    settings: ref.watch(settingsServiceProvider),
  );
});

final stressTestSeederProvider = Provider<StressTestSeeder>((ref) {
  return StressTestSeeder(
    cycleRepo: ref.watch(cycleRepositoryProvider),
    wellbeingRepo: ref.watch(wellbeingRepositoryProvider),
    diaryRepo: ref.watch(diaryRepositoryProvider),
    supportRepo: ref.watch(supportRepositoryProvider),
    wishRepo: ref.watch(wishRepositoryProvider),
    importantDateRepo: ref.watch(importantDateRepositoryProvider),
    imageStorage: const DiaryImageStorage(),
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

final diaryQueryProvider =
    FutureProvider.family<List<DiaryEntry>, DiaryListQuery>((ref, query) async {
  ref.watch(diaryListProvider);
  return ref.watch(diaryRepositoryProvider).query(query);
});

final diaryImagesProvider =
    FutureProvider.family<List<DiaryImage>, String>((ref, diaryId) async {
  ref.watch(diaryListProvider);
  return ref.watch(diaryRepositoryProvider).getImages(diaryId);
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

final upcomingImportantDatesProvider =
    FutureProvider<List<UpcomingImportantDate>>((ref) async {
  return ref.watch(importantDateRepositoryProvider).getUpcoming();
});

final importantDatesListProvider =
    FutureProvider<List<ImportantDate>>((ref) async {
  return ref.watch(importantDateRepositoryProvider).getAll();
});

final goRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(routerRefreshProvider);
  return createRouter(ref: ref, refresh: refresh);
});

/// Инвалидирует все провайдеры данных после изменений.
void invalidateAllData(WidgetRef ref) {
  ref.invalidate(cyclesProvider);
  ref.invalidate(cyclePredictionProvider);
  ref.invalidate(wellbeingListProvider);
  ref.invalidate(diaryListProvider);
  ref.invalidate(supportEventsProvider);
  ref.invalidate(wishesProvider);
  ref.invalidate(importantDatesListProvider);
  ref.invalidate(upcomingImportantDatesProvider);
  syncHomeWidget(ref);
}
