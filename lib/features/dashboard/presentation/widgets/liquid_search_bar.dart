import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/core/ui/liquid_glass.dart';
import 'package:script_automator/features/script_management/domain/entities/script.dart';
import 'package:script_automator/features/script_management/domain/repositories/script_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:script_automator/core/theme/liquid_page_route.dart';
import 'package:script_automator/features/editor/presentation/pages/editor_page.dart';

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
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: const _SearchOverlay(),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openSearchOverlay(context),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.9),
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
                  "Ask AI or search scripts...",
                  style: TextStyle(
                    color: LiquidTheme.textLight.withValues(alpha: 0.6),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 24,
                color: LiquidTheme.textMedium.withValues(alpha: 0.2),
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadScripts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadScripts() async {
    final result = await _repository.getScripts();
    result.fold(
      (failure) {
        setState(() => _isLoading = false);
      },
      (scripts) {
        setState(() {
          _allScripts = scripts;
          _filteredScripts = scripts;
          _isLoading = false;
        });
      },
    );
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredScripts = _allScripts;
      } else {
        _filteredScripts = _allScripts
            .where((script) => script.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Search Bar (Active state)
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: LiquidTheme.primary.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: LiquidTheme.primary.withValues(alpha: 0.2),
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 20),
                            const Icon(
                              Icons.auto_awesome_rounded,
                              color: LiquidTheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                autofocus: true,
                                style: const TextStyle(
                                  color: LiquidTheme.textDeep,
                                  fontSize: 16,
                                ),
                                decoration: InputDecoration(
                                  hintText: "What do you want to automate?",
                                  hintStyle: TextStyle(
                                    color: LiquidTheme.textLight.withValues(alpha: 0.5),
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
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
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // AI Generate Button
                LiquidGlass(
                  padding: const EdgeInsets.all(20),
                  onTap: () {
                     Navigator.pop(context); // Close overlay
                     Navigator.push(
                        context,
                        LiquidPageRoute(page: const EditorPage()), // Real intent passing could go here
                     );
                  },
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: LiquidTheme.primary.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.generating_tokens_rounded,
                          color: LiquidTheme.primary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Generate Widget with AI",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Describe your idea, AI will code it instantly",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white54,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                if (_searchController.text.isNotEmpty) ...[
                   const Text(
                     "Search Results",
                     style: TextStyle(
                       color: Colors.white70,
                       fontWeight: FontWeight.w600,
                       letterSpacing: 1.2,
                     ),
                   ),
                   const SizedBox(height: 16),
                   if (_filteredScripts.isEmpty)
                     const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                           child: Text(
                              "No scripts found matching your query.",
                              style: TextStyle(color: Colors.white54),
                           ),
                        ),
                     )
                   else
                     ..._filteredScripts.map((s) => _buildListItem(context, Icons.insert_drive_file_rounded, s)),
                ] else ...[
                   const Text(
                     "Recent Code",
                     style: TextStyle(
                       color: Colors.white70,
                       fontWeight: FontWeight.w600,
                       letterSpacing: 1.2,
                     ),
                   ),
                   const SizedBox(height: 16),
                   if (_isLoading)
                     const Center(child: CircularProgressIndicator(color: LiquidTheme.primary))
                   else if (_allScripts.isNotEmpty)
                     ..._allScripts.take(3).map((s) => _buildListItem(context, Icons.history_rounded, s)),

                   const SizedBox(height: 32),
                   const Text(
                     "Trending Scripts",
                     style: TextStyle(
                       color: Colors.white70,
                       fontWeight: FontWeight.w600,
                       letterSpacing: 1.2,
                     ),
                   ),
                   const SizedBox(height: 16),
                   if (_allScripts.isNotEmpty && _allScripts.length > 3)
                     ..._allScripts.skip(3).take(3).map((s) => _buildListItem(context, Icons.trending_up_rounded, s))
                   else if (!_isLoading)
                     const Text("No trending scripts available.", style: TextStyle(color: Colors.white54)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListItem(BuildContext context, IconData icon, Script script) {
    return GestureDetector(
      onTap: () {
         Navigator.pop(context); // Close search
         Navigator.push(
            context,
            LiquidPageRoute(page: EditorPage(script: script)),
         );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white70, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
               child: Text(
                 script.name,
                 style: const TextStyle(
                   color: Colors.white,
                   fontSize: 16,
                   fontWeight: FontWeight.w500,
                 ),
                 maxLines: 1,
                 overflow: TextOverflow.ellipsis,
               ),
            ),
          ],
        ),
      ),
    );
  }
}
