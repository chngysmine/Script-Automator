# 📋 PROJECT CONTEXT — SCRIPT AUTOMATOR

> **Cập nhật lần cuối:** 2026-05-10T20:40:00+07:00
> **Mục đích file này:** Đây là nguồn sự thật duy nhất (Single Source of Truth) cho mọi cuộc hội thoại AI. Bất kỳ phiên nào mới PHẢI đọc file này trước khi thực hiện bất kỳ thay đổi nào.

---

## 1. TỔNG QUAN DỰ ÁN

**Script Automator** là ứng dụng Flutter cho phép user viết JavaScript scripts, deploy thành native Home Screen Widgets (iOS WidgetKit / Android Glance), và chia sẻ qua cộng đồng.

### Ecosystem gồm 3 projects

| Project | Đường dẫn | Tech Stack |
|---------|-----------|------------|
| **Mobile App** | `Script-Automator/` | Flutter 3.x, Dart 3.x |
| **Admin Panel** | `script-automator-admin-web/` | React + Vite + TypeScript |
| **Community Gallery** | GitHub repo (read-only archive) | JSON index |

### Package Identifier (ĐÃ RENAME — 2026-05-10)

| Platform | Identifier |
|----------|-----------|
| **iOS Bundle ID** | `com.js.scriptAutomator` |
| **iOS Widget Extension** | `com.js.scriptAutomator.ScriptAutomatorWidget` |
| **Android applicationId** | `com.js.scriptAutomator` |
| **Android namespace** | `com.js.scriptAutomator` |
| **macOS Bundle ID** | `com.js.scriptAutomator` |
| **App Group (iOS)** | `group.com.js.scriptAutomator` |
| **Keychain Group (iOS)** | `group.com.js.scriptAutomator` |
| **MethodChannel (widget)** | `com.js.scriptAutomator/widget` |
| **MethodChannel (background)** | `com.js.scriptAutomator/background` |
| **BG Task ID** | `com.js.scriptAutomator.refresh` |

> ⚠️ **LỊCH SỬ:** Trước ngày 2026-05-10, package ID là `com.antigravity.script_automator` / `com.antigravity.scriptAutomator`. Đã rename toàn bộ 28+ files. KHÔNG BAO GIỜ quay lại dùng `antigravity`.

---

## 2. FIREBASE CONFIGURATION

### Project Info

| Key | Value |
|-----|-------|
| **Project Name** | Script Automator |
| **Project ID** | `script-automator-bdbef` |
| **Project Number** | `873767716800` |
| **Blaze Plan** | ✅ Active |
| **Support Email** | `chaunganpenny@gmail.com` |
| **Firebase Region** | Firestore: `asia-southeast1` (Singapore) |

### Registered Apps

| Platform | App ID | Bundle/Package |
|----------|--------|----------------|
| iOS | `1:873767716800:ios:f34fa38821b8ed26882a25` | `com.js.scriptAutomator` |
| Android | `1:873767716800:android:aeb684ad57a36a19882a25` | `com.js.scriptAutomator` |

### Authentication Providers (ĐÃ ENABLE)

| Provider | Status |
|----------|--------|
| Email/Password | ✅ Enabled |
| Google Sign-In | ✅ Enabled |
| Apple Sign-In | ✅ Enabled |
| Anonymous (Guest) | ✅ Enabled |

### Generated Config Files

| File | Vị trí đúng |
|------|-------------|
| `firebase_options.dart` | `lib/firebase_options.dart` |
| `GoogleService-Info.plist` | `ios/Runner/GoogleService-Info.plist` |
| `google-services.json` | `android/app/google-services.json` |

### Google Sign-In URL Scheme (iOS)

Đã thêm vào `ios/Runner/Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.873767716800-qtschojktmh5c4v6gea0761vj9do2eck</string>
    </array>
  </dict>
</array>
```

---

## 3. FIRESTORE DATABASE SCHEMA

### Collection: `users/{uid}/`

