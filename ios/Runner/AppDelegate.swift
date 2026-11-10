import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var screenChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // With UIScene, the engine is ready here rather than during app launch.
    screenChannel = FlutterMethodChannel(
      name: "countdown/screen",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    screenChannel?.setMethodCallHandler { call, result in
      if call.method == "setKeepOn" {
        let on = (call.arguments as? [String: Any])?["on"] as? Bool ?? false
        UIApplication.shared.isIdleTimerDisabled = on
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
