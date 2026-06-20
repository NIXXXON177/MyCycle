import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Сохранение фото дневника в локальную директорию приложения.
class DiaryImageStorage {
  const DiaryImageStorage({this.baseDirectory});

  /// Базовый каталог документов (для тестов).
  final String? baseDirectory;

  final _uuid = const Uuid();

  Future<String> get _imagesDir async {
    final base = baseDirectory ?? (await getApplicationDocumentsDirectory()).path;
    final dir = Directory(p.join(base, 'diary_images'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  /// Копирует файл из [sourcePath] в хранилище приложения.
  Future<String> saveFromPath(String sourcePath) async {
    final dir = await _imagesDir;
    final ext = p.extension(sourcePath).isEmpty ? '.jpg' : p.extension(sourcePath);
    final filename = '${_uuid.v4()}$ext';
    final target = p.join(dir, filename);
    await File(sourcePath).copy(target);
    return target;
  }

  Future<void> deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> deleteFiles(Iterable<String> paths) async {
    for (final path in paths) {
      await deleteFile(path);
    }
  }

  /// Путь к каталогу фотографий дневника.
  Future<String> get imagesDirectory => _imagesDir;

  /// Удаляет все файлы в каталоге фотографий.
  Future<void> clearAll() async {
    final dir = Directory(await _imagesDir);
    if (!await dir.exists()) return;
    await for (final entity in dir.list()) {
      if (entity is File) {
        await entity.delete();
      }
    }
  }

  /// Копирует каталог фотографий в [targetDir]/diary_images.
  Future<void> copyAllTo(String targetDir) async {
    final sourceDir = Directory(await _imagesDir);
    if (!await sourceDir.exists()) return;

    final destRoot = Directory(_join(targetDir, 'diary_images'));
    if (!await destRoot.exists()) {
      await destRoot.create(recursive: true);
    }

    await for (final entity in sourceDir.list()) {
      if (entity is! File) continue;
      final name = p.basename(entity.path);
      await entity.copy(_join(destRoot.path, name));
    }
  }

  /// Восстанавливает фотографии из распакованного архива.
  Future<void> restoreFromExtractedDir(String extractDir) async {
    final source = Directory(_join(extractDir, 'diary_images'));
    if (!await source.exists()) return;

    await clearAll();
    final dest = await _imagesDir;
    await for (final entity in source.list()) {
      if (entity is! File) continue;
      final name = p.basename(entity.path);
      await entity.copy(_join(dest, name));
    }
  }

  /// Создаёт резервную копию каталога фотографий.
  Future<void> backupTo(String backupDir) async {
    final source = Directory(await _imagesDir);
    final dest = Directory(_join(backupDir, 'diary_images'));
    if (await dest.exists()) {
      await dest.delete(recursive: true);
    }
    if (!await source.exists()) {
      await dest.create(recursive: true);
      return;
    }
    await _copyDirectory(source, dest);
  }

  /// Восстанавливает каталог фотографий из резервной копии.
  Future<void> restoreFromBackupDir(String backupDir) async {
    final source = Directory(_join(backupDir, 'diary_images'));
    if (!await source.exists()) return;
    await clearAll();
    final dest = Directory(await _imagesDir);
    await _copyDirectory(source, dest);
  }

  static String _join(String a, String b) => p.join(a, b);

  static Future<void> _copyDirectory(Directory source, Directory dest) async {
    if (!await dest.exists()) {
      await dest.create(recursive: true);
    }
    await for (final entity in source.list(recursive: true)) {
      if (entity is! File) continue;
      final relative = p.relative(entity.path, from: source.path);
      final target = File(p.join(dest.path, relative));
      await target.parent.create(recursive: true);
      await entity.copy(target.path);
    }
  }
}
