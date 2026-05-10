import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import 'package:script_automator/core/services/telemetry_service.dart';
import 'package:script_automator/core/security/app_secure_storage.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/features/dashboard/presentation/widgets/script_config_form.dart';
import 'package:script_automator/features/script_management/domain/entities/script.dart';
import 'package:script_automator/features/script_management/domain/repositories/script_repository.dart';

/// Single source of truth for installing scripts from the Gallery/Explore pages.
///
/// Eliminates the previous DRY violation where install logic was duplicated
/// across [ExplorePage] and [GalleryPage] (200+ lines of near-identical code).
class GalleryInstallService {
  static final GalleryInstallService _instance = GalleryInstallService._();
  factory GalleryInstallService() => _instance;
  GalleryInstallService._();

  /// Installs a script from the gallery with lazy content loading.
  ///
  /// Flow:
  /// 1. Show config form if script has configurable parameters
  /// 2. Download JS source from [scriptUrl] if no embedded content
  /// 3. Validate content is non-empty
  /// 4. Persist config values to SecureStorage
  /// 5. Save script to [ScriptRepository] with gallery metadata
  /// 6. Return true on success, false on failure/cancellation
  Future<bool> installScript(
    BuildContext context,
    Map<String, dynamic> scriptData,
  ) async {
    final name = (scriptData['name'] as String?) ?? 'Untitled';
    final existingContent = (scriptData['content'] as String?) ?? '';
    final scriptUrl = (scriptData['scriptUrl'] as String?) ?? '';
    final configSchema = scriptData['config'] as Map<String, dynamic>?;

    // Step 1: Config form (if schema exists)
    Map<String, dynamic>? configData;
    if (configSchema != null && configSchema.isNotEmpty && context.mounted) {
      configData = await ScriptConfigForm.show(context, name, configSchema);
      if (configData == null) return false; // User cancelled
    }

    // Step 2: Show loading indicator
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Installing $name..."),
        backgroundColor: LiquidTheme.primary,
        duration: const Duration(seconds: 10),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Step 3: Download content if not embedded
    String finalContent = existingContent;

    if (finalContent.isEmpty && scriptUrl.isNotEmpty) {
      try {
        final response = await http
            .get(Uri.parse(scriptUrl))
            .timeout(const Duration(seconds: 15));
        if (response.statusCode == 200) {
          finalContent = response.body;
        } else if (response.statusCode == 403) {
          throw Exception('GitHub rate limit exceeded (HTTP 403). Try again later.');
        } else if (response.statusCode == 404) {
          throw Exception('Script not found (HTTP 404). It may have been removed.');
        } else {
          throw Exception('HTTP ${response.statusCode}');
        }
      } catch (e) {
        if (!context.mounted) return false;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to download $name: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return false;
      }
    }

    // Step 4: Validate — refuse to install empty scripts
    if (finalContent.trim().isEmpty) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$name has no content. Installation skipped."),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }

    // Step 5: Persist config to SecureStorage
    final galleryId =
        (scriptData['id'] as String?) ?? name.toLowerCase().replaceAll(' ', '_');
    final galleryVersion = (scriptData['version'] as String?) ?? '1.0.0';
    final scriptId = 'gallery_$galleryId';

    if (configData != null && configData.isNotEmpty) {
      final storage = AppSecureStorage.create();
      for (final entry in configData.entries) {
        await storage.write(
          key: 'script_$scriptId.${entry.key}',
          value: entry.value.toString(),
        );
      }
    }

    // Step 6: Save script
    final script = Script(
      id: scriptId,
      name: name,
      content: finalContent,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      settings: {
        'gallery_id': galleryId,
        'gallery_version': galleryVersion,
        'gallery_script_url': scriptUrl,
      },
    );
    await GetIt.I<ScriptRepository>().saveScript(script);

    // Step 7: Real-time Telemetry (Trace deployment)
    if (GetIt.I.isRegistered<TelemetryService>()) {
      unawaited(GetIt.I<TelemetryService>().trackWidgetDeploy(galleryId));
    }

    // Step 8: Success feedback
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$name installed successfully!"),
        backgroundColor: LiquidTheme.primary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return true;
  }
}
