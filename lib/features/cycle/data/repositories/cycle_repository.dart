import 'package:mycycle/core/utils/cycle_calculator.dart';
import 'package:mycycle/features/cycle/data/datasources/cycle_local_datasource.dart';
import 'package:mycycle/features/cycle/domain/entities/cycle.dart';
import 'package:mycycle/features/cycle/domain/entities/cycle_prediction.dart';
import 'package:uuid/uuid.dart';

class CycleRepository {
  CycleRepository(this._dataSource, this._calculator);

  final CycleLocalDataSource _dataSource;
  final CycleCalculator _calculator;
  final _uuid = const Uuid();

  Future<List<Cycle>> getAllCycles() => _dataSource.getAll();

  Future<CyclePrediction> getPrediction([DateTime? date]) {
    return getAllCycles().then((cycles) {
      return _calculator.predict(cycles, date ?? DateTime.now());
    });
  }

  Future<void> addCycle({
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    final cycle = Cycle(
      id: _uuid.v4(),
      startDate: startDate,
      endDate: endDate,
      createdAt: DateTime.now(),
    );
    await _dataSource.insert(cycle);
  }

  Future<void> updateCycle(Cycle cycle) => _dataSource.update(cycle);

  Future<void> deleteCycle(String id) => _dataSource.delete(id);

  int averageCycleLength(List<Cycle> cycles) =>
      _calculator.averageCycleLength(cycles);

  int averagePeriodLength(List<Cycle> cycles) =>
      _calculator.averagePeriodLength(cycles);

  double cycleRegularity(List<Cycle> cycles) =>
      _calculator.cycleRegularity(cycles);

  bool isPeriodDay(List<Cycle> cycles, DateTime date) =>
      _calculator.isPeriodDay(cycles, date);

  bool isOvulationDay(CyclePrediction prediction, DateTime date) =>
      _calculator.isOvulationDay(prediction, date);

  bool isFertileDay(CyclePrediction prediction, DateTime date) =>
      _calculator.isFertileDay(prediction, date);
}
