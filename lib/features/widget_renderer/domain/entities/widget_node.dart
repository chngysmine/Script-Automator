import 'package:freezed_annotation/freezed_annotation.dart';
import 'widget_type.dart';
import 'sasup_modifiers.dart';
import 'sasup_action.dart';

part 'widget_node.freezed.dart';
part 'widget_node.g.dart';

@freezed
abstract class WidgetNode with _$WidgetNode {
  const factory WidgetNode({
    required WidgetType type,
    String? id, // For Diffing
    SASUPModifiers? modifiers,
    List<WidgetNode>? children, // Recursive
    dynamic content, // String for text/image path, or nested structure
    SASUPAction? action,
  }) = _WidgetNode;

  // Freezed only generates toJson when fromJson is a direct expression, so
  // legacy-shape normalization lives in a static helper.
  factory WidgetNode.fromJson(Map<String, dynamic> json) =>
      _$WidgetNodeFromJson(_normalizeLegacyJson(json));

  static Map<String, dynamic> _normalizeLegacyJson(Map<String, dynamic> json) {
    final normalized = Map<String, dynamic>.of(json);
    // Buttons may declare `label` instead of `content`.
    if (normalized['type'] == 'button' &&
        normalized['label'] != null &&
        normalized['content'] == null) {
      normalized['content'] = normalized['label'];
    }
    // Shorthand `actionId` expands to a widget_action payload.
    if (normalized['actionId'] != null && normalized['action'] == null) {
      normalized['action'] = {
        'type': 'widget_action',
        'payload': {'actionId': normalized['actionId']},
      };
    }
    return normalized;
  }
}
