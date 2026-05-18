import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'core/storage/app_storage_paths.dart';
import 'core/theme/liquid_theme.dart';
import 'core/auth/auth_service.dart';
import 'core/auth/auth_gate.dart';
import 'core/sync/firestore_sync_service.dart';
import 'features/script_management/domain/repositories/script_repository.dart';
import 'features/script_management/data/repositories/script_repository_impl.dart';
import 'features/script_management/data/datasources/script_local_data_source.dart';
import 'features/script_management/data/services/encryption_service.dart';
import 'features/script_management/data/models/script_model.dart';
import 'features/script_engine/domain/script_runner_service.dart';
import 'features/dashboard/domain/repositories/gallery_repository.dart';
import 'features/widget_renderer/domain/services/headless_widget_rendering_service.dart';
import 'features/widget_renderer/data/services/widget_registry_service.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:script_automator/core/security/app_secure_storage.dart';
import 'features/ai_integration/data/services/gemini_service.dart';
import 'features/ai_integration/data/services/ollama_service.dart';
import 'features/dashboard/data/repositories/cloud_gallery_repository.dart';
import 'package:script_automator/features/dashboard/domain/services/notification_service.dart';
import 'package:script_automator/features/dashboard/data/services/user_preferences_service.dart';
import 'package:script_automator/features/dashboard/data/services/user_stats_service.dart';
import 'package:script_automator/core/services/telemetry_service.dart';
import 'features/ai_integration/data/services/openai_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global error handler — catches framework-level errors
  FlutterError.onError = (details) {
    debugPrint('[FLUTTER_ERROR] ${details.exception}');
    debugPrint('[FLUTTER_ERROR] ${details.stack}');
  };

  // Load environment variables from .env asset
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('[BOOT] .env load failed (using defaults): $e');
  }

  // Phase 1A: Initialize Firebase (Auth, Firestore, FCM)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('[BOOT] Firebase init failed (degraded mode): $e');
  }

  // Phase 1B: Initialize Supabase Analytics & Telemetry Layer
  // Non-critical — app continues in offline mode if this fails.
  try {
    final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
    final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
    if (supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty) {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseKey,
      ).timeout(const Duration(seconds: 5));
    } else {
      debugPrint('[BOOT] Supabase credentials not found in .env (offline mode)');
    }
  } catch (e) {
    debugPrint('[BOOT] Supabase init failed (offline mode): $e');
  }

  try {
    await _setupDI();
  } catch (e, stack) {
    debugPrint('[BOOT] DI setup failed: $e');
    debugPrint('[BOOT] $stack');
  }

  // Telemetry check-in (fire-and-forget, never blocks boot)
  try {
    if (GetIt.I.isRegistered<TelemetryService>()) {
      unawaited(GetIt.I<TelemetryService>().registerProfile());
    }
  } catch (_) {}

  runApp(const MyApp());
}

