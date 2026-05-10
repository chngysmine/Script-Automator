import Flutter
import UIKit
import BackgroundTasks
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // Register Background Task
    if #available(iOS 13.0, *) {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.js.scriptAutomator.refresh", using: nil) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
    }

    // Widget Refresh Channel
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let widgetChannel = FlutterMethodChannel(name: "com.js.scriptAutomator/widget",
                                              binaryMessenger: controller.binaryMessenger)
    widgetChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "reloadTimelines" {
         if #available(iOS 14.0, *) {
             WidgetCenter.shared.reloadAllTimelines()
             print("Native: Widget Timelines Reloaded")
         }
         result(nil)
      } else if call.method == "getAppGroupPath" {
         guard let groupId = call.arguments as? String else {
             result(FlutterError(code: "INVALID_ARG", message: "Group ID must be a string", details: nil))
             return
         }
         if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupId) {
             result(url.path)
         } else {
             result(nil)
         }
      } else {
        result(FlutterMethodNotImplemented)
      }
    })


    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Headless Engine for Background Tasks
  var headlessEngine: FlutterEngine?
  
  // MARK: - Background Task Handling
  @available(iOS 13.0, *)
  func handleAppRefresh(task: BGAppRefreshTask) {
      // 1. Schedule Next (Moved to script implementation to support Smart Policy)
      // We do NOT schedule here immediately. We wait for script execution to determine needed time.
      // Fallback: If script crashes/times out, iOS will use its own discretion or we rely on the launch trigger.
      // Ideally, set a backup schedule? No, expiration handler deals with failure.
      
      // 2. Setup Expiration
      task.expirationHandler = {
          print("Background Task Expired")
          task.setTaskCompleted(success: false)
          self.headlessEngine?.destroyContext()
          self.headlessEngine = nil
      }

      // 3. Initialize Headless Engine
      // We must run it on Main Thread as per Flutter Constraints
      DispatchQueue.main.async {
          self.headlessEngine = FlutterEngine(name: "headless_runner")
          // Allow Plugins (like MethodChannel, shared_preferences) to work
          guard let engine = self.headlessEngine,
                engine.run(withEntrypoint: "scriptRunnerMain", libraryURI: nil) else {
             print("Failed to run Dart Entrypoint")
             task.setTaskCompleted(success: false)
             return
          }
          GeneratedPluginRegistrant.register(with: engine)
          
          // 4. Setup MethodChannel Bridge
          let channel = FlutterMethodChannel(
              name: "com.js.scriptAutomator/background",
              binaryMessenger: engine.binaryMessenger
          )
          
          // 5. Wait for Signal
          channel.setMethodCallHandler { (call, result) in
              if call.method == "scriptCompleted" {
                  print("Background Script Completed Successfully")
                  
                  // Extract Smart Timeline Delay if provided
                  var nextDelay: Double = 15 * 60 // Default 15 mins
                  if let args = call.arguments as? [String: Any],
                     let delay = args["nextRunDelay"] as? Double {
                      nextDelay = delay
                      print("Smart Timeline: Requested next run in \(delay) seconds")
                  }
                  
                  // Schedule next run DYNAMICALLY based on script needs
                  self.scheduleNextRefresh(delay: nextDelay)
                  
                  task.setTaskCompleted(success: true)
                  
                  // Cleanup
                  self.headlessEngine?.destroyContext()
                  self.headlessEngine = nil
                  result(nil)
              } else {
                  result(FlutterMethodNotImplemented)
              }
          }
      }
  }
  
  @available(iOS 13.0, *)
  func scheduleNextRefresh(delay: Double = 15 * 60) {
      let request = BGAppRefreshTaskRequest(identifier: "com.js.scriptAutomator.refresh")
      request.earliestBeginDate = Date(timeIntervalSinceNow: delay)
      
      do {
          try BGTaskScheduler.shared.submit(request)
          print("Scheduled next background refresh in \(delay) seconds")
      } catch {
          print("Could not schedule app refresh: \(error)")
      }
  }
}
