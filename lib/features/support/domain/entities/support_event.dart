import 'package:florea/core/enums/support_event_type.dart';

/// Событие нажатия кнопки поддержки.
class SupportEvent {
  const SupportEvent({
    required this.id,
    required this.type,
    required this.createdAt,
  });

  final String id;
  final SupportEventType type;
  final DateTime createdAt;
}
