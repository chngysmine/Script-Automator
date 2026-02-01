import 'package:freezed_annotation/freezed_annotation.dart';
import 'sasup_action.dart';

part 'sasup_modifiers.freezed.dart';
part 'sasup_modifiers.g.dart';

@freezed
abstract class SASUPPadding with _$SASUPPadding {
  const factory SASUPPadding.all(double value) = _SASUPPaddingAll;
  const factory SASUPPadding.symmetric({double? vertical, double? horizontal}) =
      _SASUPPaddingSymmetric;
  const factory SASUPPadding.only({
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) = _SASUPPaddingOnly;

  factory SASUPPadding.fromJson(Map<String, dynamic> json) =>
      _$SASUPPaddingFromJson(json);
}

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
    String? font, // For text widgets
    String? color, // Text color
    String? alignment, // 'start', 'center', 'end'
  }) = _SASUPModifiers;

  factory SASUPModifiers.fromJson(Map<String, dynamic> json) =>
      _$SASUPModifiersFromJson(json);
}
