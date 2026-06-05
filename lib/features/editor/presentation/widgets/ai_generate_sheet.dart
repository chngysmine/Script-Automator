import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/core/theme/liquid_colors.dart';
import 'package:script_automator/features/ai_integration/data/services/openai_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class ParsedMessage {
  final String text;
  final String? code;

  ParsedMessage({required this.text, this.code});
}

/// Redesigned Messenger-style bottom sheet for AI coding conversations.
class AiGenerateSheetContent extends StatefulWidget {
  final bool isDark;
  final LiquidColors colors;
  final String editorCode;

  const AiGenerateSheetContent({
    super.key,
    required this.isDark,
    required this.colors,
    required this.editorCode,
  });

  @override
  State<AiGenerateSheetContent> createState() => _AiGenerateSheetContentState();
}

class _AiGenerateSheetContentState extends State<AiGenerateSheetContent> {
  final TextEditingController _promptCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isGenerating = false;
  final OpenAIService _openAIService = GetIt.I<OpenAIService>();

  String _statusText = "Active Now";
  Color _statusColor = Colors.green;

  @override
  void initState() {
    super.initState();
    final isReady = _openAIService.isReady;
    _statusText = isReady ? "Active Now" : "Not Configured";
    _statusColor = isReady ? Colors.green : Colors.amber;

    // Warm greeting from AI
    _messages.add(ChatMessage(
      text: widget.editorCode.trim().isEmpty || widget.editorCode.trim().startsWith('// Start coding')
          ? "Hi! I'm your AI coding partner. 🚀\nWhat kind of JavaScript automation or widget would you like to create today?"
          : "Hi! I'm your AI coding partner. 🚀\nI see you have some code in your editor. How can I help you improve, debug, or extend it?",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _promptCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  ParsedMessage _parseMessage(String content) {
    final RegExp regExp = RegExp(r'```(?:javascript|js)?([\s\S]*?)```');
    final Match? match = regExp.firstMatch(content);
    
    if (match != null) {
      final code = match.group(1)?.trim();
      final text = content.replaceFirst(match.group(0)!, '').trim();
      return ParsedMessage(
        text: text.isEmpty ? "Here is the JavaScript code you requested:" : text,
        code: code,
      );
    }
    
    return ParsedMessage(text: content);
  }

  Future<void> _sendMessage() async {
    final prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty || _isGenerating) return;

    _promptCtrl.clear();
    setState(() {
      _messages.add(ChatMessage(
        text: prompt,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isGenerating = true;
    });
    _scrollToBottom();

    // Map conversation to API payload
    final apiMessages = _messages.map((m) {
      return {
        'role': m.isUser ? 'user' : 'assistant',
        'content': m.text,
      };
    }).toList();

    try {
      // Call chat API
      final response = await _openAIService.chatWithAi(
        apiMessages,
        existingCode: widget.editorCode,
      );

      if (!mounted) return;

      if (response == null || response.startsWith('Error')) {
        setState(() {
          _statusText = "Connection Error";
          _statusColor = Colors.red;
        });
      } else {
        setState(() {
          _statusText = "Active Now";
          _statusColor = Colors.green;
        });
      }

      setState(() {
        _isGenerating = false;
        _messages.add(ChatMessage(
          text: response ?? "Sorry, I couldn't get a response. Please check your network or API key settings.",
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusText = "Connection Error";
        _statusColor = Colors.red;
        _isGenerating = false;
        _messages.add(ChatMessage(
          text: "Error calling AI: $e\nPlease verify your API key settings or network connection.",
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final isDark = widget.isDark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final viewHeight = MediaQuery.of(context).size.height * 0.70;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: viewHeight,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 30,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Messenger-style AI Avatar
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [LiquidTheme.primary, LiquidTheme.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Assistant',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: colors.textTitle,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _statusText,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colors.textCaption,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      color: colors.textTitle,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Chat Messages List
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (_isGenerating ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length) {
                      // AI is thinking/typing indicator bubble
                      return _buildTypingBubble();
                    }

                    final message = _messages[index];
                    return _buildChatBubble(message);
                  },
                ),
              ),

              // Input field section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: TextField(
                          controller: _promptCtrl,
                          style: TextStyle(
                            color: colors.textTitle,
                            fontSize: 14,
                          ),
                          maxLines: 4,
                          minLines: 1,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(
                              color: colors.searchBarHint,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: LiquidTheme.primary,
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
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

  Widget _buildChatBubble(ChatMessage message) {
    final colors = widget.colors;
    final isDark = widget.isDark;

    if (message.isUser) {
      // User Chat Bubble (Messenger style - Right)
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 40),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [LiquidTheme.primary, Color(0xFF7C3AED)], // Messenger pinkish-purple gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(
            message.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.3,
            ),
          ),
        ),
      );
    } else {
      // AI Chat Bubble (Messenger style - Left)
      final parsed = _parseMessage(message.text);

      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16, right: 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Small AI avatar
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [LiquidTheme.primary, LiquidTheme.secondary],
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text Bubble
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5F9),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                          bottomLeft: Radius.circular(4),
                          bottomRight: Radius.circular(20),
                        ),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        parsed.text,
                        style: TextStyle(
                          color: colors.textTitle,
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                    ),

                    // Code Block (if parsed)
                    if (parsed.code != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Code Header
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.03),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'javascript',
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(text: parsed.code!));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Code copied to clipboard'),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                    child: const Row(
                                      children: [
                                        Icon(Icons.copy_rounded, color: Colors.white60, size: 14),
                                        SizedBox(width: 4),
                                        Text(
                                          'Copy',
                                          style: TextStyle(color: Colors.white60, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Code content
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Text(
                                  parsed.code!,
                                  style: const TextStyle(
                                    color: Color(0xFFE2E8F0),
                                    fontFamily: 'monospace',
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ),
                            // Apply button
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: LiquidTheme.primary,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 38),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                ),
                                icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                                label: const Text(
                                  'Apply to Editor',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                onPressed: () {
                                  HapticFeedback.mediumImpact();
                                  Navigator.pop(context, parsed.code);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildTypingBubble() {
    final isDark = widget.isDark;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 36),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0),
            const SizedBox(width: 4),
            _buildDot(1),
            const SizedBox(width: 4),
            _buildDot(2),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: widget.isDark ? Colors.white60 : Colors.black45,
        shape: BoxShape.circle,
      ),
    );
  }
}
