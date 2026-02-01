import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:script_automator/features/widget_renderer/domain/entities/sasup_modifiers.dart';
import 'package:script_automator/features/widget_renderer/domain/entities/sasup_schema.dart';
import 'package:script_automator/features/widget_renderer/domain/entities/widget_type.dart';

void main() {
  test('Should strictly parse valid SASUP JSON', () {
    // 1. Define a complex JSON payload (Simulating JS Output)
    final jsonString = '''
    {
      "meta": {
        "version": "1.0",
        "target": "universal",
        "timestamp": 1700000000
      },
      "root": {
        "type": "column",
        "id": "root_1",
        "modifiers": {
          "padding": { "runtimeType": "all", "value": 16.0 },
          "background": "#FFFFFF",
          "alignment": "center"
        },
        "children": [
          {
            "type": "text",
            "content": "Hello World",
            "modifiers": {
              "font": "title",
              "color": "#000000"
            }
          },
          {
            "type": "spacer",
            "modifiers": { "flex": 1 }
          },
          {
            "type": "row",
            "children": [
              {
                "type": "image",
                "content": "file:///storage/img.png",
                "modifiers": {
                  "width": 100.0,
                  "height": 100.0,
                  "cornerRadius": 12.0
                }
              },
              {
                "type": "stack",
                "children": [
                  { 
                    "type": "text", 
                    "content": "Badge",
                    "action": {
                      "type": "runScript",
                      "payload": { "scriptId": "abc-123" }
                    }
                  }
                ]
              }
            ]
          }
        ]
      }
    }
    ''';

    // 2. Parse
    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    final schema = SASUPSchema.fromJson(jsonMap);

    // 3. Assertions
    expect(schema.meta.version, "1.0");
    expect(schema.root.type, WidgetType.column);
    expect(
      schema.root.modifiers?.padding?.mapOrNull(all: (v) => v.value),
      16.0,
    );
    expect(schema.root.children?.length, 3);

    // Check first child (Text)
    final first = schema.root.children![0];
    expect(first.type, WidgetType.text);
    expect(first.content, "Hello World");

    // Check nested structure (Row -> Image)
    final row = schema.root.children![2];
    expect(row.type, WidgetType.row);
    final image = row.children![0];
    expect(image.type, WidgetType.image);
    expect(image.content, "file:///storage/img.png");
    expect(image.modifiers?.cornerRadius, 12.0);

    // Check Action
    final stack = row.children![1];
    final badge = stack.children![0];
    expect(badge.action?.type, "runScript");
    expect(badge.action?.payload?['scriptId'], "abc-123");
  });
}
