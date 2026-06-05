import SwiftUI
import WidgetKit

// MARK: - SASUP Models (Swift Mirror of Dart)

struct SASUPNode: Decodable, Hashable {
    let type: String
    let id: String?
    let modifiers: SASUPModifiers?
    let children: [SASUPNode]?
    let content: String? // Text or Image URI
    let action: SASUPAction?
    let label: String?
    let actionId: String?
    let style: String?
    
    enum CodingKeys: String, CodingKey {
        case type, id, modifiers, children, content, action, label, actionId, style
    }
}

struct SASUPAction: Decodable, Hashable {
    let type: String     // "runScript" | "openUrl"
    let scriptId: String?
    let actionId: String?
    let url: String?
    
    enum CodingKeys: String, CodingKey {
        case type, scriptId, actionId, url, payload
    }
    
    enum PayloadKeys: String, CodingKey {
        case actionId, scriptId
    }
    
    init(type: String, scriptId: String? = nil, actionId: String? = nil, url: String? = nil) {
        self.type = type
        self.scriptId = scriptId
        self.actionId = actionId
        self.url = url
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(String.self, forKey: .type)
        self.url = try container.decodeIfPresent(String.self, forKey: .url)
        
        var decodedScriptId = try container.decodeIfPresent(String.self, forKey: .scriptId)
        var decodedActionId = try container.decodeIfPresent(String.self, forKey: .actionId)
        
        if let payloadContainer = try? container.nestedContainer(keyedBy: PayloadKeys.self, forKey: .payload) {
            if decodedActionId == nil {
                decodedActionId = try payloadContainer.decodeIfPresent(String.self, forKey: .actionId)
            }
            if decodedScriptId == nil {
                decodedScriptId = try payloadContainer.decodeIfPresent(String.self, forKey: .scriptId)
            }
        }
        
        self.scriptId = decodedScriptId
        self.actionId = decodedActionId
    }
}

struct SASUPModifiers: Decodable, Hashable {
    let width: Double?
    let height: Double?
    let flex: Int?
    let background: String? // Hex or "linear-gradient(...)"
    let cornerRadius: Double?
    let padding: SASUPPadding?
    let font: String? // 'bold', 'normal', or style name
    let fontSize: Double? // Added for custom sizing
    let color: String?
    let alignment: String?
    let spacing: Double?
    let maxLines: Int? // Added for responsive lineLimit
}

struct SASUPPadding: Decodable, Hashable {
    let all: Double?
    let horizontal: Double?
    let vertical: Double?
    let left: Double?
    let right: Double?
    let top: Double?
    let bottom: Double?
    
    // Helper to get EdgeInsets
    func toEdgeInsets() -> EdgeInsets {
        if let all = all {
            return EdgeInsets(top: all, leading: all, bottom: all, trailing: all)
        }
        return EdgeInsets(
            top: top ?? vertical ?? 0,
            leading: left ?? horizontal ?? 0,
            bottom: bottom ?? vertical ?? 0,
            trailing: right ?? horizontal ?? 0
        )
    }
}

// MARK: - Parser Logic

struct ColorParser {
    static func parse(_ value: String?) -> Color {
        guard let val = value?.trimmingCharacters(in: .whitespacesAndNewlines) else { return .clear }
        
        if val.hasPrefix("#") {
            let cleanHex = String(val.dropFirst())
            let scanner = Scanner(string: cleanHex)
            var rgbValue: UInt64 = 0
            scanner.scanHexInt64(&rgbValue)
            
            if cleanHex.count == 8 {
                let a = (rgbValue & 0xFF000000) >> 24
                let r = (rgbValue & 0x00FF0000) >> 16
                let g = (rgbValue & 0x0000FF00) >> 8
                let b = rgbValue & 0x000000FF
                return Color(
                    red: Double(r) / 0xFF,
                    green: Double(g) / 0xFF,
                    blue: Double(b) / 0xFF
                ).opacity(Double(a) / 0xFF)
            } else {
                let r = (rgbValue & 0xFF0000) >> 16
                let g = (rgbValue & 0x00FF00) >> 8
                let b = rgbValue & 0x0000FF
                return Color(red: Double(r) / 0xFF, green: Double(g) / 0xFF, blue: Double(b) / 0xFF)
            }
        } else if val.hasPrefix("rgba") {
            let cleaned = val.replacingOccurrences(of: "rgba(", with: "")
                             .replacingOccurrences(of: ")", with: "")
                             .replacingOccurrences(of: " ", with: "")
            let components = cleaned.components(separatedBy: ",")
            if components.count == 4,
               let r = Double(components[0]),
               let g = Double(components[1]),
               let b = Double(components[2]),
               let a = Double(components[3]) {
                return Color(red: r / 255.0, green: g / 255.0, blue: b / 255.0).opacity(a)
            }
        } else if val.hasPrefix("rgb") {
            let cleaned = val.replacingOccurrences(of: "rgb(", with: "")
                             .replacingOccurrences(of: ")", with: "")
                             .replacingOccurrences(of: " ", with: "")
            let components = cleaned.components(separatedBy: ",")
            if components.count == 3,
               let r = Double(components[0]),
               let g = Double(components[1]),
               let b = Double(components[2]) {
                return Color(red: r / 255.0, green: g / 255.0, blue: b / 255.0)
            }
        }
        
        return .clear
    }
}
