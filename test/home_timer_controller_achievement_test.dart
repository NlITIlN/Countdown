import 'package:countdown/models/day_usage.dart';
import 'package:countdown/models/usage_stats.dart';
import 'package:countdown/screens/home_timer_controller.dart';
import 'package:countdown/services/notification_prefs.dart';
import 'package:countdown/services/notification_service.dart';
import 'package:countdown/services/timer_prefs.dart';
import 'package:countdown/services/usage_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestNotificationService extends NotificationService {
  final List<Map<String, String>> achievements = [];
  final List<int> badges = [];
  int permissionRequests = 0;
  int scheduled = 0;
  int cancelled = 0;
  int doneShown = 0;

  @override
  Future<void> requestPermission() async {
    permissionRequests++;
  }

  @override
  Future<void> cancelSteps() async {
    cancelled++;
  }

  @override
  Future<void> scheduleSteps(
      {required DateTime endsAt,
      required int totalSeconds,
      required bool isRu,
      bool playSound = true,
      bool vibrate = true}) async {
    scheduled++;
  }

  @override
  Future<void> showDone(
      {required bool isRu, bool playSound = true, bool vibrate = true}) async {
    doneShown++;
  }

  @override
  Future<void> showBadge(
      {required int count,
      required bool isRu,
      bool playSound = true,
      bool vibrate = true}) async {
    badges.add(count);
  }

  @override
  Future<void> showAchievement(
      {required String title,
      required String body,
      bool playSound = true,
      bool vibrate = true}) async {
    achievements.add({'title': title, 'body': body});
  }
}

/// Отдаёт [before] до записи завершения и [after] — после.
class TestUsageStore extends UsageStore {
  TestUsageStore(super.prefs, {required this.before, required this.after});

  final UsageStats before;
  final UsageStats after;
  int recorded = 0;

  @override
  Future<UsageStats> loadStats() async => recorded > 0 ? after : before;

  @override
  Future<void> recordCompletion() async {
    // Пауза, чтобы два параллельных завершения успели пересечься.
    await Future<void>.delayed(const Duration(milliseconds: 10));
    recorded++;
  }
}

DateTime _day(int daysAgo) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day - daysAgo);
}

