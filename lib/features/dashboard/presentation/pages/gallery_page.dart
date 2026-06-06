import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:script_automator/features/dashboard/presentation/widgets/install_progress_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    "System",
    "Productivity",
    "Lifestyle",
    "Entertainment",
    "Other",
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
                height: MediaQuery.of(context).padding.top + 76,
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
                              iconOnly: true,
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

  Future<void> _reportScript(BuildContext context, Map<String, dynamic> item) async {
    final scriptId = item['id'] ?? item['script_id'] ?? item['name'] ?? 'unknown';
    
    final confirmReport = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(dialogContext).brightness == Brightness.dark
            ? const Color(0xFF090D16)
            : Colors.white,
        title: Text(
          'Report Script',
          style: TextStyle(
            color: Theme.of(dialogContext).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to report "${item['name']}" for moderation review?',
          style: TextStyle(
            color: Theme.of(dialogContext).brightness == Brightness.dark
                ? Colors.white70
                : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Report'),
          ),
        ],
      ),
    );

    if (confirmReport == true) {
      try {
        final docRef = FirebaseFirestore.instance.collection('script_moderation').doc(scriptId);
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final snapshot = await transaction.get(docRef);
          if (snapshot.exists) {
            final currentReports = snapshot.data()?['reports_count'] ?? 0;
            transaction.update(docRef, {
              'reports_count': currentReports + 1,
              'updated_at': FieldValue.serverTimestamp(),
            });
          } else {
            transaction.set(docRef, {
              'reports_count': 1,
              'is_blocked': false,
              'updated_at': FieldValue.serverTimestamp(),
            });
          }
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thank you! Script has been reported for moderation review.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to submit report: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildPreviewSheet(BuildContext context, Map<String, dynamic> item, LiquidColors colors) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final content = item['content'] ?? '';
    final url = item['scriptUrl'] ?? '';
    final sha256 = item['sha256'] as String? ?? '';
    final category = item['category'] ?? 'General';
    final author = item['author'] ?? 'Community';
    final version = item['version'] ?? '1.0.0';
    
    final rawDesc = item['description'] as String? ?? '';
    final description = rawDesc.trim();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: BoxDecoration(
            color: isDark 
                ? LiquidTheme.darkBackground.withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: colors.glassBorder,
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Transparent Top Control Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Pull indicator bar
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white30 : Colors.black26,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                    // Floating report/flag button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => _reportScript(context, item),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.outlined_flag_rounded,
                            size: 20,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    ),
                    // Floating back/close button
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: colors.textTitle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Avatar Row (Avatar on left, Name & Badges on right)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar / Icon
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [LiquidTheme.cyan, LiquidTheme.primary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: LiquidTheme.primary.withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.widgets_rounded,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Name & Badges Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name']!,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: colors.textTitle,
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Metadata Badges (Horizontal scrollable)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: [
                                _buildPremiumBadge(
                                  icon: Icons.person_outline_rounded,
                                  label: author,
                                  backgroundColor: colors.chipBackground,
                                  textColor: colors.textBody,
                                ),
                                const SizedBox(width: 6),
                                _buildPremiumBadge(
                                  icon: Icons.tag_rounded,
                                  label: 'v$version',
                                  backgroundColor: LiquidTheme.primary.withValues(alpha: 0.1),
                                  textColor: LiquidTheme.primary,
                                ),
                                const SizedBox(width: 6),
                                _buildPremiumBadge(
                                  icon: Icons.category_outlined,
                                  label: category,
                                  backgroundColor: LiquidTheme.cyan.withValues(alpha: 0.1),
                                  textColor: LiquidTheme.cyan,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Description and Preview (Scrollable - inside unified Card)
              Expanded(
                child: Container(
                  color: isDark ? const Color(0xFF090D16) : const Color(0xFFF1F5F9),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    physics: const BouncingScrollPhysics(),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? colors.cardBackground : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: colors.cardBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.015),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section: Description
                          Row(
                            children: [
                              Icon(Icons.description_outlined, color: LiquidTheme.primary, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                "Description",
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: colors.textTitle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildUnifiedDescription(colors, isDark, description),
                          
                          const SizedBox(height: 28),

                          // Section: Code Snippet Preview (Terminal Style)
                          Row(
                            children: [
                              Icon(Icons.code_rounded, color: LiquidTheme.cyan, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                "Code Snippet Preview",
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: colors.textTitle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildTerminalCodePreview(isDark, content, url),

                          const SizedBox(height: 28),

                          // Section: Integrity & Security
                          Row(
                            children: [
                              const Icon(Icons.shield_outlined, color: Colors.green, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                "Security & Verification",
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: colors.textTitle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildUnifiedSecurity(colors, isDark, sha256, url),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 4. Fixed Bottom Action Bar (Install button tabbar)
              Container(
                padding: EdgeInsets.fromLTRB(
                  24,
                  16,
                  24,
                  16 + MediaQuery.of(context).padding.bottom,
                ),
                decoration: BoxDecoration(
                  color: isDark 
                      ? LiquidTheme.darkBackground.withValues(alpha: 0.95)
                      : Colors.white.withValues(alpha: 0.95),
                  border: Border(
                    top: BorderSide(
                      color: colors.divider,
                      width: 1,
                    ),
                  ),
                ),
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: LiquidTheme.primary.withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      if (content.isEmpty && url.isNotEmpty) {
                        _processUrlImport(url);
                      } else {
                        _installScript(context, item);
                      }
                    },
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [LiquidTheme.cyan, LiquidTheme.primary],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.download_rounded, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              "Install Script",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumBadge({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnifiedDescription(LiquidColors colors, bool isDark, String description) {
    if (description.isEmpty || description == 'No description provided.') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.02)
              : Colors.black.withValues(alpha: 0.015),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              Icons.article_outlined,
              color: colors.textCaption.withValues(alpha: 0.4),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              "No description provided",
              style: TextStyle(
                color: colors.textTitle,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "The author did not specify any details. Install the script to review the source code directly.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textCaption,
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ],
        ),
      );
    }

    return Text(
      description,
      style: TextStyle(
        fontSize: 14,
        height: 1.5,
        color: colors.textBody,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildSyntaxHighlightedCode(String code, bool isDark) {
    final List<TextSpan> spans = [];
    
    final regex = RegExp(r'(\/\/.*|\/\*[\s\S]*?\*\/|"(?:\\.|[^"\\])*"|'
                         r"'(?:\\.|[^'\\])*'|`(?:\\.|[^`\\])*`|\b(?:function|const|let|var|import|export|return|await|async|if|else|for|while|class|new|true|false|null|undefined)\b|\w+|\s+|[{}()\[\];.,+\-*/=<>!&|])");
                         
    final matches = regex.allMatches(code);
    for (final match in matches) {
      final text = match.group(0) ?? '';
      if (text.startsWith('//') || text.startsWith('/*')) {
        spans.add(TextSpan(text: text, style: const TextStyle(color: Color(0xFF64748B))));
      } else if (text.startsWith('"') || text.startsWith("'") || text.startsWith('`')) {
        spans.add(TextSpan(text: text, style: const TextStyle(color: Color(0xFF34D399))));
      } else if (const {
        'function', 'const', 'let', 'var', 'import', 'export', 'return', 'await', 
        'async', 'if', 'else', 'for', 'while', 'class', 'new'
      }.contains(text)) {
        spans.add(TextSpan(text: text, style: const TextStyle(color: Color(0xFFF43F5E), fontWeight: FontWeight.bold)));
      } else if (const {'true', 'false', 'null', 'undefined'}.contains(text)) {
        spans.add(TextSpan(text: text, style: const TextStyle(color: Color(0xFFFB923C))));
      } else if (RegExp(r'^[0-9]+$').hasMatch(text)) {
        spans.add(TextSpan(text: text, style: const TextStyle(color: Color(0xFF38BDF8))));
      } else {
        spans.add(TextSpan(text: text, style: const TextStyle(color: Color(0xFFE2E8F0))));
      }
    }

    return SelectableText.rich(
      TextSpan(children: spans),
      style: const TextStyle(
        fontFamily: 'Courier',
        fontSize: 13,
        height: 1.4,
      ),
    );
  }

  Widget _buildTerminalCodePreview(bool isDark, String content, String url) {
    final String previewCode;
    if (content.isNotEmpty) {
      final lines = content.split('\n');
      if (lines.length > 15) {
        previewCode = '${lines.take(15).join('\n')}\n\n// ... and ${lines.length - 15} more lines';
      } else {
        previewCode = content;
      }
    } else if (url.isNotEmpty) {
      previewCode = '// Remote Script (Lazy Load)\n// Full code will be downloaded from:\n// $url\n\n// Install now to preview and run.';
    } else {
      previewCode = '// No code preview available.';
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Slate 900
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF334155), // Slate 700
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B), // Slate 800
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    "preview.js",
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Courier',
                    ),
                  ),
                ),
                const Icon(
                  Icons.terminal_rounded,
                  color: Color(0xFF64748B),
                  size: 14,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _buildSyntaxHighlightedCode(previewCode, isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnifiedSecurity(LiquidColors colors, bool isDark, String sha256, String url) {
    final hasRemote = url.isNotEmpty;
    final displayHash = sha256.isNotEmpty 
        ? (sha256.length > 20 ? '${sha256.substring(0, 10)}...${sha256.substring(sha256.length - 10)}' : sha256)
        : 'Auto-Generated on Dev Publish';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withValues(alpha: 0.02)
            : Colors.black.withValues(alpha: 0.015),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
              const SizedBox(width: 8),
              Text(
                "Moderator Approved & Verified",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: colors.textTitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Source Type",
                style: TextStyle(color: colors.textCaption, fontSize: 12),
              ),
              Text(
                hasRemote ? "Cloud Hosted" : "Embedded Local",
                style: TextStyle(
                  color: colors.textBody,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Integrity Hash",
                style: TextStyle(color: colors.textCaption, fontSize: 12),
              ),
              Text(
                displayHash,
                style: const TextStyle(
                  color: Colors.green,
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
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
