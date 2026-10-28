# 📋 PROJECT CONTEXT — SCRIPT AUTOMATOR

> **Cập nhật lần cuối:** 2026-10-27
> **Mục đích:** Nguồn sự thật duy nhất cho mọi phiên làm việc. Đọc file này (và `CODEBASE_MAP.md`) trước khi thay đổi code.

---

## 1. TỔNG QUAN

**Script Automator** là app Flutter cho phép viết JavaScript, chạy trong engine sandbox, deploy thành Home Screen Widget native (iOS WidgetKit / Android Glance) và chia sẻ qua Gallery cộng đồng có kiểm duyệt.

| Project | Đường dẫn | Tech stack |
|---|---|---|
| Mobile app | `Script-Automator/` | Flutter 3.47.8, Dart 3.13 |
| Cloud Functions + Rules | `Script-Automator/functions`, `firestore.rules`, `storage.rules` | Node 22, firebase-functions 7, firebase-admin 14 |
| Admin web | `script-automator-admin-web/` | React 19.3, Vite 8, TypeScript 6.0, firebase JS 13 |

### Identifiers

| Key | Value |
|---|---|
| iOS bundle / Android applicationId | `com.js.scriptAutomator` |
| iOS widget extension | `com.js.scriptAutomator.ScriptAutomatorWidget` |
| App Group / Keychain group | `group.com.js.scriptAutomator` |
| MethodChannels | `com.js.scriptAutomator/widget`, `com.js.scriptAutomator/background` |
| BGTask ID | `com.js.scriptAutomator.refresh` |

> KHÔNG dùng lại `com.antigravity.*` (đã rename 2026-05-10).

---

## 2. FIREBASE

| Key | Value |
|---|---|
| Project | `script-automator-bdbef` (Blaze), số `873767716800` |
| Firestore location | `nam5` (US multi-region) |
| Storage bucket | `script-automator-bdbef.firebasestorage.app` (`us-east1`) |
| Functions regions | `us-central1`; `validateSubmissionUpload` in `us-east1` (must match bucket) |
| Apps | Android `1:873767716800:android:aeb684ad57a36a19882a25`, iOS `1:873767716800:ios:f34fa38821b8ed26882a25`, Web `Script_Automator_Admin` |
| Auth providers | Email/Password, Google, Apple, Anonymous (Guest) |
| AI Logic | Bật, backend Gemini Developer API |
| App Check | Code sẵn sàng, **chưa đăng ký provider**, enforcement OFF (xem §8) |

Config files bị git-ignore: `lib/firebase_options.dart`, `ios/Runner/GoogleService-Info.plist`, `android/app/google-services.json`, `firebase.json` (tạo lại bằng `flutterfire configure`).

---

## 3. FIRESTORE SCHEMA (thực tế)

```
users/{uid}                    displayName, bio, email, photoURL, lastActive, totalRuns, streakDays,
                               dailyActivity, role*, is_banned*, banned_at*   (* chỉ admin/Functions ghi)
  ├─ scripts/{scriptId}        bản sync của script local
  ├─ notifications/{id}        type(0 run|1 deploy|2 system), title, body, reject_reason?, submission_id?, timestamp
  └─ preferences/settings      darkMode, notifications

gallery_submissions/{id}       user_id, script_id, name, description, category, author, version,
                               status('pending'|'approved'|'rejected'), file_url, file_size, sha256,
                               original_gallery_id?, created_at,
                               reject_reason?, reviewed_at?, reviewed_by?   (chỉ admin)
gallery_published/{id}         name, description, author, author_uid, category, version, icon, file_url,
                               file_size, sha256, downloads, code, published_at, updated_at
script_reports/{scriptId}_{uid} script_id, reporter_uid, reason?, created_at   (1 report / user / script)
script_moderation/{scriptId}   reports_count, is_blocked, admin_override, blocked_reason, blocked_at, updated_at
app_config/global              maintenance_mode, gallery_submissions_enabled,
                               ai_chat_model, ai_completion_model, report_auto_block_threshold
app_config/metrics             total_users, total_executions, total_published, total_widget_deploys, crash_rate
telemetry_logs, user_profiles, widget_stats, user_feedback, admin_audit_log, admins, rate_limits
```

Storage: `submissions/{uid}/{file}.js` (tác giả + admin đọc), `gallery/{id}.js` (public đọc, admin ghi), `avatars/{uid}/*`.

