import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jiyibi/core/theme/app_theme.dart';

const _themePreferenceKey = 'selected_theme';

final themeControllerProvider = NotifierProvider<ThemeController, AppThemeKey>(
  ThemeController.new,
);

class ThemeController extends Notifier<AppThemeKey> {
  @override
  AppThemeKey build() {
    _loadTheme();
    return AppThemeKey.pine;
  }

  Future<void> setTheme(AppThemeKey themeKey) async {
    state = themeKey;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themePreferenceKey, themeKey.name);
  }

  Future<void> _loadTheme() async {
    final preferences = await SharedPreferences.getInstance();
    final savedTheme = preferences.getString(_themePreferenceKey);
    if (savedTheme == null) return;

    final themeKey = AppThemeKey.values.where((key) {
      return key.name == savedTheme;
    }).firstOrNull;

    if (themeKey != null) state = themeKey;
  }
}
