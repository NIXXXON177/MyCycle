/// Тип события поддержки.
enum SupportEventType {
  sad('Мне грустно', '❤️'),
  unwell('Мне плохо', '🤕'),
  tired('Устала', '😴'),
  needSupport('Нужна поддержка', '🥺');

  const SupportEventType(this.label, this.emoji);

  final String label;
  final String emoji;

  static SupportEventType fromKey(String key) {
    return SupportEventType.values.firstWhere(
      (e) => e.name == key,
      orElse: () => SupportEventType.needSupport,
    );
  }
}
