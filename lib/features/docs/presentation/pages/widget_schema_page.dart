import 'package:flutter/material.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/core/theme/liquid_colors.dart';
import 'package:script_automator/core/ui/mesh_gradient_background.dart';
import 'package:script_automator/features/docs/data/widget_schema_data.dart';

class WidgetSchemaPage extends StatefulWidget {
  const WidgetSchemaPage({super.key});

  @override
  State<WidgetSchemaPage> createState() => _WidgetSchemaPageState();
}

class _WidgetSchemaPageState extends State<WidgetSchemaPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _expandedNode;

  static const modifiersReference = [
    ('width', 'number', 'Fixed width in points.'),
    ('height', 'number', 'Fixed height in points.'),
    ('flex', 'number', 'Flexible sizing when set to 1.'),
    ('background', 'string', 'Hex color, glass, or linear-gradient(...).'),
    ('cornerRadius', 'number', 'Rounded corners in points.'),
    ('padding', 'object', 'Insets inside the node.'),
    ('font', 'string', 'Font style such as title or bold.'),
    ('fontSize', 'number', 'Custom font or icon size.'),
    ('color', 'string', 'Text or icon color as a hex value.'),
    (
      'alignment',
      'string',
      'Layout alignment for rows, columns, and containers.',
    ),
    ('spacing', 'number', 'Gap between children.'),
    ('maxLines', 'number', 'Maximum number of visible lines for text.'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<WidgetSchemaEntry> get _filteredEntries {
    final q = _query.trim().toLowerCase();
    return widgetSchema.where((entry) {
      if (q.isEmpty) return true;
      return entry.nodeType.toLowerCase().contains(q) ||
          entry.description.toLowerCase().contains(q) ||
          entry.properties.any(
            (p) =>
                p.name.toLowerCase().contains(q) ||
                p.description.toLowerCase().contains(q) ||
                p.type.toLowerCase().contains(q),
          );
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
                  Expanded(
                    child: ListView(
                      children: [
                        _buildQuickStart(colors, isDark),
                        const SizedBox(height: 18),
                        ..._filteredEntries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _buildEntryCard(entry, colors, isDark),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildModifiersReference(colors),
                      ],
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
          child: const Icon(
            Icons.view_module_rounded,
            color: LiquidTheme.primary,
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Widget Schema',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colors.textTitle,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Learn the SASUP JSON structure used to build native widgets.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: colors.textBody),
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
          hintText: 'Search node types or properties',
          hintStyle: TextStyle(color: colors.searchBarHint),
          prefixIcon: Icon(Icons.search, color: colors.searchBarHint),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
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

  Widget _buildQuickStart(LiquidColors colors, bool isDark) {
    const code = '''{
  "type": "container",
  "modifiers": {
    "background": "linear-gradient(135deg, #667eea, #764ba2)",
    "cornerRadius": 24,
    "padding": { "all": 20 }
  },
  "children": [
    {
      "type": "column",
      "modifiers": { "spacing": 8 },
      "children": [
        { "type": "text", "content": "San Francisco", "modifiers": { "font": "title", "color": "#FFFFFF" } },
        { "type": "row", "modifiers": { "spacing": 8 }, "children": [
          { "type": "icon", "content": "cloud.sun.fill", "modifiers": { "fontSize": 28, "color": "#FFD700" } },
          { "type": "text", "content": "72°", "modifiers": { "font": "title", "fontSize": 42, "color": "#FFFFFF" } }
        ]},
        { "type": "button", "label": "Refresh", "actionId": "refresh_weather", "scriptId": "weather_pro_v2" }
      ]
    }
  ]
}''';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Start',
            style: TextStyle(
              color: colors.textTitle,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'A complete weather widget with text, icons, and an interactive button.',
            style: TextStyle(color: colors.textBody),
          ),
          const SizedBox(height: 14),
          _buildCodeBlock(code, isDark),
        ],
      ),
    );
  }

  Widget _buildEntryCard(WidgetSchemaEntry entry, LiquidColors colors, bool isDark) {
    final expanded = _expandedNode == entry.nodeType;
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
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.nodeType,
                        style: TextStyle(
                          color: colors.textTitle,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        entry.description,
                        style: TextStyle(
                          color: colors.textBody,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => setState(
                    () => _expandedNode = expanded ? null : entry.nodeType,
                  ),
                  icon: Icon(
                    expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: colors.textCaption,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildPropertiesTable(entry.properties, colors),
            const SizedBox(height: 14),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(
                () => _expandedNode = expanded ? null : entry.nodeType,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: colors.secondaryButtonBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colors.cardBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'JSON Example',
                      style: TextStyle(
                        color: colors.secondaryButtonText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.code_rounded, color: colors.textCaption),
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
              crossFadeState: expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 220),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertiesTable(List<SchemaProperty> properties, LiquidColors colors) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.secondaryButtonBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        children: [
          _tableRow([
            'Property',
            'Type',
            'Required',
            'Description',
          ], colors, isHeader: true),
          ...properties.map(
            (property) => _tableRow([
              property.name,
              property.type,
              property.required ? 'Yes' : 'No',
              property.description,
            ], colors),
          ),
        ],
      ),
    );
  }

  Widget _tableRow(List<String> cells, LiquidColors colors, {bool isHeader = false}) {
    final textStyle = TextStyle(
      color: isHeader ? colors.textTitle : colors.textBody,
      fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500,
      fontSize: 12,
      height: 1.35,
    );
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isHeader ? colors.divider : colors.divider.withValues(alpha: 0.5),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(cells[0], style: textStyle)),
          const SizedBox(width: 10),
          Expanded(flex: 1, child: Text(cells[1], style: textStyle)),
          const SizedBox(width: 10),
          Expanded(flex: 1, child: Text(cells[2], style: textStyle)),
          const SizedBox(width: 10),
          Expanded(flex: 3, child: Text(cells[3], style: textStyle)),
        ],
      ),
    );
  }

  Widget _buildModifiersReference(LiquidColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Modifiers Reference',
            style: TextStyle(
              color: colors.textTitle,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ...modifiersReference.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.chipBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colors.cardBorder),
                    ),
                    child: Text(
                      item.$1,
                      style: TextStyle(
                        color: colors.textTitle,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${item.$2} · ${item.$3}',
                      style: TextStyle(
                        color: colors.textBody,
                        height: 1.35,
                      ),
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
}
