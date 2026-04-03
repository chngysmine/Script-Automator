# CODEBASE MAP — Script Automator

> Last Updated: 2026-04-03 | Audit: 100% codebase verified
> Architecture: Flutter + Native (QuickJS/JSC) + iOS WidgetKit + Android Glance
> **Overall Completion: ~82%** (Pha 1-7: Done, Pha 8: 85%, Pha 9: 70%, Pha 10: 15%)

## Data Flow Diagram

```
User Input (Editor)
    │
    ▼
┌─────────────────────┐
│  CodeForgeController │ ← Rope data structure for O(log N) edits
│  (ChangeNotifier)    │ ← Ghost Text AI (Gemini/Ollama) — NOT WORKING (model deprecated)
└──────────┬──────────┘
           │ setText() / insert()
           ▼
┌─────────────────────┐      ┌──────────────────┐
│  ScriptRepository   │─────→│ WidgetRegistry   │ (SQLite, App Group)
│  (fpdart Either)    │      │ Service           │
└──────────┬──────────┘      └──────────────────┘
           │ saveScript()
           ▼
┌─────────────────────┐
│  ScriptLocalData    │ ← Hive CE LazyBox (AES-256 encrypted)
│  Source (Dual-Store) │ ← Metadata Box + Content Box (separate)
│  + Mutex Lock        │ ← ⚠️ NO flush on app background → DATA LOSS
└─────────────────────┘

Script Execution:
┌─────────────────────┐
│  ScriptRunnerService│ ← Background Isolate with Supervisor
│  (Main Isolate)     │ ← 30s timeout, auto-restart on crash
└──────────┬──────────┘
           │ Isolate.spawn()
           ▼
┌─────────────────────┐
│  JS Engine Isolate  │ ← QuickJS (Android/Desktop) / JSC (iOS)
│  + VFS Bindings     │ ← print(), renderWidget(), writeFile()
│  + setTimeout poly  │
└──────────┬──────────┘
           │ renderWidget(jsonString)
           ▼
┌──────────────────────────┐
│ HeadlessWidgetRendering  │ ← Native JSON Passthrough (preferred)
│ Service                  │ ← PNG Rasterization (fallback)
│ → saves to App Group     │ ← sasup_ui_{scriptId}.json
└──────────┬───────────────┘
           │ MethodChannel: reloadTimelines
           ▼
┌───────────────────────────────────────────────┐
│ iOS: UniversalWidgetView                      │ ← ⚠️ lineLimit(1) hardcoded
│ iOS: ScriptDatabase                           │ ← 🔴 WRONG App Group ID!
│ Android: GlanceJsonParser                     │ ← ⚠️ alignment API sai
└───────────────────────────────────────────────┘
```

---

## Module Map — With Real Status

### `lib/core/` — Shared Infrastructure
| File | Purpose | Status |
|------|---------|--------|
| `data_structures/rope.dart` | Rope tree for editor text | ✅ STABLE |
| `theme/liquid_theme.dart` | Design system tokens | ✅ STABLE |
| `theme/liquid_animations.dart` | Shared animations | ✅ STABLE |
| `theme/liquid_page_route.dart` | Custom route transitions | ✅ STABLE |
| `theme/liquid_typography.dart` | Font definitions | ✅ STABLE |
| `ui/liquid_glass.dart` | Glass container widget | ✅ STABLE |
| `ui/liquid_button.dart` | Branded button | ✅ STABLE |

---

### `lib/features/script_management/` — Data Layer
| File | Purpose | Status |
|------|---------|--------|
| `data/datasources/script_local_data_source.dart` | Hive CE dual-store | ✅ STABLE |
| `data/models/script_model.dart` | Hive model (typeId: 0) | ✅ STABLE |
| `data/repositories/script_repository_impl.dart` | Repository + Widget sync | ✅ STABLE |
| `data/services/encryption_service.dart` | AES-256 key management | ✅ STABLE |
| `data/services/virtual_file_system_service.dart` | VFS chroot jail | ✅ STABLE |

---

