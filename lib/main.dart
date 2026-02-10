import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'core/theme/liquid_theme.dart';
import 'features/dashboard/presentation/pages/liquid_splash_page.dart';
import 'features/script_management/domain/repositories/script_repository.dart';
import 'features/script_management/data/repositories/script_repository_impl.dart';
import 'features/script_management/data/datasources/script_local_data_source.dart';
import 'features/script_management/data/services/encryption_service.dart';
import 'features/script_management/data/models/script_model.dart';
import 'features/script_engine/domain/script_runner_service.dart';
import 'features/ai/data/ai_service.dart';
import 'features/dashboard/domain/repositories/gallery_repository.dart';
// import 'features/dashboard/data/repositories/local_gallery_repository.dart'; // Replaced by Cloud
import 'features/widget_renderer/domain/services/headless_widget_rendering_service.dart';
import 'features/widget_renderer/data/services/widget_registry_service.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'features/ai_integration/data/services/gemini_service.dart';
import 'features/ai_integration/data/services/ollama_service.dart'; // New Import
import 'features/dashboard/data/repositories/cloud_gallery_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _setupDI();
  runApp(const MyApp());
}

Future<void> _setupDI() async {
  // Phase 2: Data Layer (Production)
  await Hive.initFlutter();
  Hive.registerAdapter(ScriptModelAdapter());

  final encryptionService = EncryptionService();
  final localDataSource = ScriptLocalDataSourceImpl(encryptionService);

  // Initialize secure storage and boxes
  try {
    await localDataSource.init();
  } catch (e) {
    debugPrint("Failed to init local data source: $e");
    // Handle migration or recovery here
  }

  // Register Encryption/SecureStorage for AI Service
  if (!GetIt.I.isRegistered<FlutterSecureStorage>()) {
    GetIt.I.registerLazySingleton(() => const FlutterSecureStorage());
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
  if (!GetIt.I.isRegistered<ScriptRunnerService>()) {
    GetIt.I.registerSingleton<ScriptRunnerService>(ScriptRunnerService());
  }

  if (!GetIt.I.isRegistered<AIService>()) {
    final aiService = AIService();
    await aiService.initialize();
    GetIt.I.registerSingleton<AIService>(aiService);
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Script Automator',
      theme: LiquidTheme.lightTheme,
      home: const LiquidSplashPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
