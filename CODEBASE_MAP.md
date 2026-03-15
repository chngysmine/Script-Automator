# CODEBASE MAP — Script Automator

> Last Updated: 2026-03-08 | Audit: 100% codebase read
> Architecture: Flutter + Native (QuickJS/JSC) + iOS WidgetKit + Android Glance
> **Overall Completion: ~80%** (Pha 1: 100%, Pha 2: 100%, Pha 3: 45%, Pha 4: 25%)

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
| `presentation/pages/dashboard_page.dart` | Main dashboard | ⚠️ Dock index 3,4 → blank screen |
| `presentation/pages/liquid_splash_page.dart` | Splash animation | ✅ STABLE |
| `presentation/pages/gallery_page.dart` (716 lines) | Script store + import | ✅ STABLE |
| `presentation/pages/settings_page.dart` | AI key config | ✅ STABLE |
| `presentation/widgets/liquid_bento_card.dart` | Script card | ⚠️ Glass blur bị override bởi opaque gradient |
| `presentation/widgets/staggered_script_grid.dart` | Bento grid layout | ✅ STABLE |
| `presentation/widgets/glass_dock.dart` | Bottom navigation | ✅ STABLE (logic ok, 2 tabs thiếu target) |
| `presentation/widgets/glass_drawer.dart` | Side drawer | ⚠️ Text gần vô hình (white-on-dark), menu items không navigate |
| `presentation/widgets/liquid_search_bar.dart` | Search bar | 🔴 **FAKE** — không có TextField, chỉ là Text tĩnh |
| `presentation/widgets/liquid_hero_section.dart` (290 lines) | Hero card | 🔴 **DEAD CODE** — không import/sử dụng |

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
| `data/services/gemini_service.dart` | Gemini API | ⚠️ model `gemini-pro` deprecated |
| `data/services/ollama_service.dart` | Ollama local | ✅ STABLE |
| `presentation/overlay/ai_assistant_overlay.dart` | AI chat overlay | 🔴 **DEAD CODE** — không import/sử dụng |

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
| BUG-04 | ⚠️ MEDIUM | `gemini_service.dart` | 21 | Model `gemini-pro` deprecated |
| BUG-05 | ✅ FIXED | `UniversalWidgetView.swift` | 61 | Đã xóa `.lineLimit(1)` trên mọi Text (Chunk 3) |
| BUG-06 | ✅ FIXED | `GlanceJsonParser.kt` | 40-41 | Đã sửa casting `Alignment.Horizontal` và `Alignment.Vertical` (Chunk 3) |
| BUG-07 | ⚠️ MEDIUM | `liquid_search_bar.dart` | — | SearchBar không có TextField (decorative only) |
| BUG-08 | ⚠️ MEDIUM | `dashboard_page.dart` | — | Dock index 3, 4 → blank screen |
| BUG-09 | ⚠️ LOW | `glass_drawer.dart` | — | Text dùng `textPrimary` (white) trên dark bg → gần vô hình |
| BUG-10 | ✅ FIXED | `syntax_highlighter.dart` | — | One Light palette applied (Chunk 1) |

## 🗑️ DEAD CODE REGISTRY

| File | Lines | Lý do |
|------|-------|-------|
| `ai_assistant_overlay.dart` | 63 | Không import ở bất kỳ đâu |
| `liquid_hero_section.dart` | 290 | Không import ở bất kỳ đâu |

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

### ✅ Ưu tiên 1: Editor — DONE (Chunk 1)
1. ~~BẬT LẠI syntax highlighting (BUG-02)~~ ✅
2. ~~Đổi palette SyntaxHighlighter → One Light (BUG-10)~~ ✅
3. ~~Verify rendering alignment~~ ✅
4. ~~Console BackdropFilter gây blue rect~~ ✅
5. ~~SnackBar đè console~~ ✅
6. ~~ScriptSuccessOverlay~~ ✅ removed

### ✅ Ưu tiên 2: Storage — DONE (Chunk 2)
4. ~~Sửa App Group ID (BUG-01)~~ ✅
5. ~~Thêm WidgetsBindingObserver (BUG-03)~~ ✅

### ✅ Ưu tiên 3: Widget Rendering — DONE (Chunk 3)
6. ~~Sửa lineLimit(1) (BUG-05)~~ ✅
7. ~~Sửa alignment API (BUG-06)~~ ✅
8. ~~Thêm logic deleteWidgetUI để xóa Widget cũ khi Script lỗi/trống~~ ✅

### Ưu tiên 4: Dashboard Polish
8. SearchBar thật (BUG-07)
9. Dock placeholder (BUG-08)
10. Drawer text color (BUG-09)

### Ưu tiên 5: AI + Cleanup
11. Update model name (BUG-04)
12. Remove dead code
