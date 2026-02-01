import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), node: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), node: loadJSON())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
         // Reload policy: Update whenever the Main App says so (via reloadAllTimelines)
         // or every 15 mins
        let date = Date()
        let entry = SimpleEntry(date: date, node: loadJSON())
        
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: date)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    // MARK: - Shared Storage Loading
    
    private func loadJSON() -> SASUPNode? {
        let fileManager = FileManager.default
        // Must match App Group ID in Entitlements
        guard let directory = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.scriptautomator") else {
            return nil
        }
        
        let fileURL = directory.appendingPathComponent("sasup_ui.json")
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let schema = try decoder.decode(SASUPRoot.self, from: data) // Wrapper needed or decode Node directly
            return schema.root
        } catch {
            print("Widget Load Error: \(error)")
            return nil // Will show placeholder
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
}

struct ScriptAutomatorWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        if let node = entry.node {
            UniversalWidgetView(node: node)
        } else {
            VStack {
                 Text("No Script Output")
                 Text("Run a script in app")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

@main
struct ScriptAutomatorWidget: Widget {
    let kind: String = "ScriptAutomatorWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                ScriptAutomatorWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget) // iOS 17 adaption
            } else {
                ScriptAutomatorWidgetEntryView(entry: entry)
                    .padding()
            }
        }
        .configurationDisplayName("Universal Widget")
        .description("Displays output from your scripts.")
    }
}
