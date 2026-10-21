import 'package:countdown/models/usage_stats.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime _daysAgo(int days, {int hour = 12}) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day - days, hour);
}

void main() {
  test('groups events by day and counts total', () {
    final stats = UsageStats.fromTimestamps([
      DateTime(2026, 5, 16, 10),
      DateTime(2026, 5, 16, 18),
      DateTime(2026, 5, 15, 9),
    ]);

    expect(stats.totalCount, 3);
    expect(stats.days.length, 2);
    expect(stats.days.first.date, DateTime(2026, 5, 16));
    expect(stats.days.first.count, 2);
    expect(stats.badgeKey, 'starter');
  });

  test('streak counts consecutive days ending today', () {
    final stats = UsageStats.fromTimestamps([
      _daysAgo(0),
      _daysAgo(0, hour: 18),
      _daysAgo(1),
      _daysAgo(2),
      _daysAgo(5),
    ]);
    expect(stats.streakDays, 3);
  });

  test('streak still counts if the last session was yesterday', () {
    final stats = UsageStats.fromTimestamps([_daysAgo(1), _daysAgo(2)]);
    expect(stats.streakDays, 2);
  });

  test('streak is broken after a missed day', () {
    final stats = UsageStats.fromTimestamps([_daysAgo(2), _daysAgo(3)]);
    expect(stats.streakDays, 0);
  });

  test('all-time total overrides event count and drives the badge', () {
    final stats = UsageStats.fromTimestamps([_daysAgo(0)], totalCount: 120);
    expect(stats.totalCount, 120);
    expect(stats.badgeKey, 'legend');
  });
}
