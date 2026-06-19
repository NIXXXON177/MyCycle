import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mycycle/app.dart';
import 'package:mycycle/core/providers/app_providers.dart';
import 'package:mycycle/core/theme/app_theme.dart';
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
                  const Text('🌸', style: TextStyle(fontSize: 48)),
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
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🌸', style: TextStyle(fontSize: 64)),
                SizedBox(height: 24),
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('MyCycle', style: TextStyle(fontSize: 20)),
              ],
            ),
          ),
        ),
      );
    }

    return const MyCycleApp();
  }
}

/// Загружает SharedPreferences и запускает приложение.
Future<void> bootstrapApp() async {
  WidgetsFlutterBinding.ensureInitialized();

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
