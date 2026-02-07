import 'package:flutter/material.dart';

import 'package:get_it/get_it.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/features/script_management/domain/entities/script.dart';
import 'package:script_automator/features/script_management/domain/repositories/script_repository.dart';
import 'package:script_automator/features/editor/presentation/pages/editor_page.dart';
import 'package:script_automator/features/dashboard/presentation/widgets/new_script_dialog.dart';
import 'package:script_automator/features/dashboard/presentation/widgets/staggered_script_grid.dart';
import 'package:script_automator/features/dashboard/presentation/widgets/glass_dock.dart';
import 'package:script_automator/features/dashboard/presentation/widgets/glass_drawer.dart';
import 'package:script_automator/core/theme/liquid_page_route.dart';
import 'package:script_automator/features/dashboard/presentation/widgets/liquid_search_bar.dart';

class LiquidDashboardPage extends StatefulWidget {
  const LiquidDashboardPage({super.key});

  @override
  State<LiquidDashboardPage> createState() => _LiquidDashboardPageState();
}

class _LiquidDashboardPageState extends State<LiquidDashboardPage> {
  final ScriptRepository _repository = GetIt.I<ScriptRepository>();
  List<Script> _scripts = [];
  bool _isLoading = true;
  int _navIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadScripts();
  }

  Future<void> _loadScripts() async {
    final result = await _repository.getScripts();
    result.fold(
      (failure) => setState(() => _isLoading = false),
      (scripts) => setState(() {
        _scripts = scripts;
        _isLoading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      extendBody: true, // For Floating Dock
      drawer: const GlassDrawer(), // Professional Sidebar
      body: Stack(
        children: [
          // 1. Aurora Background (Dynamic based on Time/Theme)
          Container(
            decoration: const BoxDecoration(
              gradient: LiquidTheme.auroraGradient, // Matches Editor
            ),
          ),

          // 2. Orbs (Subtle Motion could be added here later)
          Positioned(
            top: -100,
            right: -50,
            child: _buildOrb(300, LiquidTheme.secondary.withValues(alpha: 0.3)),
          ),
          Positioned(
            bottom: 100,
            left: -50,
            child: _buildOrb(250, LiquidTheme.cyan.withValues(alpha: 0.3)),
          ),

          // 3. Main Content (Slivers)
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                // Mega Header
                _buildSliverAppBar(),

                // Search & Filter Bar (Sticky)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _GlassSearchHeaderDelegate(),
                ),

                // Bento Grid Content
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    100,
                  ), // Bottom padding for Dock
                  sliver: SliverToBoxAdapter(
                    child: _isLoading
                        ? const Center(
                            heightFactor: 5,
                            child: CircularProgressIndicator(),
                          )
                        : AnimationLimiter(
                            child: StaggeredScriptGrid(
                              scripts: _scripts,
                              onTap: _openEditor,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),

          // 4. Floating Glass Dock
          Align(
            alignment: Alignment.bottomCenter,
            child: GlassDock(
              selectedIndex: _navIndex,
              onItemSelected: (index) {
                if (index == 2) {
                  _createNewScript();
                } else {
                  setState(() => _navIndex = index);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: false,
      toolbarHeight: 0, // Custom layout
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Good Morning,",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Text(
                    "CodeForge",
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                      letterSpacing: -1.5,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _scaffoldKey.currentState?.openDrawer(),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.menu_rounded,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 20)],
      ),
    );
  }

  void _openEditor(Script script) {
    Navigator.push(
      context,
      LiquidPageRoute(page: EditorPage(script: script)),
    ).then((_) => _loadScripts());
  }

  Future<void> _createNewScript() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const NewScriptDialog(),
    );
    if (name != null && name.isNotEmpty) {
      final script = Script(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        content: "// Start coding in Liquid Glass...",
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _repository.saveScript(script);
      _loadScripts();
      if (mounted) {
        _openEditor(script);
      }
    }
  }
}

class _GlassSearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      height: maxExtent,
      color: Colors.transparent, // Allow Aurora to show through
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      alignment: Alignment.center,
      child: const LiquidSearchBar(),
    );
  }

  @override
  double get maxExtent => 80;
  @override
  double get minExtent => 80;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}
