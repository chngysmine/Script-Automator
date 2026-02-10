import 'package:freezed_annotation/freezed_annotation.dart';
import 'sasup_action.dart';
import 'sasup_padding.dart';

part 'sasup_modifiers.freezed.dart';
part 'sasup_modifiers.g.dart';

@freezed
abstract class SASUPModifiers with _$SASUPModifiers {
  const factory SASUPModifiers({
    double? width,
    double? height,
    int? flex,
    String? background, // Hex or gradient definition
    double? cornerRadius,
    SASUPPadding? padding,
    SASUPAction? clickAction,
    String? font, // For text widgets ('bold', 'normal')
    double? fontSize, // Font size
    String? color, // Text color
    String? alignment, // 'start', 'center', 'end'
    double? spacing, // Gap between children in Row/Column
  }) = _SASUPModifiers;

  factory SASUPModifiers.fromJson(Map<String, dynamic> json) =>
      _$SASUPModifiersFromJson(json);
}
