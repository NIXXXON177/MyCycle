/// Локализация боли.
enum PainLocation {
  abdomen('Живот', '🫃'),
  head('Голова', '🤯'),
  back('Спина', '🔙'),
  chest('Грудь', '💗');

  const PainLocation(this.label, this.emoji);

  final String label;
  final String emoji;

  static PainLocation? fromKey(String key) {
    try {
      return PainLocation.values.byName(key);
    } catch (_) {
      return null;
    }
  }
}
