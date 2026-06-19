import 'package:mycycle/core/enums/wish_priority.dart';
import 'package:mycycle/features/wishes/domain/entities/wish.dart';

abstract final class WishModel {
  static Wish fromMap(Map<String, dynamic> map) {
    return Wish(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      link: map['link'] as String?,
      priority: WishPriority.fromValue(map['priority'] as int),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  static Map<String, dynamic> toMap(Wish wish) {
    return {
      'id': wish.id,
      'title': wish.title,
      'description': wish.description,
      'link': wish.link,
      'priority': wish.priority.value,
      'created_at': wish.createdAt.toIso8601String(),
    };
  }
}
