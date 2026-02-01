// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sasup_schema.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SASUPMeta {

 String get version; String get target; int? get timestamp;
/// Create a copy of SASUPMeta
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SASUPMetaCopyWith<SASUPMeta> get copyWith => _$SASUPMetaCopyWithImpl<SASUPMeta>(this as SASUPMeta, _$identity);

  /// Serializes this SASUPMeta to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SASUPMeta&&(identical(other.version, version) || other.version == version)&&(identical(other.target, target) || other.target == target)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,version,target,timestamp);

@override
String toString() {
  return 'SASUPMeta(version: $version, target: $target, timestamp: $timestamp)';
}


}

/// @nodoc
abstract mixin class $SASUPMetaCopyWith<$Res>  {
  factory $SASUPMetaCopyWith(SASUPMeta value, $Res Function(SASUPMeta) _then) = _$SASUPMetaCopyWithImpl;
@useResult
$Res call({
 String version, String target, int? timestamp
});




}
/// @nodoc
class _$SASUPMetaCopyWithImpl<$Res>
    implements $SASUPMetaCopyWith<$Res> {
  _$SASUPMetaCopyWithImpl(this._self, this._then);

  final SASUPMeta _self;
  final $Res Function(SASUPMeta) _then;

/// Create a copy of SASUPMeta
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? version = null,Object? target = null,Object? timestamp = freezed,}) {
  return _then(_self.copyWith(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as String,timestamp: freezed == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [SASUPMeta].
extension SASUPMetaPatterns on SASUPMeta {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SASUPMeta value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SASUPMeta() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SASUPMeta value)  $default,){
final _that = this;
switch (_that) {
case _SASUPMeta():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SASUPMeta value)?  $default,){
final _that = this;
switch (_that) {
case _SASUPMeta() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String version,  String target,  int? timestamp)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SASUPMeta() when $default != null:
return $default(_that.version,_that.target,_that.timestamp);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String version,  String target,  int? timestamp)  $default,) {final _that = this;
switch (_that) {
case _SASUPMeta():
return $default(_that.version,_that.target,_that.timestamp);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String version,  String target,  int? timestamp)?  $default,) {final _that = this;
switch (_that) {
case _SASUPMeta() when $default != null:
return $default(_that.version,_that.target,_that.timestamp);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SASUPMeta implements SASUPMeta {
  const _SASUPMeta({required this.version, required this.target, this.timestamp});
  factory _SASUPMeta.fromJson(Map<String, dynamic> json) => _$SASUPMetaFromJson(json);

@override final  String version;
@override final  String target;
@override final  int? timestamp;

/// Create a copy of SASUPMeta
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SASUPMetaCopyWith<_SASUPMeta> get copyWith => __$SASUPMetaCopyWithImpl<_SASUPMeta>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SASUPMetaToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SASUPMeta&&(identical(other.version, version) || other.version == version)&&(identical(other.target, target) || other.target == target)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,version,target,timestamp);

@override
String toString() {
  return 'SASUPMeta(version: $version, target: $target, timestamp: $timestamp)';
}


}

/// @nodoc
abstract mixin class _$SASUPMetaCopyWith<$Res> implements $SASUPMetaCopyWith<$Res> {
  factory _$SASUPMetaCopyWith(_SASUPMeta value, $Res Function(_SASUPMeta) _then) = __$SASUPMetaCopyWithImpl;
@override @useResult
$Res call({
 String version, String target, int? timestamp
});




}
/// @nodoc
class __$SASUPMetaCopyWithImpl<$Res>
    implements _$SASUPMetaCopyWith<$Res> {
  __$SASUPMetaCopyWithImpl(this._self, this._then);

  final _SASUPMeta _self;
  final $Res Function(_SASUPMeta) _then;

/// Create a copy of SASUPMeta
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? version = null,Object? target = null,Object? timestamp = freezed,}) {
  return _then(_SASUPMeta(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as String,timestamp: freezed == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$SASUPSchema {

 SASUPMeta get meta; WidgetNode get root;
/// Create a copy of SASUPSchema
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SASUPSchemaCopyWith<SASUPSchema> get copyWith => _$SASUPSchemaCopyWithImpl<SASUPSchema>(this as SASUPSchema, _$identity);

  /// Serializes this SASUPSchema to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SASUPSchema&&(identical(other.meta, meta) || other.meta == meta)&&(identical(other.root, root) || other.root == root));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,meta,root);

@override
String toString() {
  return 'SASUPSchema(meta: $meta, root: $root)';
}


}

/// @nodoc
abstract mixin class $SASUPSchemaCopyWith<$Res>  {
  factory $SASUPSchemaCopyWith(SASUPSchema value, $Res Function(SASUPSchema) _then) = _$SASUPSchemaCopyWithImpl;
@useResult
$Res call({
 SASUPMeta meta, WidgetNode root
});


$SASUPMetaCopyWith<$Res> get meta;$WidgetNodeCopyWith<$Res> get root;

}
/// @nodoc
class _$SASUPSchemaCopyWithImpl<$Res>
    implements $SASUPSchemaCopyWith<$Res> {
  _$SASUPSchemaCopyWithImpl(this._self, this._then);

  final SASUPSchema _self;
  final $Res Function(SASUPSchema) _then;

/// Create a copy of SASUPSchema
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? meta = null,Object? root = null,}) {
  return _then(_self.copyWith(
meta: null == meta ? _self.meta : meta // ignore: cast_nullable_to_non_nullable
as SASUPMeta,root: null == root ? _self.root : root // ignore: cast_nullable_to_non_nullable
as WidgetNode,
  ));
}
/// Create a copy of SASUPSchema
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SASUPMetaCopyWith<$Res> get meta {
  
  return $SASUPMetaCopyWith<$Res>(_self.meta, (value) {
    return _then(_self.copyWith(meta: value));
  });
}/// Create a copy of SASUPSchema
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WidgetNodeCopyWith<$Res> get root {
  
  return $WidgetNodeCopyWith<$Res>(_self.root, (value) {
    return _then(_self.copyWith(root: value));
  });
}
}


/// Adds pattern-matching-related methods to [SASUPSchema].
extension SASUPSchemaPatterns on SASUPSchema {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SASUPSchema value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SASUPSchema() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SASUPSchema value)  $default,){
final _that = this;
switch (_that) {
case _SASUPSchema():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SASUPSchema value)?  $default,){
final _that = this;
switch (_that) {
case _SASUPSchema() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SASUPMeta meta,  WidgetNode root)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SASUPSchema() when $default != null:
return $default(_that.meta,_that.root);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SASUPMeta meta,  WidgetNode root)  $default,) {final _that = this;
switch (_that) {
case _SASUPSchema():
return $default(_that.meta,_that.root);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SASUPMeta meta,  WidgetNode root)?  $default,) {final _that = this;
switch (_that) {
case _SASUPSchema() when $default != null:
return $default(_that.meta,_that.root);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SASUPSchema implements SASUPSchema {
  const _SASUPSchema({required this.meta, required this.root});
  factory _SASUPSchema.fromJson(Map<String, dynamic> json) => _$SASUPSchemaFromJson(json);

@override final  SASUPMeta meta;
@override final  WidgetNode root;

/// Create a copy of SASUPSchema
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SASUPSchemaCopyWith<_SASUPSchema> get copyWith => __$SASUPSchemaCopyWithImpl<_SASUPSchema>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SASUPSchemaToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SASUPSchema&&(identical(other.meta, meta) || other.meta == meta)&&(identical(other.root, root) || other.root == root));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,meta,root);

@override
String toString() {
  return 'SASUPSchema(meta: $meta, root: $root)';
}


}

