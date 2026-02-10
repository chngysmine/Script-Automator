import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:script_automator/features/widget_renderer/domain/entities/widget_node.dart';
import 'package:script_automator/features/widget_renderer/domain/entities/widget_type.dart';
import 'package:script_automator/features/widget_renderer/domain/entities/sasup_modifiers.dart';
import 'package:script_automator/features/widget_renderer/domain/entities/sasup_action.dart';
import 'package:script_automator/features/widget_renderer/domain/entities/sasup_padding.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WidgetNode Model Tests', () {
    test('Should serialize and deserialize all WidgetTypes', () {
      for (final type in WidgetType.values) {
        final node = WidgetNode(type: type, content: 'test_$type');
        final json = node.toJson();
        final restored = WidgetNode.fromJson(json);
        expect(restored.type, type, reason: 'Failed for $type');
        expect(restored.content, 'test_$type');
      }
    });

    test('Container type round-trips through JSON', () {
      const node = WidgetNode(
        type: WidgetType.container,
        modifiers: SASUPModifiers(
          background: '#FF0000',
          cornerRadius: 16,
          padding: SASUPPadding(left: 12, top: 12, right: 12, bottom: 12),
        ),
        children: [
          WidgetNode(type: WidgetType.text, content: 'Hello'),
          WidgetNode(
            type: WidgetType.icon,
            content: 'cloud.sun.fill',
            modifiers: SASUPModifiers(fontSize: 24, color: '#FFD700'),
          ),
        ],
      );

      final json = jsonDecode(jsonEncode(node.toJson()));
      final restored = WidgetNode.fromJson(json);

      expect(restored.type, WidgetType.container);
      expect(restored.modifiers?.background, '#FF0000');
      expect(restored.modifiers?.cornerRadius, 16);
      expect(restored.children?.length, 2);
      expect(restored.children![0].type, WidgetType.text);
      expect(restored.children![0].content, 'Hello');
      expect(restored.children![1].type, WidgetType.icon);
      expect(restored.children![1].content, 'cloud.sun.fill');
    });

    test('Spacer with flex:0 and explicit dimensions serializes correctly', () {
      const node = WidgetNode(
        type: WidgetType.spacer,
        modifiers: SASUPModifiers(flex: 0, width: 8, height: 12),
      );

      final json = jsonDecode(jsonEncode(node.toJson()));
      final restored = WidgetNode.fromJson(json);

      expect(restored.type, WidgetType.spacer);
      expect(restored.modifiers?.flex, 0);
      expect(restored.modifiers?.width, 8);
      expect(restored.modifiers?.height, 12);
    });

    test('Action payload survives round-trip', () {
      const node = WidgetNode(
        type: WidgetType.text,
        content: 'Click me',
        action: SASUPAction(
          type: 'runScript',
          payload: {'scriptId': 'abc-123', 'trigger': 'tap'},
        ),
      );

      final json = jsonDecode(jsonEncode(node.toJson()));
      final restored = WidgetNode.fromJson(json);

      expect(restored.action?.type, 'runScript');
      expect(restored.action?.payload?['scriptId'], 'abc-123');
      expect(restored.action?.payload?['trigger'], 'tap');
    });

    test('Deep nested tree serializes without data loss', () {
      const deepTree = WidgetNode(
        type: WidgetType.container,
        children: [
          WidgetNode(
            type: WidgetType.column,
            children: [
              WidgetNode(
                type: WidgetType.row,
                children: [
                  WidgetNode(
                    type: WidgetType.stack,
                    children: [
                      WidgetNode(type: WidgetType.text, content: 'Deepest'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      final json = jsonDecode(jsonEncode(deepTree.toJson()));
      final restored = WidgetNode.fromJson(json);

      // Navigate: container -> column -> row -> stack -> text
      final text = restored.children![0].children![0].children![0].children![0];
      expect(text.type, WidgetType.text);
      expect(text.content, 'Deepest');
    });
  });

  group('SASUPPadding Tests', () {
    test('Parses numeric value as all-sides padding', () {
      final padding = SASUPPadding.fromJson(16.0);
      expect(padding.left, 16.0);
      expect(padding.top, 16.0);
      expect(padding.right, 16.0);
      expect(padding.bottom, 16.0);
    });

    test('Parses map with "value" key as all-sides', () {
      final padding = SASUPPadding.fromJson({
        'runtimeType': 'all',
        'value': 12.0,
      });
      expect(padding.left, 12.0);
      expect(padding.top, 12.0);
    });

    test('Parses symmetric padding', () {
      final padding = SASUPPadding.fromJson({
        'vertical': 8.0,
        'horizontal': 16.0,
      });
      expect(padding.left, 16.0);
      expect(padding.right, 16.0);
      expect(padding.top, 8.0);
      expect(padding.bottom, 8.0);
    });

    test('Parses individual edge values', () {
      final padding = SASUPPadding.fromJson({
        'left': 1.0,
        'top': 2.0,
        'right': 3.0,
        'bottom': 4.0,
      });
      expect(padding.left, 1.0);
      expect(padding.top, 2.0);
      expect(padding.right, 3.0);
      expect(padding.bottom, 4.0);
    });

    test('Returns zero padding for invalid input', () {
      final padding = SASUPPadding.fromJson('invalid');
      expect(padding.left, 0);
      expect(padding.top, 0);
    });

    test('toJson produces valid output', () {
      const padding = SASUPPadding(left: 4, top: 8, right: 12, bottom: 16);
      final json = padding.toJson();
      expect(json['left'], 4);
      expect(json['top'], 8);
      expect(json['right'], 12);
      expect(json['bottom'], 16);
    });
  });

  group('SASUPModifiers Tests', () {
    test('All modifier fields survive JSON round-trip', () {
      const mods = SASUPModifiers(
        width: 100,
        height: 50,
        flex: 2,
        background: '#FF0000',
        cornerRadius: 12,
        padding: SASUPPadding(left: 8, top: 8, right: 8, bottom: 8),
        font: 'bold',
        fontSize: 18,
        color: '#FFFFFF',
        alignment: 'center',
      );

      final json = jsonDecode(jsonEncode(mods.toJson()));
      final restored = SASUPModifiers.fromJson(json);

      expect(restored.width, 100);
      expect(restored.height, 50);
      expect(restored.flex, 2);
      expect(restored.background, '#FF0000');
      expect(restored.cornerRadius, 12);
      expect(restored.padding?.left, 8);
      expect(restored.font, 'bold');
      expect(restored.fontSize, 18);
      expect(restored.color, '#FFFFFF');
      expect(restored.alignment, 'center');
    });

    test('Null modifiers deserialize cleanly', () {
      final mods = SASUPModifiers.fromJson({});
      expect(mods.width, isNull);
      expect(mods.height, isNull);
      expect(mods.background, isNull);
    });
  });
}
