import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/strings.dart';
import 'screens/home_screen.dart';
import 'services/notification_prefs.dart';
import 'services/notification_service.dart';
import 'services/theme_prefs.dart';
import 'services/timer_prefs.dart';
import 'services/usage_store.dart';
import 'theme_manager.dart';

const _localeKey = 'locale';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Color(0xFF050505),
    ),
  );

  final prefs = await SharedPreferences.getInstance();
  final localeCode = prefs.getString(_localeKey);
  final initialLocale = localeCode == 'en' ? AppLocale.en : AppLocale.ru;
  final themePrefs = ThemePrefs(prefs);
  final initialTheme = themePrefs.loadTheme();

  final notifications = NotificationService();
  await notifications.init();
  await notifications.requestPermission();

  runApp(
    CountdownApp(
      initialLocale: initialLocale,
      initialTheme: initialTheme,
      prefs: prefs,
      usageStore: UsageStore(prefs),
      timerPrefs: TimerPrefs(prefs),
      themePrefs: themePrefs,
      notificationPrefs: NotificationPrefs(prefs),
      notifications: notifications,
    ),
  );
}

class CountdownApp extends StatefulWidget {
  const CountdownApp({
    super.key,
    required this.initialLocale,
    required this.initialTheme,
    required this.prefs,
    required this.usageStore,
    required this.timerPrefs,
    required this.themePrefs,
    required this.notificationPrefs,
    required this.notifications,
  });

  final AppLocale initialLocale;
  final AppThemeMode initialTheme;
  final SharedPreferences prefs;
  final UsageStore usageStore;
  final TimerPrefs timerPrefs;
  final ThemePrefs themePrefs;
  final NotificationPrefs notificationPrefs;
  final NotificationService notifications;

  @override
  State<CountdownApp> createState() => _CountdownAppState();
}

class _CountdownAppState extends State<CountdownApp> {
  late AppLocale _locale = widget.initialLocale;
  late AppThemeMode _theme = widget.initialTheme;

  Future<void> _setLocale(AppLocale locale) async {
    setState(() => _locale = locale);
    await widget.prefs.setString(
      _localeKey,
      locale == AppLocale.en ? 'en' : 'ru',
    );
  }

  Future<void> _setTheme(AppThemeMode theme) async {
    setState(() => _theme = theme);
    await widget.themePrefs.saveTheme(theme);
  }

  @override
  Widget build(BuildContext context) {
    final strings = S(_locale);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Countdown',
      theme: buildAppTheme(_theme),
      home: HomeScreen(
        strings: strings,
        usageStore: widget.usageStore,
        timerPrefs: widget.timerPrefs,
        notificationPrefs: widget.notificationPrefs,
        notifications: widget.notifications,
        onLocaleChanged: _setLocale,
        themeMode: _theme,
        onThemeChanged: _setTheme,
      ),
    );
  }
}
