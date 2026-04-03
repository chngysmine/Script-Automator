import SwiftUI
import WidgetKit

/// A simplified, grayscale-only view optimized for iOS Lock Screen (Accessory) widgets.
/// It aggressively strips backgrounds and unsupported interactive elements.
@available(iOS 16.0, watchOS 9.0, *)
struct AccessoryWidgetView: View {
    let node: SASUPNode
    let family: WidgetFamily
    
    var body: some View {
        renderNode(node)
    }
    
    @ViewBuilder
    private func renderNode(_ node: SASUPNode) -> some View {
        switch node.type {
        case "container", "stack":
            ZStack(alignment: .center) {
                renderChildren(node.children)
            }
        case "column":
            VStack(spacing: node.modifiers?.spacing.map { CGFloat($0) } ?? 0) {
                renderChildren(node.children)
            }
        case "row":
            HStack(spacing: node.modifiers?.spacing.map { CGFloat($0) } ?? 0) {
                renderChildren(node.children)
            }
        case "text":
            Text(node.content ?? "")
                .font(parseFont(node.modifiers))
                .fontWeight(parseWeight(node.modifiers?.font))
                .minimumScaleFactor(0.5)
                .lineLimit(node.modifiers?.maxLines ?? (family == .accessoryInline ? 1 : 2))
        case "icon":
            Image(systemName: parseIconName(node.content))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(
                    width: node.modifiers?.fontSize ?? 16,
                    height: node.modifiers?.fontSize ?? 16
                )
        case "button":
            // Buttons become plain stacks on Lock Screen to prevent invalid intents
            ZStack { renderChildren(node.children) }
        case "spacer":
            Spacer()
        default:
            EmptyView()
        }
    }
    
    @ViewBuilder
    private func renderChildren(_ children: [SASUPNode]?) -> some View {
        if let children = children {
            ForEach(children.indices, id: \.self) { index in
                AccessoryWidgetView(node: children[index], family: family)
            }
        }
    }
    
    private func parseFont(_ mods: SASUPModifiers?) -> Font {
        if let size = mods?.fontSize {
            return .system(size: size, weight: parseWeight(mods?.font), design: .rounded)
        }
        
        switch mods?.font {
        case "title": return .headline
        case "subtitle": return .subheadline
        case "caption": return .caption2
        default: return .body
        }
    }
    
    private func parseWeight(_ font: String?) -> Font.Weight {
        switch font {
        case "bold": return .bold
        case "semibold": return .semibold
        case "light": return .light
        default: return .regular
        }
    }
    
    private func parseIconName(_ name: String?) -> String {
        switch name {
        case "moon.stars.fill": return "moon.stars.fill"
        case "sun.max.fill": return "sun.max.fill"
        case "cloud.fill": return "cloud.fill"
        case "wind": return "wind"
        default: return "circle.dashed" 
        }
    }
}
