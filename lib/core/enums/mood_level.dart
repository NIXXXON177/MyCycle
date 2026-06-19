/// Настроение пользователя (1–5).
enum MoodLevel {
  excellent(5, 'Отличное', '😊'),
  good(4, 'Хорошее', '🙂'),
  normal(3, 'Нормальное', '😐'),
  bad(2, 'Плохое', '😔'),
  veryBad(1, 'Очень плохое', '😢');

  const MoodLevel(this.value, this.label, this.emoji);

  final int value;
  final String label;
  final String emoji;

  static MoodLevel fromValue(int value) {
    return MoodLevel.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MoodLevel.normal,
    );
  }
}
