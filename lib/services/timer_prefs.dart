import 'package:shared_preferences/shared_preferences.dart';

class TimerPrefs {
  TimerPrefs(this._prefs);

  /// Единственное место, где задаются границы таймера (в секундах).
  static const minSeconds = 10;
  static const maxSeconds = 5 * 60;
  static const stepSeconds = 10;
  static const defaultSeconds = 5 * 60;

  /// В пределах [minSeconds]..[maxSeconds] и кратно [stepSeconds].
  static int clampSeconds(int seconds) {
    final stepped = (seconds / stepSeconds).round() * stepSeconds;
    return stepped.clamp(minSeconds, maxSeconds);
  }

  static const _secondsKey = 'timer_seconds';

  /// Ключ старых версий (длительность в минутах) — читается для миграции.
  static const _legacyMinutesKey = 'timer_minutes';
  static const _endsAtKey = 'timer_ends_at_iso';

  final SharedPreferences _prefs;

  int loadSeconds() {
    final seconds = _prefs.getInt(_secondsKey);
    if (seconds != null) return clampSeconds(seconds);
    final legacyMinutes = _prefs.getInt(_legacyMinutesKey);
    return clampSeconds(
      legacyMinutes != null ? legacyMinutes * 60 : defaultSeconds,
    );
  }

  Future<void> saveSeconds(int seconds) async {
    await _prefs.setInt(_secondsKey, clampSeconds(seconds));
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
