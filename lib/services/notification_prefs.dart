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
