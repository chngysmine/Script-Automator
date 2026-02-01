import 'package:freezed_annotation/freezed_annotation.dart';
import 'widget_node.dart';

part 'sasup_schema.freezed.dart';
part 'sasup_schema.g.dart';

@freezed
abstract class SASUPMeta with _$SASUPMeta {
  const factory SASUPMeta({
    required String version,
    required String target,
    int? timestamp,
  }) = _SASUPMeta;

  factory SASUPMeta.fromJson(Map<String, dynamic> json) =>
      _$SASUPMetaFromJson(json);
}

@freezed
abstract class SASUPSchema with _$SASUPSchema {
  const factory SASUPSchema({
    required SASUPMeta meta,
    required WidgetNode root,
  }) = _SASUPSchema;

  factory SASUPSchema.fromJson(Map<String, dynamic> json) =>
      _$SASUPSchemaFromJson(json);
}