/// @nodoc
abstract mixin class _$SASUPSchemaCopyWith<$Res> implements $SASUPSchemaCopyWith<$Res> {
  factory _$SASUPSchemaCopyWith(_SASUPSchema value, $Res Function(_SASUPSchema) _then) = __$SASUPSchemaCopyWithImpl;
@override @useResult
$Res call({
 SASUPMeta meta, WidgetNode root
});


@override $SASUPMetaCopyWith<$Res> get meta;@override $WidgetNodeCopyWith<$Res> get root;

}
/// @nodoc
class __$SASUPSchemaCopyWithImpl<$Res>
    implements _$SASUPSchemaCopyWith<$Res> {
  __$SASUPSchemaCopyWithImpl(this._self, this._then);

  final _SASUPSchema _self;
  final $Res Function(_SASUPSchema) _then;

/// Create a copy of SASUPSchema
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? meta = null,Object? root = null,}) {
  return _then(_SASUPSchema(
meta: null == meta ? _self.meta : meta // ignore: cast_nullable_to_non_nullable
as SASUPMeta,root: null == root ? _self.root : root // ignore: cast_nullable_to_non_nullable
as WidgetNode,
  ));
}

/// Create a copy of SASUPSchema
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SASUPMetaCopyWith<$Res> get meta {
  
  return $SASUPMetaCopyWith<$Res>(_self.meta, (value) {
    return _then(_self.copyWith(meta: value));
  });
}/// Create a copy of SASUPSchema
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WidgetNodeCopyWith<$Res> get root {
  
  return $WidgetNodeCopyWith<$Res>(_self.root, (value) {
    return _then(_self.copyWith(root: value));
  });
}
}

// dart format on
