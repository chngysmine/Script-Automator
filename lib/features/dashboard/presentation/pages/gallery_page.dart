import 'package:flutter/material.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/features/script_management/domain/entities/script.dart';
import 'package:script_automator/features/script_management/domain/repositories/script_repository.dart';
import 'package:script_automator/features/dashboard/domain/repositories/gallery_repository.dart';
import 'package:script_automator/features/script_management/data/services/git_service.dart';
import 'package:get_it/get_it.dart';
import 'dart:ui';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  late Future<List<Map<String, String>>> _templatesFuture;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _templatesFuture = GetIt.I<GalleryRepository>().getTemplates();
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
        final featured = items.where((i) => i['isFeatured'] == 'true').toList();
        final others = items.where((i) => i['isFeatured'] != 'true').toList();

        return CustomScrollView(
          controller: _scrollController,
          shrinkWrap: true, // Added for better integration
          physics:
              const NeverScrollableScrollPhysics(), // Added for better integration
          slivers: [
            // Glass AppBar
            SliverAppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading:
                  false, // Prevent back button in dashboard tab
              expandedHeight: 70,
              floating: true,
              pinned: true,
              flexibleSpace: const ClipRRect(child: SizedBox.shrink()),
              title: Text(
                "Script Store",
                style: LiquidTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  color: LiquidTheme.textDeep,
                  fontWeight: FontWeight.w800,
                ),
              ),
              centerTitle: false,
              actions: [
                _buildHeaderAction(
                  icon: Icons.search_rounded,
                  onPressed: () {},
                ),
                _buildHeaderAction(
                  icon: Icons.cloud_download_rounded,
                  onPressed: _showImportDialog,
                  isPrimary: true,
                ),
                const SizedBox(width: 16),
              ],
            ),

            // 1. Featured Section
            if (featured.isNotEmpty) ...[
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
                      return _buildFeaturedCard(featured[index]);
                    },
                  ),
                ),
              ),
            ],

            // 2. Main Feed
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
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return _buildListItem(others[index]);
              }, childCount: others.length),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        );
      },
    );
  }

  // --- Components ---

  Widget _buildFeaturedCard(Map<String, String> item) {
    return GestureDetector(
      onTap: () => _showPreview(context, item),
      child: Container(
        width: 320,
        margin: const EdgeInsets.only(right: 20, bottom: 20, top: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(36),
          color: Colors.white.withValues(alpha: 0.25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Stack(
              children: [
                // Liquid Accent Orb
                Positioned(
                  right: -30,
                  top: -30,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: LiquidTheme.primary.withValues(alpha: 0.15),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: LiquidTheme.primary.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "PREMIUM",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.rocket_launch_rounded,
                          color: LiquidTheme.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        item['name']!,
                        style: const TextStyle(
                          color: LiquidTheme.textDeep,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.2,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "by ${item['author'] ?? 'Antigravity Team'}",
                        style: TextStyle(
                          color: LiquidTheme.textDeep.withValues(alpha: 0.6),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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

  Widget _buildListItem(Map<String, String> item) {
    return GestureDetector(
      onTap: () => _showPreview(context, item),
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: Colors.white.withValues(alpha: 0.15),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: LiquidTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.extension_rounded,
                      color: LiquidTheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name']!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: LiquidTheme.textDeep,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['description']!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: LiquidTheme.textDeep.withValues(alpha: 0.6),
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildGetButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGetButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: LiquidTheme.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: LiquidTheme.primary.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Text(
        "GET",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
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
                  _installScript(context, item);
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
                  const SizedBox(height: 24),
                  const Text(
                    "Preview Code",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item['content']!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
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
    final repo = GetIt.I<ScriptRepository>();
    final script = Script(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: item['name']!,
      content: item['content']!,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await repo.saveScript(script);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Installed ${item['name']}"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: LiquidTheme.primary,
        ),
      );
    }
  }
}
