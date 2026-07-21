import 'package:florea/core/utils/cycle_calculator.dart';
import 'package:florea/features/cycle/data/datasources/cycle_local_datasource.dart';
import 'package:florea/features/cycle/domain/entities/cycle.dart';
import 'package:florea/features/cycle/domain/entities/cycle_prediction.dart';
import 'package:florea/features/cycle/domain/period_day_editor.dart';
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

  /// Включает или выключает день месячных. Возвращает новый статус дня.
  Future<bool> togglePeriodDay(DateTime day) async {
    final cycles = await getAllCycles();
    final result = PeriodDayEditor.toggle(
      cycles: cycles,
      day: day,
      defaultPeriodLength: _calculator.defaultPeriodLength,
    );

    for (final op in result.ops) {
      switch (op) {
        case PeriodDayCreate(:final startDate, :final endDate):
          await addCycle(startDate: startDate, endDate: endDate);
        case PeriodDayUpdate(:final cycle):
          await updateCycle(cycle);
        case PeriodDayDelete(:final id):
          await deleteCycle(id);
      }
    }

    return result.isPeriodDay;
  }

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
