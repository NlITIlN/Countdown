import 'strings.dart';

extension FormatterExtensions on S {
  String formatDay(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year;
    if (isRu) return '$d.$m.$y';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} $d, $y';
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
