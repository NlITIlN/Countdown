import 'package:shared_preferences/shared_preferences.dart';

class TimerPrefs {
  TimerPrefs(this._prefs);

  /// Единственное место, где задаются границы таймера.
  static const minMinutes = 1;
  static const maxMinutes = 5;
  static const defaultMinutes = 5;

  static int clampMinutes(int minutes) => minutes.clamp(minMinutes, maxMinutes);

  static const _minutesKey = 'timer_minutes';
  static const _endsAtKey = 'timer_ends_at_iso';

  final SharedPreferences _prefs;

  int loadMinutes() =>
      clampMinutes(_prefs.getInt(_minutesKey) ?? defaultMinutes);

  Future<void> saveMinutes(int minutes) async {
    await _prefs.setInt(_minutesKey, clampMinutes(minutes));
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
