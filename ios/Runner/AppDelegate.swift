import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller :FlutterViewController = window?.rootViewController as! FlutterViewController
    let cameraChannel = FlutterMethodChannel(name: "test_camera",
                                            binaryMessenger: controller.binaryMessenger)

    cameraChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
        switch call.method {
        case "getCamera":
          self.receiveCamera(result: result,controller: controller)
        default:
          result(FlutterMethodNotImplemented)
          return
        }
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

 func receiveCamera(result: FlutterResult, controller: FlutterViewController) {
    let pickerController = UIImagePickerController()
    pickerController.sourceType = .camera

    controller.present(pickerController,animated: true,completion: nil)
  }
}
