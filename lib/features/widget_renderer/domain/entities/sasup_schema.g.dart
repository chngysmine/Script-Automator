// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sasup_schema.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SASUPMeta _$SASUPMetaFromJson(Map<String, dynamic> json) => _SASUPMeta(
  version: json['version'] as String,
  target: json['target'] as String,
  timestamp: (json['timestamp'] as num?)?.toInt(),
);

Map<String, dynamic> _$SASUPMetaToJson(_SASUPMeta instance) =>
    <String, dynamic>{
      'version': instance.version,
      'target': instance.target,
      'timestamp': instance.timestamp,
    };

_SASUPSchema _$SASUPSchemaFromJson(Map<String, dynamic> json) => _SASUPSchema(
  meta: SASUPMeta.fromJson(json['meta'] as Map<String, dynamic>),
  root: WidgetNode.fromJson(json['root'] as Map<String, dynamic>),
);

Map<String, dynamic> _$SASUPSchemaToJson(_SASUPSchema instance) =>
    <String, dynamic>{'meta': instance.meta, 'root': instance.root};
