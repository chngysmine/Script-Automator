// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sasup_modifiers.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SASUPModifiers _$SASUPModifiersFromJson(Map<String, dynamic> json) =>
    _SASUPModifiers(
      width: (json['width'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      flex: (json['flex'] as num?)?.toInt(),
      background: json['background'] as String?,
      cornerRadius: (json['cornerRadius'] as num?)?.toDouble(),
      padding: json['padding'] == null
          ? null
          : SASUPPadding.fromJson(json['padding']),
      clickAction: json['clickAction'] == null
          ? null
          : SASUPAction.fromJson(json['clickAction'] as Map<String, dynamic>),
      font: json['font'] as String?,
      fontSize: (json['fontSize'] as num?)?.toDouble(),
      color: json['color'] as String?,
      alignment: json['alignment'] as String?,
      spacing: (json['spacing'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$SASUPModifiersToJson(_SASUPModifiers instance) =>
    <String, dynamic>{
      'width': instance.width,
      'height': instance.height,
      'flex': instance.flex,
      'background': instance.background,
      'cornerRadius': instance.cornerRadius,
      'padding': instance.padding,
      'clickAction': instance.clickAction,
      'font': instance.font,
      'fontSize': instance.fontSize,
      'color': instance.color,
      'alignment': instance.alignment,
      'spacing': instance.spacing,
    };
