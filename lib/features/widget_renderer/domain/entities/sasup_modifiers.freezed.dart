// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sasup_modifiers.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SASUPModifiers {

 double? get width; double? get height; int? get flex; String? get background;// Hex or gradient definition
 double? get cornerRadius; SASUPPadding? get padding; SASUPAction? get clickAction; String? get font;// For text widgets ('bold', 'normal')
 double? get fontSize;// Font size
 String? get color;// Text color
 String? get alignment;// 'start', 'center', 'end'
 double? get spacing;
/// Create a copy of SASUPModifiers
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SASUPModifiersCopyWith<SASUPModifiers> get copyWith => _$SASUPModifiersCopyWithImpl<SASUPModifiers>(this as SASUPModifiers, _$identity);

  /// Serializes this SASUPModifiers to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SASUPModifiers&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.flex, flex) || other.flex == flex)&&(identical(other.background, background) || other.background == background)&&(identical(other.cornerRadius, cornerRadius) || other.cornerRadius == cornerRadius)&&(identical(other.padding, padding) || other.padding == padding)&&(identical(other.clickAction, clickAction) || other.clickAction == clickAction)&&(identical(other.font, font) || other.font == font)&&(identical(other.fontSize, fontSize) || other.fontSize == fontSize)&&(identical(other.color, color) || other.color == color)&&(identical(other.alignment, alignment) || other.alignment == alignment)&&(identical(other.spacing, spacing) || other.spacing == spacing));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,width,height,flex,background,cornerRadius,padding,clickAction,font,fontSize,color,alignment,spacing);

@override
String toString() {
  return 'SASUPModifiers(width: $width, height: $height, flex: $flex, background: $background, cornerRadius: $cornerRadius, padding: $padding, clickAction: $clickAction, font: $font, fontSize: $fontSize, color: $color, alignment: $alignment, spacing: $spacing)';
}


}

/// @nodoc
abstract mixin class $SASUPModifiersCopyWith<$Res>  {
  factory $SASUPModifiersCopyWith(SASUPModifiers value, $Res Function(SASUPModifiers) _then) = _$SASUPModifiersCopyWithImpl;
@useResult
$Res call({
 double? width, double? height, int? flex, String? background, double? cornerRadius, SASUPPadding? padding, SASUPAction? clickAction, String? font, double? fontSize, String? color, String? alignment, double? spacing
});


$SASUPActionCopyWith<$Res>? get clickAction;

}
/// @nodoc
class _$SASUPModifiersCopyWithImpl<$Res>
    implements $SASUPModifiersCopyWith<$Res> {
  _$SASUPModifiersCopyWithImpl(this._self, this._then);

  final SASUPModifiers _self;
  final $Res Function(SASUPModifiers) _then;

/// Create a copy of SASUPModifiers
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? width = freezed,Object? height = freezed,Object? flex = freezed,Object? background = freezed,Object? cornerRadius = freezed,Object? padding = freezed,Object? clickAction = freezed,Object? font = freezed,Object? fontSize = freezed,Object? color = freezed,Object? alignment = freezed,Object? spacing = freezed,}) {
  return _then(_self.copyWith(
width: freezed == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as double?,height: freezed == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as double?,flex: freezed == flex ? _self.flex : flex // ignore: cast_nullable_to_non_nullable
as int?,background: freezed == background ? _self.background : background // ignore: cast_nullable_to_non_nullable
as String?,cornerRadius: freezed == cornerRadius ? _self.cornerRadius : cornerRadius // ignore: cast_nullable_to_non_nullable
as double?,padding: freezed == padding ? _self.padding : padding // ignore: cast_nullable_to_non_nullable
as SASUPPadding?,clickAction: freezed == clickAction ? _self.clickAction : clickAction // ignore: cast_nullable_to_non_nullable
as SASUPAction?,font: freezed == font ? _self.font : font // ignore: cast_nullable_to_non_nullable
as String?,fontSize: freezed == fontSize ? _self.fontSize : fontSize // ignore: cast_nullable_to_non_nullable
as double?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,alignment: freezed == alignment ? _self.alignment : alignment // ignore: cast_nullable_to_non_nullable
as String?,spacing: freezed == spacing ? _self.spacing : spacing // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}
/// Create a copy of SASUPModifiers
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SASUPActionCopyWith<$Res>? get clickAction {
    if (_self.clickAction == null) {
    return null;
  }

  return $SASUPActionCopyWith<$Res>(_self.clickAction!, (value) {
    return _then(_self.copyWith(clickAction: value));
  });
}
}


/// Adds pattern-matching-related methods to [SASUPModifiers].
extension SASUPModifiersPatterns on SASUPModifiers {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SASUPModifiers value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SASUPModifiers() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SASUPModifiers value)  $default,){
final _that = this;
switch (_that) {
case _SASUPModifiers():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SASUPModifiers value)?  $default,){
final _that = this;
switch (_that) {
case _SASUPModifiers() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double? width,  double? height,  int? flex,  String? background,  double? cornerRadius,  SASUPPadding? padding,  SASUPAction? clickAction,  String? font,  double? fontSize,  String? color,  String? alignment,  double? spacing)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SASUPModifiers() when $default != null:
return $default(_that.width,_that.height,_that.flex,_that.background,_that.cornerRadius,_that.padding,_that.clickAction,_that.font,_that.fontSize,_that.color,_that.alignment,_that.spacing);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double? width,  double? height,  int? flex,  String? background,  double? cornerRadius,  SASUPPadding? padding,  SASUPAction? clickAction,  String? font,  double? fontSize,  String? color,  String? alignment,  double? spacing)  $default,) {final _that = this;
switch (_that) {
case _SASUPModifiers():
return $default(_that.width,_that.height,_that.flex,_that.background,_that.cornerRadius,_that.padding,_that.clickAction,_that.font,_that.fontSize,_that.color,_that.alignment,_that.spacing);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double? width,  double? height,  int? flex,  String? background,  double? cornerRadius,  SASUPPadding? padding,  SASUPAction? clickAction,  String? font,  double? fontSize,  String? color,  String? alignment,  double? spacing)?  $default,) {final _that = this;
switch (_that) {
case _SASUPModifiers() when $default != null:
return $default(_that.width,_that.height,_that.flex,_that.background,_that.cornerRadius,_that.padding,_that.clickAction,_that.font,_that.fontSize,_that.color,_that.alignment,_that.spacing);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SASUPModifiers implements SASUPModifiers {
  const _SASUPModifiers({this.width, this.height, this.flex, this.background, this.cornerRadius, this.padding, this.clickAction, this.font, this.fontSize, this.color, this.alignment, this.spacing});
  factory _SASUPModifiers.fromJson(Map<String, dynamic> json) => _$SASUPModifiersFromJson(json);

@override final  double? width;
@override final  double? height;
@override final  int? flex;
@override final  String? background;
// Hex or gradient definition
@override final  double? cornerRadius;
@override final  SASUPPadding? padding;
@override final  SASUPAction? clickAction;
@override final  String? font;
// For text widgets ('bold', 'normal')
@override final  double? fontSize;
// Font size
@override final  String? color;
// Text color
@override final  String? alignment;
// 'start', 'center', 'end'
@override final  double? spacing;

/// Create a copy of SASUPModifiers
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SASUPModifiersCopyWith<_SASUPModifiers> get copyWith => __$SASUPModifiersCopyWithImpl<_SASUPModifiers>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SASUPModifiersToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SASUPModifiers&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.flex, flex) || other.flex == flex)&&(identical(other.background, background) || other.background == background)&&(identical(other.cornerRadius, cornerRadius) || other.cornerRadius == cornerRadius)&&(identical(other.padding, padding) || other.padding == padding)&&(identical(other.clickAction, clickAction) || other.clickAction == clickAction)&&(identical(other.font, font) || other.font == font)&&(identical(other.fontSize, fontSize) || other.fontSize == fontSize)&&(identical(other.color, color) || other.color == color)&&(identical(other.alignment, alignment) || other.alignment == alignment)&&(identical(other.spacing, spacing) || other.spacing == spacing));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,width,height,flex,background,cornerRadius,padding,clickAction,font,fontSize,color,alignment,spacing);

