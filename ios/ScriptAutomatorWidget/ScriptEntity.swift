import AppIntents
import Foundation

@available(iOS 16.0, *)
public struct ScriptEntity: AppEntity {
    public static var typeDisplayRepresentation: TypeDisplayRepresentation = "Script"
    
    public static var defaultQuery = ScriptQuery()
    
    public var id: String
    public var name: String
    
    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
    
    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
    
    public struct ScriptQuery: EntityStringQuery {
        public init() {}

        public func entities(for identifiers: [ScriptEntity.ID]) async throws -> [ScriptEntity] {
            return identifiers.compactMap { id in
                if let metadata = ScriptDatabase.shared.getScript(id: id) {
                    return ScriptEntity(id: metadata.id, name: metadata.name)
                }
                return nil
            }
        }
        
        public func suggestedEntities() async throws -> [ScriptEntity] {
            let scripts = ScriptDatabase.shared.getAllScripts()
            return scripts.map { ScriptEntity(id: $0.id, name: $0.name) }
        }
        
        public func entities(matching string: String) async throws -> [ScriptEntity] {
            let scripts = ScriptDatabase.shared.getAllScripts()
            return scripts
                .filter { $0.name.localizedCaseInsensitiveContains(string) }
                .map { ScriptEntity(id: $0.id, name: $0.name) }
        }
        
        public func defaultResult() async -> ScriptEntity? {
            return try? await suggestedEntities().first
        }
    }
}
