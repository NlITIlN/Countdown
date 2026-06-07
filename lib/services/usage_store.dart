import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/usage_stats.dart';

class UsageStore {
  UsageStore(this._prefs);

  static const _key = 'usage_events';
  static const _maxEvents = 500;

  final SharedPreferences _prefs;
  List<DateTime>? _cache;

  Future<List<DateTime>> _loadEvents() async {
    if (_cache != null) return _cache!;
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      _cache = [];
      return _cache!;
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    _cache = decoded.map((e) => DateTime.parse(e as String)).toList();
    return _cache!;
  }

  Future<void> recordCompletion() async {
    final events = await _loadEvents()..add(DateTime.now());
    if (events.length > _maxEvents) {
      _cache = events.sublist(events.length - _maxEvents);
    } else {
      _cache = events;
    }
    await _prefs.setString(
      _key,
      jsonEncode(_cache!.map((e) => e.toIso8601String()).toList()),
    );
  }

  Future<UsageStats> loadStats() async {
    final events = await _loadEvents();
    return UsageStats.fromTimestamps(events);
  }
}
