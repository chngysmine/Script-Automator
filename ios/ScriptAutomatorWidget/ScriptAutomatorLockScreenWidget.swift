import WidgetKit
import SwiftUI

/// Entry point for Lock Screen Accessory Widgets.
/// It uses the exact same `Provider` as the Home Screen widget to share the JSON cache.
@available(iOS 16.0, watchOS 9.0, *)
struct ScriptAutomatorLockScreenWidget: Widget {
    let kind: String = "ScriptAutomatorLockScreenWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ScriptSelectionIntent.self, provider: Provider()) { entry in
            ScriptAutomatorLockScreenWidgetEntryView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Script Lock Screen")
        .description("Display script output on your Lock Screen.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

@available(iOS 16.0, watchOS 9.0, *)
struct ScriptAutomatorLockScreenWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        if let node = entry.node {
            AccessoryWidgetView(node: node, family: family)
        } else {
            Text("-")
                .font(.caption)
        }
    }
}
