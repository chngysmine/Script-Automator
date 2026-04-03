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
    
    enum CodingKeys: String, CodingKey {
        case type, id, modifiers, children, content, action
    }
}

struct SASUPAction: Decodable, Hashable {
    let type: String     // "runScript" | "openUrl"
    let scriptId: String?
    let actionId: String?
    let url: String?
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
        guard let hex = value, hex.hasPrefix("#") else { return .clear }
        let cleanHex = String(hex.dropFirst())
        let scanner = Scanner(string: cleanHex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        
        if cleanHex.count == 8 {
            // #AARRGGBB format
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
            // #RRGGBB format (6 chars)
            let r = (rgbValue & 0xFF0000) >> 16
            let g = (rgbValue & 0x00FF00) >> 8
            let b = rgbValue & 0x0000FF
            return Color(red: Double(r) / 0xFF, green: Double(g) / 0xFF, blue: Double(b) / 0xFF)
        }
    }
}
