import 'package:intl/intl.dart';

/// Утилиты для работы с датами.
abstract final class AppDateUtils {
  static DateTime dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static int daysBetween(DateTime from, DateTime to) {
    final start = dateOnly(from);
    final end = dateOnly(to);
    return end.difference(start).inDays;
  }

  static String formatDate(DateTime date) {
    return DateFormat('d MMMM yyyy', 'ru').format(date);
  }

  static String formatShortDate(DateTime date) {
    return DateFormat('d MMM', 'ru').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  static String dateToIso(DateTime date) {
    return dateOnly(date).toIso8601String().split('T').first;
  }

  static DateTime fromIso(String iso) {
    return DateTime.parse(iso);
  }
}
