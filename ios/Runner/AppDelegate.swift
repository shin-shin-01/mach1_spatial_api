import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller :FlutterViewController = window?.rootViewController as! FlutterViewController
    let audioChannel = FlutterMethodChannel(name: "audio", binaryMessenger: controller.binaryMessenger)

    audioChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
        switch call.method {
        case "startHeadphoneMotion":
          self.startHeadphoneMotion(result: result, controller: controller)
        default:
          result(FlutterMethodNotImplemented)
          return
        }
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private let audioController: AudioController = AudioController();

  func startHeadphoneMotion(result: FlutterResult, controller: FlutterViewController) {
    audioController.startHeadphoneMotion()
    result(true)
  }
}
