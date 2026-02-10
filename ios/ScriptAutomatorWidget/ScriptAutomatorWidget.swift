import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), node: nil, scriptName: "Preview", error: nil)
    }

    func snapshot(for configuration: ScriptSelectionIntent, in context: Context) async -> SimpleEntry {
        let result = loadJSON(scriptId: configuration.script?.id)
        return SimpleEntry(date: Date(), node: result.node, scriptName: configuration.script?.name, error: result.error)
    }
    
    func timeline(for configuration: ScriptSelectionIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let date = Date()
        let scriptId = configuration.script?.id
        let scriptName = configuration.script?.name
        
        let result = loadJSON(scriptId: scriptId)
        // Reload policy
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: date)!
        let entry = SimpleEntry(date: date, node: result.node, scriptName: scriptName, error: result.error)
        
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
    
    // MARK: - Shared Storage Loading
    
    private func loadJSON(scriptId: String?) -> (node: SASUPNode?, error: String?) {
        let fileManager = FileManager.default
        // Corrected App Group ID
        guard let directory = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.antigravity.script_automator") else {
            return (nil, "App Group Not Found")
        }
        
        let fileURL: URL
        if let id = scriptId {
            // Specific Script
            fileURL = directory.appendingPathComponent("sasup_ui_\(id).json")
        } else {
            // Fallback: Latest Run (sasup_ui.json)
            fileURL = directory.appendingPathComponent("sasup_ui.json")
        }
        
        // Debug Check: If file doesn't exist, return specific error
        if !fileManager.fileExists(atPath: fileURL.path) {
             if scriptId == nil {
                 return (nil, nil) // Normal first launch state
             }
             return (nil, "Script Output Not Found")
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let schema = try decoder.decode(SASUPRoot.self, from: data)
            return (schema.root, nil)
        } catch {
            print("Widget Load Error: \(error)")
            return (nil, "Err: \(error.localizedDescription)")
        }
    }
}

// Wrapper for Root
struct SASUPRoot: Decodable {
    let root: SASUPNode
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let node: SASUPNode?
    let scriptName: String?
    let error: String?
}

struct ScriptAutomatorWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        if let node = entry.node {
            UniversalWidgetView(node: node, isRoot: true)
                .minimumScaleFactor(0.7) // Prevent tiny text
        } else {
            VStack {
                 Text(entry.scriptName ?? "Select Script")
                    .font(.headline)
                 if let error = entry.error {
                     Text(error)
                        .font(.caption2)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 4)
                 } else {
                     Text("No Output / Not Run")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                     Text("Run script in app first")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                 }
            }
        }
    }
}

@main
struct ScriptAutomatorWidget: Widget {
    let kind: String = "ScriptAutomatorWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ScriptSelectionIntent.self, provider: Provider()) { entry in
            ScriptAutomatorWidgetEntryView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .contentMarginsDisabled()
        .configurationDisplayName("Script Widget")
        .description("Display the output of your scripts.")
    }
}
