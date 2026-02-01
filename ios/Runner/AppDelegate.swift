import Flutter
import UIKit
import BackgroundTasks

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // Register Background Task
    if #available(iOS 13.0, *) {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.antigravity.scriptautomator.refresh", using: nil) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - Background Task Handling
  @available(iOS 13.0, *)
  func handleAppRefresh(task: BGAppRefreshTask) {
      // 1. Set Expiration Handler (CRITICAL)
      task.expirationHandler = {
          // Clean up any unfinished task logic here
          // e.g. Cancel JS Engine execution
          print("Background Task Expired")
      }

      // 2. Refresh Logic
      // In Phase 3, we simulate the refresh by "completing" immediately or doing a light check.
      // In Phase 4, we will call into Flutter Engine via MethodChannel.
      
      scheduleNextRefresh()
      
      // Simulate success for now
      task.setTaskCompleted(success: true)
  }
  
  @available(iOS 13.0, *)
  func scheduleNextRefresh() {
      let request = BGAppRefreshTaskRequest(identifier: "com.antigravity.scriptautomator.refresh")
      request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 mins
      
      do {
          try BGTaskScheduler.shared.submit(request)
      } catch {
          print("Could not schedule app refresh: \(error)")
      }
  }
}
