import 'package:fpdart/fpdart.dart';
import '../entities/script.dart';

/// Failures
abstract class Failure {
  final String message;
  Failure(this.message);
}

class StorageFailure extends Failure {
  StorageFailure(super.message);
}

abstract class ScriptRepository {
  /// Stream that emits an event whenever scripts are modified, created, or deleted.
  Stream<void> get onScriptsChanged;

  /// Get all scripts (Metadata only).
  Future<Either<Failure, List<Script>>> getScripts();

  /// Get full script content.
  Future<Either<Failure, Script>> getScriptDetail(String id);

  /// Save script.
  Future<Either<Failure, Unit>> saveScript(Script script);

  /// Delete script.
  Future<Either<Failure, Unit>> deleteScript(String id);

  /// Disposes resources (like streams).
  void dispose();
}
