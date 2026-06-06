import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/core/theme/liquid_colors.dart';
import 'package:script_automator/features/dashboard/data/services/user_preferences_service.dart';
import 'package:script_automator/features/dashboard/presentation/widgets/edit_profile_sheet.dart';
import 'package:script_automator/features/script_management/domain/repositories/script_repository.dart';
import 'package:script_automator/features/script_management/domain/entities/script.dart';
import 'package:script_automator/features/script_management/data/datasources/script_local_data_source.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:script_automator/features/dashboard/presentation/widgets/settings_widgets.dart';
import 'package:script_automator/features/dashboard/presentation/widgets/settings_auth_section.dart';
import 'package:script_automator/features/dashboard/presentation/widgets/feedback_sheet.dart';

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
    final isDarkRaw = await prefs.isDarkModeRaw;
    final bool darkMode;
    if (isDarkRaw != null) {
      darkMode = isDarkRaw;
    } else {
      if (GetIt.I.isRegistered<ValueNotifier<ThemeMode>>()) {
        final currentMode = GetIt.I<ValueNotifier<ThemeMode>>().value;
        if (currentMode == ThemeMode.dark) {
          darkMode = true;
        } else if (currentMode == ThemeMode.light) {
          darkMode = false;
        } else {
          darkMode = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
        }
      } else {
        darkMode = false;
      }
    }
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
        // Cache cleared
      }
    } catch (e) {
      if (mounted) {
        // Failed
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
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FeedbackSheet(appVersion: _appVersion),
    );

    if (submitted == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Feedback submitted! Thank you.',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          backgroundColor: LiquidTheme.cyan,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
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
      debugPrint("Export failed: $e");
    }
  }

  Future<void> _showAndroidWidgetConfigSheet() async {
    const channel = MethodChannel('com.js.scriptAutomator/widget');
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: LiquidTheme.cyan),
      ),
    );

    List<int> widgetIds = [];
    Map<String, String> associations = {};
    try {
      final List<dynamic>? ids = await channel.invokeMethod<List<dynamic>>('getAndroidWidgetIds');
      if (ids != null) {
        widgetIds = ids.cast<int>();
      }
      final Map<dynamic, dynamic>? assoc = await channel.invokeMethod<Map<dynamic, dynamic>>('getWidgetAssociations');
      if (assoc != null) {
        assoc.forEach((key, val) {
          associations[key.toString()] = val.toString();
        });
      }
    } catch (e) {
      debugPrint("Failed to fetch widget data: $e");
    }

    if (!mounted) return;
    Navigator.pop(context); // Dismiss loading dialog

    final repo = GetIt.I<ScriptRepository>();
    final scriptsResult = await repo.getScripts();
    final scripts = scriptsResult.fold((_) => <Script>[], (list) => list);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final colors = Theme.of(context).extension<LiquidColors>()!;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  24,
                  24,
                  24,
                  MediaQuery.of(context).viewInsets.bottom + 40,
                ),
                decoration: BoxDecoration(
                  color: colors.sheetBackground.withValues(alpha: 0.85),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: colors.textCaption.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Home Widgets",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: colors.textTitle,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Configure which script runs and displays output on each home screen widget.",
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textCaption,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (widgetIds.isEmpty) ...[
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colors.cardBackground.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.widgets_outlined,
                                size: 48,
                                color: colors.textCaption.withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "No Active Widgets Found",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colors.textTitle,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                "To add a widget:\n1. Long-press your phone's home screen.\n2. Select 'Widgets' and search for 'Script Automator'.\n3. Add a widget and return here to configure it.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colors.textCaption,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: widgetIds.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final wId = widgetIds[index];
                            final currentScriptId = associations["widget_$wId"];

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colors.cardBackground,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: colors.cardBorder,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: LiquidTheme.cyan.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.widgets_rounded,
                                      color: LiquidTheme.cyan,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Widget #$wId",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: colors.textTitle,
                                            fontSize: 15,
                                          ),
                                        ),
                                        Text(
                                          currentScriptId == null
                                              ? "Showing last run script"
                                              : "Running selected script",
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: colors.textCaption,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Theme(
                                    data: Theme.of(context).copyWith(
                                      canvasColor: colors.sheetBackground,
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String?>(
                                        value: currentScriptId,
                                        icon: Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: colors.textCaption,
                                        ),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: colors.textTitle,
                                        ),
                                        onChanged: (newScriptId) async {
                                          try {
                                            await channel.invokeMethod(
                                              'associateWidgetWithScript',
                                              {
                                                'widgetId': wId,
                                                'scriptId': newScriptId,
                                              },
                                            );
                                            setModalState(() {
                                              if (newScriptId == null) {
                                                associations.remove("widget_$wId");
                                              } else {
                                                associations["widget_$wId"] = newScriptId;
                                              }
                                            });
                                          } catch (e) {
                                            debugPrint("Failed to associate widget: $e");
                                          }
                                        },
                                        items: [
                                          DropdownMenuItem<String?>(
                                            value: null,
                                            child: Text(
                                              "Last Run",
                                              style: TextStyle(
                                                color: colors.textCaption,
                                              ),
                                            ),
                                          ),
                                          ...scripts.map(
                                            (s) => DropdownMenuItem<String?>(
                                              value: s.id,
                                              child: Text(s.name),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
                if (Platform.isAndroid)
                  SettingsActionItem(
                    icon: Icons.widgets_rounded,
                    title: "Configure Home Widgets",
                    onTap: _showAndroidWidgetConfigSheet,
                    iconColor: const Color(0xFF10B981),
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
                      iconColor: const Color(0xFF8B5CF6),
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
                        final nav = Navigator.of(context, rootNavigator: true);
                        final signedOut = await confirmAndSignOut(context);
                        if (signedOut && mounted) {
                          nav.popUntil((route) => route.isFirst);
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
                  iconColor: colors.textCaption,
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
                  iconColor: colors.textCaption,
                ),
                SettingsActionItem(
                  icon: Icons.bug_report_rounded,
                  title: "Send Feedback",
                  onTap: _sendFeedback,
                  iconColor: colors.textCaption,
                ),
              ]).animate(delay: 350.ms).fadeIn().slideY(begin: 0.1),
            ],
          ),
        ),
      ),
    );
  }

}

