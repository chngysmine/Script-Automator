import 'dart:async';
import 'package:flutter/material.dart';

import 'package:get_it/get_it.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/core/theme/liquid_colors.dart';
import 'package:script_automator/core/utils/debouncer.dart';
import 'package:script_automator/core/ui/glass_sliver_header.dart';
import 'package:script_automator/features/script_management/domain/entities/script.dart';
import 'package:script_automator/features/script_management/domain/repositories/script_repository.dart';
import 'package:script_automator/features/dashboard/presentation/widgets/staggered_script_grid.dart';
import 'package:script_automator/features/dashboard/presentation/widgets/liquid_search_bar.dart';
import 'package:script_automator/features/dashboard/presentation/widgets/glass_header_actions.dart';
import 'package:script_automator/features/dashboard/domain/services/notification_service.dart';
import 'package:script_automator/features/dashboard/presentation/widgets/script_preview_sheet.dart';

/// The main dashboard view containing the user's scripts and header.
/// Now embedded within [AppShell], stripped of its own Scaffold/Drawer/Dock.
class LiquidDashboardPage extends StatefulWidget {
  const LiquidDashboardPage({super.key});

  @override
  State<LiquidDashboardPage> createState() => _LiquidDashboardPageState();
}

class _LiquidDashboardPageState extends State<LiquidDashboardPage> {
  final ScriptRepository _repository = GetIt.I<ScriptRepository>();
  List<Script> _scripts = [];
  bool _isLoading = true;
  
  StreamSubscription<void>? _scriptSub;
  final _debouncer = Debouncer(milliseconds: 300);

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
    _scriptSub = _repository.onScriptsChanged.listen((_) {
      _debouncer.run(() {
        if (mounted) _loadScripts();
      });
    });
  }

  @override
  void dispose() {
    _scriptSub?.cancel();
    _debouncer.dispose();
    super.dispose();
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
    final topPadding = MediaQuery.of(context).padding.top;
    final colors = Theme.of(context).extension<LiquidColors>()!;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        // ── Pinned Glass Header (fixed, NO collapse) ──
        SliverPersistentHeader(
          pinned: true,
          delegate: GlassSliverHeaderDelegate(
            height: topPadding + 90,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
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
                              fontSize: 13,
                              color: colors.textCaption,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          ShaderMask(
                            shaderCallback: (bounds) => LiquidTheme
                                .brandDarkGradient
                                .createShader(bounds),
                            blendMode: BlendMode.srcIn,
                            child: const Text(
                              "CodeForge",
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.5,
                                height: 1.1,
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

        // ── Search Bar (scrollable, NOT pinned) ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: const LiquidSearchBar(),
          ),
        ),

        // ── Script Grid ──
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
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
                      onTap: _openPreview,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  void _openPreview(Script script) {
    ScriptPreviewSheet.show(
      context,
      script,
      onDeleted: () {
        if (mounted) _loadScripts();
      },
    ).then((_) {
      if (mounted) _loadScripts();
    });
  }
}