### `lib/features/editor/` — Code Editor
| File | Purpose | Status |
|------|---------|--------|
| `domain/code_forge_controller.dart` | Rope controller + AI ghost text | ⚠️ Ghost text gọi model deprecated |
| `presentation/pages/editor_page.dart` | Main editor UI | ✅ STABLE (Fixed in Chunk 1 — transparent TextField, console opaque, SnackBar removed) |
| `presentation/syntax_highlighter.dart` | Token-based syntax colors | ✅ STABLE (Fixed in Chunk 1 — One Light palette) |
| `presentation/painters/viewport_aware_painter.dart` | CustomPaint renderer | ✅ STABLE (Fixed in Chunk 1 — paint enabled) |
| `presentation/widgets/keyboard_toolbar.dart` | Key insertion bar | ✅ STABLE |
| `presentation/widgets/console_log_widget.dart` | Console output | ✅ STABLE |
| `presentation/widgets/editor_app_bar.dart` | Top bar (glass blur) | ✅ STABLE |

---

### `lib/features/dashboard/` — Home Screen
| File | Purpose | Status |
|------|---------|--------|
| `presentation/pages/dashboard_page.dart` | Main dashboard | ✅ STABLE (Chunk 4.1 - MeshGradient, Routed Profile) |
| `presentation/pages/liquid_splash_page.dart` | Splash animation | ✅ STABLE |
| `presentation/pages/gallery_page.dart` | Script store + import | ✅ STABLE (Chunk 4.1 - MeshGradient) |
| `presentation/pages/profile_page.dart` | Gamification UI | ✅ STABLE (Chunk 4.1 - Developer Dojo, XP Bar, Gacha) |
| `presentation/pages/settings_page.dart` | AI key config | ✅ STABLE |
| `presentation/widgets/liquid_bento_card.dart` | Script card | ✅ STABLE (Chunk 4.1 - Bento Grid 2.0, Spring physics, 40% Image base) |
| `presentation/widgets/staggered_script_grid.dart` | Bento grid layout | ✅ STABLE (Recreated 2026-03-22 — was deleted during Liquid Glass refactor) |
| `presentation/widgets/glass_dock.dart` | Bottom navigation | ✅ STABLE (logic ok, 3 tabs mapped) |
| `presentation/widgets/glass_drawer.dart` | Side drawer | ⚠️ Text gần vô hình (white-on-dark), menu items không navigate |
| `presentation/widgets/liquid_search_bar.dart` | AI Omnibar | ✅ STABLE (Chunk 4.1 - Search Overlay, Glow AI Icon) |
| `presentation/widgets/liquid_hero_section.dart` | Hero card | 🔴 **DEAD CODE** — không import/sử dụng |

---

### `lib/features/script_engine/` — JS Execution
| File | Purpose | Status |
|------|---------|--------|
| `domain/script_runner_service.dart` | Isolate supervisor | ✅ STABLE |
| `data/engines/quickjs_engine.dart` | QuickJS FFI | ✅ STABLE |
| `data/engines/jsc_engine.dart` | JavaScriptCore FFI | ✅ STABLE |

---

### `lib/features/widget_renderer/` — Widget Pipeline
| File | Purpose | Status |
|------|---------|--------|
| `domain/services/headless_widget_rendering_service.dart` | JSON + PNG render | ✅ STABLE |
| `data/services/widget_registry_service.dart` | SQLite sidecar DB | ✅ STABLE (Flutter side) |

---

### `lib/features/ai_integration/` — AI Features
| File | Purpose | Status |
|------|---------|--------|
| `data/services/gemini_service.dart` | Gemini API | ✅ STABLE (Chunk 5 - Model updated to `gemini-2.0-flash`) |
| `data/services/ollama_service.dart` | Ollama local | ✅ STABLE |
| `presentation/overlay/ai_assistant_overlay.dart` | AI chat overlay | 🔴 **REMOVED** — dead code deleted |

---

### Native Widget Extensions
| File | Purpose | Status |
|------|---------|--------|
| `ios/.../UniversalWidgetView.swift` | SwiftUI renderer | ✅ STABLE (Fixed in Chunk 3 - Responsive Implementation) |
| `ios/.../ScriptAutomatorWidget.swift` | Widget entry point | ✅ STABLE |
| `ios/.../ScriptDatabase.swift` | SQLite reader | ✅ STABLE (Fixed in Chunk 2 — App Group ID) |
| `ios/.../ScriptSelectionIntent.swift` | Widget config intent | ✅ STABLE |
| `android/.../GlanceJsonParser.kt` | Glance renderer | ✅ STABLE (Fixed in Chunk 3 - Responsive Implementation) |
| `android/.../ScriptAutomatorWidget.kt` | Widget entry | ✅ STABLE |

