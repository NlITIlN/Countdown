import 'package:countdown/screens/home_timer_controller.dart';
import 'package:countdown/services/notification_prefs.dart';
import 'package:countdown/services/notification_service.dart';
import 'package:countdown/services/timer_prefs.dart';
import 'package:countdown/services/usage_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SilentNotifications extends NotificationService {
  @override
  Future<void> cancelSteps() async {}

  @override
  Future<void> scheduleSteps(
      {required DateTime endsAt,
      required int totalSeconds,
      required bool isRu,
      bool playSound = true,
      bool vibrate = true}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('total count keeps growing past the stored events limit', () async {
    final events = List.generate(
      500,
      (i) => DateTime(2026, 1, 1).add(Duration(minutes: i)).toIso8601String(),
    );
    SharedPreferences.setMockInitialValues({
      'usage_events': '["${events.join('","')}"]',
    });
    final store = UsageStore(await SharedPreferences.getInstance());

    expect((await store.loadStats()).totalCount, 500);
    await store.recordCompletion();
    expect((await store.loadStats()).totalCount, 501);
  });

  test('clear removes history and the all-time counter', () async {
    SharedPreferences.setMockInitialValues({});
    final store = UsageStore(await SharedPreferences.getInstance());
    await store.recordCompletion();
    await store.recordCompletion();
    expect((await store.loadStats()).totalCount, 2);

    await store.clear();
    final stats = await store.loadStats();
    expect(stats.totalCount, 0);
    expect(stats.days, isEmpty);

    // Новый отсчёт после очистки — с нуля.
    await store.recordCompletion();
    expect((await store.loadStats()).totalCount, 1);
  });

  test('corrupted usage data does not crash and starts fresh', () async {
    SharedPreferences.setMockInitialValues({'usage_events': '{not json'});
    final store = UsageStore(await SharedPreferences.getInstance());

    expect((await store.loadStats()).totalCount, 0);
    await store.recordCompletion();
    expect((await store.loadStats()).totalCount, 1);
  });

  Future<HomeTimerController> restoreWithSecondsLeft(int seconds) async {
    SharedPreferences.setMockInitialValues({
      'timer_ends_at_iso':
          DateTime.now().add(Duration(seconds: seconds)).toIso8601String(),
    });
    final prefs = await SharedPreferences.getInstance();
    final controller = HomeTimerController(
      timerPrefs: TimerPrefs(prefs),
      usageStore: UsageStore(prefs),
      notifications: _SilentNotifications(),
      notificationPrefs: NotificationPrefs(prefs),
      localeIsRu: () => true,
    );
    await controller.bootstrap();
    return controller;
  }

  test('restored timer immediately reports running state', () async {
    final controller = await restoreWithSecondsLeft(60);
    expect(controller.running, isTrue);
    expect(controller.currentState, TimerState.running);
    controller.dispose();
  });

  test('restored timer in last seconds reports critical state', () async {
    final controller = await restoreWithSecondsLeft(5);
    expect(controller.currentState, TimerState.critical);
    controller.dispose();
  });
}
