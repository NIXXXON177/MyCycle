/// Тип близости за день.
enum IntimacyType {
  none(0, 'Не было', '—'),
  withEjaculation(1, 'С эякуляцией', '💦'),
  withoutEjaculation(2, 'Без эякуляции', '🤍');

  const IntimacyType(this.value, this.label, this.emoji);

  final int value;
  final String label;
  final String emoji;

  static IntimacyType fromValue(int? value) {
    if (value == null) return IntimacyType.none;
    return IntimacyType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => IntimacyType.none,
    );
  }

  /// Варианты для выбора в UI (без «не отмечено»).
  static const loggable = [
    IntimacyType.none,
    IntimacyType.withEjaculation,
    IntimacyType.withoutEjaculation,
  ];
}
