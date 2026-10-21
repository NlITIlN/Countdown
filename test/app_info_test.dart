import 'dart:io';

import 'package:countdown/app_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('appVersion matches pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match =
        RegExp(r'^version:\s*([^+\s]+)', multiLine: true).firstMatch(pubspec);
    expect(match, isNotNull, reason: 'pubspec.yaml has no version');
    expect(appVersion, match!.group(1),
        reason: 'update lib/app_info.dart together with pubspec.yaml');
  });
}
