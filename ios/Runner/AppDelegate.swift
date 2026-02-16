import UIKit
import Flutter
import RUN

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: "com.traftai.lumina/RunGrpcServer",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
        var error: NSError? = nil
        let args = call.arguments as? [String: Any]
        let dataDir = args?["dataDir"] as? String ?? ""
        let cacheDir = args?["cacheDir"] as? String ?? ""
        let ports = RunRunGrpcServer(dataDir, cacheDir, &error)
        result(ports)
    })
  }
}
