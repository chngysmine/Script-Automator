// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sasup_modifiers.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SASUPPaddingAll _$SASUPPaddingAllFromJson(Map<String, dynamic> json) =>
    _SASUPPaddingAll(
      (json['value'] as num).toDouble(),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$SASUPPaddingAllToJson(_SASUPPaddingAll instance) =>
    <String, dynamic>{'value': instance.value, 'runtimeType': instance.$type};

_SASUPPaddingSymmetric _$SASUPPaddingSymmetricFromJson(
  Map<String, dynamic> json,
) => _SASUPPaddingSymmetric(
  vertical: (json['vertical'] as num?)?.toDouble(),
  horizontal: (json['horizontal'] as num?)?.toDouble(),
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$SASUPPaddingSymmetricToJson(
  _SASUPPaddingSymmetric instance,
) => <String, dynamic>{
  'vertical': instance.vertical,
  'horizontal': instance.horizontal,
  'runtimeType': instance.$type,
};

_SASUPPaddingOnly _$SASUPPaddingOnlyFromJson(Map<String, dynamic> json) =>
    _SASUPPaddingOnly(
      left: (json['left'] as num?)?.toDouble(),
      top: (json['top'] as num?)?.toDouble(),
      right: (json['right'] as num?)?.toDouble(),
      bottom: (json['bottom'] as num?)?.toDouble(),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$SASUPPaddingOnlyToJson(_SASUPPaddingOnly instance) =>
    <String, dynamic>{
      'left': instance.left,
      'top': instance.top,
      'right': instance.right,
      'bottom': instance.bottom,
      'runtimeType': instance.$type,
    };

_SASUPModifiers _$SASUPModifiersFromJson(Map<String, dynamic> json) =>
    _SASUPModifiers(
      width: (json['width'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      flex: (json['flex'] as num?)?.toInt(),
      background: json['background'] as String?,
      cornerRadius: (json['cornerRadius'] as num?)?.toDouble(),
      padding: json['padding'] == null
          ? null
          : SASUPPadding.fromJson(json['padding'] as Map<String, dynamic>),
      clickAction: json['clickAction'] == null
          ? null
          : SASUPAction.fromJson(json['clickAction'] as Map<String, dynamic>),
      font: json['font'] as String?,
      color: json['color'] as String?,
      alignment: json['alignment'] as String?,
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
      'color': instance.color,
      'alignment': instance.alignment,
    };
