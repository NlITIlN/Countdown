import 'package:flutter_driver/flutter_driver.dart' as driver;
import 'package:integration_test/integration_test_driver.dart';

/// Сохраняет таймлайн сценария из integration_test/perf_test.dart
/// в build/perf.timeline_summary.json (и полный build/perf.timeline.json).
Future<void> main() {
  return integrationDriver(
    responseDataCallback: (data) async {
      if (data == null) return;
      final timeline = driver.Timeline.fromJson(
        data['timeline'] as Map<String, dynamic>,
      );
      final summary = driver.TimelineSummary.summarize(timeline);
      await summary.writeTimelineToFile(
        'perf',
        pretty: true,
        includeSummary: true,
      );
    },
  );
}
