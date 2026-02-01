// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sasup_action.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SASUPAction {

 String get type; Map<String, dynamic>? get payload;
/// Create a copy of SASUPAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SASUPActionCopyWith<SASUPAction> get copyWith => _$SASUPActionCopyWithImpl<SASUPAction>(this as SASUPAction, _$identity);

  /// Serializes this SASUPAction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SASUPAction&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.payload, payload));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,const DeepCollectionEquality().hash(payload));

@override
String toString() {
  return 'SASUPAction(type: $type, payload: $payload)';
}


}

/// @nodoc
abstract mixin class $SASUPActionCopyWith<$Res>  {
  factory $SASUPActionCopyWith(SASUPAction value, $Res Function(SASUPAction) _then) = _$SASUPActionCopyWithImpl;
@useResult
$Res call({
 String type, Map<String, dynamic>? payload
});




}
/// @nodoc
class _$SASUPActionCopyWithImpl<$Res>
    implements $SASUPActionCopyWith<$Res> {
  _$SASUPActionCopyWithImpl(this._self, this._then);

  final SASUPAction _self;
  final $Res Function(SASUPAction) _then;

/// Create a copy of SASUPAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? payload = freezed,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,payload: freezed == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [SASUPAction].
extension SASUPActionPatterns on SASUPAction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SASUPAction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SASUPAction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SASUPAction value)  $default,){
final _that = this;
switch (_that) {
case _SASUPAction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SASUPAction value)?  $default,){
final _that = this;
switch (_that) {
case _SASUPAction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String type,  Map<String, dynamic>? payload)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SASUPAction() when $default != null:
return $default(_that.type,_that.payload);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String type,  Map<String, dynamic>? payload)  $default,) {final _that = this;
switch (_that) {
case _SASUPAction():
return $default(_that.type,_that.payload);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String type,  Map<String, dynamic>? payload)?  $default,) {final _that = this;
switch (_that) {
case _SASUPAction() when $default != null:
return $default(_that.type,_that.payload);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SASUPAction implements SASUPAction {
  const _SASUPAction({required this.type, final  Map<String, dynamic>? payload}): _payload = payload;
  factory _SASUPAction.fromJson(Map<String, dynamic> json) => _$SASUPActionFromJson(json);

@override final  String type;
 final  Map<String, dynamic>? _payload;
@override Map<String, dynamic>? get payload {
  final value = _payload;
  if (value == null) return null;
  if (_payload is EqualUnmodifiableMapView) return _payload;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of SASUPAction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SASUPActionCopyWith<_SASUPAction> get copyWith => __$SASUPActionCopyWithImpl<_SASUPAction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SASUPActionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SASUPAction&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other._payload, _payload));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,const DeepCollectionEquality().hash(_payload));

@override
String toString() {
  return 'SASUPAction(type: $type, payload: $payload)';
}


}

/// @nodoc
abstract mixin class _$SASUPActionCopyWith<$Res> implements $SASUPActionCopyWith<$Res> {
  factory _$SASUPActionCopyWith(_SASUPAction value, $Res Function(_SASUPAction) _then) = __$SASUPActionCopyWithImpl;
@override @useResult
$Res call({
 String type, Map<String, dynamic>? payload
});




}
/// @nodoc
class __$SASUPActionCopyWithImpl<$Res>
    implements _$SASUPActionCopyWith<$Res> {
  __$SASUPActionCopyWithImpl(this._self, this._then);

  final _SASUPAction _self;
  final $Res Function(_SASUPAction) _then;

/// Create a copy of SASUPAction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? payload = freezed,}) {
  return _then(_SASUPAction(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,payload: freezed == payload ? _self._payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

// dart format on
