import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:local_notifier/local_notifier.dart';

import '../l10n/strings.dart';

class DesktopNotificationHandler {
  static const idDone = 100;

  final Map<int, Timer> _timers = {};

  static bool get isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  Future<void> init() async {
    if (!isDesktop) return;

    try {
      await localNotifier.setup(
        appName: 'Countdown',
      );
    } catch (e) {
      debugPrint('Desktop notifications init failed: $e');
    }
  }

  Future<void> scheduleSteps({
    required DateTime endsAt,
    required int totalSeconds,
    required bool isRu,
    bool playSound = true,
    bool vibrate = true,
  }) async {
    await cancelSteps();

    try {
      await _scheduleNotification(
        id: idDone,
        at: endsAt,
        title: S.forRu(isRu).timerDoneTitle,
        body: S.forRu(isRu).timerDoneScheduledBody,
      );
    } catch (e) {
      debugPrint('scheduleSteps failed: $e');
    }
  }

  Future<void> cancelSteps() async {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }

  /// Забирает уведомление о завершении: true — показать сейчас (запланированное
  /// ещё не сработало и отменено, или его не было); false — оно уже показано.
  Future<bool> claimDone() async {
    final timer = _timers.remove(idDone);
    if (timer == null) return true;
    if (timer.isActive) {
      timer.cancel();
      return true;
    }
    return false;
  }

  Future<void> show(
    String title,
    String body, {
    required int id,
    bool playSound = true,
    bool vibrate = true,
  }) async {
    try {
      if (isDesktop) {
        await LocalNotification(title: title, body: body).show();
      }
    } catch (e) {
      debugPrint('show failed: $e');
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required DateTime at,
    required String title,
    required String body,
  }) async {
    _timers[id]?.cancel();

    final delay = at.difference(DateTime.now());
    if (delay.isNegative) return;

    _timers[id] = Timer(delay, () => show(title, body, id: id));
  }
}
