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
  /// Get all scripts (Metadata only).
  Future<Either<Failure, List<Script>>> getScripts();

  /// Get full script content.
  Future<Either<Failure, Script>> getScriptDetail(String id);

  /// Save script.
  Future<Either<Failure, Unit>> saveScript(Script script);

  /// Delete script.
  Future<Either<Failure, Unit>> deleteScript(String id);
}
