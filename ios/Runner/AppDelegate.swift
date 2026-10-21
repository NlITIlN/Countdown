import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // «Не гасить экран» во время отсчёта — lib/services/screen_awake.dart.
    if let controller = window?.rootViewController as? FlutterViewController {
      FlutterMethodChannel(name: "countdown/screen", binaryMessenger: controller.binaryMessenger)
        .setMethodCallHandler { call, result in
          if call.method == "setKeepOn" {
            let on = (call.arguments as? [String: Any])?["on"] as? Bool ?? false
            UIApplication.shared.isIdleTimerDisabled = on
            result(nil)
          } else {
            result(FlutterMethodNotImplemented)
          }
        }
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
