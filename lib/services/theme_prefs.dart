import 'package:shared_preferences/shared_preferences.dart';

import '../theme_manager.dart';

class ThemePrefs {
  ThemePrefs(this._prefs);

  static const _themeKey = 'app_theme';

  final SharedPreferences _prefs;

  AppThemeMode loadTheme() {
    final raw = _prefs.getString(_themeKey);
    switch (raw) {
      case 'light':
        return AppThemeMode.light;
      case 'neon':
        return AppThemeMode.neon;
      case 'dark':
      default:
        return AppThemeMode.dark;
    }
  }

  Future<void> saveTheme(AppThemeMode theme) async {
    await _prefs.setString(_themeKey, theme.name);
  }
}
