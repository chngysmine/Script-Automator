// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'widget_node.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WidgetNode {

 WidgetType get type; String? get id;// For Diffing
 SASUPModifiers? get modifiers; List<WidgetNode>? get children;// Recursive
 dynamic get content;// String for text/image path, or nested structure
 SASUPAction? get action;
/// Create a copy of WidgetNode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WidgetNodeCopyWith<WidgetNode> get copyWith => _$WidgetNodeCopyWithImpl<WidgetNode>(this as WidgetNode, _$identity);

  /// Serializes this WidgetNode to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WidgetNode&&(identical(other.type, type) || other.type == type)&&(identical(other.id, id) || other.id == id)&&(identical(other.modifiers, modifiers) || other.modifiers == modifiers)&&const DeepCollectionEquality().equals(other.children, children)&&const DeepCollectionEquality().equals(other.content, content)&&(identical(other.action, action) || other.action == action));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,id,modifiers,const DeepCollectionEquality().hash(children),const DeepCollectionEquality().hash(content),action);

@override
String toString() {
  return 'WidgetNode(type: $type, id: $id, modifiers: $modifiers, children: $children, content: $content, action: $action)';
}


}

/// @nodoc
abstract mixin class $WidgetNodeCopyWith<$Res>  {
  factory $WidgetNodeCopyWith(WidgetNode value, $Res Function(WidgetNode) _then) = _$WidgetNodeCopyWithImpl;
@useResult
$Res call({
 WidgetType type, String? id, SASUPModifiers? modifiers, List<WidgetNode>? children, dynamic content, SASUPAction? action
});


$SASUPModifiersCopyWith<$Res>? get modifiers;$SASUPActionCopyWith<$Res>? get action;

}
/// @nodoc
class _$WidgetNodeCopyWithImpl<$Res>
    implements $WidgetNodeCopyWith<$Res> {
  _$WidgetNodeCopyWithImpl(this._self, this._then);

  final WidgetNode _self;
  final $Res Function(WidgetNode) _then;

/// Create a copy of WidgetNode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? id = freezed,Object? modifiers = freezed,Object? children = freezed,Object? content = freezed,Object? action = freezed,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as WidgetType,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,modifiers: freezed == modifiers ? _self.modifiers : modifiers // ignore: cast_nullable_to_non_nullable
as SASUPModifiers?,children: freezed == children ? _self.children : children // ignore: cast_nullable_to_non_nullable
as List<WidgetNode>?,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as dynamic,action: freezed == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as SASUPAction?,
  ));
}
/// Create a copy of WidgetNode
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SASUPModifiersCopyWith<$Res>? get modifiers {
    if (_self.modifiers == null) {
    return null;
  }

  return $SASUPModifiersCopyWith<$Res>(_self.modifiers!, (value) {
    return _then(_self.copyWith(modifiers: value));
  });
}/// Create a copy of WidgetNode
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SASUPActionCopyWith<$Res>? get action {
    if (_self.action == null) {
    return null;
  }

  return $SASUPActionCopyWith<$Res>(_self.action!, (value) {
    return _then(_self.copyWith(action: value));
  });
}
}


