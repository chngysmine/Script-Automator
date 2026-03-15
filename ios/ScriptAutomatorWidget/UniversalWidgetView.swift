import SwiftUI

struct UniversalWidgetView: View {
    let node: SASUPNode
    let isRoot: Bool
    
    init(node: SASUPNode, isRoot: Bool = false) {
        self.node = node
        self.isRoot = isRoot
    }
    
    var body: some View {
        renderNode(node, isRoot: isRoot)
    }
    
    @ViewBuilder
    private func renderNode(_ node: SASUPNode, isRoot: Bool = false) -> some View {
        let view = _renderRawNode(node, isRoot: isRoot)
        
        if isRoot {
            GeometryReader { geometry in
                view.frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
            }
        } else if node.modifiers?.flex == 1 {
            view.frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            view
        }
    }

    @ViewBuilder
    private func _renderRawNode(_ node: SASUPNode, isRoot: Bool = false) -> some View {
        switch node.type {
        case "container":
            applyModifiers(node.modifiers, isRoot: isRoot) {
                VStack(spacing: 0) {
                    renderChildren(node.children)
                }
            }
        case "column":
            applyModifiers(node.modifiers, isRoot: isRoot) {
                VStack(alignment: parseHorizontalAlignment(node.modifiers?.alignment), spacing: node.modifiers?.spacing.map { CGFloat($0) } ?? 0) {
                    renderChildren(node.children)
                }
            }
        case "row":
            applyModifiers(node.modifiers, isRoot: isRoot) {
                HStack(alignment: parseVerticalAlignment(node.modifiers?.alignment), spacing: node.modifiers?.spacing.map { CGFloat($0) } ?? 0) {
                    renderChildren(node.children)
                }
            }
        case "stack":
             applyModifiers(node.modifiers, isRoot: isRoot) {
                ZStack(alignment: .center) {
                    renderChildren(node.children)
                }
            }
        case "text":
            applyModifiers(node.modifiers, isRoot: isRoot) {
                Text(node.content ?? "")
                    .font(parseFont(node.modifiers))
                    .foregroundColor(ColorParser.parse(node.modifiers?.color ?? "#000000"))
                    .fontWeight(parseWeight(node.modifiers?.font))
                    .minimumScaleFactor(0.6)
                    .lineLimit(node.modifiers?.maxLines)
            }
        case "icon":
            applyModifiers(node.modifiers, isRoot: isRoot) {
                Image(systemName: parseIconName(node.content))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(ColorParser.parse(node.modifiers?.color ?? "#000000"))
                    .frame(
                        width: node.modifiers?.fontSize ?? 24,
                        height: node.modifiers?.fontSize ?? 24
                    )
            }
        case "image":
            applyModifiers(node.modifiers, isRoot: isRoot) {
                if let path = node.content, path.hasPrefix("file://") {
                    let realPath = String(path.dropFirst(7))
                    if let uiImage = UIImage(contentsOfFile: realPath) {
                         Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                         Color.gray.opacity(0.5)
                            .overlay(Text("ERR").font(.caption))
                    }
                } else {
                    Color.gray.opacity(0.3)
                }
            }
        case "spacer":
            // Support fixed-size spacers (flex: 0 with width/height)
            if let w = node.modifiers?.width, let h = node.modifiers?.height {
                Rectangle().fill(Color.clear).frame(width: w, height: h)
            } else if let w = node.modifiers?.width {
                Rectangle().fill(Color.clear).frame(width: w)
            } else if let h = node.modifiers?.height {
                Rectangle().fill(Color.clear).frame(height: h)
            } else {
                Spacer()
            }
        default:
            EmptyView()
        }
    }
    
    @ViewBuilder
    private func renderChildren(_ children: [SASUPNode]?) -> some View {
        if let children = children {
            ForEach(children.indices, id: \.self) { index in
                UniversalWidgetView(node: children[index], isRoot: false)
            }
        }
    }
    
    // MARK: - Modifiers Engine (The "Premium" Look)
    
