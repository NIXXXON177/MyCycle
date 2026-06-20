/// Сводка перед экспортом резервной копии.
class BackupExportPreview {
  const BackupExportPreview({
    required this.estimatedBytes,
    required this.diaryEntries,
    required this.photos,
    required this.wellbeingEntries,
    required this.cycles,
  });

  final int estimatedBytes;
  final int diaryEntries;
  final int photos;
  final int wellbeingEntries;
  final int cycles;

  String get formattedSize => formatBackupSize(estimatedBytes);

  /// Пиковое потребление места при сборке ZIP (несжатые данные + архив в памяти).
  int get temporarySpaceBytes {
    final uncompressed = (estimatedBytes / 0.92).round();
    return uncompressed + estimatedBytes;
  }

  String get formattedTemporarySpace =>
      formatBackupSize(temporarySpaceBytes);

  static String formatBackupSize(int bytes) {
    if (bytes < 1024) return '~$bytes Б';
    if (bytes < 1024 * 1024) {
      return '~${(bytes / 1024).round()} КБ';
    }
    if (bytes < 1024 * 1024 * 1024) {
      final mb = bytes / (1024 * 1024);
      return mb >= 10 ? '~${mb.round()} МБ' : '~${mb.toStringAsFixed(1)} МБ';
    }
    return '~${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} ГБ';
  }
}
