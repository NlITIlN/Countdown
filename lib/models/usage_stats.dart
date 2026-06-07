import 'day_usage.dart';

class UsageStats {
  const UsageStats({
    required this.totalCount,
    required this.days,
    required this.streakDays,
    required this.badgeKey,
  });

  final int totalCount;
  final List<DayUsage> days;
  final int streakDays;
  final String badgeKey;

  static const empty = UsageStats(
    totalCount: 0,
    days: [],
    streakDays: 0,
    badgeKey: 'none',
  );

  factory UsageStats.fromTimestamps(List<DateTime> events) {
    if (events.isEmpty) return UsageStats.empty;

    final byDay = <DateTime, int>{};
    for (final event in events) {
      final day = DateTime(event.year, event.month, event.day);
      byDay[day] = (byDay[day] ?? 0) + 1;
    }

    final days = byDay.entries
        .map((e) => DayUsage(date: e.key, count: e.value))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return UsageStats(
      totalCount: events.length,
      days: days,
      streakDays: _streakDays(byDay.keys.toList()..sort()),
      badgeKey: _badgeFor(events.length),
    );
  }

  static int _streakDays(List<DateTime> sortedDays) {
    if (sortedDays.isEmpty) return 0;

    final today = _today();
    final latest = sortedDays.last;
    final gap = today.difference(latest).inDays;
    if (gap > 1) return 0;

    var streak = 1;
    for (var i = sortedDays.length - 2; i >= 0; i--) {
      final diff = sortedDays[i + 1].difference(sortedDays[i]).inDays;
      if (diff == 1) {
        streak++;
      } else if (diff > 1) {
        break;
      }
    }
    return streak;
  }

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static String _badgeFor(int total) {
    if (total >= 100) return 'legend';
    if (total >= 50) return 'master';
    if (total >= 25) return 'regular';
    if (total >= 10) return 'rhythm';
    if (total >= 1) return 'starter';
    return 'none';
  }

  /// Получить количество сеансов сегодня
  int getTodayCount() {
    if (days.isEmpty) return 0;
    final today = _today();
    return days.firstWhere(
      (d) => d.date.compareTo(today) == 0,
      orElse: () => DayUsage(date: DateTime.fromMillisecondsSinceEpoch(0), count: 0),
    ).count;
  }

  /// Получить количество сеансов вчера
  int getYesterdayCount() {
    if (days.isEmpty) return 0;
    final yesterday = _today().subtract(const Duration(days: 1));
    return days.firstWhere(
      (d) => d.date.compareTo(yesterday) == 0,
      orElse: () => DayUsage(date: DateTime.fromMillisecondsSinceEpoch(0), count: 0),
    ).count;

  }

  /// Получить максимальное количество сеансов в любой день
  int getMaxDayCount() {
    if (days.isEmpty) return 0;
    return days.map((d) => d.count).reduce((a, b) => a > b ? a : b);
  }

}
