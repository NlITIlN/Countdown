import 'package:countdown/models/day_usage.dart';
import 'package:countdown/models/usage_stats.dart';
import 'package:countdown/screens/home_timer_controller.dart';
import 'package:countdown/services/notification_prefs.dart';
import 'package:countdown/services/notification_service.dart';
import 'package:countdown/services/timer_prefs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:countdown/services/usage_store.dart';

class TestNotificationService extends NotificationService {
  final List<Map<String, String>> achievements = [];

  @override
  Future<void> cancelSteps() async {}

  @override
  Future<void> scheduleSteps({required DateTime endsAt, required int totalSeconds, required bool isRu, bool playSound = true, bool vibrate = true}) async {}

  @override
  Future<void> showDone({required bool isRu, bool playSound = true, bool vibrate = true}) async {}

  @override
  Future<void> showBadge({required int count, required bool isRu, bool playSound = true, bool vibrate = true}) async {}

  @override
  Future<void> showAchievement({required String title, required String body, bool playSound = true, bool vibrate = true}) async {
    achievements.add({'title': title, 'body': body});
  }
}

class TestUsageStore extends UsageStore {
  UsageStats before;
  UsageStats after;
  bool _recorded = false;

  TestUsageStore(SharedPreferences prefs, {required this.before, required this.after}) : super(prefs);

  @override
  Future<UsageStats> loadStats() async {
    return _recorded ? after : before;
  }

  @override
  Future<void> recordCompletion() async {
    _recorded = true;
  }
}

// We'll use real TimerPrefs backed by mocked SharedPreferences in tests.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('shows record achievement and dedupes', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final notifPrefs = NotificationPrefs(prefs);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final before = UsageStats(
      totalCount: 5,
      days: [DayUsage(date: today, count: 1)],
      streakDays: 1,
      badgeKey: 'starter',
    );

    final after = UsageStats(
      totalCount: 6,
      days: [DayUsage(date: today, count: 3)],
      streakDays: 1,
      badgeKey: 'starter',
    );

    final usage = TestUsageStore(prefs, before: before, after: after);
    final notifications = TestNotificationService();
    final timerPrefs = TimerPrefs(prefs);

    final controller = HomeTimerController(
      timerPrefs: timerPrefs,
      usageStore: usage as dynamic,
      notifications: notifications,
      notificationPrefs: notifPrefs,
      localeIsRu: () => false,
    );

    // Call handleCompletion which should record completion and show achievement
    await controller.handleCompletion(notify: true);

    expect(notifications.achievements, isNotEmpty);
    final first = notifications.achievements.first['title']!;
    expect(first.contains('New record'), isTrue);

    // Call again; dedupe should prevent duplicate achievement
    await controller.handleCompletion(notify: true);
    expect(notifications.achievements.length, equals(1));
  });
}
