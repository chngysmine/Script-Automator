# Script Automator

> Write JavaScript, run it in a sandboxed engine, and ship it as native home-screen widgets on iOS and Android.

## Architecture

- **Flutter 3.47 / Dart 3.13** — UI (Liquid Glass design system)
- **QuickJS** (Android) / **JavaScriptCore** (iOS) — JS execution in a background isolate
- **WidgetKit** (iOS) / **Glance** (Android) — native widgets fed by the SASUP JSON protocol
- **Hive CE** — encrypted local store; **Firestore** sync for signed-in users
- **Firebase** — Auth, Firestore, Storage, Functions, Crashlytics, App Check, **AI Logic (Gemini)**
- **AI** — Gemini by default (`gemini-3.8-flash` chat, `gemini-3.5-flash-lite` ghost text, configurable remotely); OpenAI (own key) and Ollama as advanced options

Details: [CODEBASE_MAP.md](CODEBASE_MAP.md) · [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md)

## Getting started

```bash
flutter pub get
flutter run                      # iOS 18+ / Android (QuickJS builds via CMake)
```

Firebase config files (`lib/firebase_options.dart`, `GoogleService-Info.plist`,
`google-services.json`, `firebase.json`) are git-ignored; regenerate with
`flutterfire configure --project=script-automator-bdbef`.

Build flags (all optional):

| `--dart-define` | Effect |
|---|---|
| `ENABLE_APP_CHECK=true` | Activate App Check (Play Integrity / App Attest; debug provider in debug builds). Enable only after providers are registered in the console. |
| `APP_CHECK_DEBUG_TOKEN=<uuid>` | Pin the debug token you registered |
| `OPENAI_API_KEY=sk-...` | Local development only; users enter their own key in-app |

## Tests

```bash
flutter analyze && flutter test
flutter test integration_test/js_engine_test.dart -d <device>     # native engines
flutter test integration_test/gemini_smoke_test.dart -d <device>  # real Gemini call
cd functions && npm install && npm test                           # rules + functions (emulators, JDK 21+)
```

## Backend deploy

```bash
firebase deploy --only firestore:indexes
firebase deploy --only functions:setAdminRole,functions:banUser   # list functions explicitly
firebase deploy --only firestore:rules,storage
```

Offline demo fallback (Firebase emulators): see PROJECT_CONTEXT.md §9.

## License

Private — All rights reserved.
