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
        case "initialize":
          let arg = call.arguments as! String;
          self.initialize(result: result, controller: controller, audioFilePath: arg)
        case "playAudio":
          let args = call.arguments as! Array<NSNumber>;
          self.playAudio(result: result, controller: controller, x: args[0].floatValue, y: args[1].floatValue, z: args[2].floatValue)
        case "stopAudio":
          self.stopAudio(result: result, controller: controller)
        case "getCurrentValue":
          self.getCurrentValue(result: result, controller: controller)
        default:
          result(FlutterMethodNotImplemented)
          return
        }
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private let audioController: AudioController = AudioController();

  func initialize(result: FlutterResult, controller: FlutterViewController, audioFilePath: String) {
    audioController.initialize(audioFilePath: audioFilePath)
    result(true)
  }

 func playAudio(result: FlutterResult, controller: FlutterViewController, x: Float, y: Float, z: Float) {
    audioController.playAudio(x: x, y: y, z: z)
    // https://github.com/florent37/Flutter-AssetsAudioPlayer/blob/4ead5eb3ac7b7059507c72418df22251fedd92fe/darwin/Classes/Music.swift#L1070
    result(true)
  }

  func stopAudio(result: FlutterResult, controller: FlutterViewController) {
    audioController.stopAudio()
    result(true)
  }

  func getCurrentValue(result: FlutterResult, controller: FlutterViewController) {
    result(audioController.getCurrentValue())
  }
}
