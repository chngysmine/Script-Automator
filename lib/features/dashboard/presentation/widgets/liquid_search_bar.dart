import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/core/theme/liquid_colors.dart';
import 'package:script_automator/features/script_management/domain/entities/script.dart';
import 'package:script_automator/features/script_management/domain/repositories/script_repository.dart';
import 'package:script_automator/features/dashboard/domain/repositories/gallery_repository.dart';
import 'package:script_automator/features/dashboard/presentation/widgets/template_preview_dialog.dart';
import 'package:script_automator/features/dashboard/presentation/widgets/import_progress_dialog.dart';
import 'package:script_automator/core/security/script_integrity_checker.dart';
import 'package:script_automator/core/ui/liquid_circular_loader.dart';
import 'package:get_it/get_it.dart';
import 'package:script_automator/core/theme/liquid_page_route.dart';
import 'package:script_automator/features/editor/presentation/pages/editor_page.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LiquidSearchBar extends StatefulWidget {
  const LiquidSearchBar({super.key});

  @override
  State<LiquidSearchBar> createState() => _LiquidSearchBarState();
}

class _LiquidSearchBarState extends State<LiquidSearchBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 2.0, end: 12.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _openSearchOverlay(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.4),
        barrierDismissible: true,
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (context, animation, secondaryAnimation) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: FadeTransition(
              opacity: animation,
              child: const _SearchOverlay(),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiquidColors>()!;
    return GestureDetector(
      onTap: () => _openSearchOverlay(context),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: colors.searchBarBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colors.searchBarBorder,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: LiquidTheme.primary.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // AI Glow Icon
              AnimatedBuilder(
                animation: _glowAnimation,
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: LiquidTheme.primary,
                  size: 24,
                ),
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: LiquidTheme.primary.withValues(alpha: 0.6),
                          blurRadius: _glowAnimation.value,
                          spreadRadius: _glowAnimation.value / 4,
                        ),
                      ],
                    ),
                    child: child,
                  );
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  "Ask AI or search templates...",
                  style: TextStyle(
                    color: colors.searchBarHint,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 24,
                color: colors.divider,
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.mic_rounded, // Voice search hint
                color: LiquidTheme.primary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchOverlay extends StatefulWidget {
  const _SearchOverlay();

  @override
  State<_SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<_SearchOverlay> {
  final _searchController = TextEditingController();
  final ScriptRepository _repository = GetIt.I<ScriptRepository>();
  
  List<Script> _allScripts = [];
  List<Script> _filteredScripts = [];
  List<Map<String, dynamic>> _allTemplates = [];
  List<Map<String, dynamic>> _filteredTemplates = [];
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // 1. Fetch local scripts
    final result = await _repository.getScripts();
    result.fold(
      (failure) {},
      (scripts) {
        if (mounted) {
          setState(() {
            _allScripts = scripts;
            _filteredScripts = scripts;
          });
        }
      },
    );

    // 2. Fetch community templates
    try {
      final templates = await GetIt.I<GalleryRepository>().getTemplates();
      if (mounted) {
        setState(() {
          _allTemplates = templates;
          _filteredTemplates = templates;
        });
      }
    } catch (e) {
      // Fail silently for network issues in search loader
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredScripts = _allScripts;
        _filteredTemplates = _allTemplates;
      } else {
        _filteredScripts = _allScripts
            .where((script) => script.name.toLowerCase().contains(query))
            .toList();
        _filteredTemplates = _allTemplates
            .where((template) =>
                (template['name']?.toLowerCase().contains(query) ?? false) ||
                (template['description']?.toLowerCase().contains(query) ?? false) ||
                (template['author']?.toLowerCase().contains(query) ?? false))
            .toList();
      }
    });
  }

  void _triggerTemplateImport(BuildContext context, Map<String, dynamic> template, String code) {
    final name = template['name'] ?? 'Untitled';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => ImportProgressDialog(
        scriptName: name,
        importTask: (updateProgress) async {
          final expectedHash = template['sha256'] as String?;
          updateProgress('Verifying template integrity...');
          if (!ScriptIntegrityChecker.verify(code, expectedHash)) {
            throw Exception('Template integrity check failed (SHA-256 mismatch).');
          }

          updateProgress('Registering template local storage...');
          final script = Script(
            id: 'gallery_${name.toLowerCase().replaceAll(' ', '_')}',
            name: name,
            content: code,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            settings: {
              'gallery_id': template['id'] ?? name.toLowerCase().replaceAll(' ', '_'),
              'gallery_version': template['version'] ?? '1.0.0',
              'gallery_script_url': template['scriptUrl'] ?? '',
              'is_modified_from_gallery': false,
            },
          );
          await GetIt.I<ScriptRepository>().saveScript(script);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiquidColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hasResults = _filteredScripts.isNotEmpty || _filteredTemplates.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        color: colors.dialogBackground.withValues(alpha: 0.88),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top Search Bar (Active state)
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: colors.inputBackground,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: LiquidTheme.primary.withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: LiquidTheme.primary.withValues(alpha: 0.15),
                                blurRadius: 24,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 20),
                              const Icon(
                                Icons.search_rounded,
                                color: LiquidTheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  autofocus: true,
                                  style: TextStyle(
                                    color: colors.textTitle,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: "What do you want to automate?",
                                    hintStyle: TextStyle(
                                      color: colors.textCaption.withValues(alpha: 0.7),
                                      fontWeight: FontWeight.normal,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              if (_searchController.text.isNotEmpty)
                                IconButton(
                                  icon: Icon(Icons.clear_rounded, color: colors.textCaption),
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                ),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: colors.chipBackground,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colors.cardBorder,
                            ),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            color: colors.textTitle,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 2. AI Generate Card
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                LiquidTheme.primary.withValues(alpha: 0.15),
                                LiquidTheme.cyan.withValues(alpha: 0.05),
                              ]
                            : [
                                LiquidTheme.primary.withValues(alpha: 0.08),
                                LiquidTheme.cyan.withValues(alpha: 0.03),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: LiquidTheme.primary.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () {
                            Navigator.pop(context); // Close overlay
                            Navigator.push(
                              context,
                              LiquidPageRoute(page: const EditorPage()),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [LiquidTheme.cyan, LiquidTheme.primary],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: LiquidTheme.primary.withValues(alpha: 0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.auto_awesome_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            "Generate Widget with AI",
                                            style: TextStyle(
                                              color: colors.textTitle,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: LiquidTheme.primary.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              "BETA",
                                              style: TextStyle(
                                                color: LiquidTheme.primary,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Describe your idea, AI will code it instantly",
                                        style: TextStyle(
                                          color: colors.textBody,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: colors.textCaption,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .fade(duration: 300.ms, delay: 50.ms)
                      .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
                  const SizedBox(height: 28),

                  // 3. Scrollable List Content
                  if (_isLoading)
                    _buildLoader(colors, isDark)
                  else if (_searchController.text.isNotEmpty && !hasResults)
                    _buildEmptyState(context, _searchController.text, colors)
                  else
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_searchController.text.isNotEmpty) ...[
                              // Search mode results
                              if (_filteredScripts.isNotEmpty) ...[
                                _buildSectionTitle("My Scripts (${_filteredScripts.length})", colors),
                                const SizedBox(height: 12),
                                ..._filteredScripts.map((s) => _buildLocalScriptItem(context, s, colors, isDark)),
                                const SizedBox(height: 16),
                              ],
                              if (_filteredTemplates.isNotEmpty) ...[
                                _buildSectionTitle("Community Templates (${_filteredTemplates.length})", colors),
                                const SizedBox(height: 12),
                                ..._filteredTemplates.map((t) => _buildTemplateItem(context, t, colors, isDark)),
                              ],
                            ] else ...[
                              // Recent and Trending suggestions
                              if (_allScripts.isNotEmpty) ...[
                                _buildSectionTitle("Recent Code", colors),
                                const SizedBox(height: 12),
                                ..._allScripts.take(3).map((s) => _buildLocalScriptItem(context, s, colors, isDark)),
                                const SizedBox(height: 20),
                              ],
                              if (_allTemplates.isNotEmpty) ...[
                                _buildSectionTitle("Trending Templates", colors),
                                const SizedBox(height: 12),
                                ..._allTemplates.take(4).map((t) => _buildTemplateItem(context, t, colors, isDark)),
                              ] else
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text(
                                    "No trending templates available.",
                                    style: TextStyle(color: colors.textCaption, fontSize: 13),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, LiquidColors colors) {
    return Text(
      title,
      style: TextStyle(
        color: colors.textTitle,
        fontSize: 14,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
      ),
    )
        .animate()
        .fade(duration: 200.ms);
  }

  Widget _buildLoader(LiquidColors colors, bool isDark) {
    return const Expanded(
      child: Center(
        child: LiquidCircularLoader(size: 44),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String query, LiquidColors colors) {
    return Expanded(
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: colors.chipBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  color: colors.textCaption,
                  size: 44,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "No results found",
                style: TextStyle(
                  color: colors.textTitle,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  "We couldn't find any local scripts or templates matching \"$query\".",
                  style: TextStyle(
                    color: colors.textCaption,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fade(duration: 250.ms);
  }

  Widget _buildLocalScriptItem(BuildContext context, Script script, LiquidColors colors, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.cardBorder,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pop(context); // Close search
            Navigator.push(
              context,
              LiquidPageRoute(page: EditorPage(script: script)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: LiquidTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.description_outlined,
                    color: LiquidTheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        script.name,
                        style: TextStyle(
                          color: colors.textTitle,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Local Script",
                        style: TextStyle(
                          color: colors.textCaption,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: colors.textCaption.withValues(alpha: 0.5),
                  size: 13,
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fade(duration: 200.ms)
        .slideX(begin: 0.05, end: 0, curve: Curves.easeOutQuad);
  }

  Widget _buildTemplateItem(BuildContext context, Map<String, dynamic> template, LiquidColors colors, bool isDark) {
    final name = template['name'] ?? 'Untitled';
    final author = template['author'] ?? 'Community';
    final version = template['version'] ?? '1.0.0';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.cardBorder,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            showDialog(
              context: context,
              barrierColor: Colors.black.withValues(alpha: 0.5),
              builder: (dialogCtx) => TemplatePreviewDialog(
                scriptData: template,
                onImportTriggered: (data, code) {
                  _triggerTemplateImport(context, template, code);
                },
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: LiquidTheme.cyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.widgets_outlined,
                    color: LiquidTheme.cyan,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: colors.textTitle,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "by $author • v$version",
                        style: TextStyle(
                          color: colors.textCaption,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: LiquidTheme.cyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cloud_download_outlined,
                        color: LiquidTheme.cyan,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        "Get",
                        style: TextStyle(
                          color: LiquidTheme.cyan,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
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
    )
        .animate()
        .fade(duration: 200.ms)
        .slideX(begin: 0.05, end: 0, curve: Curves.easeOutQuad);
  }
}
