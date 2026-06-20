import 'dart:io' show Platform;

/// Платформа устройства для manifest.json резервной копии.
abstract final class BackupDevicePlatform {
  static String current() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }
}
