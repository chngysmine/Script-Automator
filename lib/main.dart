import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'core/storage/app_storage_paths.dart';
import 'core/theme/liquid_theme.dart';
import 'features/dashboard/presentation/pages/liquid_splash_page.dart';
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
import 'features/ai_integration/data/services/openai_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _setupDI();
  runApp(const MyApp());
}

Future<void> _setupDI() async {
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
  Hive.registerAdapter(ScriptModelAdapter());

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
        home: const LiquidSplashPage(),
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
          home: const LiquidSplashPage(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
