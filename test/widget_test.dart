import 'package:countdown/l10n/strings.dart';
import 'package:countdown/screens/home_screen.dart';
import 'package:countdown/services/notification_prefs.dart';
import 'package:countdown/services/notification_service.dart';
import 'package:countdown/services/timer_prefs.dart';
import 'package:countdown/services/usage_store.dart';
import 'package:countdown/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:countdown/widgets/expandable_corner_menu.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows timer circle', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final notifications = NotificationService();

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          strings: const S(AppLocale.ru),
          usageStore: UsageStore(prefs),
          timerPrefs: TimerPrefs(prefs),
          notificationPrefs: NotificationPrefs(prefs),
          notifications: notifications,
          onLocaleChanged: (_) {},
          themeMode: AppThemeMode.dark,
          onThemeChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('05:00'), findsOneWidget);
    expect(find.byType(ExpandableCornerMenu), findsOneWidget);
  });
}
