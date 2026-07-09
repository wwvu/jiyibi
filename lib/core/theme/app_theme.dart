import 'package:flutter/material.dart';

import 'package:jiyibi/core/constants.dart';

enum AppThemeKey { pine, sun, mist, sakura, night }

extension AppThemeKeyLabel on AppThemeKey {
  String get label => switch (this) {
    AppThemeKey.pine => '青松',
    AppThemeKey.sun => '暖阳',
    AppThemeKey.mist => '雾兰',
    AppThemeKey.sakura => '樱粉',
    AppThemeKey.night => '暗夜',
  };
}

class AppTheme {
  const AppTheme._();

  static ThemeData byKey(AppThemeKey key) => switch (key) {
    AppThemeKey.pine => _theme(
      seed: const Color(0xFF0F6E56),
      brightness: Brightness.light,
    ),
    AppThemeKey.sun => _theme(
      seed: const Color(0xFFD97706),
      brightness: Brightness.light,
    ),
    AppThemeKey.mist => _theme(
      seed: const Color(0xFF6B8299),
      brightness: Brightness.light,
    ),
    AppThemeKey.sakura => _theme(
      seed: const Color(0xFFC0446E),
      brightness: Brightness.light,
    ),
    AppThemeKey.night => _theme(
      seed: const Color(0xFF2DD4A7),
      brightness: Brightness.dark,
    ),
  };

  static ThemeData _theme({
    required Color seed,
    required Brightness brightness,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: const CircleBorder(),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        headerForegroundColor: colorScheme.onSurface,
        weekdayStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        dayStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return null;
        }),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary;
          }
          if (states.contains(WidgetState.disabled)) {
            return colorScheme.onSurface.withValues(alpha: 0.38);
          }
          return colorScheme.onSurface;
        }),
        todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return null;
        }),
        todayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary;
          }
          return colorScheme.primary;
        }),
        todayBorder: BorderSide(
          color: colorScheme.primary,
          width: 1.5,
        ),
        yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return null;
        }),
        yearForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary;
          }
          return colorScheme.onSurface;
        }),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        hourMinuteColor: colorScheme.surfaceContainerHighest,
        hourMinuteTextColor: colorScheme.onSurface,
        dayPeriodColor: colorScheme.surfaceContainerHighest,
        dayPeriodTextColor: colorScheme.onSurface,
        dialBackgroundColor: colorScheme.surfaceContainerHighest,
        dialHandColor: colorScheme.primary,
        dialTextColor: colorScheme.onSurface,
        entryModeIconColor: colorScheme.primary,
      ),
      extensions: const <ThemeExtension<dynamic>>[
        FinanceColors(expense: expenseColor, income: incomeColor),
      ],
    );
  }
}

@immutable
class FinanceColors extends ThemeExtension<FinanceColors> {
  const FinanceColors({required this.expense, required this.income});

  final Color expense;
  final Color income;

  @override
  FinanceColors copyWith({Color? expense, Color? income}) {
    return FinanceColors(
      expense: expense ?? this.expense,
      income: income ?? this.income,
    );
  }

  @override
  FinanceColors lerp(ThemeExtension<FinanceColors>? other, double t) {
    if (other is! FinanceColors) return this;

    return FinanceColors(
      expense: Color.lerp(expense, other.expense, t) ?? expense,
      income: Color.lerp(income, other.income, t) ?? income,
    );
  }
}
