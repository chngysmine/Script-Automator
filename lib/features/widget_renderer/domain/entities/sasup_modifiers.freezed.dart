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
SASUPPadding _$SASUPPaddingFromJson(
  Map<String, dynamic> json
) {
        switch (json['runtimeType']) {
                  case 'all':
          return _SASUPPaddingAll.fromJson(
            json
          );
                case 'symmetric':
          return _SASUPPaddingSymmetric.fromJson(
            json
          );
                case 'only':
          return _SASUPPaddingOnly.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'runtimeType',
  'SASUPPadding',
  'Invalid union type "${json['runtimeType']}"!'
);
        }
      
}

/// @nodoc
mixin _$SASUPPadding {



  /// Serializes this SASUPPadding to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SASUPPadding);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SASUPPadding()';
}


}

/// @nodoc
class $SASUPPaddingCopyWith<$Res>  {
$SASUPPaddingCopyWith(SASUPPadding _, $Res Function(SASUPPadding) __);
}


/// Adds pattern-matching-related methods to [SASUPPadding].
extension SASUPPaddingPatterns on SASUPPadding {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _SASUPPaddingAll value)?  all,TResult Function( _SASUPPaddingSymmetric value)?  symmetric,TResult Function( _SASUPPaddingOnly value)?  only,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SASUPPaddingAll() when all != null:
return all(_that);case _SASUPPaddingSymmetric() when symmetric != null:
return symmetric(_that);case _SASUPPaddingOnly() when only != null:
return only(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _SASUPPaddingAll value)  all,required TResult Function( _SASUPPaddingSymmetric value)  symmetric,required TResult Function( _SASUPPaddingOnly value)  only,}){
final _that = this;
switch (_that) {
case _SASUPPaddingAll():
return all(_that);case _SASUPPaddingSymmetric():
return symmetric(_that);case _SASUPPaddingOnly():
return only(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _SASUPPaddingAll value)?  all,TResult? Function( _SASUPPaddingSymmetric value)?  symmetric,TResult? Function( _SASUPPaddingOnly value)?  only,}){
final _that = this;
switch (_that) {
case _SASUPPaddingAll() when all != null:
return all(_that);case _SASUPPaddingSymmetric() when symmetric != null:
return symmetric(_that);case _SASUPPaddingOnly() when only != null:
return only(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( double value)?  all,TResult Function( double? vertical,  double? horizontal)?  symmetric,TResult Function( double? left,  double? top,  double? right,  double? bottom)?  only,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SASUPPaddingAll() when all != null:
return all(_that.value);case _SASUPPaddingSymmetric() when symmetric != null:
return symmetric(_that.vertical,_that.horizontal);case _SASUPPaddingOnly() when only != null:
return only(_that.left,_that.top,_that.right,_that.bottom);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( double value)  all,required TResult Function( double? vertical,  double? horizontal)  symmetric,required TResult Function( double? left,  double? top,  double? right,  double? bottom)  only,}) {final _that = this;
switch (_that) {
case _SASUPPaddingAll():
return all(_that.value);case _SASUPPaddingSymmetric():
return symmetric(_that.vertical,_that.horizontal);case _SASUPPaddingOnly():
return only(_that.left,_that.top,_that.right,_that.bottom);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( double value)?  all,TResult? Function( double? vertical,  double? horizontal)?  symmetric,TResult? Function( double? left,  double? top,  double? right,  double? bottom)?  only,}) {final _that = this;
switch (_that) {
case _SASUPPaddingAll() when all != null:
return all(_that.value);case _SASUPPaddingSymmetric() when symmetric != null:
return symmetric(_that.vertical,_that.horizontal);case _SASUPPaddingOnly() when only != null:
return only(_that.left,_that.top,_that.right,_that.bottom);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SASUPPaddingAll implements SASUPPadding {
  const _SASUPPaddingAll(this.value, {final  String? $type}): $type = $type ?? 'all';
  factory _SASUPPaddingAll.fromJson(Map<String, dynamic> json) => _$SASUPPaddingAllFromJson(json);

 final  double value;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of SASUPPadding
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SASUPPaddingAllCopyWith<_SASUPPaddingAll> get copyWith => __$SASUPPaddingAllCopyWithImpl<_SASUPPaddingAll>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SASUPPaddingAllToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SASUPPaddingAll&&(identical(other.value, value) || other.value == value));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'SASUPPadding.all(value: $value)';
}


}

/// @nodoc
abstract mixin class _$SASUPPaddingAllCopyWith<$Res> implements $SASUPPaddingCopyWith<$Res> {
  factory _$SASUPPaddingAllCopyWith(_SASUPPaddingAll value, $Res Function(_SASUPPaddingAll) _then) = __$SASUPPaddingAllCopyWithImpl;
@useResult
$Res call({
 double value
});




}
/// @nodoc
class __$SASUPPaddingAllCopyWithImpl<$Res>
    implements _$SASUPPaddingAllCopyWith<$Res> {
  __$SASUPPaddingAllCopyWithImpl(this._self, this._then);

  final _SASUPPaddingAll _self;
  final $Res Function(_SASUPPaddingAll) _then;

/// Create a copy of SASUPPadding
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(_SASUPPaddingAll(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
@JsonSerializable()

class _SASUPPaddingSymmetric implements SASUPPadding {
  const _SASUPPaddingSymmetric({this.vertical, this.horizontal, final  String? $type}): $type = $type ?? 'symmetric';
  factory _SASUPPaddingSymmetric.fromJson(Map<String, dynamic> json) => _$SASUPPaddingSymmetricFromJson(json);

 final  double? vertical;
 final  double? horizontal;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of SASUPPadding
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SASUPPaddingSymmetricCopyWith<_SASUPPaddingSymmetric> get copyWith => __$SASUPPaddingSymmetricCopyWithImpl<_SASUPPaddingSymmetric>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SASUPPaddingSymmetricToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SASUPPaddingSymmetric&&(identical(other.vertical, vertical) || other.vertical == vertical)&&(identical(other.horizontal, horizontal) || other.horizontal == horizontal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,vertical,horizontal);

@override
String toString() {
  return 'SASUPPadding.symmetric(vertical: $vertical, horizontal: $horizontal)';
}


}

/// @nodoc
abstract mixin class _$SASUPPaddingSymmetricCopyWith<$Res> implements $SASUPPaddingCopyWith<$Res> {
  factory _$SASUPPaddingSymmetricCopyWith(_SASUPPaddingSymmetric value, $Res Function(_SASUPPaddingSymmetric) _then) = __$SASUPPaddingSymmetricCopyWithImpl;
@useResult
$Res call({
 double? vertical, double? horizontal
});




}
/// @nodoc
class __$SASUPPaddingSymmetricCopyWithImpl<$Res>
    implements _$SASUPPaddingSymmetricCopyWith<$Res> {
  __$SASUPPaddingSymmetricCopyWithImpl(this._self, this._then);

  final _SASUPPaddingSymmetric _self;
  final $Res Function(_SASUPPaddingSymmetric) _then;

/// Create a copy of SASUPPadding
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? vertical = freezed,Object? horizontal = freezed,}) {
  return _then(_SASUPPaddingSymmetric(
vertical: freezed == vertical ? _self.vertical : vertical // ignore: cast_nullable_to_non_nullable
as double?,horizontal: freezed == horizontal ? _self.horizontal : horizontal // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class _SASUPPaddingOnly implements SASUPPadding {
  const _SASUPPaddingOnly({this.left, this.top, this.right, this.bottom, final  String? $type}): $type = $type ?? 'only';
  factory _SASUPPaddingOnly.fromJson(Map<String, dynamic> json) => _$SASUPPaddingOnlyFromJson(json);

 final  double? left;
 final  double? top;
 final  double? right;
 final  double? bottom;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of SASUPPadding
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SASUPPaddingOnlyCopyWith<_SASUPPaddingOnly> get copyWith => __$SASUPPaddingOnlyCopyWithImpl<_SASUPPaddingOnly>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SASUPPaddingOnlyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SASUPPaddingOnly&&(identical(other.left, left) || other.left == left)&&(identical(other.top, top) || other.top == top)&&(identical(other.right, right) || other.right == right)&&(identical(other.bottom, bottom) || other.bottom == bottom));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,left,top,right,bottom);

@override
String toString() {
  return 'SASUPPadding.only(left: $left, top: $top, right: $right, bottom: $bottom)';
}


}

/// @nodoc
abstract mixin class _$SASUPPaddingOnlyCopyWith<$Res> implements $SASUPPaddingCopyWith<$Res> {
  factory _$SASUPPaddingOnlyCopyWith(_SASUPPaddingOnly value, $Res Function(_SASUPPaddingOnly) _then) = __$SASUPPaddingOnlyCopyWithImpl;
@useResult
$Res call({
 double? left, double? top, double? right, double? bottom
});




}
/// @nodoc
class __$SASUPPaddingOnlyCopyWithImpl<$Res>
    implements _$SASUPPaddingOnlyCopyWith<$Res> {
  __$SASUPPaddingOnlyCopyWithImpl(this._self, this._then);

  final _SASUPPaddingOnly _self;
  final $Res Function(_SASUPPaddingOnly) _then;

/// Create a copy of SASUPPadding
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? left = freezed,Object? top = freezed,Object? right = freezed,Object? bottom = freezed,}) {
  return _then(_SASUPPaddingOnly(
left: freezed == left ? _self.left : left // ignore: cast_nullable_to_non_nullable
as double?,top: freezed == top ? _self.top : top // ignore: cast_nullable_to_non_nullable
as double?,right: freezed == right ? _self.right : right // ignore: cast_nullable_to_non_nullable
as double?,bottom: freezed == bottom ? _self.bottom : bottom // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}


/// @nodoc
mixin _$SASUPModifiers {

 double? get width; double? get height; int? get flex; String? get background;// Hex or gradient definition
 double? get cornerRadius; SASUPPadding? get padding; SASUPAction? get clickAction; String? get font;// For text widgets
 String? get color;// Text color
 String? get alignment;
/// Create a copy of SASUPModifiers
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SASUPModifiersCopyWith<SASUPModifiers> get copyWith => _$SASUPModifiersCopyWithImpl<SASUPModifiers>(this as SASUPModifiers, _$identity);

  /// Serializes this SASUPModifiers to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SASUPModifiers&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.flex, flex) || other.flex == flex)&&(identical(other.background, background) || other.background == background)&&(identical(other.cornerRadius, cornerRadius) || other.cornerRadius == cornerRadius)&&(identical(other.padding, padding) || other.padding == padding)&&(identical(other.clickAction, clickAction) || other.clickAction == clickAction)&&(identical(other.font, font) || other.font == font)&&(identical(other.color, color) || other.color == color)&&(identical(other.alignment, alignment) || other.alignment == alignment));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,width,height,flex,background,cornerRadius,padding,clickAction,font,color,alignment);

@override
String toString() {
  return 'SASUPModifiers(width: $width, height: $height, flex: $flex, background: $background, cornerRadius: $cornerRadius, padding: $padding, clickAction: $clickAction, font: $font, color: $color, alignment: $alignment)';
}


}

/// @nodoc
abstract mixin class $SASUPModifiersCopyWith<$Res>  {
  factory $SASUPModifiersCopyWith(SASUPModifiers value, $Res Function(SASUPModifiers) _then) = _$SASUPModifiersCopyWithImpl;
@useResult
$Res call({
 double? width, double? height, int? flex, String? background, double? cornerRadius, SASUPPadding? padding, SASUPAction? clickAction, String? font, String? color, String? alignment
});


$SASUPPaddingCopyWith<$Res>? get padding;$SASUPActionCopyWith<$Res>? get clickAction;

}
/// @nodoc
class _$SASUPModifiersCopyWithImpl<$Res>
    implements $SASUPModifiersCopyWith<$Res> {
  _$SASUPModifiersCopyWithImpl(this._self, this._then);

  final SASUPModifiers _self;
  final $Res Function(SASUPModifiers) _then;

/// Create a copy of SASUPModifiers
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? width = freezed,Object? height = freezed,Object? flex = freezed,Object? background = freezed,Object? cornerRadius = freezed,Object? padding = freezed,Object? clickAction = freezed,Object? font = freezed,Object? color = freezed,Object? alignment = freezed,}) {
  return _then(_self.copyWith(
width: freezed == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as double?,height: freezed == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as double?,flex: freezed == flex ? _self.flex : flex // ignore: cast_nullable_to_non_nullable
as int?,background: freezed == background ? _self.background : background // ignore: cast_nullable_to_non_nullable
as String?,cornerRadius: freezed == cornerRadius ? _self.cornerRadius : cornerRadius // ignore: cast_nullable_to_non_nullable
as double?,padding: freezed == padding ? _self.padding : padding // ignore: cast_nullable_to_non_nullable
as SASUPPadding?,clickAction: freezed == clickAction ? _self.clickAction : clickAction // ignore: cast_nullable_to_non_nullable
as SASUPAction?,font: freezed == font ? _self.font : font // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,alignment: freezed == alignment ? _self.alignment : alignment // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of SASUPModifiers
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SASUPPaddingCopyWith<$Res>? get padding {
    if (_self.padding == null) {
    return null;
  }

  return $SASUPPaddingCopyWith<$Res>(_self.padding!, (value) {
    return _then(_self.copyWith(padding: value));
  });
}/// Create a copy of SASUPModifiers
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double? width,  double? height,  int? flex,  String? background,  double? cornerRadius,  SASUPPadding? padding,  SASUPAction? clickAction,  String? font,  String? color,  String? alignment)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SASUPModifiers() when $default != null:
return $default(_that.width,_that.height,_that.flex,_that.background,_that.cornerRadius,_that.padding,_that.clickAction,_that.font,_that.color,_that.alignment);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double? width,  double? height,  int? flex,  String? background,  double? cornerRadius,  SASUPPadding? padding,  SASUPAction? clickAction,  String? font,  String? color,  String? alignment)  $default,) {final _that = this;
switch (_that) {
case _SASUPModifiers():
return $default(_that.width,_that.height,_that.flex,_that.background,_that.cornerRadius,_that.padding,_that.clickAction,_that.font,_that.color,_that.alignment);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double? width,  double? height,  int? flex,  String? background,  double? cornerRadius,  SASUPPadding? padding,  SASUPAction? clickAction,  String? font,  String? color,  String? alignment)?  $default,) {final _that = this;
switch (_that) {
case _SASUPModifiers() when $default != null:
return $default(_that.width,_that.height,_that.flex,_that.background,_that.cornerRadius,_that.padding,_that.clickAction,_that.font,_that.color,_that.alignment);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SASUPModifiers implements SASUPModifiers {
  const _SASUPModifiers({this.width, this.height, this.flex, this.background, this.cornerRadius, this.padding, this.clickAction, this.font, this.color, this.alignment});
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
// For text widgets
@override final  String? color;
// Text color
@override final  String? alignment;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SASUPModifiers&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.flex, flex) || other.flex == flex)&&(identical(other.background, background) || other.background == background)&&(identical(other.cornerRadius, cornerRadius) || other.cornerRadius == cornerRadius)&&(identical(other.padding, padding) || other.padding == padding)&&(identical(other.clickAction, clickAction) || other.clickAction == clickAction)&&(identical(other.font, font) || other.font == font)&&(identical(other.color, color) || other.color == color)&&(identical(other.alignment, alignment) || other.alignment == alignment));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,width,height,flex,background,cornerRadius,padding,clickAction,font,color,alignment);

@override
String toString() {
  return 'SASUPModifiers(width: $width, height: $height, flex: $flex, background: $background, cornerRadius: $cornerRadius, padding: $padding, clickAction: $clickAction, font: $font, color: $color, alignment: $alignment)';
}


}

/// @nodoc
abstract mixin class _$SASUPModifiersCopyWith<$Res> implements $SASUPModifiersCopyWith<$Res> {
  factory _$SASUPModifiersCopyWith(_SASUPModifiers value, $Res Function(_SASUPModifiers) _then) = __$SASUPModifiersCopyWithImpl;
@override @useResult
$Res call({
 double? width, double? height, int? flex, String? background, double? cornerRadius, SASUPPadding? padding, SASUPAction? clickAction, String? font, String? color, String? alignment
});


@override $SASUPPaddingCopyWith<$Res>? get padding;@override $SASUPActionCopyWith<$Res>? get clickAction;

}
/// @nodoc
class __$SASUPModifiersCopyWithImpl<$Res>
    implements _$SASUPModifiersCopyWith<$Res> {
  __$SASUPModifiersCopyWithImpl(this._self, this._then);

  final _SASUPModifiers _self;
  final $Res Function(_SASUPModifiers) _then;

/// Create a copy of SASUPModifiers
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? width = freezed,Object? height = freezed,Object? flex = freezed,Object? background = freezed,Object? cornerRadius = freezed,Object? padding = freezed,Object? clickAction = freezed,Object? font = freezed,Object? color = freezed,Object? alignment = freezed,}) {
  return _then(_SASUPModifiers(
width: freezed == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as double?,height: freezed == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as double?,flex: freezed == flex ? _self.flex : flex // ignore: cast_nullable_to_non_nullable
as int?,background: freezed == background ? _self.background : background // ignore: cast_nullable_to_non_nullable
as String?,cornerRadius: freezed == cornerRadius ? _self.cornerRadius : cornerRadius // ignore: cast_nullable_to_non_nullable
as double?,padding: freezed == padding ? _self.padding : padding // ignore: cast_nullable_to_non_nullable
as SASUPPadding?,clickAction: freezed == clickAction ? _self.clickAction : clickAction // ignore: cast_nullable_to_non_nullable
as SASUPAction?,font: freezed == font ? _self.font : font // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,alignment: freezed == alignment ? _self.alignment : alignment // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of SASUPModifiers
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SASUPPaddingCopyWith<$Res>? get padding {
    if (_self.padding == null) {
    return null;
  }

  return $SASUPPaddingCopyWith<$Res>(_self.padding!, (value) {
    return _then(_self.copyWith(padding: value));
  });
}/// Create a copy of SASUPModifiers
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