**Không dùng** `community_scripts` (thiết kế cũ, đã thay bằng `gallery_*`).

### Luồng cộng đồng
1. App: `PublishScriptSheet` → upload `submissions/{uid}/{scriptId}.js` → `gallery_submissions` (pending). Guest bị chặn.
2. Admin: duyệt → `gallery_published` + notification type 1; từ chối **bắt buộc lý do** → `reject_reason` + notification type 2.
3. App: Report → **một transaction** ghi `script_reports/{scriptId}_{uid}` + tăng `script_moderation.reports_count` đúng 1, tự block khi ≥ `report_auto_block_threshold` (mặc định 5). `firestore.rules` kiểm tra toàn bộ (1 report/user/script, +1, chỉ block khi đạt ngưỡng, không unblock, tôn trọng `admin_override`). Admin bỏ block ⇒ `admin_override=true`.
4. Runner chặn chạy script gallery bị block (fail-closed, id lấy từ `settings.gallery_id`).

---

## 4. RULES, INDEXES, FUNCTIONS

- Nguồn duy nhất: `Script-Automator/firestore.rules`, `storage.rules`, `firestore.indexes.json` (admin web không còn bản copy).
- Admin = custom claim `admin`. **Tạm thời** rules còn email fallback `chaunganpenny@gmail.com` — xoá sau khi xác nhận claim (deploy bước 7).
- Owner không được tự sửa `role` / `is_banned`. Client không ghi được `script_moderation`.
- Functions trên prod: `setAdminRole`, `banUser` (disable Auth + revoke token + audit). `openAiProxy` (Node 20) **giữ tạm** cho bản app cũ — xoá khi bản mới phát hành: `firebase functions:delete openAiProxy`.
- `validateSubmissionUpload` (us-east1) và `aggregateMetrics` có trong code nhưng **chưa deploy prod**: function theo sự kiện cần 4 IAM binding chỉ Owner cấp được (tài khoản CLI là Editor). Thay thế: Storage Rules giới hạn 500KB + `text/javascript`, Admin hiển thị cảnh báo mẫu nguy hiểm khi duyệt; Admin tự đếm metrics khi chưa có `app_config/metrics`. Chúng vẫn chạy đầy đủ trên emulator.
- **Deploy functions phải liệt kê rõ** (không dùng `--only functions`):
  `cd functions && npm run deploy` (= deploy `setAdminRole`, `banUser` + `enable-callables`).
- ⚠️ **Callable trên prod đang trả 403 từ Cloud Run** (đã như vậy từ trước, kể cả `openAiProxy`): service không có invoker công khai. Bật cần `run.services.setIamPolicy` (chỉ Owner). Owner chạy một lần: `cd functions && npm run enable-callables` (bật `invokerIamDisabled` cho `setadminrole`, `banuser`; không mở `openAiProxy`).
  Trong lúc chờ: Admin **Ban** tự fallback sang cờ `users/{uid}.is_banned` (app chặn realtime + rules chặn ghi; Auth account chưa bị disable). **Grant/Revoke admin** không có fallback (cần Admin SDK).
- Test: `cd functions && npm test` (25 rules + 4 functions, emulator, JDK 21+ — JBR của Android Studio dùng được).

---

## 5. AI

| Provider | Khi nào | Ghi chú |
|---|---|---|
| Gemini (mặc định) | Luôn sẵn sàng khi có mạng | `firebase_ai`, không có API key trong app; chat `gemini-3.8-flash`, ghost text `gemini-3.5-flash-lite` (cả hai có free tier, kiểm tra 2026-10-26). Đổi model qua Admin → Settings (`app_config/global`). |
| OpenAI | User tự nhập key | `dart_openai`, không còn proxy server |
| Ollama | User cấu hình URL LAN | `/api/chat` |

`AiService` chọn provider theo lựa chọn user, tự fallback về Gemini nếu provider chưa cấu hình.

---

## 6. TECH STACK (phiên bản đã resolve)

