import 'package:florea/core/enums/support_event_type.dart';
import 'package:florea/features/support/domain/entities/support_event.dart';

abstract final class SupportEventModel {
  static SupportEvent fromMap(Map<String, dynamic> map) {
    return SupportEvent(
      id: map['id'] as String,
      type: SupportEventType.fromKey(map['type'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  static Map<String, dynamic> toMap(SupportEvent event) {
    return {
      'id': event.id,
      'type': event.type.name,
      'created_at': event.createdAt.toIso8601String(),
    };
  }
}
