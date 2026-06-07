import 'package:countdown/services/notification_prefs.dart';
import 'package:countdown/services/timer_prefs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('timer prefs clamp minutes to 1..5 and persists values', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final timerPrefs = TimerPrefs(prefs);

    await timerPrefs.saveMinutes(45);
    expect(timerPrefs.loadMinutes(), 5);

    await timerPrefs.saveMinutes(0);
    expect(timerPrefs.loadMinutes(), 1);

    await timerPrefs.saveMinutes(3);
    expect(timerPrefs.loadMinutes(), 3);
  });

  test('notification prefs persist sound and vibration settings', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final notificationPrefs = NotificationPrefs(prefs);

    expect(notificationPrefs.soundEnabled(), isTrue);
    expect(notificationPrefs.vibrationEnabled(), isTrue);

    await notificationPrefs.saveSoundEnabled(false);
    await notificationPrefs.saveVibrationEnabled(false);

    expect(notificationPrefs.soundEnabled(), isFalse);
    expect(notificationPrefs.vibrationEnabled(), isFalse);
  });
}
