import '../l10n/strings.dart';
import '_desktop_notification_handler.dart';
import '_mobile_notification_handler.dart';

class NotificationService {
  static const idDone = 100;
  static const idBadge = 103;
  static const idAchievementStart = 200; // диапазон для достижений

  final MobileNotificationHandler _mobile = MobileNotificationHandler();
  final DesktopNotificationHandler _desktop = DesktopNotificationHandler();

  Future<void>? _initFuture;

  /// Идемпотентна: запускается один раз, остальные вызовы ждут тот же Future.
  /// Каждый метод сервиса сам дожидается init — порядок вызовов не важен,
  /// поэтому main() может отложить init до первого кадра.
  Future<void> init() => _initFuture ??= _init();

  Future<void> _init() async {
    if (MobileNotificationHandler.isMobile) {
      await _mobile.init();
    }

    if (DesktopNotificationHandler.isDesktop) {
      await _desktop.init();
    }
  }

  Future<void> requestPermission() async {
    await init();
    if (MobileNotificationHandler.isMobile) {
      await _mobile.requestPermission();
    }
  }

  Future<void> scheduleSteps({
    required DateTime endsAt,
    required int totalSeconds,
    required bool isRu,
    bool playSound = true,
    bool vibrate = true,
  }) async {
    await init();
    if (MobileNotificationHandler.isMobile) {
      await _mobile.scheduleSteps(
        endsAt: endsAt,
        totalSeconds: totalSeconds,
        isRu: isRu,
        playSound: playSound,
        vibrate: vibrate,
      );
    }

    if (DesktopNotificationHandler.isDesktop) {
      await _desktop.scheduleSteps(
        endsAt: endsAt,
        totalSeconds: totalSeconds,
        isRu: isRu,
        playSound: playSound,
        vibrate: vibrate,
      );
    }
  }

  Future<void> cancelSteps() async {
    await init();
    await _mobile.cancelSteps();
    await _desktop.cancelSteps();
  }

  Future<void> showDone({
    required bool isRu,
    bool playSound = true,
    bool vibrate = true,
  }) async {
    await init();
    final s = S.forRu(isRu);
    final title = s.timerDoneTitle;
    final body = s.timerDoneBody;

    if (MobileNotificationHandler.isMobile) {
      await _mobile.show(
        title,
        body,
        id: idDone,
        playSound: playSound,
        vibrate: vibrate,
      );
    } else {
      await _desktop.show(
        title,
        body,
        id: idDone,
        playSound: playSound,
        vibrate: vibrate,
      );
    }
  }

  Future<void> showBadge({
    required int count,
    required bool isRu,
    bool playSound = true,
    bool vibrate = true,
  }) async {
    await init();
    final s = S.forRu(isRu);
    final title = s.badgeNotificationTitle;
    final body = s.badgeNotificationBody(count);

    if (MobileNotificationHandler.isMobile) {
      await _mobile.show(
        title,
        body,
        id: idBadge,
        playSound: playSound,
        vibrate: vibrate,
      );
    } else {
      await _desktop.show(
        title,
        body,
        id: idBadge,
        playSound: playSound,
        vibrate: vibrate,
      );
    }
  }

  /// Показать уведомление о достижении
  Future<void> showAchievement({
    required String title,
    required String body,
    bool playSound = true,
    bool vibrate = true,
  }) async {
    await init();
    // Генерируем уникальный ID для каждого достижения
    final id = idAchievementStart + DateTime.now().millisecond % 100;

    if (MobileNotificationHandler.isMobile) {
      await _mobile.show(
        title,
        body,
        id: id,
        playSound: playSound,
        vibrate: vibrate,
      );
    } else {
      await _desktop.show(
        title,
        body,
        id: id,
        playSound: playSound,
        vibrate: vibrate,
      );
    }
  }
}