```
users/{uid}/
├── profile {
│   displayName: string
│   bio: string
│   avatarUrl: string
│   os: string
│   appVersion: string
│   createdAt: timestamp
│   lastActive: timestamp
│   xp: number
│   level: number
│   streakDays: number
│   totalRuns: number
│   totalDeploys: number
│ }
├── scripts/{scriptId} {
│   name: string
│   content: string
│   language: string
│   createdAt: timestamp
│   updatedAt: timestamp
│   config: map
│   isPublished: boolean
│ }
└── preferences {
│   darkMode: boolean
│   notifications: boolean
│   defaultAiProvider: string
│ }
```

### Collection: `community_scripts/`

```
community_scripts/{docId} {
  authorUid: string
  authorName: string
  scriptName: string
  scriptContent: string
  description: string
  category: string
  version: string
  status: 'pending' | 'published' | 'rejected'
  rejectReason: string?
  submittedAt: timestamp
  reviewedAt: timestamp?
  reviewedBy: string?
  downloads: number
  rating: number
  icon: string
}
```

### Collection: `admins/`

```
admins/{uid} {
  isAdmin: boolean
  email: string
  createdAt: timestamp
}
```

### Firestore Security Rules (ĐÃ APPLY)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
    match /community_scripts/{docId} {
      allow read: if resource.data.status == 'published';
      allow read: if request.auth != null
                  && resource.data.authorUid == request.auth.uid;
      allow create: if request.auth != null
                    && !request.auth.token.firebase.sign_in_provider.matches('anonymous')
                    && request.resource.data.authorUid == request.auth.uid
                    && request.resource.data.status == 'pending';
      allow update: if request.auth != null
                    && resource.data.authorUid == request.auth.uid
                    && resource.data.status == 'pending';
      allow delete: if false;
    }
    match /admins/{uid} {
      allow read: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

### Firestore Composite Indexes (ĐÃ TẠO)

| Collection | Field 1 | Field 2 |
|------------|---------|---------|
| `community_scripts` | `status` ↑ | `submittedAt` ↓ |
| `community_scripts` | `category` ↑ | `downloads` ↓ |
| `community_scripts` | `authorUid` ↑ | `submittedAt` ↓ |

---

## 4. SYSTEM ARCHITECTURE

┌────────────────────────────────────────────────────────┐
│                      FIREBASE                          │
│                                                        │
│  ✅ Authentication (Google, Apple, Email, Guest)       │
│  ✅ Firestore (User scripts, Community, Preferences)    │
│  ✅ Telemetry & System Logging                          │
│  ✅ Cloud Functions & Security Rules for Moderation     │
└────────────────────────────────────────────────────────┘

**Rule:** Firebase is the single backend provider for all data, settings, auth, and telemetries.

---

## 6. TRẠNG THÁI CÁC PHASE

### ✅ PHASE 0 — Package Rename + Firebase Setup (HOÀN TẤT)

- [x] Rename `com.antigravity` → `com.js.scriptAutomator` (28+ files: Dart, iOS, Android, macOS)
- [x] Firebase Console: Auth providers, Firestore DB, Security Rules, Indexes
- [x] `flutterfire configure` → `firebase_options.dart`
- [x] `flutter pub add`: firebase_core, firebase_auth, cloud_firestore, google_sign_in, sign_in_with_apple
- [x] Google Sign-In URL scheme → Info.plist
- [x] Duplicate config files cleaned

### ✅ PHASE 1 — Crash Fix + Firebase Boot (HOÀN TẤT — 2026-05-10)

**Mục tiêu:** App PHẢI khởi động được dù mất mạng. Zero-crash policy.

**Files đã sửa:**

| File | Thay đổi |
|------|----------|
| `lib/main.dart` | Thêm `Firebase.initializeApp()` trong try/catch. Wrap `TelemetryService.registerProfile()` trong try/catch. |
| `lib/core/services/telemetry_service.dart` | Cấu hình logger đẩy telemetry lên Firebase Cloud Firestore. |
| `lib/features/dashboard/data/repositories/cloud_gallery_repository.dart` | Nạp dữ liệu script mẫu từ index JSON. |
| `lib/features/script_engine/domain/script_runner_service.dart` | Kiểm tra trạng thái bị ban/chặn qua Firestore trước khi chạy script. |
| `.env` | API key thật đã xóa. Chỉ còn placeholder comment. |

**Verification:** `flutter analyze` 0 issues. `flutter build ios --no-codesign` ✅ success (53.2MB).

### 🔴 PHASE 2 — Authentication + Cloud Sync (CHƯA THỰC HIỆN)

**Mục tiêu:** User đăng nhập, data sync lên Firestore, đổi device giữ nguyên data.

**Files MỚI cần tạo:**

| File | Mô tả |
|------|-------|
| `lib/core/auth/auth_service.dart` | Firebase Auth wrapper: signInAnonymously, signInWithGoogle, signInWithApple, signInWithEmail, linkWithCredential, signOut, authStateChanges stream |
| `lib/core/auth/auth_gate.dart` | StreamBuilder widget: auto anonymous sign-in, điều hướng Login ↔ AppShell |
| `lib/core/sync/firestore_sync_service.dart` | Hive ↔ Firestore bidirectional sync, chạy trong compute() |
| `lib/features/auth/presentation/pages/login_page.dart` | UI: 4 nút auth (Apple, Google, Email, Guest), Glassmorphism design |

**Files cần SỬA:**

| File | Thay đổi |
|------|----------|
| `lib/main.dart` | Thêm AuthService vào GetIt DI, thay home widget bằng AuthGate |
| `lib/features/dashboard/presentation/pages/app_shell.dart` | Wrap trong AuthGate |
| `lib/features/dashboard/presentation/pages/profile_page.dart` | Hiển thị Firebase user info, nút Link Account |
| `lib/features/dashboard/presentation/pages/settings_page.dart` | Section Account: auth state, Sign Out, Sync Now |

**Guest → Account migration flow:**
1. User dùng app ở Guest mode (anonymous auth)
2. User tap "Link with Google/Apple"
3. Firebase `linkWithCredential()` — UID được giữ nguyên
4. `FirestoreSyncService.pushLocalToCloud(uid)` — đẩy Hive data lên Firestore
5. Đổi device → sign in cùng account → `pullCloudToLocal(uid)` — kéo data về

### 🔴 PHASE 3 — In-App Store (CHƯA THỰC HIỆN)

**Mục tiêu:** User publish script từ app → Admin review → Script xuất hiện trên Store.

**Files MỚI cần tạo:**

| File | Mô tả |
|------|-------|
| `lib/features/community/domain/models/community_script.dart` | Freezed model cho community script |
| `lib/features/community/data/services/publish_service.dart` | Submit lên Firestore, listen status changes |
| `lib/features/community/presentation/pages/publish_page.dart` | Form submit: name, description, category, icon, code preview |

**Files cần SỬA:**

| File | Thay đổi |
|------|----------|
| `lib/features/dashboard/data/repositories/cloud_gallery_repository.dart` | Thêm Firestore query `community_scripts` (status=published), merge với GitHub |
| `lib/features/dashboard/presentation/pages/explore_page.dart` | Thêm Community section |
| `script-automator-admin-web/src/App.tsx` | Tab Script Review: list pending, approve/reject |
| `script-automator-admin-web/src/lib/firebase.ts` | Thêm Firebase Admin integration |

**Publish pipeline:**
```
User viết script → Tap Publish → Auth check (block guest) →
Firestore community_scripts (status: pending) →
Admin Panel sees pending → Review code → Approve/Reject →
status: published → Script hiện trên Community Templates list
```

---

## 7. TECH STACK & DEPENDENCIES (2026-05-10)

### Flutter App — Key Dependencies

| Package | Version | Vai trò |
|---------|---------|---------|
| `firebase_core` | ^4.7.0 | Firebase initialization |
| `firebase_auth` | ^6.4.0 | Authentication |
| `cloud_firestore` | ^6.3.0 | Cloud database |
| `google_sign_in` | ^7.2.0 | Google OAuth |
| `sign_in_with_apple` | ^8.0.0 | Apple OAuth |
| `firebase_analytics` | ^10.8.0 | Telemetry backend |
| `hive_ce` | ^2.19.0 | Local storage |
| `hive_ce_flutter` | ^2.3.4 | Hive Flutter integration |
| `flutter_secure_storage` | ^10.0.0 | Keychain/Keystore |
| `dart_openai` | ^6.1.1 | AI code completion |
| `get_it` | ^7.6.0 | Dependency injection |
| `sqflite` | ^2.4.2 | Widget registry SQLite |

### Admin Panel — Key Dependencies

| Package | Vai trò |
|---------|---------|
| `firebase` | Telemetry + moderation queries |
| React + Vite + TypeScript | Web framework |

---

## 8. BUG REGISTRY HIỆN TẠI

| ID | Severity | Mô tả | File | Trạng thái |
|----|----------|--------|------|------------|
| CRASH-01 | 🔴 FATAL | `Firebase.initializeApp()` không có try/catch, DNS fail = app crash | `main.dart:35` | ✅ FIXED Phase 1 |
| CRASH-02 | 🟡 | `TelemetryService` initialization failures when offline | `telemetry_service.dart:7` | ✅ FIXED Phase 1 |
| SEC-01 | 🔴 | OpenAI API key lộ plaintext trong `.env` file | `.env:9` | ✅ FIXED Phase 1 (REVOKE KEY!) |
| UX-01 | 🟡 | Không có auth → data mất khi đổi device | — | PHASE 2 |
| UX-02 | 🟡 | Community Gallery chỉ qua GitHub PR → rào cản cho non-coder | — | PHASE 3 |

---

## 9. QUY TẮC BẤT DI BẤT DỊCH

1. **Ngôn ngữ code:** Toàn bộ source code, comments, variable names bằng **TIẾNG ANH**. Không ngoại lệ.
2. **Không comment hiển nhiên.** Chỉ comment khi giải thích WHY, không phải WHAT.
3. **Package ID:** Luôn dùng `com.js.scriptAutomator`. KHÔNG BAO GIỜ quay lại `com.antigravity`.
4. **DI Container:** Dùng `GetIt`. Kiểm tra `CODEBASE_MAP.md` và `main.dart` trước khi thêm service mới.
5. **Theme System:** Dùng `LiquidTheme` + `LiquidColors`. KHÔNG hardcode màu.
6. **Sidebar:** Đã bị xóa hoàn toàn. KHÔNG tạo lại. Navigation qua `GlassDock` + header buttons.
7. **Single Backend:** Unified Firebase stack for both user-facing features (Auth, Firestore DB) and system logic (Telemetry, Moderation logs).
8. **Offline First:** App phải hoạt động offline. Mọi network call phải có try/catch + fallback.
9. **API Keys:** OpenAI key auto-loaded via `flutter_dotenv` từ `.env` asset (built-in). User có thể override bằng custom key trong Settings (SecureStorage). `.env` nằm trong `.gitignore`. Resolution order: SecureStorage → .env → dart-define.
10. **Hive data:** Đang ở App Group container trên iOS (`group.com.js.scriptAutomator`). Widget Extension đọc SQLite sidecar, KHÔNG đọc Hive.

---

## 10. CẤU TRÚC THƯ MỤC CHÍNH

```
Script-Automator/
├── lib/
│   ├── main.dart                          ← Entry point + DI setup
│   ├── firebase_options.dart              ← Auto-generated by FlutterFire CLI
│   ├── script_runner_entrypoint.dart      ← Background execution entry
│   ├── core/
│   │   ├── auth/                          ← [PHASE 2] AuthService, AuthGate
│   │   ├── sync/                          ← [PHASE 2] FirestoreSyncService
│   │   ├── security/
│   │   │   └── app_secure_storage.dart    ← Keychain wrapper
│   │   ├── storage/
│   │   │   └── app_storage_paths.dart     ← Hive root + App Group paths
│   │   ├── services/
│   │   │   └── telemetry_service.dart     ← Firebase telemetry logs
│   │   ├── theme/
│   │   │   ├── liquid_theme.dart          ← Theme tokens
│   │   │   └── liquid_colors.dart         ← Semantic color system
│   │   └── ui/                            ← Shared widgets (GlassDock, etc.)
│   └── features/
│       ├── ai_integration/
│       │   └── data/services/
│       │       ├── openai_service.dart
│       │       ├── gemini_service.dart
│       │       └── ollama_service.dart
│       ├── auth/                          ← [PHASE 2] Login page
│       ├── community/                     ← [PHASE 3] Publish flow
│       ├── dashboard/
│       │   ├── data/repositories/
│       │   │   └── cloud_gallery_repository.dart  ← GitHub + Firestore community templates
│       │   └── presentation/pages/
│       │       ├── app_shell.dart          ← Navigation shell (GlassDock)
│       │       ├── dashboard_page.dart     ← Home tab
│       │       ├── explore_page.dart       ← Community templates gallery
│       │       ├── gallery_page.dart       ← My scripts gallery
│       │       ├── profile_page.dart       ← User profile
│       │       ├── settings_page.dart      ← Settings
│       │       └── liquid_splash_page.dart ← Splash screen
│       ├── editor/                        ← Code editor
│       ├── script_engine/
│       │   └── domain/
│       │       └── script_runner_service.dart  ← JS Engine (QuickJS/JSC) in Isolate
│       ├── script_management/
│       │   └── data/services/
│       │       └── virtual_file_system_service.dart  ← VFS chroot jail
│       └── widget_renderer/
│           ├── data/services/
│           │   └── widget_registry_service.dart  ← SQLite sidecar
│           └── domain/services/
│               └── headless_widget_rendering_service.dart  ← Native JSON passthrough
├── ios/
│   ├── Runner/
│   │   ├── AppDelegate.swift              ← MethodChannels, BGTask
│   │   ├── Runner.entitlements            ← App Group, Keychain
│   │   ├── Info.plist                     ← BGTask ID, Google Sign-In URL
│   │   └── GoogleService-Info.plist       ← Firebase iOS config
│   └── ScriptAutomatorWidget/            ← iOS WidgetKit Extension
├── android/
│   ├── app/
│   │   ├── build.gradle.kts              ← namespace, applicationId
│   │   ├── google-services.json          ← Firebase Android config
│   │   └── src/main/kotlin/com/js/scriptAutomator/  ← Android native code
└── macos/                                ← macOS target
```

---

## 11. ADMIN PANEL CONTEXT

| Key | Value |
|-----|-------|
| **Đường dẫn** | `script-automator-admin-web/` |
| **Framework** | React + Vite + TypeScript |
| **Backend** | Firebase (telemetry, moderation, auth) |
| **Env vars** | `VITE_FIREBASE_API_KEY`, `VITE_FIREBASE_AUTH_DOMAIN`, `VITE_FIREBASE_PROJECT_ID` |

---

## 12. THỨ TỰ THỰC HIỆN

| Phase | Nội dung | Effort | Phụ thuộc | Trạng thái |
|-------|----------|--------|-----------|------------|
| 0 | Package Rename + Firebase Setup | 2 giờ | Không | ✅ XONG |
| 1 | Crash Fix + Firebase Boot | 1-2 giờ | Phase 0 | ✅ XONG |
| 2 | Auth + Cloud Sync | 3-5 ngày | Phase 1 | 🔴 TIẾP THEO |
| 3 | In-App Store + Admin | 5-7 ngày | Phase 2 | ⏳ |
