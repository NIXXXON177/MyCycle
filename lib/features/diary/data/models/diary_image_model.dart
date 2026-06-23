import 'package:florea/features/diary/domain/entities/diary_image.dart';

abstract final class DiaryImageModel {
  static DiaryImage fromMap(Map<String, dynamic> map) {
    return DiaryImage(
      id: map['id'] as String,
      diaryId: map['diary_id'] as String,
      imagePath: map['image_path'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  static Map<String, dynamic> toMap(DiaryImage image) {
    return {
      'id': image.id,
      'diary_id': image.diaryId,
      'image_path': image.imagePath,
      'created_at': image.createdAt.toIso8601String(),
    };
  }
}
