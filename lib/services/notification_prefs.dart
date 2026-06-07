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

  // Achievement dedupe keys
  static const _lastAchievementKey = 'notification_last_achievement_key';
  static const _lastAchievementAt = 'notification_last_achievement_at';

  String? lastAchievementKey() => _prefs.getString(_lastAchievementKey);

  DateTime? lastAchievementAt() {
    final ms = _prefs.getInt(_lastAchievementAt);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> saveLastAchievement(String key) async {
    await _prefs.setString(_lastAchievementKey, key);
    await _prefs.setInt(_lastAchievementAt, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> clearLastAchievement() async {
    await _prefs.remove(_lastAchievementKey);
    await _prefs.remove(_lastAchievementAt);
  }
}
