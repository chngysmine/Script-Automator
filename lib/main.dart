import 'package:flutter/material.dart';
import 'features/script_engine/domain/script_runner_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Script Automator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _scriptService = ScriptRunnerService();
  bool _isEngineReady = false;
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _scriptService.logs.listen((log) {
      setState(() {
        _logs.add(log);
      });
    });
    _initEngine();
  }

  Future<void> _initEngine() async {
    try {
      await _scriptService.initialize();
      setState(() {
        _isEngineReady = true;
      });
    } catch (e) {
      debugPrint("Engine Init Failed: $e");
    }
  }

  void _runTestScript() {
    // Note: Since we don't have the real QuickJS lib compiled yet, this might crash or fail if run.
    // But this demonstrates the architecture.
    const script = """
      'Hello World from ' + 'QuickJS';
    """;
    _scriptService.runScript(script);
  }

  @override
  void dispose() {
    _scriptService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Script Automator Core')),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            'Engine Status: ${_isEngineReady ? "Ready" : "Initializing..."}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _isEngineReady ? _runTestScript : null,
            child: const Text('Run Test Script (Hello World)'),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  final log = _logs[index];
                  Color color = Colors.greenAccent;
                  if (log.contains("SEVERE") || log.contains("Error")) {
                    color = Colors.redAccent;
                  }
                  if (log.contains("WARNING")) {
                    color = Colors.orangeAccent;
                  }
                  return Text(
                    log,
                    style: TextStyle(color: color, fontFamily: 'Courier'),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
