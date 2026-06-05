import 'package:flutter/material.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: LiquidTheme.darkBackground,
      body: Stack(
        children: [
          const Positioned.fill(child: MeshGradientBackground()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 16),
                  _buildSearchBar(),
                  const SizedBox(height: 16),
                  _buildCategoryFilter(),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _filteredEntries.isEmpty
                        ? _buildEmptyState(theme)
                        : ListView.separated(
                            itemCount: _filteredEntries.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 14),
                            itemBuilder: (context, index) => _buildEntryCard(_filteredEntries[index]),
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

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Explore every built-in scripting API with examples.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _query = value),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search APIs, categories, or signatures',
          hintStyle: const TextStyle(color: Colors.white54),
          prefixIcon: const Icon(Icons.search, color: Colors.white54),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white54),
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

  Widget _buildCategoryFilter() {
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
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            labelStyle: TextStyle(
              color: selected ? LiquidTheme.primary : Colors.white70,
              fontWeight: FontWeight.w600,
            ),
            side: BorderSide(
              color: selected ? LiquidTheme.primary.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.08),
            ),
            onSelected: (_) => setState(() => _selectedCategory = category),
          );
        },
      ),
    );
  }

  Widget _buildEntryCard(ApiEntry entry) {
    final expanded = _expandedApi == entry.name;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
                        style: const TextStyle(
                          color: Colors.white,
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
                        style: const TextStyle(color: Colors.white70, height: 1.4),
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
              _buildParams(entry.params!),
            ],
            const SizedBox(height: 14),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => _expandedApi = expanded ? null : entry.name),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Example',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    Icon(
                      expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      color: Colors.white70,
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _buildCodeBlock(entry.example),
              ),
              crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 220),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParams(List<ApiParam> params) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Parameters',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
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
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    param.name,
                    style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${param.type}${param.required ? ' · required' : ''} · ${param.description}',
                    style: const TextStyle(color: Colors.white70, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCodeBlock(String code) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: SelectableText(
        code,
        style: const TextStyle(
          color: Color(0xFFE5E7EB),
          fontFamily: 'monospace',
          fontSize: 13,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, color: LiquidTheme.primary, size: 48),
            const SizedBox(height: 12),
            Text(
              'No APIs match your search.',
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try a different keyword or category.',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
