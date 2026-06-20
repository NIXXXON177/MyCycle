/// Константы формата резервной копии MyCycle Backup v2.
abstract final class BackupConstants {
  static const int backupVersion = 2;

  static const String manifestFile = 'manifest.json';
  static const String settingsFile = 'settings.json';
  static const String databaseFile = 'mycycle.db';
  static const String imagesDir = 'diary_images';

  static const List<int> sqliteMagic = [
    0x53, 0x51, 0x4C, 0x69, 0x74, 0x65, 0x20, 0x66, //
    0x6F, 0x72, 0x6D, 0x61, 0x74, 0x20, 0x33, 0x00, //
  ];
}
