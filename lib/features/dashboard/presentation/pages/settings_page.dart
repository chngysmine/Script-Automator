import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/features/ai_integration/data/services/gemini_service.dart';
import 'package:script_automator/features/ai_integration/data/services/openai_service.dart';
import 'package:script_automator/features/dashboard/data/services/user_preferences_service.dart';
import 'package:script_automator/features/dashboard/presentation/widgets/edit_profile_sheet.dart';
import 'package:script_automator/features/script_management/domain/repositories/script_repository.dart';
import 'package:script_automator/features/script_management/data/datasources/script_local_data_source.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _geminiKeyController = TextEditingController();
  final _openAiKeyController = TextEditingController();
  final GeminiService _geminiService = GetIt.I<GeminiService>();
  final OpenAIService _openAiService = GetIt.I<OpenAIService>();
  
  bool _isLoadingGemini = false;
  bool _isLoadingOpenAi = false;
  
  bool _hasGeminiKey = false;
  bool _hasOpenAiKey = false;

  // App settings state
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  // Profile state (loaded from UserPreferencesService)
  String _displayName = 'My Workspace';
  String _displayBio = 'Widget automation workspace';

  // Cache state (calculated from disk)
  String _cacheSizeText = '—';

  // App version (from PackageInfo)
  String _appVersion = '—';

  @override
  void initState() {
    super.initState();
    _checkKey();
    _loadPreferences();
    _calculateCacheSize();
    _loadPackageInfo();
  }

  Future<void> _loadPreferences() async {
    final prefs = GetIt.I<UserPreferencesService>();
    final notifications = await prefs.notificationsEnabled;
    final darkMode = await prefs.isDarkMode;
    final name = await prefs.displayName;
    final bio = await prefs.bio;
    if (mounted) {
      setState(() {
        _notificationsEnabled = notifications;
        _darkModeEnabled = darkMode;
        _displayName = name;
        _displayBio = bio;
      });
    }
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _appVersion = '${info.version} (${info.buildNumber})');
      }
    } catch (_) {
      // Fallback for platforms where PackageInfo is unavailable
    }
  }

  Future<void> _calculateCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final appSupportDir = await getApplicationSupportDirectory();
      int totalBytes = 0;

      // Count temp directory
      if (tempDir.existsSync()) {
        totalBytes += _dirSize(tempDir);
      }

      // Count Hive box files in app support
      if (appSupportDir.existsSync()) {
        for (final entity in appSupportDir.listSync()) {
          if (entity is File &&
              (entity.path.endsWith('.hive') ||
                  entity.path.endsWith('.lock'))) {
            totalBytes += entity.lengthSync();
          }
        }
      }

      if (mounted) {
        setState(() => _cacheSizeText = _formatBytes(totalBytes));
      }
    } catch (_) {
      if (mounted) setState(() => _cacheSizeText = '—');
    }
  }

  int _dirSize(Directory dir) {
    int size = 0;
    try {
      for (final entity in dir.listSync(recursive: true, followLinks: false)) {
        if (entity is File) {
          size += entity.lengthSync();
        }
      }
    } catch (_) {}
    return size;
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  void dispose() {
    _geminiKeyController.dispose();
    _openAiKeyController.dispose();
    super.dispose();
  }

  Future<void> _checkKey() async {
    final hasGemini = await _geminiService.hasCustomApiKey();
    final hasOpenAi = await _openAiService.hasCustomApiKey();
    setState(() {
      _hasGeminiKey = hasGemini;
      _hasOpenAiKey = hasOpenAi;
    });
  }

  Future<void> _saveGeminiKey() async {
    final key = _geminiKeyController.text.trim();
    if (key.isEmpty) return;

    setState(() => _isLoadingGemini = true);
    await _geminiService.setApiKey(key);
    await _checkKey();
    setState(() => _isLoadingGemini = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Gemini API Key Saved successfully!"),
          backgroundColor: LiquidTheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> _saveOpenAiKey() async {
    final key = _openAiKeyController.text.trim();
    if (key.isEmpty) return;

    setState(() => _isLoadingOpenAi = true);
    await _openAiService.setApiKey(key);
    await _checkKey();
    setState(() => _isLoadingOpenAi = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("OpenAI API Key Saved successfully!"),
          backgroundColor: LiquidTheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      FocusScope.of(context).unfocus();
    }
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Clear Cache",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: LiquidTheme.textDeep,
          ),
        ),
        content: Text(
          "Clear $_cacheSizeText of temporary data? Your scripts and settings will not be affected.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: LiquidTheme.textMedium),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performCacheClear();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Clear",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performCacheClear() async {
    try {
      // 1. Clear temp directory
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        for (final entity in tempDir.listSync()) {
          try {
            if (entity is File) {
              entity.deleteSync();
            } else if (entity is Directory) {
              entity.deleteSync(recursive: true);
            }
          } catch (_) {}
        }
      }

      // 2. Compact Hive boxes (defrag without losing data)
      final dataSource = GetIt.I<ScriptLocalDataSource>();
      await dataSource.flushData();

      // 3. Recalculate cache size
      await _calculateCacheSize();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Cache cleared successfully!"),
            backgroundColor: LiquidTheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to clear cache: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _openEditProfile() async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          EditProfileSheet(currentName: _displayName, currentBio: _displayBio),
    );

    // Persist edited profile to UserPreferencesService
    if (result != null && mounted) {
      final prefs = GetIt.I<UserPreferencesService>();
      final newName = result['name'] ?? _displayName;
      final newBio = result['bio'] ?? _displayBio;
      await prefs.setDisplayName(newName);
      await prefs.setBio(newBio);
      setState(() {
        _displayName = newName;
        _displayBio = newBio;
      });
    }
  }

  Future<void> _sendFeedback() async {
    final subject = Uri.encodeComponent(
      'Script Automator Feedback — v$_appVersion',
    );
    final body = Uri.encodeComponent(
      'Hi Antigravity Team,\n\n'
      'App Version: $_appVersion\n'
      'Platform: ${Platform.operatingSystem}\n\n'
      '--- Describe your feedback below ---\n\n',
    );
    final mailUri = Uri.parse(
      'mailto:feedback@scriptautomator.app?subject=$subject&body=$body',
    );

    if (await canLaunchUrl(mailUri)) {
      await launchUrl(mailUri);
    } else {
      // Fallback: open GitHub issues in browser
      final githubUri = Uri.parse(
        'https://github.com/chngysmine/script-automator-community-gallery/issues/new',
      );
      if (await canLaunchUrl(githubUri)) {
        await launchUrl(githubUri, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Could not open email or browser."),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _exportData() async {
    try {
      final repo = GetIt.I<ScriptRepository>();
      final scriptsResult = await repo.getScripts();

      final scripts = scriptsResult.fold(
        (failure) => <Map<String, dynamic>>[],
        (scriptList) => scriptList
            .map(
              (s) => {
                'id': s.id,
                'name': s.name,
                'content': s.content,
                'createdAt': s.createdAt.toIso8601String(),
                'updatedAt': s.updatedAt.toIso8601String(),
              },
            )
            .toList(),
      );

      final exportData = {
        'exportedAt': DateTime.now().toIso8601String(),
        'appVersion': _appVersion,
        'scriptCount': scripts.length,
        'scripts': scripts,
      };

      final jsonStr = const JsonEncoder.withIndent('  ').convert(exportData);

      // Write to temp file for sharing
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final exportFile = File(
        '${tempDir.path}/script_automator_export_$timestamp.json',
      );
      await exportFile.writeAsString(jsonStr);

      // Share via system share sheet
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(exportFile.path)],
          subject: 'Script Automator Export',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Export failed: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Settings",
          style: TextStyle(
            color: LiquidTheme.textDeep,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white.withValues(alpha: 0.2),
        elevation: 0,
        iconTheme: const IconThemeData(color: LiquidTheme.textDeep),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(color: Color(0xFFF3F4F6)),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            24,
            MediaQuery.of(context).padding.top + 70,
            24,
            60,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(
                "AI CONFIGURATION",
              ).animate().fadeIn().slideY(begin: 0.1),
              const SizedBox(height: 12),
              _buildOpenAiCard().animate(delay: 50.ms).fadeIn().slideY(begin: 0.1),
              const SizedBox(height: 16),
              _buildGeminiCard().animate(delay: 55.ms).fadeIn().slideY(begin: 0.1),

              const SizedBox(height: 32),

              _buildSectionTitle(
                "GENERAL",
              ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.1),
              const SizedBox(height: 12),
              _buildSettingsGroup([
                _buildToggleItem(
                  Icons.notifications_active_rounded,
                  "Push Notifications",
                  _notificationsEnabled,
                  (val) async {
                    setState(() => _notificationsEnabled = val);
                    await GetIt.I<UserPreferencesService>()
                        .setNotificationsEnabled(val);
                  },
                  LiquidTheme.cyan,
                ),
                _buildToggleItem(
                  Icons.dark_mode_rounded,
                  "Dark Mode",
                  _darkModeEnabled,
                  (val) async {
                    setState(() => _darkModeEnabled = val);
                    await GetIt.I<UserPreferencesService>().setDarkMode(val);
                    if (GetIt.I.isRegistered<ValueNotifier<ThemeMode>>()) {
                      GetIt.I<ValueNotifier<ThemeMode>>().value = val
                          ? ThemeMode.dark
                          : ThemeMode.light;
                    }
                  },
                  const Color(0xFF8B5CF6),
                ),
                _buildActionItem(
                  Icons.cleaning_services_rounded,
                  "Clear Cache",
                  _cacheSizeText,
                  _showClearCacheDialog,
                  const Color(0xFFF59E0B),
                ),
              ]).animate(delay: 150.ms).fadeIn().slideY(begin: 0.1),

              const SizedBox(height: 32),

              _buildSectionTitle(
                "ACCOUNT",
              ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1),
              const SizedBox(height: 12),
              _buildSettingsGroup([
                    _buildActionItem(
                      Icons.person_rounded,
                      "Edit Profile",
                      null,
                      _openEditProfile,
                      LiquidTheme.primary,
                    ),
                    _buildActionItem(
                      Icons.cloud_download_rounded,
                      "Export Data",
                      null,
                      _exportData,
                      const Color(0xFF10B981),
                    ),
                  ], isLastGroup: true)
                  .animate(delay: 250.ms)
                  .fadeIn()
                  .slideY(begin: 0.1),

              const SizedBox(height: 32),

              _buildSectionTitle(
                "ABOUT",
              ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1),
              const SizedBox(height: 12),
              _buildSettingsGroup([
                _buildActionItem(
                  Icons.info_outline_rounded,
                  "Version",
                  _appVersion,
                  () {},
                  Colors.grey.shade600,
                ),
                _buildActionItem(
                  Icons.description_rounded,
                  "Open Source Licenses",
                  null,
                  () {
                    showLicensePage(
                      context: context,
                      applicationName: "Script Automator",
                      applicationVersion: _appVersion,
                    );
                  },
                  Colors.grey.shade600,
                ),
                _buildActionItem(
                  Icons.bug_report_rounded,
                  "Send Feedback",
                  null,
                  _sendFeedback,
                  Colors.grey.shade600,
                ),
              ]).animate(delay: 350.ms).fadeIn().slideY(begin: 0.1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: LiquidTheme.textMedium.withValues(alpha: 0.7),
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildOpenAiCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: LiquidTheme.primary.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: LiquidTheme.primary.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: LiquidTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: LiquidTheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "OpenAI API Key (Default)",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: LiquidTheme.textDeep,
                      ),
                    ),
                    Text(
                      "Used for ChatGPT Ghost Text",
                      style: TextStyle(
                        fontSize: 12,
                        color: LiquidTheme.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _openAiKeyController,
            obscureText: true,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: _hasOpenAiKey
                  ? "Key is configured (Hidden)"
                  : "Paste sk-... Key here...",
              hintStyle: TextStyle(
                color: LiquidTheme.textMedium.withValues(alpha: 0.6),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: LiquidTheme.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoadingOpenAi ? null : _saveOpenAiKey,
              style: ElevatedButton.styleFrom(
                backgroundColor: LiquidTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isLoadingOpenAi
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      "Save Configuration",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
          if (_hasOpenAiKey) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green.shade600,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Actively using OpenAI Key",
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGeminiCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.8),
            Colors.white.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Gemini API Key (Optional)",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: LiquidTheme.textDeep,
                      ),
                    ),
                    Text(
                      "Used for Gemini code completion",
                      style: TextStyle(
                        fontSize: 12,
                        color: LiquidTheme.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _geminiKeyController,
            obscureText: true,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: _hasGeminiKey
                  ? "Key is configured (Hidden)"
                  : "Paste API Key here...",
              hintStyle: TextStyle(
                color: LiquidTheme.textMedium.withValues(alpha: 0.6),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.blueAccent),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoadingGemini ? null : _saveGeminiKey,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isLoadingGemini
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      "Save Configuration",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
          if (_hasGeminiKey) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green.shade600,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Actively using Gemini Key",
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(
    List<Widget> children, {
    bool isLastGroup = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          final idx = entry.key;
          final child = entry.value;
          final isLast = idx == children.length - 1;

          if (isLast) return child;
          return Column(
            children: [
              child,
              Divider(
                height: 1,
                thickness: 1,
                color: Colors.grey.withValues(alpha: 0.1),
                indent: 64,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildToggleItem(
    IconData icon,
    String title,
    bool value,
    ValueChanged<bool> onChanged,
    Color iconColor,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: LiquidTheme.textDeep,
          fontSize: 15,
        ),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeTrackColor: LiquidTheme.primary,
      ),
    );
  }

  Widget _buildActionItem(
    IconData icon,
    String title,
    String? trailingText,
    VoidCallback onTap,
    Color iconColor, {
    bool isDestructive = false,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDestructive ? Colors.red.shade600 : LiquidTheme.textDeep,
          fontSize: 15,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null) ...[
            Text(
              trailingText,
              style: TextStyle(
                color: LiquidTheme.textLight,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
          ],
          const Icon(
            Icons.chevron_right_rounded,
            color: LiquidTheme.textMedium,
            size: 20,
          ),
        ],
      ),
    );
  }
}