---

## 🔴 BUG REGISTRY

| ID | Severity | File | Line | Mô tả |
|----|----------|------|------|--------|
| BUG-01 | ✅ FIXED | `ScriptDatabase.swift` | 14 | App Group ID sai → Sửa thành `group.com.antigravity.script_automator` (Chunk 2) |
| BUG-02 | ✅ FIXED | `viewport_aware_painter.dart` | — | Syntax highlighting ENABLED + selection highlight (Chunk 1) |
| BUG-03 | ✅ FIXED | `main.dart` | — | Thêm `WidgetsBindingObserver` để flush Hive khi background (Chunk 2) |
| BUG-04 | ✅ FIXED | `gemini_service.dart` | 21 | Model `gemini-pro` deprecated (Chunk 5) |
| BUG-05 | ✅ FIXED | `UniversalWidgetView.swift` | 61 | Đã xóa `.lineLimit(1)` trên mọi Text (Chunk 3) |
| BUG-06 | ✅ FIXED | `GlanceJsonParser.kt` | 40-41 | Đã sửa casting `Alignment.Horizontal` và `Alignment.Vertical` (Chunk 3) |
| BUG-07 | ✅ FIXED | `liquid_search_bar.dart` | — | Đã refactor thành AI Omnibar overlay (Chunk 4.1) |
| BUG-08 | ✅ FIXED | `dashboard_page.dart` | — | Đã route index 4 vào ProfilePage Gamification (Chunk 4.1) |
| BUG-09 | ✅ FIXED | `glass_drawer.dart` | — | Đã route đủ Explore(1) và Profile(4) (Audit Fix) |
| BUG-10 | ✅ FIXED | `syntax_highlighter.dart` | — | One Light palette applied (Chunk 1) |

## 🗑️ DEAD CODE REGISTRY (Cleaned up in Chunk 5)

| File | Lines | Lý do |
|------|-------|-------|
| `ai_assistant_overlay.dart` | 63 | ✅ Đã xóa (Chunk 5) |
| `liquid_hero_section.dart` | 290 | ✅ Đã xóa (Chunk 5) |

---

## ⛔ DO NOT MODIFY (Production-Stable)

> These files are tested and working correctly. Any modification requires explicit approval:

1. `lib/core/data_structures/rope.dart`
2. `lib/features/script_management/data/datasources/script_local_data_source.dart`
3. `lib/features/script_management/data/models/script_model.dart` + `.g.dart`
4. `lib/features/script_engine/data/engines/quickjs_engine.dart`
5. `lib/features/script_engine/data/engines/jsc_engine.dart`
6. `lib/features/script_engine/domain/script_runner_service.dart`
7. `lib/features/widget_renderer/domain/entities/*` (all SASUP models)
8. `test/dual_store_test.dart`
9. `test/core/data_structures/rope_test.dart`

---

## 📋 FIX ROADMAP (Thứ tự ưu tiên)

### ✅ Pha 1-5: Core Platform — DONE
- ~~Editor (syntax highlight, console, viewport paint)~~ ✅
- ~~Storage (App Group, Hive flush, encryption)~~ ✅
- ~~Widget Rendering (responsive, JSON passthrough)~~ ✅
- ~~Dashboard (Bento grid, search, profile routing)~~ ✅
- ~~AI + Cleanup (Gemini 2.0, dead code removal)~~ ✅
- ~~StaggeredScriptGrid rebuild~~ ✅ (Fixed 2026-03-22)

### ✅ Pha 6: System API Bridge — 🟢 Hoàn thành

### ✅ Pha 7: Widget Families — 🟢 Hoàn thành
- iOS: systemSmall/Medium/Large/ExtraLarge
- Android: Glance responsive sizing
- Interactive Widget (iOS 17+ / Android 14+)

### Pha 8: Community Gallery — TODO (3-4 tuần)
- GitHub repo `script-automator-community/gallery`
- Gallery UI (categories, ratings, reviews)
- User identity, publishing flow, versioning

### Pha 9: Gamification — TODO (1-2 tuần)
- XP system, achievement unlocks, streak tracking
- Daily Snippet Drop (live from gallery)

### Pha 10: Production Polish — TODO (2-3 tuần)
- Siri Shortcuts, in-app docs, onboarding
- Error reporting, analytics, CI/CD
- i18n, accessibility, App Store submission
