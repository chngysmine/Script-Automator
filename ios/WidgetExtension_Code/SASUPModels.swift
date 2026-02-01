import SwiftUI
import WidgetKit

// MARK: - SASUP Models (Swift Mirror of Dart)

struct SASUPNode: Decodable, Hashable {
    let type: String
    let id: String?
    let modifiers: SASUPModifiers?
    let children: [SASUPNode]?
    let content: String? // Text or Image URI
    // let action: SASUPAction? // To implement later
    
    enum CodingKeys: String, CodingKey {
        case type, id, modifiers, children, content
    }
}

struct SASUPModifiers: Decodable, Hashable {
    let width: Double?
    let height: Double?
    let flex: Int?
    let background: String? // Hex or "linear-gradient(...)"
    let cornerRadius: Double?
    let padding: SASUPPadding?
    let font: String?
    let color: String?
    let alignment: String?
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
        // Simple Hex Parser (6 chars)
        let scanner = Scanner(string: hex)
        scanner.currentIndex = hex.index(after: hex.startIndex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        
        let r = (rgbValue & 0xff0000) >> 16
        let g = (rgbValue & 0xff00) >> 8
        let b = rgbValue & 0xff
        
        return Color(red: Double(r) / 0xff, green: Double(g) / 0xff, blue: Double(b) / 0xff)
    }
}
