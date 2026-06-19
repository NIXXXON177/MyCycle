/// Приоритет желания.
enum WishPriority {
  low('Низкий', 1),
  medium('Средний', 2),
  high('Высокий', 3);

  const WishPriority(this.label, this.value);

  final String label;
  final int value;

  static WishPriority fromValue(int value) {
    return WishPriority.values.firstWhere(
      (e) => e.value == value,
      orElse: () => WishPriority.medium,
    );
  }
}
