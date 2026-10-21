import 'usage_stats.dart';

/// Правила недельных и месячных достижений (ROADMAP Ф7) и ключи периодов
/// для дедупликации. Чистые функции с явным [now] — легко тестировать.
class AchievementRules {
  const AchievementRules._();

  /// «Сильная неделя»: за текущую неделю (с понедельника по сегодня) запусков
  /// больше, чем медиана четырёх предыдущих недель. Медиана должна быть > 0 —
  /// без истории награды нет. Возвращает число запусков за неделю или null.
  static int? strongWeek(UsageStats stats, DateTime now) {
    final monday = weekStart(now);
    final thisWeek = _countBetween(stats, monday, _nextDay(now));
    final previous = [
      for (var k = 1; k <= 4; k++)
        _countBetween(
          stats,
          DateTime(monday.year, monday.month, monday.day - 7 * k),
          DateTime(monday.year, monday.month, monday.day - 7 * (k - 1)),
        ),
    ]..sort();
    final median = (previous[1] + previous[2]) / 2;
    return median > 0 && thisWeek > median ? thisWeek : null;
  }

  /// «Месяц идёт вверх»: начиная с 15-го числа, в среднем запусков в день
  /// в этом месяце больше, чем в прошлом (прошлый месяц должен быть активен).
  static bool monthUp(UsageStats stats, DateTime now) {
    if (now.day < 15) return false;
    final monthStart = DateTime(now.year, now.month, 1);
    final prevStart = DateTime(now.year, now.month - 1, 1);
    final prevCount = _countBetween(stats, prevStart, monthStart);
    if (prevCount == 0) return false;
    final thisCount = _countBetween(stats, monthStart, _nextDay(now));
    // День 0 текущего месяца — последний день прошлого.
    final prevDays = DateTime(now.year, now.month, 0).day;
    return thisCount / now.day > prevCount / prevDays;
  }

  /// Понедельник недели, в которую попадает [d].
  static DateTime weekStart(DateTime d) =>
      DateTime(d.year, d.month, d.day - (d.weekday - DateTime.monday));

  static String dayKey(DateTime d) =>
      '${d.year}-${_two(d.month)}-${_two(d.day)}';

  static String weekKey(DateTime now) => 'week-${dayKey(weekStart(now))}';

  static String monthKey(DateTime now) =>
      'month-${now.year}-${_two(now.month)}';

  static DateTime _nextDay(DateTime d) => DateTime(d.year, d.month, d.day + 1);

  /// Сумма запусков за дни в полуинтервале [from, to).
  static int _countBetween(UsageStats stats, DateTime from, DateTime to) =>
      stats.days
          .where((d) => !d.date.isBefore(from) && d.date.isBefore(to))
          .fold(0, (sum, d) => sum + d.count);

  static String _two(int v) => v.toString().padLeft(2, '0');
}
