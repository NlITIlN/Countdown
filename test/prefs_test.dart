import 'package:countdown/l10n/strings.dart';
import 'package:countdown/l10n/strings_formatters.dart';
import 'package:countdown/services/notification_prefs.dart';
import 'package:countdown/services/timer_prefs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
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

  test('dates are localized; the year is shown only for past years', () async {
    await initializeDateFormatting('ru');
    await initializeDateFormatting('en');
    const ru = S(AppLocale.ru);
    const en = S(AppLocale.en);
    final now = DateTime(2026, 10, 21);

    expect(ru.formatDay(DateTime(2026, 10, 21), now: now), '21 окт.');
    expect(en.formatDay(DateTime(2026, 10, 21), now: now), 'Oct 21');
    // intl ставит узкий неразрывный пробел (U+202F) перед «г.» — так «г.» не отрывается от года.
    expect(ru.formatDay(DateTime(2025, 3, 5), now: now).replaceAll(' ', ' '),
        '5 мар. 2025 г.');
    expect(en.formatDay(DateTime(2025, 3, 5), now: now), 'Mar 5, 2025');
  });
}
