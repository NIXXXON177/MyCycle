import 'package:mycycle/core/enums/mood_level.dart';
import 'package:mycycle/core/services/diary_image_storage.dart';
import 'package:mycycle/features/diary/data/datasources/diary_image_local_datasource.dart';
import 'package:mycycle/features/diary/data/datasources/diary_local_datasource.dart';
import 'package:mycycle/features/diary/domain/entities/diary_entry.dart';
import 'package:mycycle/features/diary/domain/entities/diary_image.dart';
import 'package:mycycle/features/diary/domain/entities/diary_list_query.dart';
import 'package:uuid/uuid.dart';

class DiaryRepository {
  DiaryRepository(
    this._dataSource,
    this._imageDataSource,
    this._imageStorage,
  );

  final DiaryLocalDataSource _dataSource;
  final DiaryImageLocalDataSource _imageDataSource;
  final DiaryImageStorage _imageStorage;
  final _uuid = const Uuid();

  Future<List<DiaryEntry>> getAll() => _dataSource.getAll();

  Future<List<DiaryEntry>> query(DiaryListQuery query) =>
      _dataSource.query(query);

  Future<List<DiaryEntry>> search(String query) {
    if (query.trim().isEmpty) return getAll();
    return _dataSource.search(query.trim());
  }

  Future<DiaryEntry?> getById(String id) => _dataSource.getById(id);

  Future<List<DiaryImage>> getImages(String diaryId) =>
      _imageDataSource.getByDiaryId(diaryId);

  Future<List<DiaryImage>> getAllImages() => _imageDataSource.getAll();

  Future<DiaryEntry> add({
    required DateTime date,
    required String text,
    required MoodLevel mood,
    bool isFavorite = false,
    List<String> imageSourcePaths = const [],
  }) async {
    final now = DateTime.now();
    final entry = DiaryEntry(
      id: _uuid.v4(),
      date: date,
      text: text,
      mood: mood,
      createdAt: now,
      updatedAt: now,
      isFavorite: isFavorite,
    );
    await _dataSource.insert(entry);
    await _attachImages(entry.id, imageSourcePaths);
    return entry;
  }

  Future<void> update(DiaryEntry entry) async {
    final updated = entry.copyWith(updatedAt: DateTime.now());
    await _dataSource.update(updated);
  }

  Future<void> toggleFavorite(DiaryEntry entry) async {
    await update(entry.copyWith(isFavorite: !entry.isFavorite));
  }

  Future<DiaryImage> addImage({
    required String diaryId,
    required String sourcePath,
  }) async {
    final storedPath = await _imageStorage.saveFromPath(sourcePath);
    final image = DiaryImage(
      id: _uuid.v4(),
      diaryId: diaryId,
      imagePath: storedPath,
      createdAt: DateTime.now(),
    );
    await _imageDataSource.insert(image);
    return image;
  }

  Future<void> deleteImage(DiaryImage image) async {
    await _imageStorage.deleteFile(image.imagePath);
    await _imageDataSource.delete(image.id);
  }

  Future<void> delete(String id) async {
    final images = await _imageDataSource.getByDiaryId(id);
    await _imageStorage.deleteFiles(images.map((i) => i.imagePath));
    await _imageDataSource.deleteByDiaryId(id);
    await _dataSource.delete(id);
  }

  Future<void> _attachImages(String diaryId, List<String> paths) async {
    for (final path in paths) {
      await addImage(diaryId: diaryId, sourcePath: path);
    }
  }
}
