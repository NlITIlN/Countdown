import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/usage_stats.dart';

class UsageStore {
  UsageStore(this._prefs);

  static const _key = 'usage_events';
  static const _totalKey = 'usage_total_count';
  static const _maxEvents = 500;

  final SharedPreferences _prefs;
  List<DateTime>? _cache;

  Future<List<DateTime>> _loadEvents() async {
    if (_cache != null) return _cache!;
    _cache = _decode(_prefs.getString(_key));
    return _cache!;
  }

  /// Битые данные не должны ронять приложение: пропускаем то, что не парсится.
  static List<DateTime> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<String>()
          .map(DateTime.tryParse)
          .whereType<DateTime>()
          .toList();
    } on FormatException catch (e) {
      debugPrint('usage events corrupted, starting fresh: $e');
      return [];
    }
  }

  /// Счётчик за всё время. Для данных старых версий — по числу сохранённых событий.
  int _loadTotal(List<DateTime> events) =>
      _prefs.getInt(_totalKey) ?? events.length;

  Future<void> recordCompletion() async {
    final events = await _loadEvents();
    final total = _loadTotal(events) + 1;
    events.add(DateTime.now());
    if (events.length > _maxEvents) {
      _cache = events.sublist(events.length - _maxEvents);
    } else {
      _cache = events;
    }
    await _prefs.setString(
      _key,
      jsonEncode(_cache!.map((e) => e.toIso8601String()).toList()),
    );
    await _prefs.setInt(_totalKey, total);
  }

  Future<UsageStats> loadStats() async {
    final events = await _loadEvents();
    return UsageStats.fromTimestamps(events, totalCount: _loadTotal(events));
  }
}
