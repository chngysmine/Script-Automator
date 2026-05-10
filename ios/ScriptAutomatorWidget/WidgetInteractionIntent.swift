import AppIntents
import WidgetKit
import Foundation

/// Handles button taps inside a widget by triggering a script action.
@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
struct WidgetInteractionIntent: AppIntent {
    static var title: LocalizedStringResource = "Run Widget Action"

    @Parameter(title: "Script ID")
    var scriptId: String

    @Parameter(title: "Action ID")
    var actionId: String

    // Required for AppIntent
    init() {}

    init(scriptId: String, actionId: String) {
        self.scriptId = scriptId
        self.actionId = actionId
    }

    func perform() async throws -> some IntentResult {
        // Save action to shared storage for Flutter to pick up on next open
        let fm = FileManager.default
        guard let dir = fm.containerURL(forSecurityApplicationGroupIdentifier: "group.com.js.scriptAutomator") else {
            return .result()
        }
        
        // Write pending action payload
        let payload: [String: Any] = [
            "scriptId": scriptId,
            "actionId": actionId,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: payload)
            let fileURL = dir.appendingPathComponent("pending_action.json")
            try data.write(to: fileURL)
            print("Widget tap recorded: \(actionId)")
        } catch {
            print("Failed to save pending action: \(error)")
        }
        
        // Reload timelines visually if needed
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
