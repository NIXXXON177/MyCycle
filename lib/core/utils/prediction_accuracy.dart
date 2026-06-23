import 'package:florea/features/cycle/domain/entities/cycle.dart';

/// Уровень точности прогноза цикла.
enum PredictionAccuracyLevel {
  insufficient('Недостаточно данных', 'Отметь минимум 2 цикла'),
  low('Низкая', 'Мало записей или нерегулярный цикл'),
  medium('Средняя', 'Прогноз приблизительный'),
  high('Высокая', 'Достаточно данных для надёжного прогноза');

  const PredictionAccuracyLevel(this.label, this.hint);

  final String label;
  final String hint;
}

/// Оценка точности прогноза по истории циклов.
abstract final class PredictionAccuracy {
  static PredictionAccuracyLevel evaluate(
    List<Cycle> cycles,
    double regularity,
  ) {
    if (cycles.length < 2) return PredictionAccuracyLevel.insufficient;
    if (cycles.length < 3 || regularity >= 4) {
      return PredictionAccuracyLevel.low;
    }
    if (cycles.length < 5 || regularity >= 2) {
      return PredictionAccuracyLevel.medium;
    }
    return PredictionAccuracyLevel.high;
  }
}
