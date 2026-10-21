import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// «Не гасить экран» во время отсчёта. Нативная сторона — канал
/// `countdown/screen` в MainActivity.kt, AppDelegate.swift, flutter_window.cpp.
class ScreenAwake {
  static const _channel = MethodChannel('countdown/screen');

  bool? _current;

  /// Повторный вызов с тем же значением ничего не делает.
  Future<void> set(bool on) async {
    if (_current == on) return;
    _current = on;
    try {
      await _channel.invokeMethod<void>('setKeepOn', {'on': on});
    } on MissingPluginException {
      // Платформа без реализации (тесты, web) — экран просто гаснет как обычно.
    } on PlatformException catch (e) {
      debugPrint('ScreenAwake.set($on) failed: $e');
    }
  }
}
