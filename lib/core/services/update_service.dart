import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:florea/core/constants/update_config.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Информация о доступном обновлении.
class AppUpdateInfo {
  const AppUpdateInfo({
    required this.versionCode,
    required this.versionName,
    required this.apkUrl,
    this.notes,
  });

  final int versionCode;
  final String versionName;
  final String apkUrl;
  final String? notes;

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    final code = json['versionCode'];
    return AppUpdateInfo(
      versionCode: code is int ? code : int.tryParse('$code') ?? 0,
      versionName: json['versionName']?.toString() ?? '',
      apkUrl: json['apkUrl']?.toString() ?? '',
      notes: json['notes']?.toString(),
    );
  }

  /// Минимальная валидность: есть номер сборки и ссылка на APK.
  bool get isValid => versionCode > 0 && apkUrl.isNotEmpty;
}

/// Проверка и установка обновлений через GitHub Releases.
class UpdateService {
  static const _headers = {
    'User-Agent': 'Florea-App',
    'Accept': 'application/vnd.github+json',
  };

  Future<PackageInfo> currentPackageInfo() => PackageInfo.fromPlatform();

  /// Возвращает обновление, если на GitHub есть более новая сборка.
  Future<AppUpdateInfo?> checkForUpdate() async {
    if (!UpdateConfig.isEnabled) return null;

    final package = await currentPackageInfo();
    final currentCode = int.tryParse(package.buildNumber) ?? 0;

    final manifestUpdate = await _checkManifest(currentCode);
    if (manifestUpdate != null) return manifestUpdate;

    return _checkGitHubRelease(currentCode);
  }

  Future<AppUpdateInfo?> _checkManifest(int currentCode) async {
    try {
      final response = await http
          .get(Uri.parse(UpdateConfig.manifestUrl), headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) return null;

      final update = AppUpdateInfo.fromJson(decoded);
      if (!update.isValid || update.versionCode <= currentCode) return null;
      return update;
    } catch (e) {
      debugPrint('Manifest check failed: $e');
      return null;
    }
  }

  Future<AppUpdateInfo?> _checkGitHubRelease(int currentCode) async {
    final response = await http
        .get(Uri.parse(UpdateConfig.releasesApiUrl), headers: _headers)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('GitHub вернул код ${response.statusCode}');
    }

    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) return null;

      final tag = decoded['tag_name']?.toString() ?? '';
      final parsed = _parseReleaseTag(tag);
      if (parsed == null) return null;

      final (versionName, versionCode) = parsed;
      if (versionCode <= currentCode) return null;

      final assets = decoded['assets'];
      String? apkUrl;

      if (assets is List) {
        for (final asset in assets) {
          if (asset is! Map) continue;
          final name = asset['name']?.toString() ?? '';
          if (name.toLowerCase().endsWith('.apk')) {
            apkUrl = asset['browser_download_url']?.toString();
            break;
          }
        }
      }

      apkUrl ??=
          UpdateConfig.manifestUrl.replaceAll('manifest.json', 'Florea.apk');

      return AppUpdateInfo(
        versionCode: versionCode,
        versionName: versionName,
        apkUrl: apkUrl,
        notes: decoded['body']?.toString().trim(),
      );
    } catch (e) {
      debugPrint('GitHub release parse failed: $e');
      return null;
    }
  }

  /// Разбирает тег релиза вида `v1.2.3.45` → (versionName: "1.2.3", code: 45).
  /// Возвращает null, если в теге нет числового хвоста после последней точки.
  (String, int)? _parseReleaseTag(String tag) {
    final normalized =
        (tag.startsWith('v') ? tag.substring(1) : tag).trim();
    if (normalized.isEmpty) return null;

    final separator = normalized.lastIndexOf('.');
    if (separator <= 0 || separator == normalized.length - 1) return null;

    final versionName = normalized.substring(0, separator);
    final versionCode = int.tryParse(normalized.substring(separator + 1));
    if (versionCode == null) return null;

    return (versionName, versionCode);
  }

  /// Скачивает APK и открывает системный установщик (обновление поверх).
  Future<void> downloadAndInstall(AppUpdateInfo update) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('Обновление доступно только на Android');
    }

    final canInstall = await _ensureInstallPermission();
    if (!canInstall) {
      throw Exception('Нет разрешения на установку приложений');
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/florea_update.apk');

    final request = http.Request('GET', Uri.parse(update.apkUrl));
    request.headers.addAll(_headers);
    final response = await request.send().timeout(const Duration(minutes: 10));

    if (response.statusCode != 200) {
      throw Exception('Не удалось скачать APK (${response.statusCode})');
    }

    final sink = file.openWrite();
    try {
      await response.stream.pipe(sink);
    } finally {
      await sink.close();
    }

    final result = await OpenFilex.open(
      file.path,
      type: 'application/vnd.android.package-archive',
    );

    if (result.type != ResultType.done) {
      debugPrint('OpenFilex result: ${result.message}');
    }
  }

  Future<bool> _ensureInstallPermission() async {
    if (!Platform.isAndroid) return false;

    final status = await Permission.requestInstallPackages.status;
    if (status.isGranted) return true;

    final result = await Permission.requestInstallPackages.request();
    return result.isGranted;
  }
}
