import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/features/script_management/domain/entities/script.dart';
import 'package:script_automator/features/dashboard/presentation/widgets/premium_bento_card.dart';
import 'package:script_automator/features/script_management/domain/repositories/script_repository.dart';
import 'package:script_automator/features/dashboard/domain/repositories/gallery_repository.dart';
import 'package:script_automator/features/script_management/data/services/git_service.dart';
import 'package:get_it/get_it.dart';
import 'package:script_automator/features/dashboard/presentation/widgets/glass_header_actions.dart';
import 'package:script_automator/features/dashboard/domain/services/notification_service.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  late Future<List<Map<String, String>>> _templatesFuture;
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
    return FutureBuilder<List<Map<String, String>>>(
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
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        "Script Store",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: LiquidTheme.textDeep,
                          letterSpacing: -1.2,
                        ),
                      ),
                      Row(
                        children: [
                          _buildHeaderAction(
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

            // Filter & Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  children: [
                    // Search Input
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
                        onChanged: (val) =>
                            setState(() => _searchQuery = val.toLowerCase()),
                        decoration: InputDecoration(
                          hintText: "Search in gallery...",
                          hintStyle: TextStyle(
                            color: LiquidTheme.textLight.withValues(alpha: 0.5),
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: LiquidTheme.textLight.withValues(alpha: 0.5),
                            size: 20,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close, size: 16),
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
                    ),
                    const SizedBox(height: 16),
                    // Sort & Categories
                    Row(
                      children: [
                        // Sort Dropdown
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _sortOption,
                              icon: const Icon(
                                Icons.sort_rounded,
                                size: 16,
                                color: LiquidTheme.textMedium,
                              ),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: LiquidTheme.textDeep,
                              ),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() => _sortOption = newValue);
                                }
                              },
                              items: _sortOptions.map<DropdownMenuItem<String>>(
                                (String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                },
                              ).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
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
                                          : Colors.white.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      cat,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? Colors.white
                                            : LiquidTheme.textMedium,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 1. Featured Section (hide if searching)
            if (featured.isNotEmpty && _searchQuery.isEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Text(
                    "Editor's Choice",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: LiquidTheme.textDeep,
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
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 40, 24, 16),
                  child: Text(
                    "New Releases",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: LiquidTheme.textDeep,
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
                          color: LiquidTheme.textLight.withValues(alpha: 0.8),
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

  Widget _buildBentoCardFromMap(Map<String, String> item, BentoSize size) {
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

  Widget _buildHeaderAction({
    required IconData icon,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: IconButton(
        icon: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isPrimary
                ? LiquidTheme.primary.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.5),
            shape: BoxShape.circle,
            border: Border.all(
              color: isPrimary
                  ? LiquidTheme.primary.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.5),
            ),
          ),
          child: Icon(
            icon,
            color: isPrimary ? LiquidTheme.primary : LiquidTheme.textDeep,
            size: 20,
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }

  // --- Actions ---

  void _showPreview(BuildContext context, Map<String, String> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPreviewSheet(context, item),
    );
  }

  Widget _buildPreviewSheet(BuildContext context, Map<String, String> item) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
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
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: LiquidTheme.textDeep,
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
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: LiquidTheme.textMedium,
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
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Import Script",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: LiquidTheme.textDeep,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Enter a Raw URL (GitHub, Pastebin) to cloud-import a widget script.",
                    style: TextStyle(
                      fontSize: 14,
                      color: LiquidTheme.textLight,
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
                      fillColor: Colors.white.withValues(alpha: 0.5),
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
                              color: LiquidTheme.textLight,
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
      ),
    );
  }

  Future<void> _processUrlImport(String url) async {
    // Show Loading
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Downloading script...")));

    try {
      final gitService = GitService();
      final content = await gitService.downloadScript(url);

      // Basic naming strategy
      final name = url
          .split('/')
          .last
          .replaceAll('.js', '')
          .replaceAll('.json', '');

      if (mounted) {
        final item = {
          'name': name,
          'content': content,
          'description': 'Imported from $url',
        };
        await _installScript(context, item);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to import: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _installScript(
    BuildContext context,
    Map<String, String> item,
  ) async {
    final name = item['name'] ?? 'Untitled';
    final existingContent = item['content'] ?? '';
    final scriptUrl = item['scriptUrl'] ?? '';

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Installing $name..."),
          backgroundColor: LiquidTheme.primary,
          duration: const Duration(seconds: 10),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

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
        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to download $name: $e"),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    }

    if (finalContent.isEmpty) {
      finalContent =
          '// $name\n// Installed from Gallery\n\n// Script content not available offline.';
    }

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
      },
    );
    await repo.saveScript(script);

    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Installed $name"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: LiquidTheme.primary,
        ),
      );
    }
  }
}
