import UIKit
import Flutter
import RUN

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    		    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let batteryChannel = FlutterMethodChannel(name: "com.traftai.lumina/RunGrpcServer",binaryMessenger: controller.binaryMessenger)
    batteryChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
        var error: NSError? = nil
        let args = call.arguments as? [String: Any]
        let dataDir = args?["dataDir"] as? String ?? ""
        let cacheDir = args?["cacheDir"] as? String ?? ""
        let ports = RunRunGrpcServer(dataDir, cacheDir, &error)
        result(ports)
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
