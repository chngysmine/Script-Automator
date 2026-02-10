import WidgetKit
import AppIntents

@available(iOS 17.0, *)
struct ScriptSelectionIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Script"
    static var description = IntentDescription("Choose a script to display.")
    
    @Parameter(title: "Script")
    var script: ScriptEntity?
}
