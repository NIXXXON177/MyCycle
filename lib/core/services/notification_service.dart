import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mycycle/core/services/settings_service.dart';
import 'package:mycycle/features/cycle/domain/entities/cycle_prediction.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Сервис локальных уведомлений.
class NotificationService {
  NotificationService();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _channelId = 'mycycle_reminders';
  static const _channelName = 'Напоминания MyCycle';

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    // База — UTC. Конкретные напоминания планируем как абсолютный момент,
    // вычисленный из локального времени устройства (см. _toTz). Так уведомления
    // приходят в правильное местное время в любом часовом поясе, а не только в МСК.
    tz.setLocalLocation(tz.UTC);

    const androidSettings =
        AndroidInitializationSettings('@drawable/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(initSettings);

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Напоминания о цикле и самочувствии',
      importance: Importance.high,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<void> scheduleReminders({
    required ReminderSettings settings,
    required CyclePrediction prediction,
  }) async {
    try {
      await initialize();
      await cancelAll();

      if (!settings.periodApproaching &&
          !settings.periodStart &&
          !settings.dailyWellbeing) {
        return;
      }

      if (settings.dailyWellbeing) {
        await _scheduleDaily(
          id: 1,
          title: 'Как ты сегодня?',
          body: 'Не забудь отметить самочувствие',
          hour: settings.hour,
          minute: settings.minute,
        );
      }

      if (settings.periodStart && prediction.nextPeriodDate != null) {
        final periodDate = prediction.nextPeriodDate!;
        if (periodDate.isAfter(DateTime.now())) {
          await _scheduleOnce(
            id: 2,
            title: 'Месячные начинаются',
            body: 'Сегодня ожидается начало месячных',
            scheduledDate:
                _tzFromDate(periodDate, settings.hour, settings.minute),
          );
        }
      }

      if (settings.periodApproaching && prediction.nextPeriodDate != null) {
        final approachDate =
            prediction.nextPeriodDate!.subtract(const Duration(days: 2));
        if (approachDate.isAfter(DateTime.now())) {
          await _scheduleOnce(
            id: 3,
            title: 'Месячные скоро',
            body: 'Через 2 дня ожидаются месячные — приготовься',
            scheduledDate:
                _tzFromDate(approachDate, settings.hour, settings.minute),
          );
        }
      }
    } catch (e, stack) {
      debugPrint('Failed to schedule reminders: $e\n$stack');
    }
  }

  Future<void> _scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _scheduleOnce({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
  }) async {
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Преобразует локальное «настенное» время устройства в абсолютный момент.
  /// Планировщик настроен на UTC, поэтому момент срабатывает корректно
  /// независимо от часового пояса пользователя.
  tz.TZDateTime _toTz(DateTime localWallClock) =>
      tz.TZDateTime.from(localWallClock.toUtc(), tz.UTC);

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return _toTz(scheduled);
  }

  tz.TZDateTime _tzFromDate(DateTime date, int hour, int minute) {
    return _toTz(DateTime(date.year, date.month, date.day, hour, minute));
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