    private func applyModifiers<Content: View>(_ modifiers: SASUPModifiers?, isRoot: Bool = false, @ViewBuilder content: () -> Content) -> some View {
        content()
            // Padding should be applied INSIDE elements for better containment
            .padding(modifiers?.padding?.toEdgeInsets() ?? EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            .frame(
                width: modifiers?.width.map { CGFloat($0) },
                height: modifiers?.height.map { CGFloat($0) }
            )
            .frame(
                maxWidth: isRoot ? .infinity : (modifiers?.flex == 1 ? .infinity : nil),
                maxHeight: isRoot ? .infinity : (modifiers?.flex == 1 ? .infinity : nil),
                alignment: parseAlignment(modifiers?.alignment)
            )
            .background(parseBackground(modifiers?.background))
            .cornerRadius(modifiers?.cornerRadius ?? 0)
            // If it's a root container, we ensure it doesn't clip its own glass effects
            .clipped(antialiased: true)
    }
    
    private func parseAlignment(_ align: String?) -> Alignment {
        switch align {
        case "center": return .center
        case "leading": return .leading
        case "trailing": return .trailing
        case "spaceBetween", "spaceAround", "spaceEvenly": return .center // Containers handle this internally
        default: return .center
        }
    }
    
    @ViewBuilder
    private func parseBackground(_ bg: String?) -> some View {
        if let bg = bg {
            if bg == "glass" {
                 // Premium Feature: Glassmorphism
                 Rectangle()
                    .fill(.ultraThinMaterial)
            } else if bg.contains("gradient") {
                 // Premium Feature: Gradient
                 // Parse: linear-gradient(...) -> Extract hex codes
                 let colors = extractColors(from: bg)
                 LinearGradient(
                    gradient: Gradient(colors: colors.isEmpty ? [.purple, .blue] : colors),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                 )
            } else {
                ColorParser.parse(bg)
            }
        } else {
            Color.clear
        }
    }
    
    private func extractColors(from input: String) -> [Color] {
        // Regex for #RRGGBB or #RRGGBBAA (6 or 8 hex digits)
        let regex = try! NSRegularExpression(pattern: "#[a-fA-F0-9]{6,8}")
        let results = regex.matches(in: input, range: NSRange(input.startIndex..., in: input))
        return results.map {
            let hex = String(input[Range($0.range, in: input)!])
            return ColorParser.parse(hex)
        }
    }
    
    // MARK: - Helpers
    
    private func parseWeight(_ font: String?) -> Font.Weight {
        switch font {
        case "bold": return .bold
        case "semibold": return .semibold
        case "light": return .light
        default: return .regular
        }
    }
    
    // Minimal Icon Mapper
    private func parseIconName(_ name: String?) -> String {
        switch name {
        case "moon.stars.fill": return "moon.stars.fill"
        case "sun.max.fill": return "sun.max.fill"
        case "cloud.fill": return "cloud.fill"
        case "cloud.sun.fill": return "cloud.sun.fill"
        case "location.fill": return "location.fill"
        case "drop.fill": return "drop.fill"
        case "wind": return "wind"
        case "thermometer.medium": return "thermometer.medium"
        case "arrow.clockwise": return "arrow.clockwise"
        case "arrow.up": return "arrow.up"
        case "arrow.down": return "arrow.down"
        default: return "questionmark.circle"
        }
    }
    
    private func parseHorizontalAlignment(_ align: String?) -> HorizontalAlignment {
        switch align {
        case "center": return .center
        case "end": return .trailing
        default: return .leading
        }
    }
    
    private func parseVerticalAlignment(_ align: String?) -> VerticalAlignment {
         switch align {
        case "center": return .center
        case "end": return .bottom
        default: return .top
        }
    }
    
    private func parseFont(_ mods: SASUPModifiers?) -> Font {
        if let size = mods?.fontSize {
            // Custom Size
            return .system(size: size, weight: parseWeight(mods?.font), design: .rounded)
        }
        
        switch mods?.font {
        case "title": return .title.bold()
        case "subtitle": return .headline // Apple style
        case "caption": return .caption
        default: return .body
        }
    }
}
