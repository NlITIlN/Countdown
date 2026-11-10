import Cocoa
import FlutterMacOS
import IOKit.pwr_mgt

class MainFlutterWindow: NSWindow {
  private var screenChannel: FlutterMethodChannel?
  private var displayAssertion: IOPMAssertionID = 0

  private func setKeepScreenOn(_ on: Bool) -> IOReturn {
    if on {
      if displayAssertion != 0 { return kIOReturnSuccess }
      return IOPMAssertionCreateWithName(
        kIOPMAssertionTypeNoDisplaySleep as CFString,
        IOPMAssertionLevel(kIOPMAssertionLevelOn),
        "Countdown timer is running" as CFString,
        &displayAssertion
      )
    }
    if displayAssertion == 0 { return kIOReturnSuccess }
    let status = IOPMAssertionRelease(displayAssertion)
    displayAssertion = 0
    return status
  }

  deinit {
    if displayAssertion != 0 { IOPMAssertionRelease(displayAssertion) }
  }

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    self.minSize = NSSize(width: 320, height: 480)
    self.title = "Countdown"

    screenChannel = FlutterMethodChannel(
      name: "countdown/screen", binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    screenChannel?.setMethodCallHandler { [weak self] call, result in
      guard call.method == "setKeepOn" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let self = self else {
        result(nil)
        return
      }
      let on = (call.arguments as? [String: Any])?["on"] as? Bool ?? false
      let status = self.setKeepScreenOn(on)
      if status == kIOReturnSuccess {
        result(nil)
      } else {
        result(FlutterError(code: "screen_awake", message: "Could not update display sleep assertion", details: status))
      }
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
