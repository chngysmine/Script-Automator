import Foundation
import SQLite3

struct ScriptMetadata: Identifiable {
    let id: String
    let name: String
    let updatedAt: Date
}

class ScriptDatabase {
    static let shared = ScriptDatabase()
    private var db: OpaquePointer?
    private let dbName = "widget_registry.db"
    private let appGroupId = "group.com.js.scriptAutomator"

    private init() {
        openDatabase()
    }

    private func openDatabase() {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            NSLog("ScriptDatabase ERROR: Failed to get App Group container. Check AppGroup entitlements for ID: \(appGroupId)")
            return
        }

        let dbURL = containerURL.appendingPathComponent(dbName)
        
        // Open in Read-Only mode for safety in Extension
        if sqlite3_open_v2(dbURL.path, &db, SQLITE_OPEN_READONLY, nil) != SQLITE_OK {
            print("ScriptDatabase: Error opening database")
        }
    }

    deinit {
        if db != nil {
            sqlite3_close(db)
        }
    }

    func getAllScripts() -> [ScriptMetadata] {
        var scripts: [ScriptMetadata] = []
        let queryStatementString = "SELECT id, name, updated_at FROM scripts ORDER BY updated_at DESC;"
        var queryStatement: OpaquePointer?

        if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                guard let idCStr = sqlite3_column_text(queryStatement, 0),
                      let nameCStr = sqlite3_column_text(queryStatement, 1) else {
                    continue
                }

                let id = String(cString: idCStr)
                let name = String(cString: nameCStr)
                let timestamp = sqlite3_column_int64(queryStatement, 2)
                let date = Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000)

                scripts.append(ScriptMetadata(id: id, name: name, updatedAt: date))
            }
        } else {
            print("ScriptDatabase: SELECT statement could not be prepared")
        }
        sqlite3_finalize(queryStatement)
        return scripts
    }
    
    func getScript(id: String) -> ScriptMetadata? {
        let queryStatementString = "SELECT id, name, updated_at FROM scripts WHERE id = ?;"
        var queryStatement: OpaquePointer?
        
        var script: ScriptMetadata?
        
        if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
            sqlite3_bind_text(queryStatement, 1, (id as NSString).utf8String, -1, nil)
            
            if sqlite3_step(queryStatement) == SQLITE_ROW {
                if let idCStr = sqlite3_column_text(queryStatement, 0),
                   let nameCStr = sqlite3_column_text(queryStatement, 1) {
                    
                    let id = String(cString: idCStr)
                    let name = String(cString: nameCStr)
                    let timestamp = sqlite3_column_int64(queryStatement, 2)
                    let date = Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000)
                    
                    script = ScriptMetadata(id: id, name: name, updatedAt: date)
                }
            }
        }
        sqlite3_finalize(queryStatement)
        return script
    }
}
