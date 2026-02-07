import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get_it/get_it.dart';
import 'core/theme/liquid_theme.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'features/script_management/domain/entities/script.dart';
import 'features/script_management/domain/repositories/script_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _setupDI();
  runApp(const MyApp());
}

Future<void> _setupDI() async {
  if (!GetIt.I.isRegistered<ScriptRepository>()) {
    GetIt.I.registerSingleton<ScriptRepository>(_InMemoryScriptRepository());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Script Automator',
      theme: LiquidTheme.lightTheme,
      home: const LiquidDashboardPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class _InMemoryScriptRepository implements ScriptRepository {
  final List<Script> _scripts = [];

  @override
  Future<Either<Failure, List<Script>>> getScripts() async {
    // Return dummy data for "Recent Scripts" visual confirmation
    if (_scripts.isEmpty) {
      _scripts.add(
        Script(
          id: '1',
          name: 'Hello World',
          content: "console.log('Hello from Liquid Glass!');",
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      _scripts.add(
        Script(
          id: '2',
          name: 'Web Scraper',
          content: "// A simple scraper\nfunction scrape() { ... }",
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: DateTime.now(),
        ),
      );
      _scripts.add(
        Script(
          id: '3',
          name: 'Weather Widget',
          content: """
// Liquid Weather Widget
// Author: CodeForge AI

function render() {
  return Widget.Container({
    decoration: BoxDecoration({
      gradient: LinearGradient([Colors.blue, Colors.lightBlueAccent]),
      borderRadius: 24,
      boxShadow: [BoxShadow(blur: 20, color: Colors.blue.withOpacity(0.4))]
    }),
    child: Column([
      Icon(Icons.sunny, size: 64, color: Colors.white),
      Text("San Francisco", style: TextStyle(color: Colors.white, fontSize: 24)),
      Text("72°F", style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: Bold)),
      Text("Clear Sky", style: TextStyle(color: Colors.white70))
    ])
  });
}
""",
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }
    return right(_scripts);
  }

  @override
  Future<Either<Failure, Script>> getScriptDetail(String id) async {
    final script = _scripts.firstWhere(
      (s) => s.id == id,
      orElse: () => _scripts.first,
    );
    return right(script);
  }

  @override
  Future<Either<Failure, Unit>> saveScript(Script script) async {
    final index = _scripts.indexWhere((s) => s.id == script.id);
    if (index >= 0) {
      _scripts[index] = script;
    } else {
      _scripts.add(script);
    }
    return right(unit);
  }

  @override
  Future<Either<Failure, Unit>> deleteScript(String id) async {
    _scripts.removeWhere((s) => s.id == id);
    return right(unit);
  }
}
