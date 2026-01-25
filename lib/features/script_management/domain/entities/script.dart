import 'package:freezed_annotation/freezed_annotation.dart';

part 'script.freezed.dart';

@freezed
abstract class Script with _$Script {
  const factory Script({
    required String id,
    required String name,
    required String content,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default({}) Map<String, dynamic> settings,
  }) = _Script;
}
