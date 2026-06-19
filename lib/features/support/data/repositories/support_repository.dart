import 'package:mycycle/core/enums/support_event_type.dart';
import 'package:mycycle/features/support/data/datasources/support_local_datasource.dart';
import 'package:mycycle/features/support/domain/entities/support_event.dart';
import 'package:uuid/uuid.dart';

class SupportRepository {
  SupportRepository(this._dataSource);

  final SupportLocalDataSource _dataSource;
  final _uuid = const Uuid();

  Future<List<SupportEvent>> getAll() => _dataSource.getAll();

  Future<void> add(SupportEvent event) => _dataSource.insert(event);

  Future<SupportEvent> recordEvent(SupportEventType type) async {
    final event = SupportEvent(
      id: _uuid.v4(),
      type: type,
      createdAt: DateTime.now(),
    );
    await _dataSource.insert(event);
    return event;
  }
}
