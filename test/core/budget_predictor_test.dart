import 'package:flutter_test/flutter_test.dart';
import 'package:jiyibi/core/budget_predictor.dart';

void main() {
  group('BudgetPredictor.predictMonthEndCents', () {
    test('predicts overspend for heavy early spending', () {
      final projected = BudgetPredictor.predictMonthEndCents(
        usedCents: 60000,
        daysPassed: 15,
        daysInMonth: 30,
      );
      expect(projected, 120000);
    });

    test('returns 0 when daysPassed is 0', () {
      expect(
        BudgetPredictor.predictMonthEndCents(
          usedCents: 50000,
          daysPassed: 0,
          daysInMonth: 30,
        ),
        0,
      );
    });

    test('handles 31-day month', () {
      final projected = BudgetPredictor.predictMonthEndCents(
        usedCents: 30000,
        daysPassed: 10,
        daysInMonth: 31,
      );
      expect(projected, 93000);
    });
  });

  group('BudgetPredictor.willExceed', () {
    test('true when predicted exceeds budget', () {
      expect(
        BudgetPredictor.willExceed(predictedCents: 120000, budgetCents: 100000),
        isTrue,
      );
    });

    test('false when predicted equals budget', () {
      expect(
        BudgetPredictor.willExceed(predictedCents: 100000, budgetCents: 100000),
        isFalse,
      );
    });

    test('false when predicted below budget', () {
      expect(
        BudgetPredictor.willExceed(predictedCents: 80000, budgetCents: 100000),
        isFalse,
      );
    });
  });

  group('BudgetPredictor.overageCents', () {
    test('returns overage when overspend', () {
      expect(
        BudgetPredictor.overageCents(
          predictedCents: 120000,
          budgetCents: 100000,
        ),
        20000,
      );
    });

    test('returns 0 when not overspend', () {
      expect(
        BudgetPredictor.overageCents(
          predictedCents: 80000,
          budgetCents: 100000,
        ),
        0,
      );
    });
  });

  group('BudgetPredictor.suggestedDailyCents', () {
    test('suggests daily limit to stay within budget', () {
      expect(
        BudgetPredictor.suggestedDailyCents(
          budgetCents: 100000,
          usedCents: 60000,
          daysPassed: 15,
          daysInMonth: 30,
        ),
        2666,
      );
    });

    test('returns 0 when no days left', () {
      expect(
        BudgetPredictor.suggestedDailyCents(
          budgetCents: 100000,
          usedCents: 50000,
          daysPassed: 30,
          daysInMonth: 30,
        ),
        0,
      );
    });

    test('returns 0 when already over budget', () {
      expect(
        BudgetPredictor.suggestedDailyCents(
          budgetCents: 100000,
          usedCents: 120000,
          daysPassed: 15,
          daysInMonth: 30,
        ),
        0,
      );
    });
  });

  group('BudgetPredictor.daysInMonth', () {
    test('returns 30 for April', () {
      expect(BudgetPredictor.daysInMonth(2026, 4), 30);
    });

    test('returns 31 for July', () {
      expect(BudgetPredictor.daysInMonth(2026, 7), 31);
    });

    test('returns 28 for Feb in non-leap year', () {
      expect(BudgetPredictor.daysInMonth(2026, 2), 28);
    });

    test('returns 29 for Feb in leap year', () {
      expect(BudgetPredictor.daysInMonth(2024, 2), 29);
    });
  });
}
