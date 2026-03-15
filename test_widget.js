var ui = {
    type: "container",
    modifiers: {
        padding: { value: 16 },
        background: "glass", // iOS ultraThinMaterial test
        cornerRadius: 24,
        flex: 1, // Fill entire widget container
        alignment: "center"
    },
    children: [
        {
            type: "column",
            modifiers: { spacing: 12, alignment: "start" },
            children: [
                {
                    type: "row",
                    modifiers: { spacing: 8, alignment: "center" },
                    children: [
                        { type: "icon", content: "sun.max.fill", modifiers: { color: "#FFD700", fontSize: 24 } },
                        { type: "text", content: "Good Morning!", modifiers: { font: "bold", fontSize: 18, color: "#FFFFFF" } }
                    ]
                },
                {
                    type: "text",
                    // Long text to test responsive lineLimit and scaling
                    content: "This is a very long text to test the dynamic scaling and responsive multi-line limit on the iOS and Android widget architecture.",
                    modifiers: {
                        color: "#E2E8F0",
                        fontSize: 14,
                        maxLines: 4 // Test max lines
                    }
                },
                {
                    type: "row",
                    modifiers: { flex: 1, spacing: 10, alignment: "center" },
                    children: [
                        {
                            type: "container",
                            modifiers: { padding: { value: 8 }, background: "#334155", cornerRadius: 12, flex: 1, alignment: "center" },
                            children: [
                                { type: "text", content: "25°C", modifiers: { font: "bold", fontSize: 16, color: "#FFFFFF", alignment: "center" } },
                                { type: "text", content: "Sunny", modifiers: { fontSize: 12, color: "#94A3B8", alignment: "center" } }
                            ]
                        },
                        {
                            type: "container",
                            modifiers: { padding: { value: 8 }, background: "#334155", cornerRadius: 12, flex: 1, alignment: "center" },
                            children: [
                                { type: "text", content: "AQI 42", modifiers: { font: "bold", fontSize: 16, color: "#4ADE80", alignment: "center" } },
                                { type: "text", content: "Good", modifiers: { fontSize: 12, color: "#94A3B8", alignment: "center" } }
                            ]
                        }
                    ]
                }
            ]
        }
    ]
};

print("Rendering Responsive Widget...");
renderWidget(JSON.stringify(ui));