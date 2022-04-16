import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  var viewController: ViewController!

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller :FlutterViewController = window?.rootViewController as! FlutterViewController
    let audioChannel = FlutterMethodChannel(name: "audio", binaryMessenger: controller.binaryMessenger)

    audioChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
        switch call.method {
        case "playAudio":
          // self.flutterViewController = FlutterViewController()
          // let viewController = ViewController.init(rootViewController: self.flutterViewController!)
          // self.window.rootViewController = viewController
          // self.window.makeKeyAndVisible()
          self.playAudio(result: result, controller: controller)
        default:
          result(FlutterMethodNotImplemented)
          return
        }
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

 func playAudio(result: FlutterResult, controller: FlutterViewController) {
    // let next = controller.storyboard?.instantiateViewController(withIdentifier: "ViewController")
    // result(next!.playButton())

    // // Fatal error: Unexpectedly found nil while implicitly unwrapping an Optional value
    result(self.viewController.playButton())

    // controller.present(self.viewController.playButton(), animated: true, completion: nil)
  }
}
