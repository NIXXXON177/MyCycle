import 'package:mycycle/core/constants/db_tables.dart';
import 'package:mycycle/core/database/app_database.dart';
import 'package:mycycle/features/support/data/models/support_event_model.dart';
import 'package:mycycle/features/support/domain/entities/support_event.dart';

class SupportLocalDataSource {
  SupportLocalDataSource(this._db);

  final AppDatabase _db;

  Future<List<SupportEvent>> getAll() async {
    final database = await _db.database;
    final maps = await database.query(
      DbTables.supportEvents,
      orderBy: 'created_at DESC',
    );
    return maps.map(SupportEventModel.fromMap).toList();
  }

  Future<void> insert(SupportEvent event) async {
    final database = await _db.database;
    await database.insert(DbTables.supportEvents, SupportEventModel.toMap(event));
  }
}
