import 'package:flutter_test/flutter_test.dart';
import 'package:jiyibi/core/spending_pulse.dart';

void main() {
  group('SpendingPulse', () {
    test('asks for a budget when none is configured', () {
      final pulse = SpendingPulse.calculate(
        budgetCents: 0,
        monthExpenseCents: 120000,
        todayExpenseCents: 2000,
        now: DateTime(2026, 7, 10),
      );

      expect(pulse.level, SpendingPulseLevel.unconfigured);
      expect(pulse.safeDailyCents, 0);
    });

    test('marks clearly slow spending as calm', () {
      final pulse = SpendingPulse.calculate(
        budgetCents: 310000,
        monthExpenseCents: 50000,
        todayExpenseCents: 1000,
        now: DateTime(2026, 7, 15),
      );

      expect(pulse.level, SpendingPulseLevel.calm);
      expect(pulse.remainingCents, 260000);
    });

    test('warns when spending runs ahead of time', () {
      final pulse = SpendingPulse.calculate(
        budgetCents: 310000,
        monthExpenseCents: 190000,
        todayExpenseCents: 30000,
        now: DateTime(2026, 7, 15),
      );

      expect(pulse.level, SpendingPulseLevel.watch);
      expect(pulse.projectedCents, greaterThan(310000));
    });

    test('marks an exceeded budget as over', () {
      final pulse = SpendingPulse.calculate(
        budgetCents: 100000,
        monthExpenseCents: 120000,
        todayExpenseCents: 0,
        now: DateTime(2026, 7, 20),
      );

      expect(pulse.level, SpendingPulseLevel.over);
      expect(pulse.remainingCents, -20000);
    });
  });
}
