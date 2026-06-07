import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/usage_stats.dart';
import '../services/notification_prefs.dart';
import '../services/notification_service.dart';
import '../services/timer_prefs.dart';
import '../services/usage_store.dart';

enum TimerState { idle, press, running, critical, completed }

class HomeTimerController extends ChangeNotifier {
  HomeTimerController({
    required this.timerPrefs,
    required this.usageStore,
    required this.notifications,
    required this.notificationPrefs,
    required this.localeIsRu,
  });

  final TimerPrefs timerPrefs;
  final UsageStore usageStore;
  final NotificationService notifications;
  final NotificationPrefs notificationPrefs;
  final bool Function() localeIsRu;

  int totalSeconds = 5 * 60;
  int remainingSeconds = 5 * 60;
  bool running = false;
  bool ready = false;
  TimerState currentState = TimerState.idle;

  Timer? _ticker;

  bool get canEdit => !running;
  double get progress => totalSeconds == 0 || !running
      ? 0
      : remainingSeconds / totalSeconds;

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
      final minutes = timerPrefs.loadMinutes();
      final total = minutes * 60;
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
      ready = true;
      _notifyUpdate();

      if (active) {
        final restoredEndsAt = timerPrefs.loadEndsAt();
        if (restoredEndsAt != null) {
          await notifications.scheduleSteps(
            endsAt: restoredEndsAt,
            totalSeconds: total,
            isRu: isRu,
            playSound: notificationPrefs.soundEnabled(),
            vibrate: notificationPrefs.vibrationEnabled(),
          );
        }
        _startTicker();
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('bootstrap failed: $e\n$st');
      }
      totalSeconds = 5 * 60;
      remainingSeconds = 5 * 60;
      running = false;
      ready = true;
      _notifyUpdate();
    }
  }

  Future<void> setMinutes(int minutes) async {
    if (!canEdit) return;
    final clamped = minutes.clamp(1, 24 * 60);
    final seconds = clamped * 60;
    await timerPrefs.saveMinutes(clamped);
    totalSeconds = seconds;
    remainingSeconds = seconds;
    _notifyUpdate();
  }

  Future<void> start() async {
    final seconds = remainingSeconds.clamp(1, 24 * 60 * 60);
    final endsAt = DateTime.now().add(Duration(seconds: seconds));
    await timerPrefs.saveEndsAt(endsAt);

    await notifications.scheduleSteps(
      endsAt: endsAt,
      totalSeconds: seconds,
      isRu: localeIsRu(),
      playSound: notificationPrefs.soundEnabled(),
      vibrate: notificationPrefs.vibrationEnabled(),
    );

    running = true;
    _setState(TimerState.running);
    _startTicker();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => syncFromClock());
  }

  Future<void> syncFromClock() async {
    final endsAt = timerPrefs.loadEndsAt();
    if (!running || endsAt == null) return;

    final left = endsAt.difference(DateTime.now()).inSeconds;
    if (left <= 0) {
      await handleCompletion(notify: true);
      return;
    }

    remainingSeconds = left;
    
    // Update state based on remaining time
    if (left < 10) {
      _setState(TimerState.critical);
    } else if (running) {
      _setState(TimerState.running);
    }
  }

  Future<void> pause() async {
    _ticker?.cancel();
    await notifications.cancelSteps();
    await timerPrefs.clearEndsAt();
    running = false;
    _setState(TimerState.idle);
  }

  Future<void> reset() async {
    _ticker?.cancel();
    await notifications.cancelSteps();
    await timerPrefs.clearEndsAt();
    running = false;
    remainingSeconds = totalSeconds;
    _setState(TimerState.idle);
  }

  Future<void> handleCompletion({required bool notify}) async {
    _ticker?.cancel();
    await notifications.cancelSteps();
    await timerPrefs.clearEndsAt();

    final before = await usageStore.loadStats();
    await usageStore.recordCompletion();
    final after = await usageStore.loadStats();

    _setState(TimerState.completed);

    if (notify) {
      if (notificationPrefs.vibrationEnabled()) {
        HapticFeedback.heavyImpact();
      }
      await notifications.showDone(
        isRu: localeIsRu(),
        playSound: notificationPrefs.soundEnabled(),
        vibrate: notificationPrefs.vibrationEnabled(),
      );
    }
    await _notifyMilestones(before, after, localeIsRu());

    running = false;
    remainingSeconds = totalSeconds;
    
    // Emit completed state, then transition back to idle after animation
    await Future.delayed(const Duration(seconds: 3));
    _setState(TimerState.idle);
  }

  Future<void> _notifyMilestones(UsageStats before, UsageStats after, bool isRu) async {
    for (final milestone in [10, 25, 50, 100]) {
      if (before.totalCount < milestone && after.totalCount >= milestone) {
        await notifications.showBadge(
          count: milestone,
          isRu: isRu,
          playSound: notificationPrefs.soundEnabled(),
          vibrate: notificationPrefs.vibrationEnabled(),
        );
        break;
      }
    }
    
    // Проверить достижения
    await _checkAchievements(before, after, isRu);
  }

  Future<void> _checkAchievements(UsageStats before, UsageStats after, bool isRu) async {
    final prefs = notificationPrefs;
    
    // 1. Новый рекорд дня
    final todayCount = after.getTodayCount();
    if (todayCount > 0 && before.getMaxDayCount() < todayCount) {
      final prevMax = before.getMaxDayCount();
      final title = isRu ? '🔥 Новый рекорд!' : '🔥 New record!';
      final body = isRu
          ? '$todayCount сеансов (было $prevMax)'
          : '$todayCount sessions (was $prevMax)';
      final key = 'record_$todayCount';
      // Дедупликация: не показываем повторное то же достижение
      if (prefs.lastAchievementKey() == key) return;
      await notifications.showAchievement(
        title: title,
        body: body,
        playSound: prefs.soundEnabled(),
        vibrate: prefs.vibrationEnabled(),
      );
      await prefs.saveLastAchievement(key);
      return; // Показываем только одно достижение за раз
    }
    
    // 2. Рост активности (>20%)
    final yesterdayCount = after.getYesterdayCount();
    if (yesterdayCount > 0 && todayCount > yesterdayCount * 1.2) {
      final title = isRu ? '✨ Отличный прогресс!' : '✨ Great progress!';
      final increase = ((todayCount - yesterdayCount) / yesterdayCount * 100).toInt();
      final body = isRu
          ? '+$increase% к вчера'
          : '+$increase% vs yesterday';
      final key = 'progress_$increase';
      if (prefs.lastAchievementKey() == key) return;
      await notifications.showAchievement(
        title: title,
        body: body,
        playSound: prefs.soundEnabled(),
        vibrate: prefs.vibrationEnabled(),
      );
      await prefs.saveLastAchievement(key);
      return;
    }
    
    // 3. Серия дней (N дней подряд)
    if (after.streakDays >= 3 && before.streakDays < after.streakDays) {
      final title = isRu ? '🔗 Серия дней!' : '🔗 Streak!';
      final body = isRu
          ? 'Серия ${after.streakDays} дней! Держи темп'
          : 'Streak of ${after.streakDays} days! Keep it up';
      final key = 'streak_${after.streakDays}';
      if (prefs.lastAchievementKey() == key) return;
      await notifications.showAchievement(
        title: title,
        body: body,
        playSound: prefs.soundEnabled(),
        vibrate: prefs.vibrationEnabled(),
      );
      await prefs.saveLastAchievement(key);
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
