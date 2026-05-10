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
        guard let directory = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.js.scriptAutomator") else {
            return (nil, "App Group Not Found")
        }
        
        let fileURL: URL
        if let id = scriptId {
            // Specific Script
            fileURL = directory.appendingPathComponent("sasup_ui_\(id).json")
            
            // If the specific script file doesn't exist, it means it's empty or deleted.
            // DO NOT fallback to the global sasup_ui.json, as that belongs to potentially another script.
            if !fileManager.fileExists(atPath: fileURL.path) {
                return (nil, "Script Output Not Found")
            }
        } else {
            // Fallback: Latest Run (sasup_ui.json) when no specific script is selected
            fileURL = directory.appendingPathComponent("sasup_ui.json")
            
            if !fileManager.fileExists(atPath: fileURL.path) {
                return (nil, nil) // Normal first launch state
            }
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
    let family: String?
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
    @Environment(\.widgetFamily) var family

    var body: some View {
        if let node = entry.node {
            UniversalWidgetView(node: node, isRoot: true, family: family)
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
struct ScriptAutomatorWidgets: WidgetBundle {
    var body: some Widget {
        ScriptAutomatorWidget()
        ScriptAutomatorLockScreenWidget()
    }
}

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
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .systemExtraLarge
        ])
    }
}
