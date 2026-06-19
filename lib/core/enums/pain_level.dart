/// Уровень боли.
enum PainLevel {
  none(0, 'Нет', '✅'),
  mild(1, 'Слабая', '😣'),
  moderate(2, 'Средняя', '😖'),
  severe(3, 'Сильная', '🤕');

  const PainLevel(this.value, this.label, this.emoji);

  final int value;
  final String label;
  final String emoji;

  static PainLevel fromValue(int value) {
    return PainLevel.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PainLevel.none,
    );
  }
}
