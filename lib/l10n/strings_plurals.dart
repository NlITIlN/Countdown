import 'strings.dart';

extension PluralExtensions on S {
  String sessionsLabel(int count) {
    if (!isRu) return count == 1 ? 'session' : 'sessions';
    if (count % 10 == 1 && count % 100 != 11) return 'запуск';
    if (count % 10 >= 2 &&
        count % 10 <= 4 &&
        (count % 100 < 10 || count % 100 >= 20)) {
      return 'запуска';
    }
    return 'запусков';
  }

  String achievementRecordBody(int today, int previousBest) => isRu
      ? '$today ${sessionsLabel(today)} за день (было $previousBest)'
      : '$today ${sessionsLabel(today)} in a day (was $previousBest)';

  String dayActivity(String day, int count) =>
      '$day: $count ${sessionsLabel(count)}';

  String timesOnDay(int count) {
    if (!isRu) return '$count×';
    if (count % 10 == 1 && count % 100 != 11) return '$count раз';
    if (count % 10 >= 2 &&
        count % 10 <= 4 &&
        (count % 100 < 10 || count % 100 >= 20)) {
      return '$count раза';
    }
    return '$count раз';
  }
}