@override
String toString() {
  return 'SASUPModifiers(width: $width, height: $height, flex: $flex, background: $background, cornerRadius: $cornerRadius, padding: $padding, clickAction: $clickAction, font: $font, fontSize: $fontSize, color: $color, alignment: $alignment, spacing: $spacing)';
}


}

/// @nodoc
abstract mixin class _$SASUPModifiersCopyWith<$Res> implements $SASUPModifiersCopyWith<$Res> {
  factory _$SASUPModifiersCopyWith(_SASUPModifiers value, $Res Function(_SASUPModifiers) _then) = __$SASUPModifiersCopyWithImpl;
@override @useResult
$Res call({
 double? width, double? height, int? flex, String? background, double? cornerRadius, SASUPPadding? padding, SASUPAction? clickAction, String? font, double? fontSize, String? color, String? alignment, double? spacing
});


@override $SASUPActionCopyWith<$Res>? get clickAction;

}
/// @nodoc
class __$SASUPModifiersCopyWithImpl<$Res>
    implements _$SASUPModifiersCopyWith<$Res> {
  __$SASUPModifiersCopyWithImpl(this._self, this._then);

  final _SASUPModifiers _self;
  final $Res Function(_SASUPModifiers) _then;

/// Create a copy of SASUPModifiers
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? width = freezed,Object? height = freezed,Object? flex = freezed,Object? background = freezed,Object? cornerRadius = freezed,Object? padding = freezed,Object? clickAction = freezed,Object? font = freezed,Object? fontSize = freezed,Object? color = freezed,Object? alignment = freezed,Object? spacing = freezed,}) {
  return _then(_SASUPModifiers(
width: freezed == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as double?,height: freezed == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as double?,flex: freezed == flex ? _self.flex : flex // ignore: cast_nullable_to_non_nullable
as int?,background: freezed == background ? _self.background : background // ignore: cast_nullable_to_non_nullable
as String?,cornerRadius: freezed == cornerRadius ? _self.cornerRadius : cornerRadius // ignore: cast_nullable_to_non_nullable
as double?,padding: freezed == padding ? _self.padding : padding // ignore: cast_nullable_to_non_nullable
as SASUPPadding?,clickAction: freezed == clickAction ? _self.clickAction : clickAction // ignore: cast_nullable_to_non_nullable
as SASUPAction?,font: freezed == font ? _self.font : font // ignore: cast_nullable_to_non_nullable
as String?,fontSize: freezed == fontSize ? _self.fontSize : fontSize // ignore: cast_nullable_to_non_nullable
as double?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,alignment: freezed == alignment ? _self.alignment : alignment // ignore: cast_nullable_to_non_nullable
as String?,spacing: freezed == spacing ? _self.spacing : spacing // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

/// Create a copy of SASUPModifiers
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SASUPActionCopyWith<$Res>? get clickAction {
    if (_self.clickAction == null) {
    return null;
  }

  return $SASUPActionCopyWith<$Res>(_self.clickAction!, (value) {
    return _then(_self.copyWith(clickAction: value));
  });
}
}

// dart format on
