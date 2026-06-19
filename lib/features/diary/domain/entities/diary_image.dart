/// Фото, прикреплённое к записи дневника.
class DiaryImage {
  const DiaryImage({
    required this.id,
    required this.diaryId,
    required this.imagePath,
    required this.createdAt,
  });

  final String id;
  final String diaryId;
  final String imagePath;
  final DateTime createdAt;
}
