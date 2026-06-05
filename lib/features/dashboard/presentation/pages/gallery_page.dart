import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:script_automator/features/dashboard/presentation/widgets/install_progress_dialog.dart';

import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/core/theme/liquid_colors.dart';
import 'package:script_automator/features/script_management/domain/entities/script.dart';
import 'package:script_automator/features/dashboard/presentation/widgets/premium_bento_card.dart';
import 'package:script_automator/features/script_management/domain/repositories/script_repository.dart';
import 'package:script_automator/features/dashboard/domain/repositories/gallery_repository.dart';
import 'package:script_automator/features/script_management/data/services/git_service.dart';
import 'package:get_it/get_it.dart';
import 'package:script_automator/features/dashboard/presentation/widgets/glass_header_actions.dart';
import 'package:script_automator/features/dashboard/domain/services/notification_service.dart';
import 'package:script_automator/core/ui/glass_sliver_header.dart';
import 'package:script_automator/core/security/script_integrity_checker.dart';
import 'package:script_automator/core/services/app_config_service.dart';
import 'package:script_automator/core/ui/styled_dropdown.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  late Future<List<Map<String, dynamic>>> _templatesFuture;
  final ScrollController _scrollController = ScrollController();

  // Filter & Sort State
  String _searchQuery = "";
  String _selectedCategory = "All";
  String _sortOption = "Popular";
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    "All",
    "Weather",
    "Finance",
    "Utilities",
    "AI",
    "Games",
  ];
  final List<String> _sortOptions = ["Popular", "Newest", "A-Z"];

  @override
  void initState() {
    super.initState();
    _templatesFuture = GetIt.I<GalleryRepository>().getTemplates();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiquidColors>()!;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _templatesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Failed to load gallery",
              style: TextStyle(color: Colors.red[400]),
            ),
          );
        }

        final items = snapshot.data ?? [];

        // Apply filters
        var filteredList = items.where((i) {
          final matchesSearch =
              _searchQuery.isEmpty ||
              (i['name']?.toLowerCase().contains(_searchQuery) ?? false) ||
              (i['author']?.toLowerCase().contains(_searchQuery) ?? false);

          final matchesCategory =
              _selectedCategory == "All" ||
              (i['category'] == _selectedCategory);

          return matchesSearch && matchesCategory;
        }).toList();

        // Apply sort
        if (_sortOption == "A-Z") {
          filteredList.sort(
            (a, b) => (a['name'] ?? "").compareTo(b['name'] ?? ""),
          );
        } else if (_sortOption == "Newest") {
          // Date sorting for real data
          filteredList = filteredList.reversed.toList();
        }

        final featured = filteredList
            .where((i) => i['isFeatured'] == 'true')
            .toList();
        final others = filteredList
            .where((i) => i['isFeatured'] != 'true')
            .toList();

        return CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // ── Pinned Glass Header (fixed, NO collapse) ──
            SliverPersistentHeader(
              pinned: true,
              delegate: GlassSliverHeaderDelegate(
                height: MediaQuery.of(context).padding.top + 64,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Script Store",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: colors.textTitle,
                            letterSpacing: -1.2,
                          ),
                        ),
                        Row(
                          children: [
                            _buildHeaderAction(context,
                              icon: Icons.cloud_download_rounded,
                              onPressed: _showImportDialog,
                              isPrimary: true,
                            ),
                            const SizedBox(width: 12),
                            StreamBuilder<int>(
                              stream: GetIt.I<NotificationService>().unreadCount,
                              builder: (context, snapshot) {
                                return GlassHeaderActions(
                                  hasNotificationBadge: (snapshot.data ?? 0) > 0,
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Filter & Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  children: [
                    // Search Input
                    Builder(
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
                            onChanged: (val) =>
                                setState(() => _searchQuery = val.toLowerCase()),
                            style: TextStyle(color: colors.textTitle),
                            decoration: InputDecoration(
                              hintText: "Search in gallery...",
                              hintStyle: TextStyle(
                                color: colors.searchBarHint,
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: colors.searchBarHint,
                                size: 20,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.close, size: 16, color: colors.textCaption),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = "");
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    // Sort & Categories
                    Builder(
                      builder: (context) {
                        final colors = Theme.of(context).extension<LiquidColors>()!;
                        return Row(
                          children: [
                            // Sort Dropdown
                            StyledDropdown<String>(
                              value: _sortOption,
                              items: _sortOptions,
                              labelBuilder: (item) => item,
                              onChanged: (val) => setState(() => _sortOption = val),
                              icon: Icons.sort_rounded,
                              width: 140,
                            ),
                            const SizedBox(width: 10),
                            // Category Tabs horizontally scrolling
                            Expanded(
                              child: SizedBox(
                                height: 36,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _categories.length,
                                  itemBuilder: (context, index) {
                                    final cat = _categories[index];
                                    final isSelected = _selectedCategory == cat;
                                    return GestureDetector(
                                      onTap: () =>
                                          setState(() => _selectedCategory = cat),
                                      child: Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? LiquidTheme.primary
                                              : colors.chipBackground,
                                          borderRadius: BorderRadius.circular(20),
                                          border: isSelected
                                              ? null
                                              : Border.all(color: colors.cardBorder),
                                        ),
                                        child: Text(
                                          cat,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected
                                                ? Colors.white
                                                : colors.textBody,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // 1. Featured Section (hide if searching)
            if (featured.isNotEmpty && _searchQuery.isEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Text(
                    "Editor's Choice",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: colors.textTitle,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 240,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: featured.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: SizedBox(
                          width: 320,
                          child: _buildBentoCardFromMap(
                            featured[index],
                            BentoSize.large,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],

            // 2. Main Feed
            ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
                  child: Text(
                    "New Releases",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: colors.textTitle,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
              if (others.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Center(
                      child: Text(
                        "No scripts found matching $_searchQuery",
                        style: TextStyle(
                          color: colors.textCaption.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.85,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return _buildBentoCardFromMap(
                        others[index],
                        BentoSize.small,
                      );
                    }, childCount: others.length),
                  ),
                ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ],
        );
      },
    );
  }

  // --- Components ---

  Widget _buildBentoCardFromMap(Map<String, dynamic> item, BentoSize size) {
    final embedded = item['content'] ?? '';
    final scriptUrl = item['scriptUrl'] ?? '';
    final previewContent = embedded.isNotEmpty
        ? embedded
        : (scriptUrl.isNotEmpty
            ? '// Remote script (gallery)\n// Tap card → Install to download'
            : '');

    final displayScript = Script(
      id: item['id'] ?? 'unknown',
      name: item['name'] ?? 'Unknown Script',
      content: previewContent,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return PremiumBentoCard(
      script: displayScript,
      size: size,
      onTap: () => _showPreview(context, item),
    );
  }

  Widget _buildHeaderAction(BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    final colors = Theme.of(context).extension<LiquidColors>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: IconButton(
        icon: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isPrimary
                ? LiquidTheme.primary.withValues(alpha: 0.1)
                : colors.cardBackground,
            shape: BoxShape.circle,
            border: Border.all(
              color: isPrimary
                  ? LiquidTheme.primary.withValues(alpha: 0.2)
                  : colors.cardBorder,
            ),
          ),
          child: Icon(
            icon,
            color: isPrimary ? LiquidTheme.primary : colors.textTitle,
            size: 20,
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }

  // --- Actions ---

  void _showPreview(BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final colors = Theme.of(context).extension<LiquidColors>()!;
        return _buildPreviewSheet(context, item, colors);
      },
    );
  }

  Widget _buildPreviewSheet(BuildContext context, Map<String, dynamic> item, LiquidColors colors) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: colors.sheetBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: const Icon(
              Icons.widgets_rounded,
              size: 40,
              color: LiquidTheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            item['name']!,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colors.textTitle,
            ),
          ),
          Text(
            "${item['author'] ?? 'Community'} • ${item['version'] ?? 'V1.0'}",
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // Action Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: LiquidTheme.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  final content = item['content'] ?? '';
                  final url = item['scriptUrl'] ?? '';
                  if (content.isEmpty && url.isNotEmpty) {
                    _processUrlImport(url);
                  } else {
                    _installScript(context, item);
                  }
                },
                child: const Text(
                  "Install Script",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          // Description
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Description",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['description']!,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: colors.textBody,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if ((item['scriptUrl'] ?? '').isNotEmpty)
                    Row(
                      children: [
                        const Icon(
                          Icons.cloud_download_outlined,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Cloud Script (Lazy Load)",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImportDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        final colors = Theme.of(context).extension<LiquidColors>()!;
        return Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: colors.cardBackground,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: colors.cardBorder,
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Text(
                      "Import Script",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: colors.textTitle,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Enter a Raw URL (GitHub, Pastebin) to cloud-import a widget script.",
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textCaption,
                        height: 1.4,
                      ),
                    ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: controller,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: "https://raw.githubusercontent.com/...",
                      filled: true,
                      fillColor: colors.inputBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.link_rounded),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            "CANCEL",
                            style: TextStyle(
                              color: colors.textCaption,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            final url = controller.text.trim();
                            if (url.isNotEmpty) {
                              Navigator.pop(context);
                              _processUrlImport(url);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: LiquidTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "IMPORT",
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      },
    );
  }

  Future<void> _processUrlImport(String url) async {
    if (!mounted) return;

    if (!url.startsWith('https://')) {
      showDialog(
        context: context,
        builder: (context) => InstallProgressDialog(
          scriptName: 'Import from URL',
          installTask: (updateProgress) async {
            throw Exception('Only HTTPS URLs are allowed for security.');
          },
        ),
      );
      return;
    }

    final name = url
        .split('/')
        .last
        .replaceAll('.js', '')
        .replaceAll('.json', '');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => InstallProgressDialog(
        scriptName: name,
        installTask: (updateProgress) async {
          updateProgress('Downloading remote script...');
          final gitService = GitService();
          final content = await gitService.downloadScript(url);

          updateProgress('Registering widget local storage...');
          final script = Script(
            id: 'gallery_${name.toLowerCase().replaceAll(' ', '_')}',
            name: name,
            content: content,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            settings: {
              'gallery_id': name.toLowerCase().replaceAll(' ', '_'),
              'gallery_version': '1.0.0',
              'gallery_script_url': url,
              'is_modified_from_gallery': false,
            },
          );
          final repo = GetIt.I<ScriptRepository>();
          await repo.saveScript(script);
        },
      ),
    );
  }

  Future<void> _installScript(
    BuildContext context,
    Map<String, dynamic> item,
  ) async {
    final name = item['name'] ?? 'Untitled';

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
          final existingContent = item['content'] ?? '';
          final scriptUrl = item['scriptUrl'] ?? '';

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

          // SHA-256 integrity check for remotely downloaded scripts
          final expectedHash = item['sha256'] as String?;
          final hasRemoteSource = scriptUrl.isNotEmpty && finalContent != existingContent;
          if (hasRemoteSource) {
            updateProgress('Verifying script integrity...');
            if (!ScriptIntegrityChecker.verify(finalContent, expectedHash)) {
              throw Exception('Script integrity check failed (SHA-256 mismatch). possible tampering detected.');
            }
          }

          updateProgress('Registering widget local storage...');
          final galleryId =
              item['id'] ?? name.toLowerCase().replaceAll(' ', '_');
          final galleryVersion = item['version'] ?? '1.0.0';

          final repo = GetIt.I<ScriptRepository>();
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
              'is_modified_from_gallery': false,
            },
          );
          await repo.saveScript(script);
        },
      ),
    );
  }
}
