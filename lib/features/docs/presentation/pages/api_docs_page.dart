import 'package:flutter/material.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/core/theme/liquid_colors.dart';
import 'package:script_automator/core/ui/mesh_gradient_background.dart';
import 'package:script_automator/features/docs/data/api_reference_data.dart';

class ApiDocsPage extends StatefulWidget {
  const ApiDocsPage({super.key});

  @override
  State<ApiDocsPage> createState() => _ApiDocsPageState();
}

class _ApiDocsPageState extends State<ApiDocsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _selectedCategory = 'All';
  String? _expandedApi;

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
  void dispose() {
    _searchController.dispose();
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
                  _buildSearchBar(colors),
                  const SizedBox(height: 16),
                  _buildCategoryFilter(colors),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _filteredEntries.isEmpty
                        ? _buildEmptyState(colors)
                        : ListView.separated(
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
      children: [
        SizedBox(
          width: 52,
          height: 52,
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.textTitle, size: 20),
            padding: EdgeInsets.zero,
            style: IconButton.styleFrom(
              backgroundColor: colors.headerActionBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colors.headerActionBorder),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.headerActionBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.headerActionBorder),
          ),
          child: const Icon(Icons.menu_book_rounded, color: LiquidTheme.primary, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'API Reference',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: colors.textTitle,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Explore every built-in scripting API with examples.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.textBody),
              ),
            ],
          ),
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
                      'Example',
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
                child: _buildCodeBlock(entry.example, isDark),
              ),
              crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 220),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParams(List<ApiParam> params, LiquidColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Parameters',
          style: TextStyle(color: colors.textTitle, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        ...params.map(
          (param) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.chipBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.cardBorder),
                  ),
                  child: Text(
                    param.name,
                    style: TextStyle(color: colors.textTitle, fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${param.type}${param.required ? ' · required' : ''} · ${param.description}',
                    style: TextStyle(color: colors.textBody, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCodeBlock(String code, bool isDark) {
    final bg = isDark ? const Color(0xFF0B1220) : const Color(0xFFF1F5F9);
    final textCol = isDark ? const Color(0xFFE5E7EB) : const Color(0xFF1E293B);
    final borderCol = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
      ),
      child: SelectableText(
        code,
        style: TextStyle(
          color: textCol,
          fontFamily: 'monospace',
          fontSize: 13,
          height: 1.5,
        ),
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