UsageStats _stats(Map<int, int> countsByDaysAgo, {int streak = 1}) {
  final days = countsByDaysAgo.entries
      .map((e) => DayUsage(date: _day(e.key), count: e.value))
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));
  return UsageStats(
    totalCount: countsByDaysAgo.values.fold(0, (a, b) => a + b),
    days: days,
    streakDays: streak,
    badgeKey: 'starter',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late TestNotificationService notifications;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    notifications = TestNotificationService();
  });

  HomeTimerController controllerFor(TestUsageStore usage) =>
      HomeTimerController(
        timerPrefs: TimerPrefs(prefs),
        usageStore: usage,
        notifications: notifications,
        notificationPrefs: NotificationPrefs(prefs),
        localeIsRu: () => false,
        completionHold: const Duration(milliseconds: 20),
      );

  test('record achievement shown once per day', () async {
    final usage = TestUsageStore(
      prefs,
      before: _stats({0: 2, 1: 2}, streak: 2),
      after: _stats({0: 3, 1: 2}, streak: 2),
    );
    final controller = controllerFor(usage);

    await controller.handleCompletion(notify: true);
    expect(notifications.achievements, hasLength(1));
    expect(notifications.achievements.first['title'], contains('New record'));

    // Повторный рекорд в тот же день не показывается.
    await controller.handleCompletion(notify: true);
    expect(notifications.achievements, hasLength(1));
    controller.dispose();
  });

  test('first ever session is not a record', () async {
    final usage = TestUsageStore(
      prefs,
      before: UsageStats.empty,
      after: _stats({0: 1}),
    );
    final controller = controllerFor(usage);

    await controller.handleCompletion(notify: true);
    expect(notifications.achievements, isEmpty);
    controller.dispose();
  });

  test('streak of 3+ days is announced when it grows', () async {
    final usage = TestUsageStore(
      prefs,
      before: _stats({1: 1, 2: 1}, streak: 2),
      after: _stats({0: 1, 1: 1, 2: 1}, streak: 3),
    );
    final controller = controllerFor(usage);

    await controller.handleCompletion(notify: true);
    expect(notifications.achievements, hasLength(1));
    expect(notifications.achievements.first['title'], contains('Streak'));
    controller.dispose();
  });

  test('comeback after 3+ day break', () async {
    final usage = TestUsageStore(
      prefs,
      before: _stats({5: 1}),
      after: _stats({0: 1, 5: 1}),
    );
    final controller = controllerFor(usage);

    await controller.handleCompletion(notify: true);
    expect(notifications.achievements, hasLength(1));
    expect(notifications.achievements.first['title'], contains('Welcome back'));
    controller.dispose();
  });

  test('badge takes priority over achievement', () async {
    final before = _stats({0: 4, 1: 5});
    final after = UsageStats(
      totalCount: 10,
      days: [
        DayUsage(date: _day(0), count: 6),
        DayUsage(date: _day(1), count: 4)
      ],
      streakDays: 2,
      badgeKey: 'rhythm',
    );
    final usage = TestUsageStore(prefs, before: before, after: after);
    final controller = controllerFor(usage);

    await controller.handleCompletion(notify: true);
    expect(notifications.badges, [10]);
    expect(notifications.achievements, isEmpty);
    controller.dispose();
  });

  test('concurrent completions are recorded once', () async {
    final usage = TestUsageStore(
      prefs,
      before: UsageStats.empty,
      after: _stats({0: 1}),
    );
    final controller = controllerFor(usage);

    await Future.wait([
      controller.handleCompletion(notify: false),
      controller.handleCompletion(notify: false),
    ]);
    expect(usage.recorded, 1);
    controller.dispose();
  });

  test('completed state returns to idle, but not over a new run', () async {
    final usage = TestUsageStore(
      prefs,
      before: UsageStats.empty,
      after: _stats({0: 1}),
    );
    final controller = controllerFor(usage);

    await controller.handleCompletion(notify: false);
    expect(controller.currentState, TimerState.completed);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(controller.currentState, TimerState.idle);

    await controller.handleCompletion(notify: false);
    await controller.start();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(controller.currentState, TimerState.running);
    controller.dispose();
  });

  test('notification permission is requested only on the first start',
      () async {
    final usage = TestUsageStore(
      prefs,
      before: UsageStats.empty,
      after: UsageStats.empty,
    );
    final controller = controllerFor(usage);

    await controller.start();
    await controller.reset();
    await controller.start();
    expect(notifications.permissionRequests, 1);
    controller.dispose();
  });

  test('notifications switched off: no permission, nothing scheduled or shown',
      () async {
    await NotificationPrefs(prefs).saveNotificationsEnabled(false);
    final usage = TestUsageStore(
      prefs,
      before: _stats({0: 2, 1: 2}, streak: 2),
      after: _stats({0: 3, 1: 2}, streak: 2),
    );
    final controller = controllerFor(usage);

    await controller.start();
    expect(notifications.permissionRequests, 0);
    expect(notifications.scheduled, 0);

    await controller.handleCompletion(notify: true);
    expect(notifications.doneShown, 0);
    expect(notifications.achievements, isEmpty);
    expect(usage.recorded, 1, reason: 'statistics still counts');
    controller.dispose();
  });

  test('toggling notifications during a run cancels and reschedules', () async {
    await NotificationPrefs(prefs).saveNotificationsEnabled(false);
    final controller = controllerFor(TestUsageStore(
      prefs,
      before: UsageStats.empty,
      after: UsageStats.empty,
    ));
    await controller.start();

    await controller.setNotificationsEnabled(true);
    expect(notifications.permissionRequests, 1);
    expect(notifications.scheduled, 1);

    final cancelledBefore = notifications.cancelled;
    await controller.setNotificationsEnabled(false);
    expect(notifications.cancelled, cancelledBefore + 1);
    controller.dispose();
  });
}
