import 'package:countdown/models/usage_stats.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