| Package | Version | Ghi chú |
|---|---|---|
| firebase_core / auth / cloud_firestore | 4.15.2 / 6.7.1 / 6.10.2 | Giữ dòng firebase-ios-sdk 12.x (xem §8) |
| cloud_functions / firebase_storage / crashlytics / app_check / firebase_ai | 6.5.1 / 13.6.1 / 5.4.1 / 0.4.9 / 4.0.0 | |
| google_sign_in / sign_in_with_apple | 7.2.0 / 8.2.0 | |
| get_it / hive_ce / flutter_secure_storage | 9.3.0 / 2.22.0 / 11.2.0 | |
| share_plus / flutter_local_notifications / google_fonts | 13.3.1 / 22.3.3 / 9.0.0 | |
| freezed / json_serializable / build_runner | 4.0.3 / 6.15 / 2.16 | |
| Android | AGP 9.1.0, Gradle 9.3.1, Kotlin 2.4.0, Java 17, Crashlytics plugin 3.0.8 | `android.builtInKotlin=false` tới khi plugin Firebase hỗ trợ built-in Kotlin |
| iOS | Deployment target 18.0, SPM (không CocoaPods), UIScene lifecycle | dSYM upload qua build phase |

Đã gỡ: `flutter_bloc`, `equatable`, `home_widget`, `google_generative_ai`, `flutter_dotenv` (+ `.env` không còn bundle), `flutter_staggered_animations`, `mockito`.

---

## 7. TRẠNG THÁI

| Hạng mục | Trạng thái |
|---|---|
| Phase 0–1: rename, Firebase boot, crash fixes | ✅ |
| Phase 2: Auth + Cloud Sync + Guest linking (Google/Apple/Email), delete account | ✅ |
| Phase 3: Gallery publish → review (lý do từ chối) → publish, report + auto-block | ✅ |
| AI Gemini qua Firebase AI Logic | ✅ (smoke test thật trên Android emulator) |
| Crashlytics | ✅ (release builds) |
| App Check | ⏳ chờ đăng ký provider trên console |
| Git clone/pull (Phase 5) | 🔲 chưa làm, không hiển thị trên UI |
| macOS / web / desktop | 🔲 scaffolding, không hỗ trợ |

---

## 8. LƯU Ý QUAN TRỌNG

1. **App Check:** khi đã activate, `firebase_ai` từ chối gửi request nếu không lấy được token (kể cả khi enforcement OFF). Vì vậy App Check chỉ bật với `--dart-define=ENABLE_APP_CHECK=true`, sau khi: bật Firebase App Check API, đăng ký Play Integrity (SHA-256 key ký app), App Attest (Team ID), và debug token cho máy dev.
2. **FlutterFire 5.x (firebase-ios-sdk 13)** xung đột `gtm-session-fetcher` với GoogleSignIn 9 của `google_sign_in_ios`. Nâng cả dòng FlutterFire khi `google_sign_in_ios` lên GoogleSignIn 10.
3. Hive lowercase tên box — luôn so sánh tên box ở dạng lowercase.
4. Code/comment bằng tiếng Anh; dùng `LiquidTheme`/`LiquidColors`, không hardcode màu; DI bằng GetIt (`setupDependencies()` trong `main.dart`); offline-first: mọi call mạng có try/catch + fallback.

---

## 9. CHẾ ĐỘ DỰ PHÒNG (EMULATOR) — CHỈ DÙNG KHI PROD/MẠNG GẶP SỰ CỐ

Đường chính luôn là prod. Khi cần demo không phụ thuộc Firebase thật (trừ Gemini, vẫn cần Internet):

```bash
# Terminal 1 — backend local (dữ liệu lưu ở ../emulator-data, UI http://127.0.0.1:4000)
cd Script-Automator/functions && npm run demo
# Terminal 2 — dữ liệu mẫu (chạy 1 lần; idempotent)
cd Script-Automator/functions && npm run demo:seed
# Terminal 3 — app (Android emulator tự dùng 10.0.2.2; máy thật: thêm FIREBASE_EMULATOR_HOST=<IP laptop>)
cd Script-Automator && flutter run --dart-define=USE_FIREBASE_EMULATOR=true
# Terminal 4 — admin web (http://localhost:5173)
cd script-automator-admin-web && npm run dev:emulator
```

Tài khoản mẫu: admin `admin@demo.local` / `demo1234`, user `user@demo.local` / `demo1234`.
Chỉ hoạt động ở bản debug (`USE_FIREBASE_EMULATOR` bị bỏ qua ở release). Kiểm thử: `integration_test/emulator_demo_test.dart`.

