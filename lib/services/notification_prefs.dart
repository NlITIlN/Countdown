import 'package:shared_preferences/shared_preferences.dart';

class NotificationPrefs {
  NotificationPrefs(this._prefs);

  static const _soundKey = 'notification_sound_enabled';
  static const _vibrateKey = 'notification_vibration_enabled';

  final SharedPreferences _prefs;

  bool soundEnabled() => _prefs.getBool(_soundKey) ?? true;

  bool vibrationEnabled() => _prefs.getBool(_vibrateKey) ?? true;

  Future<void> saveSoundEnabled(bool enabled) async {
    await _prefs.setBool(_soundKey, enabled);
  }

  Future<void> saveVibrationEnabled(bool enabled) async {
    await _prefs.setBool(_vibrateKey, enabled);
  }

  static const _enabledKey = 'notifications_enabled';

  /// Главный выключатель: false — никаких уведомлений (статистика и награды
  /// всё равно считаются).
  bool notificationsEnabled() => _prefs.getBool(_enabledKey) ?? true;

  Future<void> saveNotificationsEnabled(bool enabled) async {
    await _prefs.setBool(_enabledKey, enabled);
  }

  static const _permissionAskedKey = 'notification_permission_asked';

  /// Разрешение спрашиваем один раз — при первом запуске таймера.
  bool permissionAsked() => _prefs.getBool(_permissionAskedKey) ?? false;

  Future<void> markPermissionAsked() async {
    await _prefs.setBool(_permissionAskedKey, true);
  }

  // Achievement dedupe: each type is shown at most once per period
  // (day / week / month key from AchievementRules). The prefix keeps its
  // historic name so flags saved by older versions still apply.
  static const _achievementPrefix = 'notification_achievement_day_';

  bool achievementShownIn(String type, String period) =>
      _prefs.getString('$_achievementPrefix$type') == period;

  Future<void> markAchievementShown(String type, String period) async {
    await _prefs.setString('$_achievementPrefix$type', period);
  }
}
