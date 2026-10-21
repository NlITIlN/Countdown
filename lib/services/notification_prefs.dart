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

  // Achievement dedupe: each type is shown at most once per day.
  static const _achievementDayPrefix = 'notification_achievement_day_';

  bool achievementShownToday(String type) =>
      _prefs.getString('$_achievementDayPrefix$type') ==
      _dayKey(DateTime.now());

  Future<void> markAchievementShown(String type) async {
    await _prefs.setString(
      '$_achievementDayPrefix$type',
      _dayKey(DateTime.now()),
    );
  }

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
