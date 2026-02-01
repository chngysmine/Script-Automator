import 'package:json_annotation/json_annotation.dart';

enum WidgetType {
  @JsonValue('column')
  column,
  @JsonValue('row')
  row,
  @JsonValue('stack')
  stack,
  @JsonValue('text')
  text,
  @JsonValue('image')
  image,
  @JsonValue('spacer')
  spacer,
  @JsonValue('list')
  list,
}
