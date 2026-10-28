# CODEBASE MAP — Script Automator

> Last updated: 2026-10-27 (SDK upgrade + completion pass)
> Stack: Flutter 3.47 / Dart 3.13 · QuickJS (Android) / JavaScriptCore (iOS) · iOS WidgetKit · Android Glance · Firebase
> See `PROJECT_CONTEXT.md` for schema, rules, deploy and phase status.

## Data flow

```
Editor (CodeForgeController, Rope) ──ghost text──▶ AiService ─▶ Gemini (firebase_ai) | OpenAI (own key) | Ollama
        │ save
        ▼
ScriptRepository ─▶ ScriptLocalDataSource (Hive CE, AES-256, metadata + content boxes)
        │                └▶ FirestoreSyncService ⇄ users/{uid}/scripts (signed-in, non-guest)
        ▼
WidgetRegistryService (SQLite in App Group) ◀── iOS ScriptDatabase.swift / Android Glance
        │
ScriptRunnerService (isolate supervisor, 30s timeout, moderation pre-check)
        └▶ QuickJSEngine | JSCEngine ─renderWidget()─▶ HeadlessWidgetRenderingService ─▶ App Group JSON ─▶ native widgets

Community: PublishScriptSheet ─▶ Storage submissions/{uid}/ + gallery_submissions (pending)
           Admin web approve/reject ─▶ gallery_published + users/{uid}/notifications
           Report ─▶ transaction: script_reports/{scriptId}_{uid} + script_moderation (+1, auto-block) — enforced by firestore.rules
```

## Module map

### `lib/core/`
| Path | Purpose |
|---|---|
| `auth/auth_service.dart` | Google (v7) / Apple / Email / Guest sign-in, account linking (`AccountAlreadyExistsException`), delete account |
| `auth/auth_gate.dart` | Root widget: landing → Login ↔ AppShell, ban enforcement, background `fullSync` |
| `sync/firestore_sync_service.dart` | Hive ⇄ Firestore sync with conflict modes; remote notifications (`parseRemoteNotification`) |
| `sync/sync_retry_queue.dart` | Connectivity-driven retry queue |
| `services/firebase_bootstrap.dart` | `Firebase.initializeApp` + Crashlytics handlers + App Check (opt-in `ENABLE_APP_CHECK`) |
| `services/app_config_service.dart` | `app_config/global` flags + AI model names + report threshold, Hive-cached |
| `services/telemetry_service.dart` | `telemetry_logs`, `user_profiles`, `widget_stats` writes (offline buffer) |
| `security/`, `storage/`, `theme/`, `ui/` | Secure storage, App Group paths, Liquid design system, shared widgets (`staggered_entrance.dart` replaces flutter_staggered_animations) |

### `lib/features/ai_integration/`
| Path | Purpose |
|---|---|
| `domain/ai_service.dart` | Provider router (Gemini default, fallback when selected provider isn't configured) |
| `domain/ai_backend.dart`, `ai_text_client.dart`, `ai_prompts.dart` | Shared interface, testable client contract, prompts |
| `data/clients/firebase_ai_text_client.dart` | Firebase AI Logic (Gemini Developer API) client with error mapping |
| `data/services/gemini_service.dart` | Default provider; models from `AppConfigService` |
| `data/services/openai_service.dart` | Optional, user's own key only (no server proxy) |
| `data/services/ollama_service.dart` | Optional local Ollama (`/api/chat`) |

### `lib/features/dashboard/`
Pages: `app_shell`, `dashboard_page`, `explore_page`, `gallery_page` (import + report), `profile_page`, `settings_page` (account, AI provider, delete account), `notification_page`.
Data: `cloud_gallery_repository.dart` (`gallery_published` read + moderation filter, submit, `reportScript`), `user_preferences_service`, `user_stats_service`, `notification_service`.
Widgets: `publish_script_sheet.dart` (guest blocked), `settings_auth_section.dart` (link Google/Apple/Email, conflicts).

### Other features
| Feature | Key files |
|---|---|
| `editor/` | `code_forge_controller.dart`, `editor_page.dart`, `ai_generate_sheet.dart`, `ai_onboarding_dialog.dart` (provider picker) |
| `script_engine/` | `script_runner_service.dart`, `data/engines/quickjs_engine.dart`, `jsc_engine.dart`, `system_api_handler.dart` |
| `script_management/` | Hive data source, models, repository, VFS, `git_service.dart` (URL import only) |
| `widget_renderer/` | SASUP entities (freezed), headless renderer, SQLite registry |
| `auth/`, `onboarding/`, `docs/` | Login/signup, onboarding, in-app API docs |

### Native
| Path | Purpose |
|---|---|
| `ios/Runner/AppDelegate.swift`, `SceneDelegate.swift` | UIScene lifecycle, implicit engine, BGTask headless runner, widget channel |
| `ios/ScriptAutomatorWidget/` | WidgetKit home + lock-screen widgets (AppIntent config) |
| `android/app/src/main/kotlin/com/js/scriptAutomator/` | Glance widget, JSON parser, WorkManager runner, watchdog |
| `android/app/src/main/cpp/CMakeLists.txt`, `native/` | QuickJS + `quickjs_wrapper.c` → `libscript_engine.so` |

### Backend (`functions/`, rules)
| Path | Purpose |
|---|---|
| `functions/src/index.ts` | `setAdminRole`, `banUser` (prod); `validateSubmissionUpload`, `aggregateMetrics` (emulator / need Owner IAM for prod) |
| `functions/src/auth.ts` | Admin guard |
| `functions/test/` | Rules tests + functions integration tests (emulators) |
| `functions/scripts/` | One-off admin scripts + `seed-emulator.mjs` (excluded from deploy) |
| `firestore.rules`, `storage.rules`, `firestore.indexes.json` | Single source of truth (admin web has no copy) |

## Tests

| Command | Scope |
|---|---|
| `flutter test` | Unit/widget tests (Rope, VFS, dual store, SASUP, AI router, Gemini service, app config, gallery repo) |
| `flutter test integration_test/<file> -d <device>` | `js_engine_test` (native engines), `gemini_smoke_test` (real AI Logic), `scroll_perf_test` (editor) |
| `cd functions && npm test` | Rules (25) + Cloud Functions (4) on emulators — needs JDK 21+ |
| `flutter test integration_test/emulator_demo_test.dart --dart-define=USE_FIREBASE_EMULATOR=true` | Offline demo fallback (emulators running) |
| admin web `npm test`, `npm run test:emulator` | Helpers + end-to-end admin flows |

## Notes
- Files previously marked "do not modify" were touched minimally: `widget_node.dart` (freezed 3 `toJson`), engines (`checkSyntax` returned `"null"`), runner (moderation id from `settings.gallery_id`).
- macOS / web / Windows / Linux folders are scaffolding only (no Firebase config; QuickJS not built).
- `ffigen.yaml` writes reference bindings to `tool/ffigen/`; the runtime uses the hand-maintained bindings.
