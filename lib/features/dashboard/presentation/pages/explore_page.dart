import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/core/theme/liquid_colors.dart';
import 'package:script_automator/core/ui/glass_sliver_header.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:script_automator/features/script_management/domain/entities/script.dart';
import 'package:script_automator/features/script_management/domain/repositories/script_repository.dart';
import 'package:script_automator/features/dashboard/domain/repositories/gallery_repository.dart';
import 'package:script_automator/features/dashboard/presentation/widgets/glass_header_actions.dart';
import 'package:script_automator/features/dashboard/domain/services/notification_service.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:script_automator/core/security/script_integrity_checker.dart';
import 'package:script_automator/core/services/app_config_service.dart';
import 'package:script_automator/features/dashboard/presentation/widgets/install_progress_dialog.dart';

/// Explore/Discovery page that fetches scripts from the community gallery.
///
/// Displays categories, a search bar, and script cards sourced from
/// [GalleryRepository]. Users can install scripts directly to their
/// local [ScriptRepository].
class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  String _selectedCategory = "All";
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allScripts = [];
  bool _isLoading = true;
  String? _error;

  /// Maps gallery script IDs to their installed versions.
  /// Used to show "Installed" or "Update" badges.
  Map<String, String> _installedVersions = {};

  final List<String> _categories = [
    "All",
    "System",
    "Productivity",
    "Lifestyle",
    "Entertainment",
    "Other",
  ];

  /// Icon mapping for known script categories.
  static final Map<String, IconData> _categoryIcons = {
    'System': Icons.settings_suggest_rounded,
    'Productivity': Icons.checklist_rtl_rounded,
    'Lifestyle': Icons.favorite_rounded,
    'Entertainment': Icons.sports_esports_rounded,
    'Other': Icons.extension_rounded,
  };

  /// Color mapping for known script categories.
  static final Map<String, Color> _categoryColors = {
    'System': LiquidTheme.primary,
    'Productivity': const Color(0xFFEAB308),
    'Lifestyle': LiquidTheme.cyan,
    'Entertainment': const Color(0xFFEC4899),
    'Other': const Color(0xFF8B5CF6),
  };

  @override
  void initState() {
    super.initState();
    _loadGalleryData();
    _loadInstalledVersions();
  }

  /// Loads installed gallery script versions from existing scripts' settings.
  Future<void> _loadInstalledVersions() async {
    try {
      final result = await GetIt.I<ScriptRepository>().getScripts();
      result.fold((_) {}, (scripts) {
        final map = <String, String>{};
        for (final s in scripts) {
          final gid = s.settings['gallery_id'];
          final gver = s.settings['gallery_version'];
          if (gid != null && gver != null) {
            map[gid.toString()] = gver.toString();
          }
        }
        if (mounted) setState(() => _installedVersions = map);
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGalleryData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final templates = await GetIt.I<GalleryRepository>().getTemplates();
      setState(() {
        _allScripts = templates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    await _loadGalleryData();
    _searchController.clear();
    setState(() {
      _searchQuery = "";
      _selectedCategory = "All";
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiquidColors>()!;
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: LiquidTheme.primary,
      backgroundColor: colors.sheetBackground,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // ── Pinned Glass Header (fixed, NO collapse) ──
          SliverPersistentHeader(
            pinned: true,
            delegate: GlassSliverHeaderDelegate(
              height: MediaQuery.of(context).padding.top + 76,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Builder(
                        builder: (context) {
                          final colors = Theme.of(context).extension<LiquidColors>()!;
                          return Text(
                            "Explore",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: colors.textTitle,
                              letterSpacing: -1.2,
                            ),
                          );
                        },
                      ),
                      StreamBuilder<int>(
                        stream: GetIt.I<NotificationService>().unreadCount,
                        builder: (context, snapshot) {
                          final unread = snapshot.data ?? 0;
                          return GlassHeaderActions(
                            hasNotificationBadge: unread > 0,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Maintenance Mode Banner ──
          if (GetIt.I.isRegistered<AppConfigService>())
            SliverToBoxAdapter(
              child: ListenableBuilder(
                listenable: GetIt.I<AppConfigService>(),
                builder: (context, _) {
                  final config = GetIt.I<AppConfigService>();
                  if (!config.maintenanceMode) return const SizedBox.shrink();
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF78350F).withValues(alpha: 0.2)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.25 : 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded, 
                            color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706), 
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Gallery is in maintenance mode. Some features may be unavailable.',
                              style: TextStyle(
                                color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E), 
                                fontSize: 13, 
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          // ── Search Bar (scrollable) ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Builder(
                builder: (context) {
                  final colors = Theme.of(context).extension<LiquidColors>()!;
                  return Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: colors.searchBarBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colors.searchBarBorder,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.toLowerCase();
                        });
                      },
                      style: TextStyle(color: colors.textTitle),
                      decoration: InputDecoration(
                        hintText: "Search scripts, authors, tags...",
                        hintStyle: TextStyle(
                          color: colors.searchBarHint,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: colors.searchBarHint,
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.05);
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      "Categories",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: colors.textTitle,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        return _buildCategoryChip(
                          cat,
                          _selectedCategory == cat,
                          colors,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ).animate(delay: 200.ms).fadeIn(),
          ),
          SliverToBoxAdapter(child: _buildContent(colors)),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildContent(LiquidColors colors) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(60),
        child: Center(
          child: CircularProgressIndicator(color: LiquidTheme.primary),
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: colors.textCaption.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                "Failed to load scripts",
                style: TextStyle(
                  color: colors.textCaption.withValues(alpha: 0.8),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _loadGalleryData,
                child: Text(
                  "Tap to retry",
                  style: TextStyle(
                    color: LiquidTheme.primary.withValues(alpha: 0.8),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _searchQuery.isNotEmpty
                    ? "Search Results"
                    : _selectedCategory == "All"
                    ? "All Scripts"
                    : _selectedCategory,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colors.textTitle,
                ),
              ),
              Text(
                "${_filteredScripts.length} available",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: LiquidTheme.primary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._buildFilteredList(colors),
        ],
      ),
    ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.05);
  }

  List<Map<String, dynamic>> get _filteredScripts {
    return _allScripts.where((s) {
      if (_searchQuery.isNotEmpty) {
        return (s['name']?.toLowerCase().contains(_searchQuery) ?? false) ||
            (s['author']?.toLowerCase().contains(_searchQuery) ?? false) ||
            (s['description']?.toLowerCase().contains(_searchQuery) ?? false);
      } else {
        if (_selectedCategory == "All") return true;
        return s['category'] == _selectedCategory;
      }
    }).toList();
  }

  /// Cover from [coverUrl] when present; otherwise category gradient + icon.
  Widget _buildScriptCoverThumbnail(
    String coverUrl,
    IconData icon,
    Color color,
  ) {
    if (coverUrl.isEmpty) {
      return _categoryCoverPlaceholder(icon, color);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Image.network(
          coverUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _categoryCoverPlaceholder(icon, color),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.2),
                    color.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color.withValues(alpha: 0.85),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _categoryCoverPlaceholder(IconData icon, Color color) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected, LiquidColors colors) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = label;
          _searchController.clear();
          _searchQuery = "";
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? LiquidTheme.primary
              : colors.chipBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? LiquidTheme.primary
                : colors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : colors.textBody,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFilteredList(LiquidColors colors) {
    final filtered = _filteredScripts;

    if (filtered.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Text(
              "No scripts found matching your criteria.",
              style: TextStyle(
                color: colors.textCaption.withValues(alpha: 0.8),
              ),
            ),
          ),
        ),
      ];
    }

    return filtered.map((s) {
      final category = s['category'] ?? 'Utilities';
      final icon = _categoryIcons[category] ?? Icons.extension_rounded;
      final color = _categoryColors[category] ?? LiquidTheme.primary;
      final coverUrl = (s['coverUrl'] ?? '').trim();

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.cardBorder),
        ),
        child: Row(
          children: [
            _buildScriptCoverThumbnail(coverUrl, icon, color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s['name'] ?? 'Untitled',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.textTitle,
                    ),
                  ),
                  if ((s['author'] ?? '').isNotEmpty)
                    Text(
                      "by ${s['author']}",
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textCaption.withValues(alpha: 0.7),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildInstallButton(s),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildInstallButton(Map<String, dynamic> s) {
    final gid = s['id'] ?? s['name']?.toLowerCase().replaceAll(' ', '_') ?? '';
    final gver = s['version'] ?? '1.0.0';
    final installedVer = _installedVersions[gid];

    if (installedVer == null) {
      return GestureDetector(
        onTap: () => _installFromGallery(s),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [LiquidTheme.primary, LiquidTheme.cyan],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: LiquidTheme.primary.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Text(
            "Install",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      );
    } else if (installedVer != gver) {
      return GestureDetector(
        onTap: () => _installFromGallery(s),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange.shade500,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Text(
            "Update",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      );
    } else {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_rounded, 
              size: 14, 
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            const SizedBox(width: 4),
            Text(
              "Installed",
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }
  }

  /// Installs a script from the gallery with lazy content loading.
  /// If `content` is already embedded (offline fallback), uses it directly.
  /// Otherwise, downloads from `scriptUrl` first.
  Future<void> _installFromGallery(Map<String, dynamic> scriptData) async {
    final name = scriptData['name'] ?? 'Untitled';

    // Block installs during maintenance mode
    if (GetIt.I.isRegistered<AppConfigService>() &&
        GetIt.I<AppConfigService>().maintenanceMode) {
      showDialog(
        context: context,
        builder: (context) => InstallProgressDialog(
          scriptName: name,
          installTask: (updateProgress) async {
            throw Exception('Gallery is in maintenance mode. Installations are disabled.');
          },
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => InstallProgressDialog(
        scriptName: name,
        installTask: (updateProgress) async {
          final existingContent = scriptData['content'] ?? '';
          final scriptUrl = scriptData['scriptUrl'] ?? '';

          String finalContent = existingContent;

          if (finalContent.isEmpty && scriptUrl.isNotEmpty) {
            updateProgress('Connecting to store storage...');
            final response = await http
                .get(Uri.parse(scriptUrl))
                .timeout(const Duration(seconds: 15));
            if (response.statusCode == 200) {
              finalContent = utf8.decode(response.bodyBytes);
            } else {
              throw Exception('Server returned HTTP ${response.statusCode}');
            }
          }

          if (finalContent.isEmpty) {
            finalContent =
                '// $name\n// Installed from Gallery\n\n// Script content not available offline.';
          }

          // SHA-256 integrity check
          final expectedHash = scriptData['sha256'] as String?;
          final hasRemoteSource = scriptUrl.isNotEmpty && finalContent != existingContent;
          if (hasRemoteSource) {
            updateProgress('Verifying script integrity...');
            if (!ScriptIntegrityChecker.verify(finalContent, expectedHash)) {
              throw Exception('Script integrity check failed (SHA-256 mismatch). possible tampering detected.');
            }
          }

          updateProgress('Registering widget local storage...');
          final galleryId =
              scriptData['id'] ?? name.toLowerCase().replaceAll(' ', '_');
          final galleryVersion = scriptData['version'] ?? '1.0.0';

          final script = Script(
            id: 'gallery_${name.toLowerCase().replaceAll(' ', '_')}',
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
          
          // Refresh versions listing in state
          await _loadInstalledVersions();
        },
      ),
    );
  }
}
