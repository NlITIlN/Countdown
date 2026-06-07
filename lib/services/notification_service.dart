import '_desktop_notification_handler.dart';
import '_mobile_notification_handler.dart';

class NotificationService {
  static const idDone = 100;
  static const idHalf = 101;
  static const idTenSec = 102;
  static const idBadge = 103;
  static const idAchievementStart = 200; // диапазон для достижений

  final MobileNotificationHandler _mobile = MobileNotificationHandler();
  final DesktopNotificationHandler _desktop = DesktopNotificationHandler();

  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;

    if (MobileNotificationHandler.isMobile) {
      await _mobile.init();
    }

    if (DesktopNotificationHandler.isDesktop) {
      await _desktop.init();
    }

    _ready = true;
  }

  Future<void> requestPermission() async {
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
    await _mobile.cancelSteps();
    await _desktop.cancelSteps();
  }

  Future<void> showDone({
    required bool isRu,
    bool playSound = true,
    bool vibrate = true,
  }) async {
    final title = isRu ? 'Таймер завершён' : 'Timer finished';
    final body = isRu ? 'Время вышло' : 'Time is up';
    
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
    final title = isRu ? 'Новый значок!' : 'New badge!';
    final body = isRu
        ? 'Вы завершили таймер $count раз'
        : 'You completed the timer $count times';
    
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

