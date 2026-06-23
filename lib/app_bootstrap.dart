import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:florea/app.dart';
import 'package:florea/core/providers/app_providers.dart';
import 'package:florea/core/theme/app_theme.dart';
import 'package:florea/shared/widgets/app_logo.dart';
import 'package:florea/shared/widgets/splash_screen.dart';
import 'package:florea/core/services/widget/widget_background_handler.dart';
import 'package:florea/core/services/widget/widget_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Экран загрузки и безопасная инициализация перед показом приложения.
class AppBootstrap extends ConsumerStatefulWidget {
  const AppBootstrap({super.key});

  @override
  ConsumerState<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends ConsumerState<AppBootstrap> {
  Object? _error;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_initialize);
  }

  Future<void> _initialize() async {
    try {
      await initializeDateFormatting('ru', null);
      await initializeDateFormatting('ru_RU', null);

      await ref.read(notificationServiceProvider).initialize();
      await ref.read(demoDataSeederProvider).seedIfNeeded();

      ref.invalidate(cyclesProvider);
      ref.invalidate(cyclePredictionProvider);

      final settings = ref.read(settingsServiceProvider);
      final prediction =
          await ref.read(cycleRepositoryProvider).getPrediction();
      await ref.read(notificationServiceProvider).scheduleReminders(
            settings: settings.reminderSettings,
            prediction: prediction,
          );

      await ref.read(homeWidgetServiceProvider).sync();

      if (mounted) setState(() => _ready = true);
    } catch (e, stack) {
      debugPrint('Startup failed: $e\n$stack');
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AppLogo(size: 72),
                  const SizedBox(height: 16),
                  const Text(
                    'Не удалось запустить приложение',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$_error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        _error = null;
                        _ready = false;
                      });
                      Future.microtask(_initialize);
                    },
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (!_ready) {
      return MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: SplashScreen(),
        ),
      );
    }

    return const FloreaApp();
  }
}

/// Загружает SharedPreferences и запускает приложение.
Future<void> bootstrapApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  await registerWidgetCallbacks();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const AppBootstrap(),
    ),
  );
}
