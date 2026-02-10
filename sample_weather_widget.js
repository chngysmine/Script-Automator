/**
 * 🌤️ Beautiful Weather Widget - Clean & Modern
 * No debug lines, perfect spacing, gorgeous design
 */

function getWeatherData() {
    const cities = ["Hanoi", "Saigon", "Da Nang"];
    const city = cities[Math.floor(Math.random() * cities.length)];
    const temp = 24 + Math.floor(Math.random() * 8);

    return {
        city: city,
        temp: temp,
        condition: "Mostly Clear",
        icon: "moon.stars.fill",
        humidity: 70 + Math.floor(Math.random() * 15),
        wind: 8 + Math.floor(Math.random() * 10),
        uvIndex: Math.floor(Math.random() * 8),
        updated: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    };
}

function buildWeatherUI(data) {
    return {
        type: "container",
        modifiers: {
            background: "linear-gradient(180deg, #2E3440, #3B4252, #434C5E)",
            cornerRadius: 32,
            padding: { left: 20, top: 20, right: 20, bottom: 20 }
        },
        children: [
            // Top Bar
            {
                type: "row",
                modifiers: { alignment: "spaceBetween" },
                children: [
                    {
                        type: "row",
                        modifiers: { spacing: 6 },
                        children: [
                            {
                                type: "icon",
                                content: "location.fill",
                                modifiers: { fontSize: 16, color: "#88C0D0" }
                            },
                            {
                                type: "text",
                                content: data.city,
                                modifiers: {
                                    color: "#ECEFF4",
                                    fontSize: 18,
                                    font: "semibold"
                                }
                            }
                        ]
                    },
                    {
                        type: "text",
                        content: data.updated,
                        modifiers: { color: "#88ECEFF4", fontSize: 10 }
                    }
                ]
            },

            { type: "spacer", modifiers: { height: 16 } },

            // Weather Icon & Temp
            {
                type: "column",
                modifiers: { alignment: "center", spacing: 8 },
                children: [
                    {
                        type: "icon",
                        content: data.icon,
                        modifiers: { fontSize: 64, color: "#EBCB8B" }
                    },
                    {
                        type: "text",
                        content: data.temp + "°",
                        modifiers: {
                            color: "#ECEFF4",
                            fontSize: 54,
                            font: "bold"
                        }
                    },
                    {
                        type: "text",
                        content: data.condition,
                        modifiers: { color: "#D8DEE9", fontSize: 16 }
                    }
                ]
            },

            { type: "spacer", modifiers: { height: 20 } },

            // Info Grid
            {
                type: "column",
                modifiers: { spacing: 12 },
                children: [
                    {
                        type: "row",
                        modifiers: { alignment: "spaceEvenly", spacing: 12 },
                        children: [
                            buildStatCard("drop.fill", data.humidity + "%", "Humidity", "#88C0D0"),
                            buildStatCard("wind", data.wind + " km/h", "Wind", "#A3BE8C")
                        ]
                    },
                    {
                        type: "row",
                        modifiers: { alignment: "spaceEvenly", spacing: 12 },
                        children: [
                            buildStatCard("sun.max.fill", "UV " + data.uvIndex, "UV Index", "#EBCB8B"),
                            buildStatCard("thermometer.medium", "32°", "High", "#BF616A")
                        ]
                    }
                ]
            }
        ]
    };
}

function buildStatCard(icon, value, label, iconColor) {
    return {
        type: "container",
        modifiers: {
            background: "#28ECEFF4",
            cornerRadius: 18,
            padding: { left: 16, top: 14, right: 16, bottom: 14 },
            flex: 1
        },
        children: [
            {
                type: "row",
                modifiers: { alignment: "leading", spacing: 12 },
                children: [
                    {
                        type: "icon",
                        content: icon,
                        modifiers: { fontSize: 22, color: iconColor }
                    },
                    {
                        type: "column",
                        modifiers: { spacing: 2 },
                        children: [
                            {
                                type: "text",
                                content: value,
                                modifiers: {
                                    color: "#ECEFF4",
                                    fontSize: 15,
                                    fontWeight: "semibold"
                                }
                            },
                            {
                                type: "text",
                                content: label,
                                modifiers: { color: "#BBECEFF4", fontSize: 11 }
                            }
                        ]
                    }
                ]
            }
        ]
    };
}

// Execute
print("Starting Beautiful Weather Widget...");
const data = getWeatherData();
const ui = buildWeatherUI(data);

renderWidget(JSON.stringify(ui));
print("Done!");