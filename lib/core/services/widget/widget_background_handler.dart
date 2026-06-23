import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:florea/core/enums/mood_level.dart';
import 'package:florea/core/services/widget/home_widget_service.dart';

/// Обработчик нажатий на кнопки виджета (без открытия приложения).
@pragma('vm:entry-point')
Future<void> widgetInteractivityCallback(Uri? uri) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (uri?.host != 'mood') return;

  final segment = uri?.pathSegments.isNotEmpty == true
      ? uri!.pathSegments.first
      : null;

  final mood = switch (segment) {
    'good' => MoodLevel.good,
    'bad' => MoodLevel.bad,
    _ => MoodLevel.normal,
  };

  await saveMoodFromWidget(mood);
}

/// Регистрирует callback виджета — вызывать до [runApp].
Future<void> registerWidgetCallbacks() async {
  await HomeWidget.registerInteractivityCallback(widgetInteractivityCallback);
}
