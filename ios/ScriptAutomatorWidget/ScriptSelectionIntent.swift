import WidgetKit
import AppIntents

@available(iOS 17.0, *)
public struct ScriptSelectionIntent: WidgetConfigurationIntent {
    public static var title: LocalizedStringResource = "Select Script"
    public static var description = IntentDescription("Choose a script to display.")
    
    @Parameter(title: "Script")
    public var script: ScriptEntity?

    public init() {}
}
