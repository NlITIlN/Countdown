import 'package:countdown/l10n/strings.dart';
import 'package:countdown/main.dart';
import 'package:countdown/services/notification_prefs.dart';
import 'package:countdown/services/notification_service.dart';
import 'package:countdown/services/theme_prefs.dart';
import 'package:countdown/services/timer_prefs.dart';
import 'package:countdown/services/usage_store.dart';
import 'package:countdown/theme_manager.dart';
import 'package:countdown/ui/rings_timer_button.dart';
import 'package:countdown/widgets/expandable_corner_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Замер производительности (ROADMAP О1 / О8).
///
/// Запуск:
///   flutter drive --profile -d windows --driver=test_driver/perf_driver.dart --target=integration_test/perf_test.dart
///
/// Результат: build/perf.timeline_summary.json
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Реальные кадры движка, а не виртуальное время теста.
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('countdown scenario performance', (tester) async {
    // Изолированные настройки: замер не трогает реальные данные приложения.
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      CountdownApp(
        initialLocale: AppLocale.ru,
        initialTheme: AppThemeMode.dark,
        prefs: prefs,
        usageStore: UsageStore(prefs),
        timerPrefs: TimerPrefs(prefs),
        themePrefs: ThemePrefs(prefs),
        notificationPrefs: NotificationPrefs(prefs),
        notifications: NotificationService(),
      ),
    );
    await _wait(tester, 2);

    await binding.traceAction(
      () async {
        // 1. Покой.
        await _wait(tester, 2);

        // 2. Отсчёт.
        await tester.tap(find.byType(RingsTimerButton));
        await _wait(tester, 12);

        // 3. Меню → статистика → назад.
        await _openMenu(tester);
        await _wait(tester, 1);
        await tester.tap(find.byIcon(Icons.bar_chart));
        await _wait(tester, 2);
        await tester.pageBack();
        await _wait(tester, 1);

        // 4. Меню → настройки → вкладки → назад.
        await _openMenu(tester);
        await _wait(tester, 1);
        await tester.tap(find.byIcon(Icons.settings_outlined));
        await _wait(tester, 2);
        await tester.tap(find.byType(Tab).last);
        await _wait(tester, 1);
        await tester.tap(find.byType(Tab).first);
        await _wait(tester, 1);
        await tester.pageBack();
        await _wait(tester, 1);

        // 5. Сброс таймера.
        await tester.tap(find.byType(RingsTimerButton));
        await _wait(tester, 2);
      },
      reportKey: 'timeline',
    );
  });
}

/// Кнопка «⋯» прижата к правому краю меню — тапаем именно в неё.
Future<void> _openMenu(WidgetTester tester) async {
  final menu = find.byType(ExpandableCornerMenu);
  final size = tester.widget<ExpandableCornerMenu>(menu).size;
  await tester.tapAt(tester.getRect(menu).centerRight - Offset(size / 2, 0));
}

/// В режиме fullyLive кадры идут сами — просто ждём реальное время.
Future<void> _wait(WidgetTester tester, int seconds) async {
  await tester.pump();
  await Future<void>.delayed(Duration(seconds: seconds));
}
