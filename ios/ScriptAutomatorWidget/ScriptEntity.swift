import AppIntents
import Foundation

@available(iOS 16.0, *)
struct ScriptEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Script"
    
    static var defaultQuery = ScriptQuery()
    
    var id: String
    var name: String
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
    
    struct ScriptQuery: EntityQuery {
        func entities(for identifiers: [ScriptEntity.ID]) async throws -> [ScriptEntity] {
            return identifiers.compactMap { id in
                if let metadata = ScriptDatabase.shared.getScript(id: id) {
                    return ScriptEntity(id: metadata.id, name: metadata.name)
                }
                return nil
            }
        }
        
        func suggestedEntities() async throws -> [ScriptEntity] {
            let scripts = ScriptDatabase.shared.getAllScripts()
            return scripts.map { ScriptEntity(id: $0.id, name: $0.name) }
        }
        
        func defaultResult() async -> ScriptEntity? {
            return try? await suggestedEntities().first
        }
    }
}
