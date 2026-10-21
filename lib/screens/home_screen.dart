import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../theme_manager.dart';
import '../screens/analytics_screen.dart';
import '../services/notification_prefs.dart';
import '../services/notification_service.dart';
import '../services/timer_prefs.dart';
import '../screens/home_timer_controller.dart';
import '../services/usage_store.dart';
import '../ui/rings_timer_button.dart';
import '../ui/layout.dart' show AppMetrics, ResponsiveShell;
import '../widgets/control_panel.dart';
import '../widgets/expandable_corner_menu.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.strings,
    required this.usageStore,
    required this.timerPrefs,
    required this.notificationPrefs,
    required this.notifications,
    required this.onLocaleChanged,
    required this.themeMode,
    required this.onThemeChanged,
  });

  final S strings;
  final UsageStore usageStore;
  final TimerPrefs timerPrefs;
  final NotificationPrefs notificationPrefs;
  final NotificationService notifications;
  final ValueChanged<AppLocale> onLocaleChanged;
  final AppThemeMode themeMode;
  final ValueChanged<AppThemeMode> onThemeChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late final HomeTimerController _timerController;

  S get s => widget.strings;

  /// Экран целиком перестраивается только при смене ready; тики таймера
  /// слушает одна кнопка с кольцами (см. ListenableBuilder в build).
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _timerController = HomeTimerController(
      timerPrefs: widget.timerPrefs,
      usageStore: widget.usageStore,
      notifications: widget.notifications,
      notificationPrefs: widget.notificationPrefs,
      localeIsRu: () => widget.strings.isRu,
    );
    _timerController.addListener(_onReadyChanged);
    WidgetsBinding.instance.addObserver(this);
    _timerController.bootstrap();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _timerController.syncFromClock();
    }
  }

  Future<void> _setDuration(int seconds) async {
    await _timerController.setDurationSeconds(seconds);
  }

  void _onCircleTap() {
    if (_timerController.running) {
      _timerController.reset();
    } else {
      _start();
    }
  }

  Future<void> _start() async {
    await _timerController.start();
  }

  void _onReadyChanged() {
    if (!mounted || _timerController.ready == _ready) return;
    setState(() => _ready = _timerController.ready);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timerController.removeListener(_onReadyChanged);
    _timerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, _) {
            final m = AppMetrics.of(context);

            return ResponsiveShell(
              child: Padding(
                padding: m.screenPadding,
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: ListenableBuilder(
                        listenable: _timerController,
                        builder: (context, _) => RingsTimerButton(
                          timeText: _timerController.timeText,
                          endsAt: _timerController.endsAt,
                          totalDuration: _timerController.totalDuration,
                          state: _timerController.currentState,
                          semanticsHint: _timerController.running
                              ? s.resetTimerHint
                              : s.startTimerHint,
                          onTap: _onCircleTap,
                          onLongPress: () {
                            // Long press placeholder for future gestures
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: ExpandableCornerMenu(
                        size: m.cornerButtonSize,
                        tooltip: s.openMenu,
                        analyticsLabel: s.analytics,
                        settingsLabel: s.settings,
                        onAnalytics: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (ctx) => Scaffold(
                                backgroundColor:
                                    Theme.of(context).scaffoldBackgroundColor,
                                appBar: AppBar(
                                  backgroundColor: Colors.transparent,
                                  elevation: 0,
                                  title: Text(s.analytics.toLowerCase()),
                                ),
                                body: SafeArea(
                                  child: AnalyticsScreen(
                                    strings: s,
                                    usageStore: widget.usageStore,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        onSettings: () async {
                          final seconds = _timerController.totalSeconds;
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (ctx) => Scaffold(
                                backgroundColor:
                                    Theme.of(context).scaffoldBackgroundColor,
                                appBar: AppBar(
                                  backgroundColor: Colors.transparent,
                                  elevation: 0,
                                  title: Text(s.settings.toLowerCase()),
                                ),
                                body: SafeArea(
                                  child: ControlPanel(
                                    strings: s,
                                    initialSeconds: seconds,
                                    running: _timerController.running,
                                    notificationPrefs: widget.notificationPrefs,
                                    onTimerApply: (value) async {
                                      if (value != seconds) {
                                        await _setDuration(value);
                                      }
                                    },
                                    onLocaleChanged: widget.onLocaleChanged,
                                    themeMode: widget.themeMode,
                                    onThemeChanged: widget.onThemeChanged,
                                    onNotificationsChanged: _timerController
                                        .setNotificationsEnabled,
                                    onReset: _timerController.running
                                        ? () async {
                                            await _timerController.reset();
                                          }
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
