import 'package:florea/core/enums/wish_priority.dart';
import 'package:florea/features/wishes/data/datasources/wish_local_datasource.dart';
import 'package:florea/features/wishes/domain/entities/wish.dart';
import 'package:uuid/uuid.dart';

class WishRepository {
  WishRepository(this._dataSource);

  final WishLocalDataSource _dataSource;
  final _uuid = const Uuid();

  Future<List<Wish>> getAll() => _dataSource.getAll();

  Future<void> add(Wish wish) => _dataSource.insert(wish);

  Future<Wish> create({
    required String title,
    String? description,
    String? link,
    required WishPriority priority,
  }) async {
    final wish = Wish(
      id: _uuid.v4(),
      title: title,
      description: description,
      link: link,
      priority: priority,
      createdAt: DateTime.now(),
    );
    await _dataSource.insert(wish);
    return wish;
  }

  Future<void> update(Wish wish) => _dataSource.update(wish);

  Future<void> delete(String id) => _dataSource.delete(id);
}
