import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/features/script_engine/domain/script_runner_service.dart';

class SandboxTerminalSheet extends StatefulWidget {
  final String apiName;
  final String code;

  const SandboxTerminalSheet({
    super.key,
    required this.apiName,
    required this.code,
  });

  @override
  State<SandboxTerminalSheet> createState() => _SandboxTerminalSheetState();
}

class _SandboxTerminalSheetState extends State<SandboxTerminalSheet>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final List<String> _logs = [];
  String _status = "INITIALIZING";
  StreamSubscription<String>? _subscription;
  late AnimationController _cursorAnimController;

  @override
  void initState() {
    super.initState();
    _cursorAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    // Delay run to let sheet build completely
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _run();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _cursorAnimController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    if (!mounted) return;
    setState(() {
      _logs.clear();
      _logs.add("🤖 SYSTEM: Spawning background JS Isolate Sandbox...");
      _logs.add("🤖 SYSTEM: Evaluating API '${widget.apiName}'...");
      _status = "RUNNING";
    });

    _subscription = GetIt.I<ScriptRunnerService>().logs.listen((log) {
      if (!mounted) return;
      setState(() {
        _logs.add(log);
      });
      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients && mounted) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
          );
        }
      });
    });

    try {
      await GetIt.I<ScriptRunnerService>().runScript(
        widget.code,
        'sandbox_run_${widget.apiName.replaceAll('.', '_')}',
      );
      if (!mounted) return;
      
      final hasError = _logs.any((log) =>
          log.contains('Script Error:') ||
          log.contains('error') ||
          log.contains('Exception'));
      setState(() {
        _status = hasError ? "ERROR" : "SUCCESS";
        _logs.add(hasError 
            ? "🛑 SYSTEM: Execution failed with errors." 
            : "✨ SYSTEM: Script executed successfully.");
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _logs.add("🛑 SYSTEM ERROR: ${e.toString()}");
        _status = "ERROR";
      });
    }
  }

  Color _getStatusColor() {
    switch (_status) {
      case "RUNNING":
        return Colors.orangeAccent;
      case "SUCCESS":
        return const Color(0xFF00FF66);
      case "ERROR":
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeArea = MediaQuery.of(context).padding;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.65,
          decoration: BoxDecoration(
            color: const Color(0xFF070B19).withValues(alpha: 0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(
              color: _getStatusColor().withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              // Pull indicator & Header bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.terminal_rounded,
                          color: Color(0xFF00FF66),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "SANDBOX TERMINAL: ${widget.apiName}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor().withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _getStatusColor().withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_status == "RUNNING") ...[
                                const SizedBox(
                                  width: 8,
                                  height: 8,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.orangeAccent,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                _status,
                                style: TextStyle(
                                  color: _getStatusColor(),
                                  fontFamily: 'monospace',
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Console Terminal Logs Area
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.black.withValues(alpha: 0.25),
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _logs.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _logs.length) {
                        // Pulse cursor
                        if (_status == "RUNNING") {
                          return FadeTransition(
                            opacity: _cursorAnimController,
                            child: const Text(
                              "█",
                              style: TextStyle(
                                color: Color(0xFF00FF66),
                                fontFamily: 'monospace',
                                fontSize: 13,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }

                      final log = _logs[index];
                      Color logColor = const Color(0xFF00FF66); // Default green
                      if (log.contains("🛑") || log.contains("Script Error:") || log.contains("Exception") || log.contains("error")) {
                        logColor = Colors.redAccent;
                      } else if (log.contains("🤖 SYSTEM:") || log.contains("✨ SYSTEM:")) {
                        logColor = const Color(0xFF00E5FF); // Cyan for systems
                      } else if (log.contains("[Main Isolate]")) {
                        logColor = Colors.purpleAccent;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          log,
                          style: TextStyle(
                            color: logColor,
                            fontFamily: 'monospace',
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Bottom action bar
              Container(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + safeArea.bottom),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.02),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.white.withValues(alpha: 0.06),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                        child: const Text(
                          "CLOSE TERMINAL",
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (_status != "RUNNING")
                      Expanded(
                        child: GestureDetector(
                          onTap: _run,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: LiquidTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              "RE-RUN",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
