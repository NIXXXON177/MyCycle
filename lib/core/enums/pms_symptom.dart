/// Симптомы ПМС / предменструального периода.
enum PmsSymptom {
  irritability('Раздражительность', '😤'),
  anxiety('Тревога', '😰'),
  tearfulness('Плаксивость', '😢'),
  breastSensitivity('Чувствительность груди', '💗'),
  bloating('Вздутие', '🎈'),
  sugarCraving('Тяга к сладкому', '🍫');

  const PmsSymptom(this.label, this.emoji);

  final String label;
  final String emoji;

  static PmsSymptom? fromKey(String key) {
    try {
      return PmsSymptom.values.byName(key);
    } catch (_) {
      return null;
    }
  }
}
