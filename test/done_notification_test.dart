import 'package:countdown/services/_desktop_notification_handler.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ф2: уведомление о завершении — ровно одно.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<DesktopNotificationHandler> scheduledIn(Duration delay) async {
    final handler = DesktopNotificationHandler();
    await handler.scheduleSteps(
      endsAt: DateTime.now().add(delay),
      totalSeconds: 60,
      isRu: true,
    );
    return handler;
  }

  test('nothing scheduled — show now', () async {
    expect(await DesktopNotificationHandler().claimDone(), isTrue);
  });

  test('scheduled one not fired yet — cancel it and show now', () async {
    final handler = await scheduledIn(const Duration(seconds: 5));
    expect(await handler.claimDone(), isTrue);
  });

  test('scheduled one already shown — do not show a second time', () async {
    final handler = await scheduledIn(const Duration(milliseconds: 30));
    await Future<void>.delayed(const Duration(milliseconds: 120));
    expect(await handler.claimDone(), isFalse);
  });
}
