import 'package:mycycle/core/enums/wish_priority.dart';

/// Запись в списке желаний.
class Wish {
  const Wish({
    required this.id,
    required this.title,
    this.description,
    this.link,
    required this.priority,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String? description;
  final String? link;
  final WishPriority priority;
  final DateTime createdAt;

  Wish copyWith({
    String? id,
    String? title,
    String? description,
    String? link,
    WishPriority? priority,
    DateTime? createdAt,
    bool clearDescription = false,
    bool clearLink = false,
  }) {
    return Wish(
      id: id ?? this.id,
      title: title ?? this.title,
      description: clearDescription ? null : (description ?? this.description),
      link: clearLink ? null : (link ?? this.link),
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
