import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../l10n/strings.dart';
import '../l10n/strings_plurals.dart';
import '../models/achievement_rules.dart';
import '../models/usage_stats.dart';
import '../services/notification_prefs.dart';
import '../services/notification_service.dart';
import '../services/screen_awake.dart';
import '../services/timer_prefs.dart';
import '../services/usage_store.dart';

enum TimerState { idle, running, critical, completed }

class HomeTimerController extends ChangeNotifier {
  HomeTimerController({
    required this.timerPrefs,
    required this.usageStore,
    required this.notifications,
    required this.notificationPrefs,
    required this.localeIsRu,
    this.completionHold = const Duration(seconds: 3),
    ScreenAwake? screenAwake,
  }) : screenAwake = screenAwake ?? ScreenAwake();

  final TimerPrefs timerPrefs;
  final UsageStore usageStore;
  final NotificationService notifications;
  final NotificationPrefs notificationPrefs;
  final bool Function() localeIsRu;
  final ScreenAwake screenAwake;

  /// Сколько держится состояние completed перед возвратом в idle.
  final Duration completionHold;

  /// Последние секунды, когда кольца пульсируют.
  static const _criticalSeconds = 10;

  int totalSeconds = TimerPrefs.defaultSeconds;
  int remainingSeconds = TimerPrefs.defaultSeconds;
  bool running = false;
  bool ready = false;
  TimerState currentState = TimerState.idle;

  Timer? _ticker;
  Timer? _idleTimer;

  /// Защита от повторного завершения (тикер и resume могут сработать одновременно).
  bool _completing = false;

  bool get canEdit => !running;

  /// Время окончания текущего отсчёта (null — таймер не идёт).
  /// По нему кнопка сама плавно считает прогресс на каждом кадре.
  DateTime? get endsAt => running ? timerPrefs.loadEndsAt() : null;

  Duration get totalDuration => Duration(seconds: totalSeconds);

