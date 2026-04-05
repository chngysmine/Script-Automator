import 'package:flutter/material.dart';

import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/core/ui/mesh_gradient_background.dart';
import 'package:script_automator/core/theme/liquid_page_route.dart';
import 'package:script_automator/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:script_automator/features/dashboard/presentation/pages/explore_page.dart';
import 'package:script_automator/features/dashboard/presentation/pages/gallery_page.dart';
import 'package:script_automator/features/dashboard/presentation/pages/profile_page.dart';
import 'package:script_automator/features/dashboard/presentation/pages/notification_page.dart';
import 'package:script_automator/features/dashboard/presentation/widgets/glass_dock.dart';
import 'package:script_automator/features/dashboard/presentation/widgets/glass_drawer.dart';
import 'package:script_automator/features/dashboard/presentation/widgets/new_script_dialog.dart';

import 'package:get_it/get_it.dart';
import 'package:script_automator/features/script_management/domain/entities/script.dart';
import 'package:script_automator/features/script_management/domain/repositories/script_repository.dart';
import 'package:script_automator/features/editor/presentation/pages/editor_page.dart';

/// The global navigation shell for the application.
///
/// Ensures the [GlassDock] and [GlassDrawer] are persistent across all main
/// tabs: Dashboard, Explore, Gallery, and Profile.
class AppShell extends StatefulWidget {
  final int initialIndex;

  const AppShell({super.key, this.initialIndex = 0});

  @override
  State<AppShell> createState() => AppShellState();
}

class AppShellState extends State<AppShell> {
  late int _navIndex;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScriptRepository _repository = GetIt.I<ScriptRepository>();

  @override
  void initState() {
    super.initState();
    _navIndex = widget.initialIndex;
  }

  /// Navigates to a specific tab index from anywhere in the shell.
  void setNavIndex(int index) {
    setState(() => _navIndex = index);
  }

  /// Opens the side drawer.
  void openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  /// Creates a new script and opens the editor.
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

      if (mounted) {
        Navigator.push(
          context,
          LiquidPageRoute(page: EditorPage(script: script)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: LiquidTheme.darkBackground,

      drawer: GlassDrawer(
        currentNavIndex: _navIndex,
        onNavigate: (index) {
          Navigator.pop(context);
          if (index == 5) {
            Navigator.push(
              context,
              LiquidPageRoute(page: const NotificationPage()),
            );
          } else {
            setState(() => _navIndex = index);
          }
        },
      ),

      body: Stack(
        children: [
          const Positioned.fill(child: MeshGradientBackground()),
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: _buildBodyContent(),
            ),
          ),
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

  Widget _buildBodyContent() {
    switch (_navIndex) {
      case 0:
        return LiquidDashboardPage(
          key: const ValueKey('dashboard'),
          onMenuTap: openDrawer,
        );
      case 1:
        return const ExplorePage(key: ValueKey('explore'));
      case 3:
        return const GalleryPage(key: ValueKey('gallery'));
      case 4:
        return const ProfilePage(key: ValueKey('profile'));
      default:
        return LiquidDashboardPage(
          key: const ValueKey('dashboard_fallback'),
          onMenuTap: openDrawer,
        );
    }
  }
}
