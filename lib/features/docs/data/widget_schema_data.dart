class WidgetSchemaEntry {
  final String nodeType;
  final String description;
  final List<SchemaProperty> properties;
  final String example;

  const WidgetSchemaEntry({
    required this.nodeType,
    required this.description,
    required this.properties,
    required this.example,
  });
}

class SchemaProperty {
  final String name;
  final String type;
  final String description;
  final bool required;

  const SchemaProperty({
    required this.name,
    required this.type,
    required this.description,
    required this.required,
  });
}

const List<WidgetSchemaEntry> widgetSchema = [
  WidgetSchemaEntry(
    nodeType: 'container',
    description: 'A top-level visual wrapper that applies background, padding, radius, and layout constraints.',
    properties: [
      SchemaProperty(name: 'type', type: 'string', description: 'Must be container.', required: true),
      SchemaProperty(name: 'modifiers', type: 'object', description: 'Visual styling and spacing.', required: false),
      SchemaProperty(name: 'children', type: 'array', description: 'Nested nodes rendered inside the container.', required: false),
    ],
    example: '''{
  "type": "container",
  "modifiers": {
    "background": "linear-gradient(135deg, #667eea, #764ba2)",
    "cornerRadius": 24,
    "padding": { "all": 20 }
  },
  "children": [
    { "type": "text", "content": "Hello World" }
  ]
}''',
  ),
  WidgetSchemaEntry(
    nodeType: 'column',
    description: 'Stacks children vertically with configurable spacing and alignment.',
    properties: [
      SchemaProperty(name: 'type', type: 'string', description: 'Must be column.', required: true),
      SchemaProperty(name: 'modifiers', type: 'object', description: 'Spacing and alignment.', required: false),
      SchemaProperty(name: 'children', type: 'array', description: 'Child nodes rendered top-to-bottom.', required: false),
    ],
    example: '''{
  "type": "column",
  "modifiers": { "spacing": 8, "alignment": "center" },
  "children": [
    { "type": "text", "content": "Title" },
    { "type": "text", "content": "Subtitle" }
  ]
}''',
  ),
  WidgetSchemaEntry(
    nodeType: 'row',
    description: 'Lays out children horizontally.',
    properties: [
      SchemaProperty(name: 'type', type: 'string', description: 'Must be row.', required: true),
      SchemaProperty(name: 'modifiers', type: 'object', description: 'Spacing and alignment.', required: false),
      SchemaProperty(name: 'children', type: 'array', description: 'Child nodes rendered left-to-right.', required: false),
    ],
    example: '''{
  "type": "row",
  "modifiers": { "spacing": 12, "alignment": "center" },
  "children": [
    { "type": "icon", "content": "cloud.sun.fill" },
    { "type": "text", "content": "72°" }
  ]
}''',
  ),
  WidgetSchemaEntry(
    nodeType: 'stack',
    description: 'Overlays children on top of each other.',
    properties: [
      SchemaProperty(name: 'type', type: 'string', description: 'Must be stack.', required: true),
      SchemaProperty(name: 'children', type: 'array', description: 'Nodes rendered in the same coordinate space.', required: false),
    ],
    example: '''{
  "type": "stack",
  "children": [
    { "type": "image", "content": "file:///tmp/bg.png" },
    { "type": "text", "content": "Overlay" }
  ]
}''',
  ),
  WidgetSchemaEntry(
    nodeType: 'text',
    description: 'Renders a text label with automatic truncation and responsive scaling.',
    properties: [
      SchemaProperty(name: 'type', type: 'string', description: 'Must be text.', required: true),
      SchemaProperty(name: 'content', type: 'string', description: 'Text content to display.', required: true),
      SchemaProperty(name: 'modifiers', type: 'object', description: 'Font, color, size, and line limits.', required: false),
    ],
    example: '''{
  "type": "text",
  "content": "Good morning",
  "modifiers": {
    "font": "title",
    "fontSize": 22,
    "color": "#FFFFFF",
    "maxLines": 2
  }
}''',
  ),
  WidgetSchemaEntry(
    nodeType: 'icon',
    description: 'Renders an SF Symbol or mapped icon asset.',
    properties: [
      SchemaProperty(name: 'type', type: 'string', description: 'Must be icon.', required: true),
      SchemaProperty(name: 'content', type: 'string', description: 'SF Symbol name.', required: true),
      SchemaProperty(name: 'modifiers', type: 'object', description: 'Tint and sizing options.', required: false),
    ],
    example: '''{
  "type": "icon",
  "content": "cloud.sun.fill",
  "modifiers": {
    "fontSize": 32,
    "color": "#FFD700"
  }
}''',
  ),
  WidgetSchemaEntry(
    nodeType: 'image',
    description: 'Renders an image from a local file URL.',
    properties: [
      SchemaProperty(name: 'type', type: 'string', description: 'Must be image.', required: true),
      SchemaProperty(name: 'content', type: 'string', description: 'file:// path to the image.', required: true),
    ],
    example: '''{
  "type": "image",
  "content": "file:///var/mobile/Containers/Data/image.png"
}''',
  ),
  WidgetSchemaEntry(
    nodeType: 'button',
    description: 'Renders an interactive native button that triggers a widget action.',
    properties: [
      SchemaProperty(name: 'type', type: 'string', description: 'Must be button.', required: true),
      SchemaProperty(name: 'label', type: 'string', description: 'Visible button label.', required: true),
      SchemaProperty(name: 'actionId', type: 'string', description: 'Callback identifier for Widget.onAction.', required: true),
      SchemaProperty(name: 'scriptId', type: 'string', description: 'Script identifier required by the native action bridge.', required: false),
    ],
    example: '''{
  "type": "button",
  "label": "Refresh",
  "actionId": "refresh_weather",
  "scriptId": "weather_pro_v2"
}''',
  ),
  WidgetSchemaEntry(
    nodeType: 'spacer',
    description: 'Adds fixed or flexible space between nodes.',
    properties: [
      SchemaProperty(name: 'type', type: 'string', description: 'Must be spacer.', required: true),
      SchemaProperty(name: 'modifiers', type: 'object', description: 'Width, height, or flex settings.', required: false),
    ],
    example: '''{
  "type": "spacer",
  "modifiers": { "height": 12 }
}''',
  ),
];
