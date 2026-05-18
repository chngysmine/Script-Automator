import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/core/theme/liquid_colors.dart';
import 'package:script_automator/features/dashboard/data/services/user_preferences_service.dart';
import 'package:script_automator/features/dashboard/presentation/widgets/edit_profile_sheet.dart';
import 'package:script_automator/features/script_management/domain/repositories/script_repository.dart';
import 'package:script_automator/features/script_management/data/datasources/script_local_data_source.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:script_automator/features/dashboard/presentation/widgets/settings_widgets.dart';
import 'package:script_automator/features/dashboard/presentation/widgets/settings_auth_section.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // App settings state
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  // Profile state (loaded from UserPreferencesService)
  String _displayName = '';
  String _displayBio = '';

  // Cache state (calculated from disk)
  String _cacheSizeText = '—';

  // App version (from PackageInfo)
  String _appVersion = '—';

  @override
  void initState() {
    super.initState();
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



  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final colors = Theme.of(context).extension<LiquidColors>()!;
        return AlertDialog(
          backgroundColor: colors.sheetBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            "Clear Cache",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colors.textTitle,
            ),
          ),
          content: Text(
            "Clear $_cacheSizeText of temporary data? Your scripts and settings will not be affected.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(color: colors.textCaption),
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
        );
      },
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
      'Hi Script Automator Team,\n\n'
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
    final messenger = ScaffoldMessenger.of(context);
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
      messenger.showSnackBar(
        SnackBar(
          content: Text("Export failed: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiquidColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "Settings",
          style: TextStyle(
            color: colors.textTitle,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: colors.glassOverlay,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textTitle),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF3F4F6),
        ),
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

              const SettingsSectionTitle(
                "GENERAL",
              ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.1),
              const SizedBox(height: 12),
              SettingsGroup(children: [
                SettingsToggleItem(
                  icon: Icons.notifications_active_rounded,
                  title: "Push Notifications",
                  value: _notificationsEnabled,
                  onChanged: (val) async {
                    setState(() => _notificationsEnabled = val);
                    await GetIt.I<UserPreferencesService>()
                        .setNotificationsEnabled(val);
                  },
                  iconColor: LiquidTheme.cyan,
                ),
                SettingsToggleItem(
                  icon: Icons.dark_mode_rounded,
                  title: "Dark Mode",
                  value: _darkModeEnabled,
                  onChanged: (val) async {
                    setState(() => _darkModeEnabled = val);
                    await GetIt.I<UserPreferencesService>().setDarkMode(val);
                    if (GetIt.I.isRegistered<ValueNotifier<ThemeMode>>()) {
                      GetIt.I<ValueNotifier<ThemeMode>>().value = val
                          ? ThemeMode.dark
                          : ThemeMode.light;
                    }
                  },
                  iconColor: const Color(0xFF8B5CF6),
                ),
                SettingsActionItem(
                  icon: Icons.cleaning_services_rounded,
                  title: "Clear Cache",
                  trailingText: _cacheSizeText,
                  onTap: _showClearCacheDialog,
                  iconColor: const Color(0xFFF59E0B),
                ),
              ]).animate(delay: 150.ms).fadeIn().slideY(begin: 0.1),

              const SizedBox(height: 32),

              const SettingsSectionTitle(
                "ACCOUNT",
              ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1),
              const SizedBox(height: 12),
              SettingsGroup(children: [
                    SettingsActionItem(
                      icon: Icons.person_rounded,
                      title: "Edit Profile",
                      onTap: _openEditProfile,
                      iconColor: LiquidTheme.primary,
                    ),
                    SettingsActionItem(
                      icon: Icons.cloud_download_rounded,
                      title: "Export Data",
                      onTap: _exportData,
                      iconColor: const Color(0xFF10B981),
                    ),
                    SettingsActionItem(
                      icon: Icons.sync_rounded,
                      title: "Sync to Cloud",
                      trailingText: buildAuthSubtitle(),
                      onTap: () => syncToCloud(context),
                      iconColor: LiquidTheme.cyan,
                    ),
                    if (isAnonymousUser())
                      SettingsActionItem(
                        icon: Icons.link_rounded,
                        title: "Link Account",
                        trailingText: "Upgrade from Guest",
                        onTap: () => showLinkAccountSheet(context,
                            onLinked: () => setState(() {})),
                        iconColor: const Color(0xFF8B5CF6),
                      ),
                    SettingsActionItem(
                      icon: Icons.logout_rounded,
                      title: "Sign Out",
                      onTap: () async {
                        if (mounted) {
                          await confirmAndSignOut(context);
                        }
                      },
                      iconColor: const Color(0xFFEF4444),
                    ),
                  ])
                  .animate(delay: 250.ms)
                  .fadeIn()
                  .slideY(begin: 0.1),

              const SizedBox(height: 32),

              const SettingsSectionTitle(
                "ABOUT",
              ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1),
              const SizedBox(height: 12),
              SettingsGroup(children: [
                SettingsActionItem(
                  icon: Icons.info_outline_rounded,
                  title: "Version",
                  trailingText: _appVersion,
                  onTap: () {},
                  iconColor: Colors.grey.shade600,
                ),
                SettingsActionItem(
                  icon: Icons.description_rounded,
                  title: "Open Source Licenses",
                  onTap: () {
                    showLicensePage(
                      context: context,
                      applicationName: "Script Automator",
                      applicationVersion: _appVersion,
                    );
                  },
                  iconColor: Colors.grey.shade600,
                ),
                SettingsActionItem(
                  icon: Icons.bug_report_rounded,
                  title: "Send Feedback",
                  onTap: _sendFeedback,
                  iconColor: Colors.grey.shade600,
                ),
              ]).animate(delay: 350.ms).fadeIn().slideY(begin: 0.1),
            ],
          ),
        ),
      ),
    );
  }

}

