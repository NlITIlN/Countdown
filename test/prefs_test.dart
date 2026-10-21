import 'package:countdown/l10n/strings.dart';
import 'package:countdown/services/notification_prefs.dart';
import 'package:countdown/services/timer_prefs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('timer duration: 10 s .. 5 min, 10 s step, persisted', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final timerPrefs = TimerPrefs(prefs);

    expect(timerPrefs.loadSeconds(), 300, reason: 'default 5 min');

    await timerPrefs.saveSeconds(45 * 60);
    expect(timerPrefs.loadSeconds(), 300);

    await timerPrefs.saveSeconds(0);
    expect(timerPrefs.loadSeconds(), 10);

    await timerPrefs.saveSeconds(94);
    expect(timerPrefs.loadSeconds(), 90, reason: 'rounded to 10 s step');

    await timerPrefs.saveSeconds(150);
    expect(timerPrefs.loadSeconds(), 150);
  });

  test('timer duration migrates from the old minutes setting', () async {
    SharedPreferences.setMockInitialValues({'timer_minutes': 3});
    final timerPrefs = TimerPrefs(await SharedPreferences.getInstance());

    expect(timerPrefs.loadSeconds(), 180);
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

  test('duration label', () {
    const ru = S(AppLocale.ru);
    const en = S(AppLocale.en);
    expect(ru.durationLabel(40), '40 сек');
    expect(ru.durationLabel(180), '3 мин');
    expect(ru.durationLabel(90), '1 мин 30 сек');
    expect(en.durationLabel(90), '1 min 30 sec');
  });
}
