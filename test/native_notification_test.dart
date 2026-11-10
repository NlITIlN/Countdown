import 'package:countdown/services/_native_notification_handler.dart';
import 'package:countdown/services/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  final calls = <MethodCall>[];
  var pending = <Map<String, Object>>[];

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    MacOSFlutterLocalNotificationsPlugin.registerWith();
    calls.clear();
    pending = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      switch (call.method) {
        case 'initialize':
        case 'requestPermissions':
          return true;
        case 'pendingNotificationRequests':
          return pending;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('macOS uses native scheduling and explicitly requests permission',
      () async {
    expect(NativeNotificationHandler.isSupported, isTrue);
    final service = NotificationService();
    await service.requestPermission();
    await service.scheduleSteps(
      endsAt: DateTime.now().add(const Duration(minutes: 1)),
      totalSeconds: 60,
      isRu: true,
      playSound: false,
    );

    expect(calls.where((c) => c.method == 'initialize'), hasLength(1));
    final init = calls.firstWhere((c) => c.method == 'initialize').arguments
        as Map<dynamic, dynamic>;
    expect(init['requestAlertPermission'], isFalse);
    expect(calls.where((c) => c.method == 'requestPermissions'), hasLength(1));
    final scheduled = calls.singleWhere((c) => c.method == 'zonedSchedule');
    final args = scheduled.arguments as Map<dynamic, dynamic>;
    expect(args['id'], NotificationService.idDone);
    expect(args['platformSpecifics']['presentSound'], isFalse);
  });

  test('already delivered macOS notification is not shown again', () async {
    final service = NotificationService();
    await service.scheduleSteps(
      endsAt: DateTime.now().add(const Duration(minutes: 1)),
      totalSeconds: 60,
      isRu: false,
    );
    await service.deliverDone(isRu: false);
    expect(calls.where((c) => c.method == 'show'), isEmpty);
  });

  test('pending macOS notification is cancelled before immediate delivery',
      () async {
    final service = NotificationService();
    await service.scheduleSteps(
      endsAt: DateTime.now().add(const Duration(minutes: 1)),
      totalSeconds: 60,
      isRu: false,
    );
    pending = [
      {'id': NotificationService.idDone, 'title': 'Done', 'body': 'Done'},
    ];
    calls.clear();
    await service.deliverDone(isRu: false);
    expect(calls.map((c) => c.method),
        ['pendingNotificationRequests', 'cancel', 'show']);
  });

  test('reset cancels the native macOS notification', () async {
    final service = NotificationService();
    await service.scheduleSteps(
      endsAt: DateTime.now().add(const Duration(minutes: 1)),
      totalSeconds: 60,
      isRu: false,
    );
    calls.clear();
    await service.cancelSteps();
    expect(calls.where((c) => c.method == 'cancel').map((c) => c.arguments),
        contains(NotificationService.idDone));
  });
}
