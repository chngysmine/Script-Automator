import 'package:flutter/material.dart';

import 'package:get_it/get_it.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/features/script_management/domain/entities/script.dart';
import 'package:script_automator/features/script_management/domain/repositories/script_repository.dart';
import 'package:script_automator/features/editor/presentation/pages/editor_page.dart';
import 'package:script_automator/features/dashboard/presentation/widgets/staggered_script_grid.dart';
import 'package:script_automator/core/theme/liquid_page_route.dart';
import 'package:script_automator/features/dashboard/presentation/widgets/liquid_search_bar.dart';
import 'package:script_automator/features/dashboard/presentation/widgets/glass_header_actions.dart';
import 'package:script_automator/features/dashboard/domain/services/notification_service.dart';

/// The main dashboard view containing the user's scripts and header.
/// Now embedded within [AppShell], stripped of its own Scaffold/Drawer/Dock.
class LiquidDashboardPage extends StatefulWidget {
  final VoidCallback onMenuTap;

  const LiquidDashboardPage({super.key, required this.onMenuTap});

  @override
  State<LiquidDashboardPage> createState() => _LiquidDashboardPageState();
}

class _LiquidDashboardPageState extends State<LiquidDashboardPage> {
  final ScriptRepository _repository = GetIt.I<ScriptRepository>();
  List<Script> _scripts = [];
  bool _isLoading = true;

  /// Returns a time-appropriate greeting based on the current hour.
  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning,";
    if (hour < 17) return "Good Afternoon,";
    return "Good Evening,";
  }

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
    // Return just the scroll view, background and navigation are handled by AppShell
    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        _buildSliverAppBar(),
        SliverPersistentHeader(
          pinned: true,
          delegate: _GlassSearchHeaderDelegate(),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          sliver: SliverToBoxAdapter(
            child: _isLoading
                ? const Center(
                    heightFactor: 5,
                    child: CircularProgressIndicator(
                      color: LiquidTheme.primary,
                    ),
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
    );
  }

  Widget _buildSliverAppBar() {
    return SliverToBoxAdapter(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting,
                      style: TextStyle(
                        fontSize: 14,
                        color: LiquidTheme.textLight.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          LiquidTheme.brandDarkGradient.createShader(bounds),
                      blendMode: BlendMode.srcIn,
                      child: const Text(
                        "CodeForge",
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.8,
                          height: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Glass Buttons Group
              StreamBuilder<int>(
                stream: GetIt.I<NotificationService>().unreadCount,
                builder: (context, snapshot) {
                  final unread = snapshot.data ?? 0;
                  return GlassHeaderActions(
                    onMenuTap: widget.onMenuTap,
                    hasNotificationBadge: unread > 0,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openEditor(Script script) {
    Navigator.push(
      context,
      LiquidPageRoute(page: EditorPage(script: script)),
    ).then((_) {
      if (mounted) {
        _loadScripts();
      }
    });
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
