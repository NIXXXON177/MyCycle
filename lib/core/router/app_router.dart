import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mycycle/core/security/security_controller.dart';
import 'package:mycycle/features/auth/presentation/screens/pin_screen.dart';
import 'package:mycycle/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:mycycle/features/cycle/presentation/screens/cycle_history_screen.dart';
import 'package:mycycle/features/cycle/presentation/screens/home_screen.dart';
import 'package:mycycle/features/diary/presentation/screens/diary_edit_screen.dart';
import 'package:mycycle/features/diary/presentation/screens/diary_screen.dart';
import 'package:mycycle/features/partner/presentation/screens/partner_screen.dart';
import 'package:mycycle/features/patterns/presentation/screens/patterns_screen.dart';
import 'package:mycycle/features/settings/presentation/screens/reminders_screen.dart';
import 'package:mycycle/features/settings/presentation/screens/settings_screen.dart';
import 'package:mycycle/features/statistics/presentation/screens/statistics_screen.dart';
import 'package:mycycle/features/support/presentation/screens/support_screen.dart';
import 'package:mycycle/features/wellbeing/presentation/screens/wellbeing_screen.dart';
import 'package:mycycle/features/wishes/presentation/screens/wishes_screen.dart';
import 'package:mycycle/shared/widgets/main_shell.dart';

/// Маршруты приложения.
abstract final class AppRoutes {
  static const home = '/';
  static const pin = '/pin';
  static const calendar = '/calendar';
  static const wellbeing = '/wellbeing';
  static const wellbeingDay = '/wellbeing/day';
  static const diary = '/diary';
  static const diaryEdit = '/diary/edit';
  static const statistics = '/statistics';
  static const patterns = '/patterns';
  static const partner = '/partner';
  static const support = '/support';
  static const wishes = '/wishes';
  static const settings = '/settings';
  static const reminders = '/settings/reminders';
  static const cycleHistory = '/cycle/history';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter({
  required Ref ref,
  required RouterRefreshNotifier refresh,
}) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    refreshListenable: refresh,
    initialLocation: AppRoutes.home,
    redirect: (context, state) {
      final security = ref.read(securityProvider);
      final onPin = state.matchedLocation == AppRoutes.pin;

      if (security.lockRequired) {
        return onPin ? null : AppRoutes.pin;
      }
      if (onPin) return AppRoutes.home;
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Ошибка')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(state.error?.toString() ?? 'Неизвестная ошибка'),
        ),
      ),
    ),
    routes: [
      GoRoute(
        path: AppRoutes.pin,
        builder: (context, state) => const PinScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: HomeScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.calendar,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: CalendarScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.wellbeing,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: WellbeingScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.diary,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: DiaryScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.statistics,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: StatisticsScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.diaryEdit,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.uri.queryParameters['id'];
          return DiaryEditScreen(entryId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.wellbeingDay,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final raw = state.uri.queryParameters['date'];
          final millis = int.tryParse(raw ?? '');
          final date = millis != null
              ? DateTime.fromMillisecondsSinceEpoch(millis)
              : DateTime.now();
          return WellbeingScreen(initialDate: date);
        },
      ),
      GoRoute(
        path: AppRoutes.patterns,
        builder: (context, state) => const PatternsScreen(),
      ),
      GoRoute(
        path: AppRoutes.partner,
        builder: (context, state) => const PartnerScreen(),
      ),
      GoRoute(
        path: AppRoutes.support,
        builder: (context, state) => const SupportScreen(),
      ),
      GoRoute(
        path: AppRoutes.wishes,
        builder: (context, state) => const WishesScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.reminders,
        builder: (context, state) => const RemindersScreen(),
      ),
      GoRoute(
        path: AppRoutes.cycleHistory,
        builder: (context, state) => const CycleHistoryScreen(),
      ),
    ],
  );
}
