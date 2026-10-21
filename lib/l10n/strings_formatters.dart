import 'package:intl/intl.dart';

import 'strings.dart';

extension FormatterExtensions on S {
  /// «21 окт.» / «Oct 21» в текущем году, с годом — для прошлых лет.
  String formatDay(DateTime date, {DateTime? now}) {
    final sameYear = date.year == (now ?? DateTime.now()).year;
    final format = sameYear
        ? DateFormat.MMMd(languageCode)
        : DateFormat.yMMMd(languageCode);
    return format.format(date);
  }

  String badgeTitle(String key) {
    switch (key) {
      case 'legend':
        return isRu ? 'Значок: Легенда (100+)' : 'Badge: Legend (100+)';
      case 'master':
        return isRu ? 'Значок: Мастер (50+)' : 'Badge: Master (50+)';
      case 'regular':
        return isRu ? 'Значок: Постоянство (25+)' : 'Badge: Regular (25+)';
      case 'rhythm':
        return isRu ? 'Значок: В ритме (10+)' : 'Badge: In rhythm (10+)';
      case 'starter':
        return isRu ? 'Значок: Первый шаг' : 'Badge: First step';
      default:
        return isRu ? 'Значок: —' : 'Badge: —';
    }
  }
}
