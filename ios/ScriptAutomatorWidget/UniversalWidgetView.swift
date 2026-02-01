import SwiftUI

struct UniversalWidgetView: View {
    let node: SASUPNode
    
    var body: some View {
        renderNode(node)
    }
    
    @ViewBuilder
    private func renderNode(_ node: SASUPNode) -> some View {
        switch node.type {
        case "column":
            applyModifiers(node.modifiers) {
                VStack(alignment: parseHorizontalAlignment(node.modifiers?.alignment), spacing: 0) {
                    renderChildren(node.children)
                }
            }
        case "row":
            applyModifiers(node.modifiers) {
                HStack(alignment: parseVerticalAlignment(node.modifiers?.alignment), spacing: 0) {
                    renderChildren(node.children)
                }
            }
        case "stack":
             applyModifiers(node.modifiers) {
                ZStack(alignment: .center) { // Default center, need generic alignment parser
                    renderChildren(node.children)
                }
            }
        case "text":
            applyModifiers(node.modifiers) {
                Text(node.content ?? "")
                    .font(parseFont(node.modifiers?.font))
                    .foregroundColor(ColorParser.parse(node.modifiers?.color ?? "#000000"))
            }
        case "image":
            applyModifiers(node.modifiers) {
                // Image handling: Real logic to read from App Group file
                if let path = node.content, path.hasPrefix("file://") {
                    // Remove "file://" prefix to get absolute path
                    let realPath = String(path.dropFirst(7))
                    if let uiImage = UIImage(contentsOfFile: realPath) {
                         Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                         // Failed load
                         Color.gray.opacity(0.5)
                            .overlay(Text("ERR").font(.caption))
                    }
                } else {
                    Color.gray.opacity(0.3)
                }
            }
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
                UniversalWidgetView(node: children[index])
            }
        }
    }
    
    // MARK: - Modifiers Engine (The "Premium" Look)
    
    private func applyModifiers<Content: View>(_ modifiers: SASUPModifiers?, @ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(modifiers?.padding?.toEdgeInsets() ?? EdgeInsets())
            .frame(
                width: modifiers?.width,
                height: modifiers?.height
            )
            .background(parseBackground(modifiers?.background))
            .cornerRadius(modifiers?.cornerRadius ?? 0)
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
                    colors: colors.isEmpty ? [.purple, .blue] : colors,
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
        let regex = try! NSRegularExpression(pattern: "#[a-fA-F0-9]{6}")
        let results = regex.matches(in: input, range: NSRange(input.startIndex..., in: input))
        return results.map {
            let hex = String(input[Range($0.range, in: input)!])
            return ColorParser.parse(hex)
        }
    }
    
    // MARK: - Helpers
    
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
    
    private func parseFont(_ name: String?) -> Font {
        switch name {
        case "title": return .title.bold()
        case "subtitle": return .headline // Apple style
        case "caption": return .caption
        default: return .body
        }
    }
}
