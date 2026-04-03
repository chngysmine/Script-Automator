import 'package:flutter/material.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:script_automator/features/script_management/domain/entities/script.dart';
import 'package:script_automator/features/script_management/domain/repositories/script_repository.dart';
import 'package:script_automator/features/dashboard/domain/repositories/gallery_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

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
  List<Map<String, String>> _allScripts = [];
  bool _isLoading = true;
  String? _error;

  /// Maps gallery script IDs to their installed versions.
  /// Used to show "Installed" or "Update" badges.
  Map<String, String> _installedVersions = {};

  final List<String> _categories = [
    "All",
    "Weather",
    "Finance",
    "Utilities",
    "AI",
    "Games",
  ];

  /// Icon mapping for known script categories.
  static final Map<String, IconData> _categoryIcons = {
    'Weather': Icons.cloud_rounded,
    'Finance': Icons.currency_bitcoin_rounded,
    'Utilities': Icons.build_rounded,
    'AI': Icons.auto_awesome,
    'Games': Icons.sports_esports_rounded,
  };

  /// Color mapping for known script categories.
  static final Map<String, Color> _categoryColors = {
    'Weather': LiquidTheme.cyan,
    'Finance': const Color(0xFFEAB308),
    'Utilities': LiquidTheme.primary,
    'AI': const Color(0xFF8B5CF6),
    'Games': const Color(0xFFEC4899),
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
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: LiquidTheme.primary,
      backgroundColor: Colors.white,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Explore",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: LiquidTheme.textDeep,
                        letterSpacing: -1.2,
                      ),
                    ).animate().fadeIn(duration: 300.ms),
                    const SizedBox(height: 16),
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.toLowerCase();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: "Search scripts, authors, tags...",
                          hintStyle: TextStyle(
                            color: LiquidTheme.textLight.withValues(alpha: 0.5),
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: LiquidTheme.textLight.withValues(alpha: 0.5),
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.05),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      "Categories",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: LiquidTheme.textDeep,
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
                        );
                      },
                    ),
                  ),
                ],
              ),
            ).animate(delay: 200.ms).fadeIn(),
          ),
          SliverToBoxAdapter(child: _buildContent()),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildContent() {
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
                color: LiquidTheme.textLight.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                "Failed to load scripts",
                style: TextStyle(
                  color: LiquidTheme.textLight.withValues(alpha: 0.8),
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
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: LiquidTheme.textDeep,
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
          ..._buildFilteredList(),
        ],
      ),
    ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.05);
  }

  List<Map<String, String>> get _filteredScripts {
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

  Widget _buildCategoryChip(String label, bool isSelected) {
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
              : Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? LiquidTheme.primary
                : Colors.white.withValues(alpha: 0.8),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : LiquidTheme.textMedium,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFilteredList() {
    final filtered = _filteredScripts;

    if (filtered.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Text(
              "No scripts found matching your criteria.",
              style: TextStyle(
                color: LiquidTheme.textLight.withValues(alpha: 0.8),
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

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
        ),
        child: Row(
          children: [
            Container(
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
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s['name'] ?? 'Untitled',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: LiquidTheme.textDeep,
                    ),
                  ),
                  if ((s['author'] ?? '').isNotEmpty)
                    Text(
                      "by ${s['author']}",
                      style: TextStyle(
                        fontSize: 12,
                        color: LiquidTheme.textLight.withValues(alpha: 0.7),
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

  Widget _buildInstallButton(Map<String, String> s) {
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
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded, size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              "Installed",
              style: TextStyle(
                color: Colors.grey.shade600,
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
  Future<void> _installFromGallery(Map<String, String> scriptData) async {
    final name = scriptData['name'] ?? 'Untitled';
    final existingContent = scriptData['content'] ?? '';
    final scriptUrl = scriptData['scriptUrl'] ?? '';

    // Show loading indicator
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Installing $name..."),
        backgroundColor: LiquidTheme.primary,
        duration: const Duration(seconds: 10),
        behavior: SnackBarBehavior.floating,
      ),
    );

    String finalContent = existingContent;

    if (finalContent.isEmpty && scriptUrl.isNotEmpty) {
      try {
        final response = await http
            .get(Uri.parse(scriptUrl))
            .timeout(const Duration(seconds: 15));
        if (response.statusCode == 200) {
          finalContent = response.body;
        } else {
          throw Exception('HTTP ${response.statusCode}');
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to download $name: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    if (finalContent.isEmpty) {
      finalContent =
          '// $name\n// Installed from Gallery\n\n// Script content not available offline.';
    }

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
    await _loadInstalledVersions();

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$name installed successfully!"),
        backgroundColor: LiquidTheme.primary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
