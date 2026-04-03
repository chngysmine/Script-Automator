# Script Automator

> Cross-platform automation toolkit powered by JavaScript engines and AI — a Scriptable alternative for iOS + Android.

## Architecture

- **Flutter** (Dart) — UI layer with Liquid Glass 2.0 design system
- **QuickJS** (Android/Desktop) / **JavaScriptCore** (iOS) — JS execution in background isolate
- **WidgetKit** (iOS) / **Glance** (Android) — native home screen widgets
- **SASUP** — JSON-based widget protocol with Native JSON Passthrough rendering
- **Hive CE** — encrypted dual-store (metadata + content) with AES-256
- **Gemini 2.0 Flash** / **Ollama** — AI ghost text completion

## Key Features

- Code editor with Rope data structure, syntax highlighting, and AI ghost text
- Write JavaScript that renders native home screen widgets
- Script execution with 30s timeout, crash recovery, and auto-restart
- Gallery with import from URL (GitHub raw, Pastebin)
- Gamification system (Developer Dojo, XP, Badges)

## Getting Started

```bash
flutter pub get
flutter run
```

## Project Status

See [CODEBASE_MAP.md](CODEBASE_MAP.md) for detailed module status and roadmap.

| Phase | Status |
|---|---|
| Pha 1-5: Core Platform | ✅ Done |
| Pha 6: System API Bridge | 🔲 Planned |
| Pha 7: Widget Families | 🔲 Planned |
| Pha 8: Community Gallery | 🔲 Planned |
| Pha 9: Gamification | 🔲 Planned |
| Pha 10: Production Polish | 🔲 Planned |

## License

Private — All rights reserved.