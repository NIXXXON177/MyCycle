/// Уровень энергии.
enum EnergyLevel {
  high(3, 'Высокая', '⚡'),
  medium(2, 'Средняя', '🔋'),
  low(1, 'Низкая', '🪫');

  const EnergyLevel(this.value, this.label, this.emoji);

  final int value;
  final String label;
  final String emoji;

  static EnergyLevel fromValue(int value) {
    return EnergyLevel.values.firstWhere(
      (e) => e.value == value,
      orElse: () => EnergyLevel.medium,
    );
  }
}
