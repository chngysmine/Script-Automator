import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/core/theme/liquid_colors.dart';
import 'package:script_automator/core/theme/liquid_page_route.dart';
import 'package:script_automator/core/ui/mesh_gradient_background.dart';
import 'package:script_automator/features/docs/data/api_reference_data.dart';
import 'package:script_automator/features/docs/presentation/widgets/sandbox_terminal_sheet.dart';
import 'package:script_automator/features/editor/presentation/pages/editor_page.dart';
import 'package:script_automator/features/script_management/domain/entities/script.dart';
import 'package:script_automator/features/script_management/domain/repositories/script_repository.dart';

class ApiDocsPage extends StatefulWidget {
  const ApiDocsPage({super.key});

  @override
  State<ApiDocsPage> createState() => _ApiDocsPageState();
}

class _ApiDocsPageState extends State<ApiDocsPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  String _query = '';
  String _selectedCategory = 'All';
  String? _expandedApi;
  bool _showSearchIconInHeader = false;
  bool _forceShowSearchBar = false;

  static const categories = [
    'All',
    'Console',
    'Network',
    'Device',
    'Storage',
    'Notification',
    'Widget',
    'Rendering',
    'FileSystem',
    'Timers',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.offset;
    final shouldShow = offset > 50;
    if (shouldShow != _showSearchIconInHeader) {
      setState(() {
        _showSearchIconInHeader = shouldShow;
        if (!shouldShow) {
          _forceShowSearchBar = false;
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<ApiEntry> get _filteredEntries {
    final q = _query.trim().toLowerCase();
    return apiReference.where((entry) {
      final categoryMatch = _selectedCategory == 'All' || entry.category == _selectedCategory;
      if (!categoryMatch) return false;
      if (q.isEmpty) return true;
      return entry.name.toLowerCase().contains(q) ||
          entry.description.toLowerCase().contains(q) ||
          entry.category.toLowerCase().contains(q) ||
          entry.signature.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiquidColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showSearchBar = !_showSearchIconInHeader || _forceShowSearchBar;

    return Scaffold(
      backgroundColor: isDark ? LiquidTheme.darkBackground : LiquidTheme.lightBackground,
      body: Stack(
        children: [
          const Positioned.fill(child: MeshGradientBackground()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildHeader(context, colors),
                  const SizedBox(height: 16),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.fastOutSlowIn,
                    height: showSearchBar ? 70.0 : 0.0,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: showSearchBar ? 1.0 : 0.0,
                      curve: Curves.easeInOut,
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildSearchBar(colors),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _buildCategoryFilter(colors),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _filteredEntries.isEmpty
                        ? _buildEmptyState(colors)
                        : ListView.separated(
                            controller: _scrollController,
                            itemCount: _filteredEntries.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 14),
                            itemBuilder: (context, index) => _buildEntryCard(_filteredEntries[index], colors, isDark),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, LiquidColors colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.textTitle, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          splashRadius: 24,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            'API Reference',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colors.textTitle,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: animation,
                child: child,
              ),
            );
          },
          child: _showSearchIconInHeader
              ? IconButton(
                  key: ValueKey('header_search_icon_$_forceShowSearchBar'),
                  onPressed: () {
                    setState(() {
                      _forceShowSearchBar = !_forceShowSearchBar;
                      if (_forceShowSearchBar) {
                        _searchFocusNode.requestFocus();
                      } else {
                        _searchFocusNode.unfocus();
                      }
                    });
                  },
                  icon: Icon(
                    _forceShowSearchBar ? Icons.close_rounded : Icons.search_rounded,
                    color: colors.textTitle,
                    size: 22,
                  ),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  splashRadius: 24,
                )
              : const SizedBox.shrink(key: ValueKey('header_search_icon_empty')),
        ),
      ],
    );
  }

  Widget _buildSearchBar(LiquidColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.searchBarBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.searchBarBorder),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: (value) => setState(() => _query = value),
        style: TextStyle(color: colors.textTitle),
        decoration: InputDecoration(
          hintText: 'Search APIs, categories, or signatures',
          hintStyle: TextStyle(color: colors.searchBarHint),
          prefixIcon: Icon(Icons.search, color: colors.searchBarHint),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: colors.searchBarHint),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(LiquidColors colors) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = _selectedCategory == category;
          return ChoiceChip(
            label: Text(category),
            selected: selected,
            selectedColor: LiquidTheme.primary.withValues(alpha: 0.22),
            backgroundColor: colors.chipBackground,
            labelStyle: TextStyle(
              color: selected ? LiquidTheme.primary : colors.textCaption,
              fontWeight: FontWeight.w600,
            ),
            side: BorderSide(
              color: selected ? LiquidTheme.primary.withValues(alpha: 0.5) : colors.cardBorder,
            ),
            onSelected: (_) => setState(() => _selectedCategory = category),
          );
        },
      ),
    );
  }

  Widget _buildEntryCard(ApiEntry entry, LiquidColors colors, bool isDark) {
    final expanded = _expandedApi == entry.name;
    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.name,
                        style: TextStyle(
                          color: colors.textTitle,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        entry.signature,
                        style: const TextStyle(
                          color: LiquidTheme.primary,
                          fontFamily: 'monospace',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        entry.description,
                        style: TextStyle(color: colors.textBody, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: LiquidTheme.primary.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    entry.category,
                    style: const TextStyle(
                      color: LiquidTheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (entry.params != null && entry.params!.isNotEmpty) ...[
              const SizedBox(height: 14),
              _buildParams(entry.params!, colors),
            ],
            const SizedBox(height: 14),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => _expandedApi = expanded ? null : entry.name),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: colors.secondaryButtonBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.cardBorder),
                ),
                child: Row(
                  children: [
                    Text(
                      'Example Code',
                      style: TextStyle(color: colors.secondaryButtonText, fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    Icon(
                      expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      color: colors.textCaption,
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCodeBlock(entry.example, isDark),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _runInSandbox(context, entry),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: colors.glassBorder),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.play_arrow_rounded, color: LiquidTheme.primary, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  "Run in Sandbox",
                                  style: TextStyle(
                                    color: colors.textTitle,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _cloneToEditor(context, entry),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                gradient: isDark
                                    ? LiquidTheme.primaryGradient
                                    : LiquidTheme.brandDarkGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.copy_rounded, color: Colors.white, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    "Clone to Editor",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 220),
            ),
          ],
        ),
      ),
    );
  }

  void _runInSandbox(BuildContext context, ApiEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SandboxTerminalSheet(
        apiName: entry.name,
        code: entry.example,
      ),
    );
  }

  void _cloneToEditor(BuildContext context, ApiEntry entry) async {
    final repo = GetIt.I<ScriptRepository>();
    final script = Script(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: entry.name,
      content: entry.example,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await repo.saveScript(script);

    if (context.mounted) {
      Navigator.push(
        context,
        LiquidPageRoute(page: EditorPage(script: script)),
      );
    }
  }

  Widget _buildParams(List<ApiParam> params, LiquidColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.api_rounded, size: 16, color: LiquidTheme.primary),
            const SizedBox(width: 6),
            Text(
              'Parameters',
              style: TextStyle(
                color: colors.textTitle,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: colors.cardBackground.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.cardBorder),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: List.generate(params.length, (index) {
              final param = params[index];
              return Padding(
                padding: EdgeInsets.only(bottom: index == params.length - 1 ? 0 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Param Name Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: colors.chipBackground,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: colors.cardBorder),
                          ),
                          child: Text(
                            param.name,
                            style: TextStyle(
                              color: colors.textTitle,
                              fontFamily: 'monospace',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Param Type Badge
                        Text(
                          param.type,
                          style: const TextStyle(
                            color: LiquidTheme.primary,
                            fontFamily: 'monospace',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        // Required Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: param.required
                                ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                                : colors.textCaption.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: param.required
                                  ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                                  : colors.textCaption.withValues(alpha: 0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            param.required ? 'REQUIRED' : 'OPTIONAL',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: param.required ? const Color(0xFFEF4444) : colors.textCaption,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        param.description,
                        style: TextStyle(
                          color: colors.textBody,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ),
                    if (index < params.length - 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Divider(height: 1, color: colors.divider.withValues(alpha: 0.5)),
                      ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildCodeBlock(String code, bool isDark) {
    final bg = isDark ? const Color(0xFF0B1220) : const Color(0xFFF1F5F9);
    final borderCol = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
      ),
      child: JSSyntaxHighlighter(
        code: code,
        isDark: isDark,
      ),
    );
  }

  Widget _buildEmptyState(LiquidColors colors) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, color: LiquidTheme.primary, size: 48),
            const SizedBox(height: 12),
            Text(
              'No APIs match your search.',
              style: TextStyle(color: colors.textTitle, fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              'Try a different keyword or category.',
              style: TextStyle(color: colors.textBody),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// CUSTOM REGEX JAVASCRIPT SYNTAX HIGHLIGHTER
// ==========================================
class JSSyntaxHighlighter extends StatelessWidget {
  final String code;
  final bool isDark;

  const JSSyntaxHighlighter({
    super.key,
    required this.code,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final spans = _highlight(code);
    return SelectableText.rich(
      TextSpan(
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          height: 1.5,
          color: isDark ? const Color(0xFFD4D4D4) : const Color(0xFF09090B),
        ),
        children: spans,
      ),
    );
  }

  List<TextSpan> _highlight(String text) {
    final List<TextSpan> spans = [];

    // Regex for comments, strings, keywords, built-ins, and numeric values
    final regex = RegExp(
      r'(//.*)|' // 1. Comments
      r'("(?:\\.|[^"\\])*"|\x27(?:\\.|[^\x27\\])*\x27|`(?:\\.|[^`\\])*`)|' // 2. Strings
      r'\b(const|let|var|await|async|function|class|return|if|else|try|catch|throw|new|import|export|from)\b|' // 3. Keywords
      r'\b(console|Widget|Device|Keychain|Notification|Share|Clipboard|FileSystem|fetch)\b|' // 4. Built-in objects
      r'\b(\d+)\b', // 5. Numbers
    );

    int lastIndex = 0;
    for (final match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
      }

      final matchedText = match.group(0)!;
      if (match.group(1) != null) {
        // Comments - Muted Green
        spans.add(TextSpan(
          text: matchedText,
          style: TextStyle(color: isDark ? const Color(0xFF6A9955) : const Color(0xFF008000)),
        ));
      } else if (match.group(2) != null) {
        // Strings - Warm Terracotta / Dark Red
        spans.add(TextSpan(
          text: matchedText,
          style: TextStyle(color: isDark ? const Color(0xFFCE9178) : const Color(0xFFA31515)),
        ));
      } else if (match.group(3) != null) {
        // Keywords - Royal Blue
        spans.add(TextSpan(
          text: matchedText,
          style: TextStyle(
            color: isDark ? const Color(0xFF569CD6) : const Color(0xFF0000FF),
            fontWeight: FontWeight.bold,
          ),
        ));
      } else if (match.group(4) != null) {
        // Built-ins - Teal
        spans.add(TextSpan(
          text: matchedText,
          style: TextStyle(
            color: isDark ? const Color(0xFF4EC9B0) : const Color(0xFF267F99),
            fontWeight: FontWeight.w600,
          ),
        ));
      } else if (match.group(5) != null) {
        // Numbers - Sage Green / Forest Green
        spans.add(TextSpan(
          text: matchedText,
          style: TextStyle(color: isDark ? const Color(0xFFB5CEA8) : const Color(0xFF098658)),
        ));
      }

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex)));
    }

    return spans;
  }
}