Future<void> _setupDI() async {
  // Phase 0: Telemetry Engine (Always First)
  if (!GetIt.I.isRegistered<TelemetryService>()) {
    GetIt.I.registerSingleton<TelemetryService>(TelemetryService());
  }

  // Phase 1: Auth Service (must be before sync)
  if (!GetIt.I.isRegistered<AuthService>()) {
    GetIt.I.registerSingleton<AuthService>(AuthService());
  }
  if (!GetIt.I.isRegistered<FirestoreSyncService>()) {
    GetIt.I.registerSingleton<FirestoreSyncService>(FirestoreSyncService());
  }

  // Phase 2: Data Layer — Hive root matches App Group on iOS when available
  // (see [AppStoragePaths.hiveRootDirectory]); mirrors [Hive.initFlutter] adapters.
  final hiveDir = await AppStoragePaths.hiveRootDirectory();
  Hive.init(hiveDir.path);
  final colorAdapter = ColorAdapter();
  if (!Hive.isAdapterRegistered(colorAdapter.typeId)) {
    Hive.registerAdapter(colorAdapter);
  }
  final todAdapter = TimeOfDayAdapter();
  if (!Hive.isAdapterRegistered(todAdapter.typeId)) {
    Hive.registerAdapter(todAdapter);
  }
  final scriptAdapter = ScriptModelAdapter();
  if (!Hive.isAdapterRegistered(scriptAdapter.typeId)) {
    Hive.registerAdapter(scriptAdapter);
  }

  final encryptionService = EncryptionService();
  final localDataSource = ScriptLocalDataSourceImpl(encryptionService);

  // Initialize secure storage and boxes
  try {
    await localDataSource.init();
    // Register localDataSource to GetIt to be accessible from MyApp lifecycle listener
    GetIt.I.registerSingleton<ScriptLocalDataSource>(localDataSource);
  } catch (e) {
    debugPrint("Failed to init local data source: $e");
    // Handle migration or recovery here
  }

  // Register Encryption/SecureStorage for AI Service
  if (!GetIt.I.isRegistered<FlutterSecureStorage>()) {
    GetIt.I.registerLazySingleton(AppSecureStorage.create);
  }

  // Phase 3: Widget Registry (SQLite)
  final widgetRegistry = WidgetRegistryService();
  if (!GetIt.I.isRegistered<WidgetRegistryService>()) {
    GetIt.I.registerSingleton<WidgetRegistryService>(widgetRegistry);
  }

  if (!GetIt.I.isRegistered<ScriptRepository>()) {
    GetIt.I.registerSingleton<ScriptRepository>(
      ScriptRepositoryImpl(localDataSource, widgetRegistry),
    );
  }

  // Phase 4: Integration - Real Services
  if (!GetIt.I.isRegistered<NotificationService>()) {
    final notifService = NotificationService();
    await notifService.init();
    GetIt.I.registerSingleton<NotificationService>(notifService);
  }
  if (!GetIt.I.isRegistered<UserPreferencesService>()) {
    final prefs = UserPreferencesService();
    await prefs.init();
    GetIt.I.registerSingleton<UserPreferencesService>(prefs);
    
    // Register Global Theme Notifier
    final isDarkMode = await prefs.isDarkMode;
    final themeNotifier = ValueNotifier<ThemeMode>(
      isDarkMode ? ThemeMode.dark : ThemeMode.light
    );
    GetIt.I.registerSingleton<ValueNotifier<ThemeMode>>(themeNotifier);
  }
  if (!GetIt.I.isRegistered<UserStatsService>()) {
    final stats = UserStatsService();
    await stats.init();
    GetIt.I.registerSingleton<UserStatsService>(stats);
  }
  if (!GetIt.I.isRegistered<ScriptRunnerService>()) {
    GetIt.I.registerSingleton<ScriptRunnerService>(ScriptRunnerService());
  }

  // Phase 4: AI & Cloud
  if (!GetIt.I.isRegistered<GeminiService>()) {
    final geminiService = GeminiService(GetIt.I<FlutterSecureStorage>());
    await geminiService.initialize();
    GetIt.I.registerSingleton<GeminiService>(geminiService);
  }

  if (!GetIt.I.isRegistered<OllamaService>()) {
    final ollamaService = OllamaService(GetIt.I<FlutterSecureStorage>());
    await ollamaService.initialize();
    GetIt.I.registerSingleton<OllamaService>(ollamaService);
  }

  if (!GetIt.I.isRegistered<OpenAIService>()) {
    final openAiService = OpenAIService(GetIt.I<FlutterSecureStorage>());
    await openAiService.initialize();
    GetIt.I.registerSingleton<OpenAIService>(openAiService);
  }

  // Use Cloud Repo with Fallback (replaces LocalGalleryRepository)
  if (!GetIt.I.isRegistered<GalleryRepository>()) {
    GetIt.I.registerSingleton<GalleryRepository>(CloudGalleryRepository());
  }

  // Phase 4: Widget Renderer
  if (!GetIt.I.isRegistered<HeadlessWidgetRenderingService>()) {
    GetIt.I.registerSingleton<HeadlessWidgetRenderingService>(
      HeadlessWidgetRenderingService(),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      // Flush safely to the persistent storage to prevent data loss on OS kill
      if (GetIt.I.isRegistered<ScriptLocalDataSource>()) {
        unawaited(GetIt.I<ScriptLocalDataSource>().flushData());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!GetIt.I.isRegistered<ValueNotifier<ThemeMode>>()) {
      return MaterialApp(
        title: 'Script Automator',
        theme: LiquidTheme.lightTheme,
        darkTheme: LiquidTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const AuthGate(),
        debugShowCheckedModeBanner: false,
      );
    }
    
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: GetIt.I<ValueNotifier<ThemeMode>>(),
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Script Automator',
          theme: LiquidTheme.lightTheme,
          darkTheme: LiquidTheme.darkTheme,
          themeMode: themeMode,
          home: const AuthGate(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
