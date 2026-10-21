import 'package:countdown/models/achievement_rules.dart';
import 'package:countdown/models/usage_stats.dart';
import 'package:flutter_test/flutter_test.dart';

/// [sessions]: дата → число запусков в этот день.
UsageStats _stats(Map<DateTime, int> sessions) => UsageStats.fromTimestamps([
      for (final e in sessions.entries)
        for (var i = 0; i < e.value; i++) e.key.add(Duration(hours: 9 + i)),
    ]);

void main() {
  // Среда, 21 октября 2026; неделя начинается в понедельник 19-го.
  final wednesday = DateTime(2026, 10, 21, 18);

  group('strong week', () {
    final previousWeeks = {
      DateTime(2026, 10, 12): 2,
      DateTime(2026, 10, 5): 2,
      DateTime(2026, 9, 28): 2,
      DateTime(2026, 9, 21): 2,
    };

    test('more than the median of the previous 4 weeks', () {
      final stats = _stats({
        ...previousWeeks,
        DateTime(2026, 10, 19): 2,
        DateTime(2026, 10, 21): 1,
      });
      expect(AchievementRules.strongWeek(stats, wednesday), 3);
    });

    test('equal to the median is not enough', () {
      final stats = _stats({...previousWeeks, DateTime(2026, 10, 20): 2});
      expect(AchievementRules.strongWeek(stats, wednesday), isNull);
    });

    test('no history — no award', () {
      final stats = _stats({DateTime(2026, 10, 21): 5});
      expect(AchievementRules.strongWeek(stats, wednesday), isNull);
    });

    test('sessions older than 4 weeks do not count', () {
      final stats = _stats({
        DateTime(2026, 9, 14): 10, // 5 недель назад
        DateTime(2026, 10, 21): 1,
      });
      expect(AchievementRules.strongWeek(stats, wednesday), isNull);
    });
  });

  group('month up', () {
    test('more sessions per day than last month (from the 15th)', () {
      // Сентябрь: 15 за 30 дней = 0,5/день; октябрь: 11 за 21 день ≈ 0,52/день.
      final stats = _stats({
        DateTime(2026, 9, 10): 15,
        DateTime(2026, 10, 2): 11,
      });
      expect(AchievementRules.monthUp(stats, wednesday), isTrue);
    });

    test('fewer per day than last month', () {
      final stats = _stats({
        DateTime(2026, 9, 10): 15,
        DateTime(2026, 10, 2): 10, // ≈ 0,48/день
      });
      expect(AchievementRules.monthUp(stats, wednesday), isFalse);
    });

    test('not before the 15th', () {
      final stats = _stats({
        DateTime(2026, 9, 10): 1,
        DateTime(2026, 10, 2): 10,
      });
      expect(AchievementRules.monthUp(stats, DateTime(2026, 10, 14)), isFalse);
    });

    test('no activity last month — no award', () {
      final stats = _stats({DateTime(2026, 10, 2): 30});
      expect(AchievementRules.monthUp(stats, wednesday), isFalse);
    });

    test('uses the real length of the previous month (February)', () {
      // Февраль 2027: 28 дней, 14 запусков = 0,5/день; март: 8 за 15 дней ≈ 0,53.
      final stats = _stats({
        DateTime(2027, 2, 3): 14,
        DateTime(2027, 3, 4): 8,
      });
      expect(AchievementRules.monthUp(stats, DateTime(2027, 3, 15)), isTrue);
    });
  });

  group('period keys', () {
    test('week key is the Monday, also across the new year', () {
      expect(AchievementRules.weekKey(wednesday), 'week-2026-10-19');
      expect(
          AchievementRules.weekKey(DateTime(2026, 10, 19)), 'week-2026-10-19');
      expect(
          AchievementRules.weekKey(DateTime(2026, 10, 25)), 'week-2026-10-19');
      // 1 января 2027 — пятница; понедельник — 28 декабря 2026.
      expect(AchievementRules.weekKey(DateTime(2027, 1, 1)), 'week-2026-12-28');
    });

    test('day and month keys', () {
      expect(AchievementRules.dayKey(wednesday), '2026-10-21');
      expect(AchievementRules.monthKey(wednesday), 'month-2026-10');
    });
  });
}
