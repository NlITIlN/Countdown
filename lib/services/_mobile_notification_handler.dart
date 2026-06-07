import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class MobileNotificationHandler {
  static const _channelId = 'countdown_steps';
  static const _channelName = 'Timer';

  static const idDone = 100;
  static const idHalf = 101;
  static const idTenSec = 102;
  static const idBadge = 103;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  static bool get isMobile {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  Future<void> init() async {
    if (_ready) return;

    try {
      tz_data.initializeTimeZones();
      try {
        final name = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(name));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
      }

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios),
      );

      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'Timer milestones and completion',
        importance: Importance.high,
      );

      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      _ready = true;
    } catch (e, st) {
      debugPrint('Mobile notifications init failed: $e\n$st');
    }
  }

  Future<void> requestPermission() async {
    if (!_ready) return;

    try {
      if (Platform.isAndroid) {
        await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      } else if (Platform.isIOS) {
        await _plugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, sound: true);
      }
    } catch (e) {
      debugPrint('Notification permission failed: $e');
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
      await _scheduleNative(
        id: idDone,
        at: endsAt,
        title: isRu ? 'Таймер завершён' : 'Timer finished',
        body: isRu
            ? 'Время вышло — нажмите для нового запуска'
            : 'Time is up — tap to start again',
        playSound: playSound,
        vibrate: vibrate,
      );

      if (totalSeconds >= 120) {
        final halfAt = endsAt.subtract(Duration(seconds: totalSeconds ~/ 2));
        if (halfAt.isAfter(DateTime.now())) {
          await _scheduleNative(
            id: idHalf,
            at: halfAt,
            title: isRu ? 'Половина пути' : 'Halfway there',
            body: isRu ? 'Осталось 50% времени' : '50% of time remaining',
          );
        }
      }

      if (totalSeconds > 15) {
        final tenAt = endsAt.subtract(const Duration(seconds: 10));
        if (tenAt.isAfter(DateTime.now())) {
          await _scheduleNative(
            id: idTenSec,
            at: tenAt,
            title: isRu ? '10 секунд' : '10 seconds',
            body: isRu ? 'Скоро окончание таймера' : 'Timer ending soon',
          );
        }
      }
    } catch (e) {
      debugPrint('scheduleSteps failed: $e');
    }
  }

  Future<void> cancelSteps() async {
    if (!_ready) return;
    try {
      for (final id in [idDone, idHalf, idTenSec]) {
        await _plugin.cancel(id);
      }
    } catch (e) {
      debugPrint('cancelSteps failed: $e');
    }
  }

  Future<void> show(
    String title,
    String body, {
    required int id,
    bool playSound = true,
    bool vibrate = true,
  }) async {
    if (!_ready) return;
    try {
      await _plugin.show(
        id,
        title,
        body,
        _notificationDetails(playSound: playSound, vibrate: vibrate),
      );
    } catch (e) {
      debugPrint('show failed: $e');
    }
  }

  Future<void> _scheduleNative({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    bool playSound = true,
    bool vibrate = true,
  }) async {
    if (at.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(at, tz.local),
      _notificationDetails(playSound: playSound, vibrate: vibrate),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  NotificationDetails _notificationDetails({
    bool playSound = true,
    bool vibrate = true,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        importance: Importance.high,
        priority: Priority.high,
        playSound: playSound,
        enableVibration: vibrate,
      ),
      iOS: DarwinNotificationDetails(
        presentSound: playSound,
        presentAlert: true,
        presentBadge: true,
      ),
    );
  }
}
