enum AppLocale { ru, en }

class S {
  const S(this.locale);

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
  String get sound => isRu ? 'Звук' : 'Sound';
  String get soundDescription => isRu
      ? 'Звук при уведомлениях'
      : 'Notification sound';
  String get vibration => isRu ? 'Вибрация' : 'Vibration';
  String get vibrationDescription => isRu
      ? 'Вибрация при окончании'
      : 'Vibration for timer completion';
  String get russian => 'Русский';
  String get english => 'English';

  String get timer => isRu ? 'Таймер' : 'Timer';
  String get setMinutes => isRu ? 'Минуты' : 'Minutes';
  String get apply => isRu ? 'Готово' : 'Done';
  String get reset => isRu ? 'Сброс' : 'Reset';
  String get done => isRu ? 'Готово' : 'Done';
  String get tapHint => isRu ? 'нажмите' : 'tap';
  String get minUnit => isRu ? 'мин' : 'min';

  String minutesLabel(int minutes) => '$minutes $minUnit';

  String get analytics => isRu ? 'Статистика' : 'Analytics';
  String get notificationsHint => isRu
      ? 'Уведомления: 50%, 10 сек до конца и завершение таймера.'
      : 'Notifications: 50%, 10 sec left, and timer done.';
  String get analyticsEmpty => isRu
      ? 'Здесь появится история, когда таймер дойдёт до нуля.'
      : 'History appears here after a timer reaches zero.';
  String get byDate => isRu ? 'По датам' : 'By date';

  String streakDays(int days) =>
      isRu ? 'Серия: $days дн. подряд' : 'Streak: $days days';
}
