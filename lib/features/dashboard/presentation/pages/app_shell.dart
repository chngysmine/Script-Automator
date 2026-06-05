import 'package:flutter/material.dart';

import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/core/ui/mesh_gradient_background.dart';
import 'package:script_automator/core/theme/liquid_page_route.dart';
import 'package:script_automator/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:script_automator/features/dashboard/presentation/pages/explore_page.dart';
import 'package:script_automator/features/dashboard/presentation/pages/gallery_page.dart';
import 'package:script_automator/features/dashboard/presentation/pages/profile_page.dart';
import 'package:script_automator/features/dashboard/presentation/widgets/glass_dock.dart';
import 'package:script_automator/features/dashboard/presentation/widgets/new_script_dialog.dart';
import 'package:script_automator/features/docs/presentation/pages/api_docs_page.dart';
import 'package:script_automator/features/docs/presentation/pages/widget_schema_page.dart';

import 'package:get_it/get_it.dart';
import 'package:script_automator/features/script_management/domain/entities/script.dart';
import 'package:script_automator/features/script_management/domain/repositories/script_repository.dart';
import 'package:script_automator/features/editor/presentation/pages/editor_page.dart';

/// The global navigation shell for the application.
///
/// Ensures the [GlassDock] is persistent across all main
/// tabs: Dashboard, Explore, Gallery, and Profile.
/// Navigation is handled exclusively by the bottom dock — sidebar/drawer
/// has been removed in favor of header-level Settings/Notification buttons.
class AppShell extends StatefulWidget {
  final int initialIndex;

  const AppShell({super.key, this.initialIndex = 0});

  @override
  State<AppShell> createState() => AppShellState();
}

class AppShellState extends State<AppShell> {
  late int _navIndex;
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
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: LiquidTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Script Automator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_rounded),
            onPressed: () {
              Navigator.push(
                context,
                LiquidPageRoute(page: const ApiDocsPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.schema_rounded),
            onPressed: () {
              Navigator.push(
                context,
                LiquidPageRoute(page: const WidgetSchemaPage()),
              );
            },
          ),
        ],
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
        return const LiquidDashboardPage(
          key: ValueKey('dashboard'),
        );
      case 1:
        return const ExplorePage(key: ValueKey('explore'));
      case 3:
        return const GalleryPage(key: ValueKey('gallery'));
      case 4:
        return const ProfilePage(key: ValueKey('profile'));
      default:
        return const LiquidDashboardPage(
          key: ValueKey('dashboard_fallback'),
        );
    }
  }
}
