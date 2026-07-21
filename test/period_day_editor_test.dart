import 'package:flutter_test/flutter_test.dart';
import 'package:florea/features/cycle/domain/entities/cycle.dart';
import 'package:florea/features/cycle/domain/period_day_editor.dart';

Cycle _cycle({
  required String id,
  required DateTime start,
  DateTime? end,
}) {
  return Cycle(
    id: id,
    startDate: start,
    endDate: end,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('PeriodDayEditor.toggle', () {
    test('adds isolated day as create start=end', () {
      final result = PeriodDayEditor.toggle(
        cycles: const [],
        day: DateTime(2026, 3, 10),
      );

      expect(result.isPeriodDay, isTrue);
      expect(result.ops, hasLength(1));
      final op = result.ops.single as PeriodDayCreate;
      expect(op.startDate, DateTime(2026, 3, 10));
      expect(op.endDate, DateTime(2026, 3, 10));
    });

    test('extends range to the right', () {
      final cycles = [
        _cycle(
          id: 'a',
          start: DateTime(2026, 3, 10),
          end: DateTime(2026, 3, 12),
        ),
      ];

      final result = PeriodDayEditor.toggle(
        cycles: cycles,
        day: DateTime(2026, 3, 13),
      );

      expect(result.isPeriodDay, isTrue);
      expect(result.ops, hasLength(1));
      final op = result.ops.single as PeriodDayUpdate;
      expect(op.cycle.id, 'a');
      expect(op.cycle.startDate, DateTime(2026, 3, 10));
      expect(op.cycle.endDate, DateTime(2026, 3, 13));
    });

    test('extends range to the left', () {
      final cycles = [
        _cycle(
          id: 'a',
          start: DateTime(2026, 3, 10),
          end: DateTime(2026, 3, 12),
        ),
      ];

      final result = PeriodDayEditor.toggle(
        cycles: cycles,
        day: DateTime(2026, 3, 9),
      );

      expect(result.isPeriodDay, isTrue);
      final op = result.ops.single as PeriodDayUpdate;
      expect(op.cycle.startDate, DateTime(2026, 3, 9));
      expect(op.cycle.endDate, DateTime(2026, 3, 12));
    });

    test('merges two ranges when filling the gap', () {
      final cycles = [
        _cycle(
          id: 'left',
          start: DateTime(2026, 3, 10),
          end: DateTime(2026, 3, 11),
        ),
        _cycle(
          id: 'right',
          start: DateTime(2026, 3, 13),
          end: DateTime(2026, 3, 14),
        ),
      ];

      final result = PeriodDayEditor.toggle(
        cycles: cycles,
        day: DateTime(2026, 3, 12),
      );

      expect(result.isPeriodDay, isTrue);
      expect(result.ops, hasLength(2));
      final update = result.ops.whereType<PeriodDayUpdate>().single;
      final delete = result.ops.whereType<PeriodDayDelete>().single;
      expect(update.cycle.id, 'left');
      expect(update.cycle.startDate, DateTime(2026, 3, 10));
      expect(update.cycle.endDate, DateTime(2026, 3, 14));
      expect(delete.id, 'right');
    });

    test('removes single-day cycle', () {
      final cycles = [
        _cycle(
          id: 'a',
          start: DateTime(2026, 3, 10),
          end: DateTime(2026, 3, 10),
        ),
      ];

      final result = PeriodDayEditor.toggle(
        cycles: cycles,
        day: DateTime(2026, 3, 10),
      );

      expect(result.isPeriodDay, isFalse);
      expect(result.ops.single, isA<PeriodDayDelete>());
      expect((result.ops.single as PeriodDayDelete).id, 'a');
    });

    test('shrinks from left edge', () {
      final cycles = [
        _cycle(
          id: 'a',
          start: DateTime(2026, 3, 10),
          end: DateTime(2026, 3, 13),
        ),
      ];

      final result = PeriodDayEditor.toggle(
        cycles: cycles,
        day: DateTime(2026, 3, 10),
      );

      expect(result.isPeriodDay, isFalse);
      final op = result.ops.single as PeriodDayUpdate;
      expect(op.cycle.startDate, DateTime(2026, 3, 11));
      expect(op.cycle.endDate, DateTime(2026, 3, 13));
    });

    test('shrinks from right edge', () {
      final cycles = [
        _cycle(
          id: 'a',
          start: DateTime(2026, 3, 10),
          end: DateTime(2026, 3, 13),
        ),
      ];

      final result = PeriodDayEditor.toggle(
        cycles: cycles,
        day: DateTime(2026, 3, 13),
      );

      expect(result.isPeriodDay, isFalse);
      final op = result.ops.single as PeriodDayUpdate;
      expect(op.cycle.startDate, DateTime(2026, 3, 10));
      expect(op.cycle.endDate, DateTime(2026, 3, 12));
    });

    test('splits range when removing middle day', () {
      final cycles = [
        _cycle(
          id: 'a',
          start: DateTime(2026, 3, 10),
          end: DateTime(2026, 3, 14),
        ),
      ];

      final result = PeriodDayEditor.toggle(
        cycles: cycles,
        day: DateTime(2026, 3, 12),
      );

      expect(result.isPeriodDay, isFalse);
      expect(result.ops, hasLength(2));
      final update = result.ops.whereType<PeriodDayUpdate>().single;
      final create = result.ops.whereType<PeriodDayCreate>().single;
      expect(update.cycle.id, 'a');
      expect(update.cycle.startDate, DateTime(2026, 3, 10));
      expect(update.cycle.endDate, DateTime(2026, 3, 11));
      expect(create.startDate, DateTime(2026, 3, 13));
      expect(create.endDate, DateTime(2026, 3, 14));
    });

    test('open cycle uses defaultPeriodLength for coverage', () {
      final cycles = [
        _cycle(id: 'open', start: DateTime(2026, 3, 10)),
      ];

      // defaultPeriodLength=5 → 10..14 covered
      final covered = PeriodDayEditor.toggle(
        cycles: cycles,
        day: DateTime(2026, 3, 14),
        defaultPeriodLength: 5,
      );
      expect(covered.isPeriodDay, isFalse);
      final shrink = covered.ops.single as PeriodDayUpdate;
      expect(shrink.cycle.startDate, DateTime(2026, 3, 10));
      expect(shrink.cycle.endDate, DateTime(2026, 3, 13));

      final outside = PeriodDayEditor.toggle(
        cycles: cycles,
        day: DateTime(2026, 3, 15),
        defaultPeriodLength: 5,
      );
      expect(outside.isPeriodDay, isTrue);
      final extend = outside.ops.single as PeriodDayUpdate;
      expect(extend.cycle.startDate, DateTime(2026, 3, 10));
      expect(extend.cycle.endDate, DateTime(2026, 3, 15));
    });

    test('removing middle of open cycle materializes both sides', () {
      final cycles = [
        _cycle(id: 'open', start: DateTime(2026, 3, 10)),
      ];

      final result = PeriodDayEditor.toggle(
        cycles: cycles,
        day: DateTime(2026, 3, 12),
        defaultPeriodLength: 5,
      );

      expect(result.isPeriodDay, isFalse);
      final update = result.ops.whereType<PeriodDayUpdate>().single;
      final create = result.ops.whereType<PeriodDayCreate>().single;
      expect(update.cycle.endDate, DateTime(2026, 3, 11));
      expect(create.startDate, DateTime(2026, 3, 13));
      expect(create.endDate, DateTime(2026, 3, 14));
    });
  });
}
