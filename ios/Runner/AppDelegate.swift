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

    // ViewControllerを初期化
    ViewController().initialize()

    audioChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
        switch call.method {
        case "playAudio":
          self.playAudio(result: result, controller: controller)
        case "stopAudio":
          self.stopAudio(result: result, controller: controller)
        default:
          result(FlutterMethodNotImplemented)
          return
        }
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

 func playAudio(result: FlutterResult, controller: FlutterViewController) {
    ViewController().playButton()
    // https://github.com/florent37/Flutter-AssetsAudioPlayer/blob/4ead5eb3ac7b7059507c72418df22251fedd92fe/darwin/Classes/Music.swift#L1070
    result(true)
  }

  func stopAudio(result: FlutterResult, controller: FlutterViewController) {
    ViewController().stopButton()
    result(true)
  }
}
