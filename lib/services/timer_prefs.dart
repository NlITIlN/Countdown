import 'package:shared_preferences/shared_preferences.dart';

class TimerPrefs {
  TimerPrefs(this._prefs);

  static const _minutesKey = 'timer_minutes';
  static const _endsAtKey = 'timer_ends_at_iso';

  final SharedPreferences _prefs;

  int loadMinutes() {
    final raw = _prefs.getInt(_minutesKey) ?? 5;
    return raw.clamp(1, 5);
  }

  Future<void> saveMinutes(int minutes) async {
    await _prefs.setInt(_minutesKey, minutes.clamp(1, 5));
  }

  DateTime? loadEndsAt() {
    final raw = _prefs.getString(_endsAtKey);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> saveEndsAt(DateTime endsAt) async {
    await _prefs.setString(_endsAtKey, endsAt.toIso8601String());
  }

  Future<void> clearEndsAt() async {
    await _prefs.remove(_endsAtKey);
  }
}
