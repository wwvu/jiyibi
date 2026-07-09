class MoneyUtils {
  const MoneyUtils._();

  static String formatYuan(int cents) {
    final isNegative = cents < 0;
    final absoluteCents = cents.abs();
    final yuan = absoluteCents ~/ 100;
    final fraction = absoluteCents % 100;
    final yuanText = yuan.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );

    return '${isNegative ? '-' : ''}¥$yuanText.${fraction.toString().padLeft(2, '0')}';
  }

  /// 转为纯金额字符串（无 ¥ 符号、无千分位），始终 2 位小数。
  /// 纯整数运算，不经 double。例：1234 -> "12.34"，1200 -> "12.00"。
  static String formatYuanPlain(int cents) {
    final isNegative = cents < 0;
    final absoluteCents = cents.abs();
    final yuan = absoluteCents ~/ 100;
    final fraction = absoluteCents % 100;
    return '${isNegative ? '-' : ''}$yuan.${fraction.toString().padLeft(2, '0')}';
  }

  static int yuanToCents(String yuan) {
    final trimmed = yuan.trim();
    if (trimmed.isEmpty) return 0;

    final isNegative = trimmed.startsWith('-');
    final body = trimmed.startsWith('-') || trimmed.startsWith('+')
        ? trimmed.substring(1)
        : trimmed;

    if (body.isEmpty) return 0;
    if (!RegExp(r'^\d+(\.\d*)?$').hasMatch(body)) return 0;

    final parts = body.split('.');
    final yuanPart = int.tryParse(parts[0]) ?? 0;
    final rawFraction = parts.length == 2 ? parts[1] : '';
    final normalizedFraction = rawFraction.padRight(2, '0');
    final centsPart = int.tryParse(normalizedFraction.substring(0, 2)) ?? 0;
    final cents = yuanPart * 100 + centsPart;

    return isNegative ? -cents : cents;
  }

  static int sub(int a, int b) => a - b;
}
