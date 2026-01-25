import 'package:hive_ce/hive.dart';

part 'script_model.g.dart';

/// Hive Object representing a User Script.
///
/// Stores metadata only. Content is stored internally in a separate box.
@HiveType(typeId: 0)
class ScriptModel extends HiveObject {
  /// Unique Identifier (UUID).
  @HiveField(0)
  final String id;

  /// Strategy Update per Report:
  /// To strictly separate metadata from content for performance, we will use TWO boxes:
  /// 1. `scripts_metadata`: Stores everything EXCEPT content.
  /// 2. `scripts_content`: Stores `id -> content`.
  ///
  /// BUT, to simplify initially while keeping high performance via LazyBox:
  /// LazyBox stores keys in RAM, values on disk.
  /// When we iterate keys (fast), we don't load values.
  /// When we need to show a list, we DO need names/icons.
  /// If we put everything in one object in a LazyBox, accessing `box.get(id)` reads the whole object (including 1MB content).
  ///
  /// OPTIMIZED STRATEGY:
  /// We will use this Model for the "Metadata" (Main) storage.
  /// The `content` field will typically be EMPTY in the main box if we were doing strict splitting.
  ///
  @HiveField(1)
  final String name;

  // Content is now stored in a separate box
  // @HiveField(2)
  // final String content;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final DateTime updatedAt;

  @HiveField(5)
  final Map<String, dynamic> settings;

  ScriptModel({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.settings = const {},
  });

  /// Factory for empty model
  factory ScriptModel.empty() => ScriptModel(
    id: '',
    name: '',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}
