---
description: UI Design Standards for Script Automator (2026 Liquid Glass Edition)
---

# UI Design Standards — Script Automator

## 1. Color Mode

- **MANDATORY: Light Mode only** for all screens.
- `LiquidTheme.lightTheme` is the only allowed `ThemeData`.
- No dark-mode backgrounds (`0xFF0F172A`, `0xFF1E293B`) outside of the Console widget.

## 2. Editor Standards

### Color Scheme
- **Theme: "One Light" / "GitHub Light"** — professional, low-contrast pastel tones.
- Keywords: `#A626A4` (purple)
- Strings: `#50A14F` (green)
- Numbers: `#986801` (amber)
- Comments: `#A0A1A7` (gray, italic)
- Background: White with `0.85` opacity glass overlay
- Gutter: `Color(0xFFF1F5F9)` (Slate 100) with `0.6` opacity — **NOT opaque**

### Banned Colors
- `#00FF00` / neon green — NEVER use
- Any `0xFF0..` full-saturation primary on editor text

### Toolbar
- Keyboard toolbar MUST float above the virtual keyboard (`MediaQuery.of(context).viewInsets.bottom`).
- Toolbar height: `44dp`, background: glass blur `sigmaX=12, sigmaY=12`.
- Must include: `Tab`, `{`, `(`, `[`, `"`, `;`, Undo, Redo buttons.

## 3. Dashboard Card Standards

### GlassContainer Specification
- `BackdropFilter` with `sigma: 18.0` on both X and Y axes.
- Overlay: white at `10%–30%` opacity depending on card size.
- Border: `Border.all(color: Colors.white.withOpacity(0.5), width: 0.5)`
- Corner radius: `32dp` for large cards, `24dp` for small cards.
- Shadow: `BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 10))`

### Bento Grid
- Hero card: full-width, 280dp height
- Pair cards: 2-column, aspect ratio 0.85
- Single leftover: full-width, 160dp height

## 4. AI Assistant

- **Ghost Text** (inline, semi-transparent suggestion in editor) is the PRIMARY interface.
- AI chat/overlay MUST NOT cover the full screen.
- If a bottom sheet is used, it must be:
  - Max height: `40%` of screen
  - `BackdropFilter` sigma 15x15
  - Background: `LiquidTheme.darkBackground.withOpacity(0.85)`

## 5. Console

- Console is the ONLY component allowed to use dark background.
- Background: `Color(0xFF0F172A)` at 85% opacity with glass blur.
- Text: monospace `13sp`, colors per log level:
  - INFO: `#9CA3AF`
  - WARNING: `#F59E0B`
  - ERROR: `#EF4444`
  - SUCCESS: `#10B981`

## 6. DO NOT MODIFY (Working Features)

> These files are production-stable. DO NOT refactor or restructure:

- `lib/core/data_structures/rope.dart` — Rope data structure (correct, tested)
- `lib/features/script_management/data/datasources/script_local_data_source.dart` — Dual-store architecture (tested with rollback)
- `lib/features/script_management/data/models/script_model.dart` — Hive model
- `lib/features/script_engine/data/engines/quickjs_engine.dart` — QuickJS FFI bridge
- `lib/features/script_engine/data/engines/jsc_engine.dart` — JSC FFI bridge
- `lib/features/widget_renderer/domain/entities/` — All SASUP entity models
- `test/dual_store_test.dart` — Storage integration test
