import 'package:countdown/screens/home_timer_controller.dart';
import 'package:countdown/ui/rings_timer_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _button({DateTime? endsAt, required Duration total, TimerState? state}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: RingsTimerButton(
          timeText: '00:10',
          endsAt: endsAt,
          totalDuration: total,
          state:
              state ?? (endsAt == null ? TimerState.idle : TimerState.running),
          onTap: () {},
          onLongPress: () {},
        ),
      ),
    ),
  );
}

void main() {
  for (final total in [
    const Duration(seconds: 10), // короткий: обновление каждый кадр
    const Duration(minutes: 5), // длинный: редкий таймер
  ]) {
    testWidgets(
        'progress driver starts and stops cleanly (${total.inSeconds}s)',
        (tester) async {
      await tester.pumpWidget(_button(
        endsAt: DateTime.now().add(total),
        total: total,
      ));
      await tester.pump(const Duration(milliseconds: 600));

      // Сброс: дуга «уезжает», драйвер останавливается.
      await tester.pumpWidget(_button(total: total));
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.hasRunningAnimations, isFalse);

      // Повторный старт и уход со страницы — без висящих таймеров.
      await tester.pumpWidget(_button(
        endsAt: DateTime.now().add(total),
        total: total,
      ));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(const SizedBox());
    });
  }
}
