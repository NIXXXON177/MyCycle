import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mycycle/core/providers/app_providers.dart';
import 'package:mycycle/core/theme/app_theme.dart';
import 'package:mycycle/shared/widgets/app_lock_observer.dart';
import 'package:mycycle/shared/widgets/update_checker.dart';

/// Корневой виджет приложения MyCycle.
class MyCycleApp extends ConsumerWidget {
  const MyCycleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'MyCycle',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => AppLockObserver(
        child: UpdateChecker(child: child),
      ),
    );
  }
}
