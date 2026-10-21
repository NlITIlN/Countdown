import 'package:countdown/models/usage_stats.dart';
import 'package:countdown/screens/home_timer_controller.dart';
import 'package:countdown/services/notification_prefs.dart';
import 'package:countdown/services/notification_service.dart';
import 'package:countdown/services/screen_awake.dart';
import 'package:countdown/services/timer_prefs.dart';
import 'package:countdown/services/usage_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeScreenAwake extends ScreenAwake {
  bool on = false;

  @override
  Future<void> set(bool on) async => this.on = on;
}

class _SilentNotifications extends NotificationService {
  @override
  Future<void> requestPermission() async {}

  @override
  Future<void> cancelSteps() async {}

  @override
  Future<void> scheduleSteps(
      {required DateTime endsAt,
      required int totalSeconds,
      required bool isRu,
      bool playSound = true,
      bool vibrate = true}) async {}

  @override
  Future<void> deliverDone(
      {required bool isRu, bool playSound = true, bool vibrate = true}) async {}
}

class _NoStatsStore extends UsageStore {
  _NoStatsStore(super.prefs);

  @override
  Future<UsageStats> loadStats() async => UsageStats.empty;

  @override
  Future<void> recordCompletion() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late _FakeScreenAwake screen;
  late HomeTimerController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    screen = _FakeScreenAwake();
    controller = HomeTimerController(
      timerPrefs: TimerPrefs(prefs),
      usageStore: _NoStatsStore(prefs),
      notifications: _SilentNotifications(),
      notificationPrefs: NotificationPrefs(prefs),
      localeIsRu: () => true,
      completionHold: Duration.zero,
      screenAwake: screen,
    );
  });

  tearDown(() => controller.dispose());

  test('screen stays on only while counting down', () async {
    await controller.start();
    expect(screen.on, isTrue);

    await controller.reset();
    expect(screen.on, isFalse);

    await controller.start();
    await controller.handleCompletion(notify: false);
    expect(screen.on, isFalse);
  });

  test('setting off keeps the normal screen timeout', () async {
    await controller.setKeepScreenOn(false);
    await controller.start();
    expect(screen.on, isFalse);

    // Включили во время отсчёта — сразу действует.
    await controller.setKeepScreenOn(true);
    expect(screen.on, isTrue);
  });
}
