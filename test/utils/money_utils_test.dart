import 'package:flutter_test/flutter_test.dart';
import 'package:jiyibi/core/utils/money_utils.dart';

void main() {
  group('MoneyUtils.formatYuan', () {
    test('formats zero cents', () {
      expect(MoneyUtils.formatYuan(0), '¥0.00');
    });

    test('formats cents below one yuan', () {
      expect(MoneyUtils.formatYuan(1), '¥0.01');
    });

    test('formats yuan with thousands separators', () {
      expect(MoneyUtils.formatYuan(123456), '¥1,234.56');
    });

    test('formats negative cents', () {
      expect(MoneyUtils.formatYuan(-123456), '-¥1,234.56');
    });
  });

  group('MoneyUtils.formatYuanPlain', () {
    test('formats zero cents', () {
      expect(MoneyUtils.formatYuanPlain(0), '0.00');
    });

    test('formats cents below one yuan', () {
      expect(MoneyUtils.formatYuanPlain(1), '0.01');
    });

    test('does not add thousands separators', () {
      expect(MoneyUtils.formatYuanPlain(123456), '1234.56');
    });

    test('always shows two decimal places', () {
      expect(MoneyUtils.formatYuanPlain(1200), '12.00');
      expect(MoneyUtils.formatYuanPlain(1230), '12.30');
    });

    test('formats negative cents', () {
      expect(MoneyUtils.formatYuanPlain(-123456), '-1234.56');
    });
  });

  group('MoneyUtils.yuanToCents', () {
    test('returns zero for empty input', () {
      expect(MoneyUtils.yuanToCents(''), 0);
    });

    test('parses integer yuan', () {
      expect(MoneyUtils.yuanToCents('12'), 1200);
    });

    test('pads one decimal place', () {
      expect(MoneyUtils.yuanToCents('12.3'), 1230);
    });

    test('parses two decimal places', () {
      expect(MoneyUtils.yuanToCents('12.34'), 1234);
    });

    test('truncates extra decimal places', () {
      expect(MoneyUtils.yuanToCents('12.345'), 1234);
    });

    test('parses negative yuan', () {
      expect(MoneyUtils.yuanToCents('-12.34'), -1234);
    });

    test('trims surrounding whitespace', () {
      expect(MoneyUtils.yuanToCents('  12.34  '), 1234);
    });

    test('returns zero for invalid formats', () {
      expect(MoneyUtils.yuanToCents('12.a'), 0);
      expect(MoneyUtils.yuanToCents('1.2.3'), 0);
    });
  });
}
