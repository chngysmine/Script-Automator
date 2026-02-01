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

  factory WidgetNode.fromJson(Map<String, dynamic> json) =>
      _$WidgetNodeFromJson(json);
}
