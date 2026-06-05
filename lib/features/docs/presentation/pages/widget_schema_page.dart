import 'package:flutter/material.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
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
                  Expanded(
                    child: ListView(
                      children: [
                        _buildQuickStart(),
                        const SizedBox(height: 18),
                        ..._filteredEntries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _buildEntryCard(entry),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildModifiersReference(),
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
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Learn the SASUP JSON structure used to build native widgets.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
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
          hintText: 'Search node types or properties',
          hintStyle: const TextStyle(color: Colors.white54),
          prefixIcon: const Icon(Icons.search, color: Colors.white54),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
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

  Widget _buildQuickStart() {
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
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Start',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'A complete weather widget with text, icons, and an interactive button.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 14),
          _buildCodeBlock(code),
        ],
      ),
    );
  }

  Widget _buildEntryCard(WidgetSchemaEntry entry) {
    final expanded = _expandedNode == entry.nodeType;
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
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.nodeType,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        entry.description,
                        style: const TextStyle(
                          color: Colors.white70,
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
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildPropertiesTable(entry.properties),
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
                  color: Colors.black.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  children: const [
                    Text(
                      'JSON Example',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Spacer(),
                    Icon(Icons.code_rounded, color: Colors.white70),
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

  Widget _buildPropertiesTable(List<SchemaProperty> properties) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          _tableRow([
            'Property',
            'Type',
            'Required',
            'Description',
          ], isHeader: true),
          ...properties.map(
            (property) => _tableRow([
              property.name,
              property.type,
              property.required ? 'Yes' : 'No',
              property.description,
            ]),
          ),
        ],
      ),
    );
  }

  Widget _tableRow(List<String> cells, {bool isHeader = false}) {
    final textStyle = TextStyle(
      color: isHeader ? Colors.white : Colors.white70,
      fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500,
      fontSize: 12,
      height: 1.35,
    );
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: isHeader ? 0.12 : 0.06),
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

  Widget _buildModifiersReference() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Modifiers Reference',
            style: TextStyle(
              color: Colors.white,
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
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.$1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${item.$2} · ${item.$3}',
                      style: const TextStyle(
                        color: Colors.white70,
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
}