  String get timeText {
    final seconds = remainingSeconds;
    final m = seconds ~/ 60;
    final sec = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  void _notifyUpdate() {
    if (!hasListeners) return;
    notifyListeners();
  }

  void _setState(TimerState state) {
    currentState = state;
    _notifyUpdate();
  }

  Future<void> bootstrap() async {
    final isRu = localeIsRu();
    try {
      final total = timerPrefs.loadSeconds();
      var remaining = total;
      var active = false;

      final endsAt = timerPrefs.loadEndsAt();
      if (endsAt != null) {
        final left = endsAt.difference(DateTime.now()).inSeconds;
        if (left > 0) {
          active = true;
          remaining = left;
        } else {
          await timerPrefs.clearEndsAt();
          final before = await usageStore.loadStats();
          await usageStore.recordCompletion();
          final after = await usageStore.loadStats();
          await _notifyMilestones(before, after, isRu);
        }
      }

      totalSeconds = total;
      remainingSeconds = active ? remaining : total;
      running = active;
      currentState = !active
          ? TimerState.idle
          : remaining < _criticalSeconds
              ? TimerState.critical
              : TimerState.running;
      ready = true;
      _notifyUpdate();
      _applyScreenAwake();

      if (active) {
        final restoredEndsAt = timerPrefs.loadEndsAt();
        if (restoredEndsAt != null) {
          await _scheduleDone(restoredEndsAt, total);
        }
        _startTicker();
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('bootstrap failed: $e\n$st');
      }
      totalSeconds = TimerPrefs.defaultSeconds;
      remainingSeconds = TimerPrefs.defaultSeconds;
      running = false;
      ready = true;
      _notifyUpdate();
    }
  }

  Future<void> setDurationSeconds(int seconds) async {
    if (!canEdit) return;
    final clamped = TimerPrefs.clampSeconds(seconds);
    await timerPrefs.saveSeconds(clamped);
    totalSeconds = clamped;
    remainingSeconds = clamped;
    _notifyUpdate();
  }

  Future<void> start() async {
    _idleTimer?.cancel();
    if (notificationPrefs.notificationsEnabled()) {
      await _ensurePermissionAsked();
    }
    final seconds = remainingSeconds.clamp(1, TimerPrefs.maxSeconds);
    final endsAt = DateTime.now().add(Duration(seconds: seconds));
    await timerPrefs.saveEndsAt(endsAt);

    await _scheduleDone(endsAt, seconds);

    running = true;
    _setState(TimerState.running);
    _applyScreenAwake();
    _startTicker();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker =
        Timer.periodic(const Duration(seconds: 1), (_) => syncFromClock());
  }

  Future<void> syncFromClock() async {
    final endsAt = timerPrefs.loadEndsAt();
    if (!running || _completing || endsAt == null) return;

    final left = endsAt.difference(DateTime.now()).inSeconds;
    if (left <= 0) {
      await handleCompletion(notify: true);
      return;
    }

    remainingSeconds = left;

    // Update state based on remaining time
    if (left < _criticalSeconds) {
      _setState(TimerState.critical);
    } else if (running) {
      _setState(TimerState.running);
    }
  }

  /// Главный выключатель уведомлений (настройки). Выключение отменяет
  /// запланированное уведомление, включение — спрашивает разрешение (если ещё
  /// не спрашивали) и планирует уведомление для идущего отсчёта.
  Future<void> setNotificationsEnabled(bool enabled) async {
    await notificationPrefs.saveNotificationsEnabled(enabled);
    if (!enabled) {
      await notifications.cancelSteps();
      return;
    }
    await _ensurePermissionAsked();
    final endsAt = this.endsAt;
    if (endsAt != null) await _scheduleDone(endsAt, totalSeconds);
  }

  /// Системный диалог разрешения — один раз за всё время.
  Future<void> _ensurePermissionAsked() async {
    if (notificationPrefs.permissionAsked()) return;
    await notifications.requestPermission();
    await notificationPrefs.markPermissionAsked();
  }

  Future<void> _scheduleDone(DateTime endsAt, int totalSeconds) async {
    if (!notificationPrefs.notificationsEnabled()) return;
    await notifications.scheduleSteps(
      endsAt: endsAt,
      totalSeconds: totalSeconds,
      isRu: localeIsRu(),
      playSound: notificationPrefs.soundEnabled(),
      vibrate: notificationPrefs.vibrationEnabled(),
    );
  }

  /// Экран не гаснет только пока идёт отсчёт и включена настройка.
  void _applyScreenAwake() =>
      screenAwake.set(running && timerPrefs.keepScreenOn());

  Future<void> setKeepScreenOn(bool on) async {
    await timerPrefs.saveKeepScreenOn(on);
    _applyScreenAwake();
  }

  Future<void> reset() async {
    _ticker?.cancel();
    await notifications.cancelSteps();
    await timerPrefs.clearEndsAt();
    running = false;
    remainingSeconds = totalSeconds;
    _setState(TimerState.idle);
    _applyScreenAwake();
  }

  Future<void> handleCompletion({required bool notify}) async {
    if (_completing) return;
    _completing = true;
    try {
      _ticker?.cancel();
      await timerPrefs.clearEndsAt();

      final before = await usageStore.loadStats();
      await usageStore.recordCompletion();
      final after = await usageStore.loadStats();

      running = false;
      remainingSeconds = totalSeconds;
      _setState(TimerState.completed);
      _applyScreenAwake();

      // Возврат в idle после анимации — только если за это время не запустили новый таймер.
      _idleTimer?.cancel();
      _idleTimer = Timer(completionHold, () {
        if (currentState == TimerState.completed) _setState(TimerState.idle);
      });

      if (notify && notificationPrefs.vibrationEnabled()) {
        HapticFeedback.heavyImpact();
      }
      if (notify && notificationPrefs.notificationsEnabled()) {
        // Ровно одно уведомление: запланированное, если система его уже
        // показала, иначе — сейчас.
        await notifications.deliverDone(
          isRu: localeIsRu(),
          playSound: notificationPrefs.soundEnabled(),
          vibrate: notificationPrefs.vibrationEnabled(),
        );
      } else {
        await notifications.cancelSteps();
      }
      await _notifyMilestones(before, after, localeIsRu());
    } finally {
      _completing = false;
    }
  }

  /// За одно завершение — максимум одна награда: значок важнее достижения.
  Future<void> _notifyMilestones(
      UsageStats before, UsageStats after, bool isRu) async {
    for (final milestone in [10, 25, 50, 100]) {
      if (before.totalCount < milestone && after.totalCount >= milestone) {
        if (notificationPrefs.notificationsEnabled()) {
          await notifications.showBadge(
            count: milestone,
            isRu: isRu,
            playSound: notificationPrefs.soundEnabled(),
            vibrate: notificationPrefs.vibrationEnabled(),
          );
        }
        return;
      }
    }

    await _checkAchievements(before, after, isRu);
  }

  /// Каждый тип достижения — не чаще раза за свой период (день / неделя /
  /// месяц), за одно завершение — только одно.
  Future<void> _checkAchievements(
      UsageStats before, UsageStats after, bool isRu) async {
    final s = S.forRu(isRu);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayCount = after.getTodayCount();
    final day = AchievementRules.dayKey(now);

    // 1. Рекорд дня: сегодня больше, чем лучший из прошлых дней (первый запуск — не рекорд).
    final prevBest = after.days
        .where((d) => d.date != today)
        .fold<int>(0, (best, d) => d.count > best ? d.count : best);
    if (prevBest > 0 && todayCount > prevBest) {
      if (await _showAchievementOnce(
        'record',
        period: day,
        title: s.achievementRecordTitle,
        body: s.achievementRecordBody(todayCount, prevBest),
      )) {
        return;
      }
    }

    // 2. Серия от 3 дней — когда серия выросла.
    if (after.streakDays >= 3 && after.streakDays > before.streakDays) {
      if (await _showAchievementOnce(
        'streak',
        period: day,
        title: s.achievementStreakTitle,
        body: s.achievementStreakBody(after.streakDays),
      )) {
        return;
      }
    }

    // 3. Возвращение: первый запуск после перерыва 3+ дня.
    if (todayCount == 1 && before.days.isNotEmpty) {
      final lastActive = before.days.first.date;
      if (today.difference(lastActive).inDays > 3) {
        if (await _showAchievementOnce(
          'comeback',
          period: day,
          title: s.achievementComebackTitle,
          body: s.achievementComebackBody,
        )) {
          return;
        }
      }
    }

    // 4. Сильная неделя — раз в неделю.
    final weekCount = AchievementRules.strongWeek(after, now);
    if (weekCount != null) {
      if (await _showAchievementOnce(
        'strong_week',
        period: AchievementRules.weekKey(now),
        title: s.achievementStrongWeekTitle,
        body: s.achievementStrongWeekBody(weekCount),
      )) {
        return;
      }
    }

    // 5. Месяц идёт вверх — раз в месяц, с 15-го числа.
    if (AchievementRules.monthUp(after, now)) {
      await _showAchievementOnce(
        'month_up',
        period: AchievementRules.monthKey(now),
        title: s.achievementMonthUpTitle,
        body: s.achievementMonthUpBody,
      );
    }
  }

  Future<bool> _showAchievementOnce(
    String type, {
    required String period,
    required String title,
    required String body,
  }) async {
    final prefs = notificationPrefs;
    if (!prefs.notificationsEnabled()) return false;
    if (prefs.achievementShownIn(type, period)) return false;
    await notifications.showAchievement(
      title: title,
      body: body,
      playSound: prefs.soundEnabled(),
      vibrate: prefs.vibrationEnabled(),
    );
    await prefs.markAchievementShown(type, period);
    return true;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _idleTimer?.cancel();
    screenAwake.set(false);
    super.dispose();
  }
}
