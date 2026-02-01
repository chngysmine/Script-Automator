// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'widget_node.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WidgetNode _$WidgetNodeFromJson(Map<String, dynamic> json) => _WidgetNode(
  type: $enumDecode(_$WidgetTypeEnumMap, json['type']),
  id: json['id'] as String?,
  modifiers: json['modifiers'] == null
      ? null
      : SASUPModifiers.fromJson(json['modifiers'] as Map<String, dynamic>),
  children: (json['children'] as List<dynamic>?)
      ?.map((e) => WidgetNode.fromJson(e as Map<String, dynamic>))
      .toList(),
  content: json['content'],
  action: json['action'] == null
      ? null
      : SASUPAction.fromJson(json['action'] as Map<String, dynamic>),
);

Map<String, dynamic> _$WidgetNodeToJson(_WidgetNode instance) =>
    <String, dynamic>{
      'type': _$WidgetTypeEnumMap[instance.type]!,
      'id': instance.id,
      'modifiers': instance.modifiers,
      'children': instance.children,
      'content': instance.content,
      'action': instance.action,
    };

const _$WidgetTypeEnumMap = {
  WidgetType.column: 'column',
  WidgetType.row: 'row',
  WidgetType.stack: 'stack',
  WidgetType.text: 'text',
  WidgetType.image: 'image',
  WidgetType.spacer: 'spacer',
  WidgetType.list: 'list',
};
