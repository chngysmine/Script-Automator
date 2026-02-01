import 'package:freezed_annotation/freezed_annotation.dart';

part 'sasup_action.freezed.dart';
part 'sasup_action.g.dart';

@freezed
abstract class SASUPAction with _$SASUPAction {
  const factory SASUPAction({
    required String type,
    Map<String, dynamic>? payload,
  }) = _SASUPAction;

  factory SASUPAction.fromJson(Map<String, dynamic> json) =>
      _$SASUPActionFromJson(json);
}
