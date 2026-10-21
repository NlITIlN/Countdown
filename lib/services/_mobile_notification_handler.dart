import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../l10n/strings.dart';

class MobileNotificationHandler {
  /// Канал из первых версий: на Android 8+ звук и вибрацию задаёт канал,
  /// поэтому вместо одного канала — по каналу на каждое сочетание настроек.
  static const _legacyChannelId = 'countdown_steps';

  static String _channelId({required bool playSound, required bool vibrate}) =>
      'countdown_timer_${playSound ? 'sound' : 'nosound'}_${vibrate ? 'vibrate' : 'novibrate'}';

  static String _channelName({required bool playSound, required bool vibrate}) {
    if (playSound && vibrate) return 'Timer: sound + vibration';
    if (playSound) return 'Timer: sound only';
    if (vibrate) return 'Timer: vibration only';
    return 'Timer: silent';
  }

  static const idDone = 100;
  static const idHalf = 101;
  static const idTenSec = 102;
  static const idBadge = 103;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

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

      final androidPlugin = _android;
      if (androidPlugin != null) {
        await androidPlugin.deleteNotificationChannel(_legacyChannelId);
        for (final playSound in [true, false]) {
          for (final vibrate in [true, false]) {
            await androidPlugin.createNotificationChannel(
              AndroidNotificationChannel(
                _channelId(playSound: playSound, vibrate: vibrate),
                _channelName(playSound: playSound, vibrate: vibrate),
                description: 'Timer completion and achievements',
                importance: Importance.high,
                playSound: playSound,
                enableVibration: vibrate,
              ),
            );
          }
        }
      }

      _ready = true;
    } catch (e, st) {
      debugPrint('Mobile notifications init failed: $e\n$st');
    }
  }

  Future<void> requestPermission() async {
    if (!_ready) return;

    try {
      if (Platform.isAndroid) {
        await _android?.requestNotificationsPermission();
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
        title: S.forRu(isRu).timerDoneTitle,
        body: S.forRu(isRu).timerDoneScheduledBody,
        playSound: playSound,
        vibrate: vibrate,
      );
    } catch (e) {
      debugPrint('scheduleSteps failed: $e');
    }
  }

  Future<void> cancelSteps() async {
    if (!_ready) return;
    try {
      // idHalf/idTenSec — уведомления старых версий, могут ещё висеть в расписании.
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

    // Точное время, если система разрешает; иначе — inexact (может опоздать).
    final exact = Platform.isAndroid &&
        (await _android?.canScheduleExactNotifications() ?? false);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(at, tz.local),
      _notificationDetails(playSound: playSound, vibrate: vibrate),
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
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
        _channelId(playSound: playSound, vibrate: vibrate),
        _channelName(playSound: playSound, vibrate: vibrate),
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
