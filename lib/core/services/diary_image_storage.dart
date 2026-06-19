import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Сохранение фото дневника в локальную директорию приложения.
class DiaryImageStorage {
  const DiaryImageStorage();

  final _uuid = const Uuid();

  Future<String> get _imagesDir async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'diary_images'));
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
}