/// Adds pattern-matching-related methods to [WidgetNode].
extension WidgetNodePatterns on WidgetNode {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WidgetNode value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WidgetNode() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WidgetNode value)  $default,){
final _that = this;
switch (_that) {
case _WidgetNode():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WidgetNode value)?  $default,){
final _that = this;
switch (_that) {
case _WidgetNode() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( WidgetType type,  String? id,  SASUPModifiers? modifiers,  List<WidgetNode>? children,  dynamic content,  SASUPAction? action)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WidgetNode() when $default != null:
return $default(_that.type,_that.id,_that.modifiers,_that.children,_that.content,_that.action);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( WidgetType type,  String? id,  SASUPModifiers? modifiers,  List<WidgetNode>? children,  dynamic content,  SASUPAction? action)  $default,) {final _that = this;
switch (_that) {
case _WidgetNode():
return $default(_that.type,_that.id,_that.modifiers,_that.children,_that.content,_that.action);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( WidgetType type,  String? id,  SASUPModifiers? modifiers,  List<WidgetNode>? children,  dynamic content,  SASUPAction? action)?  $default,) {final _that = this;
switch (_that) {
case _WidgetNode() when $default != null:
return $default(_that.type,_that.id,_that.modifiers,_that.children,_that.content,_that.action);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WidgetNode implements WidgetNode {
  const _WidgetNode({required this.type, this.id, this.modifiers, final  List<WidgetNode>? children, this.content, this.action}): _children = children;
  factory _WidgetNode.fromJson(Map<String, dynamic> json) => _$WidgetNodeFromJson(json);

@override final  WidgetType type;
@override final  String? id;
// For Diffing
@override final  SASUPModifiers? modifiers;
 final  List<WidgetNode>? _children;
@override List<WidgetNode>? get children {
  final value = _children;
  if (value == null) return null;
  if (_children is EqualUnmodifiableListView) return _children;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

// Recursive
@override final  dynamic content;
// String for text/image path, or nested structure
@override final  SASUPAction? action;

/// Create a copy of WidgetNode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WidgetNodeCopyWith<_WidgetNode> get copyWith => __$WidgetNodeCopyWithImpl<_WidgetNode>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WidgetNodeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WidgetNode&&(identical(other.type, type) || other.type == type)&&(identical(other.id, id) || other.id == id)&&(identical(other.modifiers, modifiers) || other.modifiers == modifiers)&&const DeepCollectionEquality().equals(other._children, _children)&&const DeepCollectionEquality().equals(other.content, content)&&(identical(other.action, action) || other.action == action));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,id,modifiers,const DeepCollectionEquality().hash(_children),const DeepCollectionEquality().hash(content),action);

@override
String toString() {
  return 'WidgetNode(type: $type, id: $id, modifiers: $modifiers, children: $children, content: $content, action: $action)';
}


}

/// @nodoc
abstract mixin class _$WidgetNodeCopyWith<$Res> implements $WidgetNodeCopyWith<$Res> {
  factory _$WidgetNodeCopyWith(_WidgetNode value, $Res Function(_WidgetNode) _then) = __$WidgetNodeCopyWithImpl;
@override @useResult
$Res call({
 WidgetType type, String? id, SASUPModifiers? modifiers, List<WidgetNode>? children, dynamic content, SASUPAction? action
});


@override $SASUPModifiersCopyWith<$Res>? get modifiers;@override $SASUPActionCopyWith<$Res>? get action;

}
/// @nodoc
class __$WidgetNodeCopyWithImpl<$Res>
    implements _$WidgetNodeCopyWith<$Res> {
  __$WidgetNodeCopyWithImpl(this._self, this._then);

  final _WidgetNode _self;
  final $Res Function(_WidgetNode) _then;

/// Create a copy of WidgetNode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? id = freezed,Object? modifiers = freezed,Object? children = freezed,Object? content = freezed,Object? action = freezed,}) {
  return _then(_WidgetNode(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as WidgetType,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,modifiers: freezed == modifiers ? _self.modifiers : modifiers // ignore: cast_nullable_to_non_nullable
as SASUPModifiers?,children: freezed == children ? _self._children : children // ignore: cast_nullable_to_non_nullable
as List<WidgetNode>?,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as dynamic,action: freezed == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as SASUPAction?,
  ));
}

/// Create a copy of WidgetNode
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SASUPModifiersCopyWith<$Res>? get modifiers {
    if (_self.modifiers == null) {
    return null;
  }

  return $SASUPModifiersCopyWith<$Res>(_self.modifiers!, (value) {
    return _then(_self.copyWith(modifiers: value));
  });
}/// Create a copy of WidgetNode
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SASUPActionCopyWith<$Res>? get action {
    if (_self.action == null) {
    return null;
  }

  return $SASUPActionCopyWith<$Res>(_self.action!, (value) {
    return _then(_self.copyWith(action: value));
  });
}
}

// dart format on
