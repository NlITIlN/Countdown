enum AppLocale { ru, en }

class S {
  const S(this.locale);

  /// Для сервисов, которые знают только флаг языка.
  factory S.forRu(bool isRu) => S(isRu ? AppLocale.ru : AppLocale.en);

  final AppLocale locale;

  bool get isRu => locale == AppLocale.ru;

  String get settings => isRu ? 'Настройки' : 'Settings';
  String get language => isRu ? 'Язык' : 'Language';
  String get theme => isRu ? 'Тема' : 'Theme';
  String get themeSoon => isRu ? 'Скоро' : 'Coming soon';
  String get themeDark => isRu ? 'Тёмная' : 'Dark';
  String get themeLight => isRu ? 'Светлая' : 'Light';
  String get themeNeon => isRu ? 'Неоновая' : 'Neon';
  String get notifications => isRu ? 'Уведомления' : 'Notifications';
  String get notificationsEnabled =>
      isRu ? 'Присылать уведомления' : 'Send notifications';
  String get sound => isRu ? 'Звук' : 'Sound';
  String get screen => isRu ? 'Экран' : 'Screen';
  String get keepScreenOn =>
      isRu ? 'Не гасить во время отсчёта' : 'Keep on during countdown';
  String get soundDescription =>
      isRu ? 'Звук при уведомлениях' : 'Notification sound';
  String get vibration => isRu ? 'Вибрация' : 'Vibration';
  String get vibrationDescription =>
      isRu ? 'Вибрация при окончании' : 'Vibration for timer completion';
  String get russian => 'Русский';
  String get english => 'English';

  String get timer => isRu ? 'Таймер' : 'Timer';
  String get setDuration => isRu ? 'Время' : 'Duration';
  String get apply => isRu ? 'Готово' : 'Done';
  String get reset => isRu ? 'Сброс' : 'Reset';
  String get done => isRu ? 'Готово' : 'Done';
  String get tapHint => isRu ? 'нажмите' : 'tap';
  String get minUnit => isRu ? 'мин' : 'min';

  String get secUnit => isRu ? 'сек' : 'sec';

  /// «40 сек», «3 мин», «1 мин 30 сек».
  String durationLabel(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m == 0) return '$s $secUnit';
    if (s == 0) return '$m $minUnit';
    return '$m $minUnit $s $secUnit';
  }

  String get analytics => isRu ? 'Статистика' : 'Analytics';
  String get notificationsHint => isRu
      ? 'Уведомление придёт, когда таймер завершится.'
      : 'You will be notified when the timer finishes.';
  String get analyticsEmpty => isRu
      ? 'Здесь появится история, когда таймер дойдёт до нуля.'
      : 'History appears here after a timer reaches zero.';
  String get byDate => isRu ? 'По датам' : 'By date';

  String streakDays(int days) =>
      isRu ? 'Серия: $days дн. подряд' : 'Streak: $days days';

  String get activityTimeline => isRu ? 'Активность' : 'Activity timeline';

  // Уведомления
  String get timerDoneTitle => isRu ? 'Таймер завершён' : 'Timer finished';
  String get timerDoneBody => isRu ? 'Время вышло' : 'Time is up';
  String get timerDoneScheduledBody => isRu
      ? 'Время вышло — нажмите для нового запуска'
      : 'Time is up — tap to start again';
  String get badgeNotificationTitle => isRu ? 'Новый значок!' : 'New badge!';
  String badgeNotificationBody(int count) => isRu
      ? 'Вы завершили таймер $count раз'
      : 'You completed the timer $count times';

  // Достижения
  String get achievementRecordTitle =>
      isRu ? '🔥 Новый рекорд!' : '🔥 New record!';
  String get achievementStreakTitle => isRu ? '🔗 Серия дней!' : '🔗 Streak!';
  String achievementStreakBody(int days) => isRu
      ? '${streakDays(days)}. Держи темп'
      : 'Streak of $days days! Keep it up';
  String get achievementStrongWeekTitle =>
      isRu ? '📈 Сильная неделя!' : '📈 Strong week!';
  String get achievementMonthUpTitle =>
      isRu ? '📊 Месяц идёт вверх!' : '📊 Your month is trending up!';
  String get achievementMonthUpBody => isRu
      ? 'В среднем в день вы запускаете таймер чаще, чем в прошлом месяце'
      : 'More sessions per day than last month';
  String get achievementComebackTitle =>
      isRu ? '👋 С возвращением!' : '👋 Welcome back!';
  String get achievementComebackBody => isRu
      ? 'Рады снова видеть. Начнём новую серию?'
      : 'Good to see you again. Start a new streak?';

  // Подписи кнопок меню (Semantics / tooltip)
  String get openMenu => isRu ? 'Меню' : 'Menu';
  String get startTimerHint => isRu ? 'Запустить таймер' : 'Start timer';
  String get resetTimerHint => isRu ? 'Сбросить таймер' : 'Reset timer';
}
