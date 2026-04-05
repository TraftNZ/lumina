import UIKit
import Flutter
import RUN
import BackgroundTasks

@main
@objc class AppDelegate: FlutterAppDelegate {
  static let bgTaskId = "com.traftai.lumina.photoSync"
  private var bgFlutterEngine: FlutterEngine?
  private var bgSyncChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController

    // Main gRPC server channel
    let channel = FlutterMethodChannel(
      name: "com.traftai.lumina/RunGrpcServer",
      binaryMessenger: controller.binaryMessenger
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

    // Background sync control channel
    let bgChannel = FlutterMethodChannel(
      name: "com.traftai.lumina/BackgroundSync",
      binaryMessenger: controller.binaryMessenger
    )
    bgChannel.setMethodCallHandler({
      [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      switch call.method {
      case "scheduleSync":
        self?.scheduleBackgroundSync()
        result(nil)
      case "cancelScheduledSync":
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: AppDelegate.bgTaskId)
        result(nil)
      case "isSyncRunning":
        result(self?.bgFlutterEngine != nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    })

    // Register background task handler
    BGTaskScheduler.shared.register(
      forTaskWithIdentifier: AppDelegate.bgTaskId,
      using: nil
    ) { [weak self] task in
      self?.handleBackgroundSync(task: task as! BGProcessingTask)
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationDidEnterBackground(_ application: UIApplication) {
    let defaults = UserDefaults.standard
    let enabled = defaults.bool(forKey: "flutter.backgroundSyncEnabled")
    if enabled {
      scheduleBackgroundSync()
    }
  }

  private func scheduleBackgroundSync() {
    let request = BGProcessingTaskRequest(identifier: AppDelegate.bgTaskId)
    request.requiresNetworkConnectivity = true
    request.requiresExternalPower = false

    let defaults = UserDefaults.standard
    let intervalMinutes = defaults.integer(forKey: "flutter.backgroundSyncInterval")
    let interval = intervalMinutes > 0 ? TimeInterval(intervalMinutes * 60) : TimeInterval(12 * 60 * 60)
    request.earliestBeginDate = Date(timeIntervalSinceNow: interval)

    do {
      try BGTaskScheduler.shared.submit(request)
    } catch {
      print("Could not schedule background sync: \(error)")
    }
  }

  private func handleBackgroundSync(task: BGProcessingTask) {
    // Schedule the next occurrence
    scheduleBackgroundSync()

    let engine = FlutterEngine(name: "BackgroundSync", project: nil)
    bgFlutterEngine = engine

    let channel = FlutterMethodChannel(
      name: "com.traftai.lumina/BackgroundSync",
      binaryMessenger: engine.binaryMessenger
    )

    channel.setMethodCallHandler({
      [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      switch call.method {
      case "RunGrpcServer":
        var error: NSError? = nil
        let args = call.arguments as? [String: Any]
        let dataDir = args?["dataDir"] as? String ?? ""
        let cacheDir = args?["cacheDir"] as? String ?? ""
        let ports = RunRunGrpcServer(dataDir, cacheDir, &error)
        result(ports)
      case "updateNotification":
        // iOS doesn't have foreground service notifications — no-op
        result(nil)
      case "syncComplete":
        result(nil)
        self?.cleanupBackgroundEngine()
        task.setTaskCompleted(success: true)
      default:
        result(FlutterMethodNotImplemented)
      }
    })

    task.expirationHandler = { [weak self] in
      // Tell Dart to cancel
      channel.invokeMethod("cancelSync", arguments: nil)
      DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
        self?.cleanupBackgroundEngine()
        task.setTaskCompleted(success: false)
      }
    }

    engine.run(withEntrypoint: "backgroundSyncEntrypoint")
    GeneratedPluginRegistrant.register(with: engine)
  }

  private func cleanupBackgroundEngine() {
    bgFlutterEngine?.destroyContext()
    bgFlutterEngine = nil
  }
}
