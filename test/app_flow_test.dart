import 'package:countdown/l10n/strings.dart';
import 'package:countdown/main.dart';
import 'package:countdown/services/notification_prefs.dart';
import 'package:countdown/services/notification_service.dart';
import 'package:countdown/services/theme_prefs.dart';
import 'package:countdown/services/timer_prefs.dart';
import 'package:countdown/services/usage_store.dart';
import 'package:countdown/theme_manager.dart';
import 'package:countdown/ui/rings_timer_button.dart';
import 'package:countdown/widgets/control_panel.dart';
import 'package:countdown/widgets/expandable_corner_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ф10: ключевые сценарии через настоящий интерфейс.

class _SilentNotifications extends NotificationService {
  @override
  Future<void> init() async {}

  @override
  Future<void> requestPermission() async {}

  @override
  Future<void> scheduleSteps(
      {required DateTime endsAt,
      required int totalSeconds,
      required bool isRu,
      bool playSound = true,
      bool vibrate = true}) async {}

  @override
  Future<void> cancelSteps() async {}

  @override
  Future<void> deliverDone(
      {required bool isRu, bool playSound = true, bool vibrate = true}) async {}
}

Future<SharedPreferences> _pumpApp(
  WidgetTester tester, {
  Map<String, Object> prefsValues = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefsValues);
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
      notifications: _SilentNotifications(),
    ),
  );
  await tester.pumpAndSettle();
  return prefs;
}

/// Кнопка «⋯» прижата к правому краю меню.
Future<void> _openMenu(WidgetTester tester) async {
  final menu = find.byType(ExpandableCornerMenu);
  final size = tester.widget<ExpandableCornerMenu>(menu).size;
  await tester.tapAt(tester.getRect(menu).centerRight - Offset(size / 2, 0));
  await tester.pumpAndSettle();
}

Future<void> _openSettings(WidgetTester tester) async {
  await _openMenu(tester);
  await tester.tap(find.byIcon(Icons.settings_outlined));
  await tester.pumpAndSettle();
}

Future<void> _openSettingsTab(WidgetTester tester) async {
  await _openSettings(tester);
  await tester.tap(find.byType(Tab).last);
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

String? _ringHint(WidgetTester tester) =>
    tester.getSemantics(find.byType(RingsTimerButton)).hint;

void main() {
  testWidgets('tap on the ring starts the timer, second tap resets it',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await _pumpApp(tester);
    const s = S(AppLocale.ru);

    expect(find.text('05:00'), findsOneWidget);
    expect(_ringHint(tester), s.startTimerHint);

    await tester.tap(find.byType(RingsTimerButton));
    await tester.pump(const Duration(milliseconds: 600));
    expect(_ringHint(tester), s.resetTimerHint);

    await tester.tap(find.byType(RingsTimerButton));
    await tester.pump(const Duration(milliseconds: 600));
    expect(_ringHint(tester), s.startTimerHint);
    expect(find.text('05:00'), findsOneWidget);

    semantics.dispose();
  });

  testWidgets('duration changed in settings shows on the main screen',
      (tester) async {
    final prefs = await _pumpApp(tester);
    await _openSettings(tester);

    await tester.tap(find.byIcon(Icons.remove));
    await tester.pumpAndSettle();
    expect(find.text('4 мин 50 сек'), findsOneWidget);

    await _tapVisible(tester, find.text(const S(AppLocale.ru).apply));
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('04:50'), findsOneWidget);
    expect(TimerPrefs(prefs).loadSeconds(), 290);
  });

  testWidgets('language and theme switch apply immediately', (tester) async {
    await _pumpApp(tester);
    await _openSettingsTab(tester);

    await _tapVisible(tester, find.text('English'));
    // Вкладки переключились на английский.
    expect(find.text('timer'), findsOneWidget);

    await _tapVisible(tester, find.text(const S(AppLocale.en).themeLight));
    final theme = Theme.of(tester.element(find.byType(ControlPanel)));
    expect(theme.brightness, Brightness.light);
  });

  testWidgets('clear statistics asks first and then deletes the history',
      (tester) async {
    final prefs = await _pumpApp(tester, prefsValues: {
      'usage_events': '["2026-10-20T10:00:00.000","2026-10-21T10:00:00.000"]',
    });
    const s = S(AppLocale.ru);
    await _openSettingsTab(tester);

    // «Отмена» ничего не трогает.
    await _tapVisible(tester, find.text(s.clearStats));
    await tester.tap(find.text(s.cancel));
    await tester.pumpAndSettle();
    expect((await UsageStore(prefs).loadStats()).totalCount, 2);

    // «Удалить» стирает историю.
    await _tapVisible(tester, find.text(s.clearStats));
    await tester.tap(find.text(s.delete));
    await tester.pumpAndSettle();
    expect(find.text(s.statsCleared), findsOneWidget);
    expect((await UsageStore(prefs).loadStats()).totalCount, 0);
  });
}
