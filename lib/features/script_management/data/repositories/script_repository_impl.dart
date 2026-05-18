import 'dart:async';
import 'package:fpdart/fpdart.dart';
import '../../domain/repositories/script_repository.dart';
import '../../domain/entities/script.dart';
import '../datasources/script_local_data_source.dart';
import '../models/script_model.dart';

import '../../../../features/widget_renderer/data/services/widget_registry_service.dart';
import '../../../../features/widget_renderer/domain/services/headless_widget_rendering_service.dart';
import 'package:get_it/get_it.dart';

class ScriptRepositoryImpl implements ScriptRepository {
  final ScriptLocalDataSource _dataSource;
  final WidgetRegistryService _widgetRegistry;
  HeadlessWidgetRenderingService?
  _rendererService; // Lazy loaded to prevent circular DI
  
  final _changeController = StreamController<void>.broadcast();

  /// Constructs a [ScriptRepositoryImpl] with the given data source and registry.
  ScriptRepositoryImpl(this._dataSource, this._widgetRegistry);

  @override
  Stream<void> get onScriptsChanged => _changeController.stream;

  @override
  /// Retrieves a list of script metadata.
  ///
  /// The content of the scripts is intentionally left empty for list views
  /// and is loaded on demand when a specific script's detail is requested.
  Future<Either<Failure, List<Script>>> getScripts() async {
    try {
      final models = await _dataSource.getScriptsMetadata();
      final entities = models
          .map(
            (m) => Script(
              id: m.id,
              name: m.name,
              content: "", // Content is loaded on demand
              createdAt: m.createdAt,
              updatedAt: m.updatedAt,
              settings: m.settings,
            ),
          )
          .toList();
      return Right(entities);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  @override
  /// Retrieves the detailed information for a single script by its [id].
  ///
  /// This method fetches the full script content.
  Future<Either<Failure, Script>> getScriptDetail(String id) async {
    try {
      final model = await _dataSource.getScriptDetail(id);
      if (model == null) {
        return Left(StorageFailure("Script not found"));
      }

      final content = await _dataSource.getScriptContent(id);

      return Right(
        Script(
          id: model.id,
          name: model.name,
          content: content,
          createdAt: model.createdAt,
          updatedAt: model.updatedAt,
          settings: model.settings,
        ),
      );
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  @override
  /// Saves a [script] to the data source.
  ///
  /// The `updatedAt` timestamp is automatically updated to the current time.
  Future<Either<Failure, Unit>> saveScript(Script script) async {
    try {
      final model = ScriptModel(
        id: script.id,
        name: script.name,
        createdAt: script.createdAt,
        updatedAt: DateTime.now(),
        settings: script.settings,
      );

      await _dataSource.saveScript(model, content: script.content);

      // Sync to SQLite Registry for Widget Extension
      await _widgetRegistry.syncScript(model);

      _changeController.add(null);

      return const Right(unit);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteScript(String id) async {
    try {
      await _dataSource.deleteScript(id);

      // Remove from SQLite Registry
      await _widgetRegistry.removeScript(id);

      // Cleanup orphan UI files
      try {
        _rendererService ??= GetIt.I<HeadlessWidgetRenderingService>();
        await _rendererService?.deleteWidgetUI(id);
      } catch (e) {
        // Fallback silently if DI is not fully booted
      }

      _changeController.add(null);

      return const Right(unit);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  @override
  void dispose() {
    _changeController.close();
  }
}

extension FutureIgnore on Future {
  void ignore() {}
}
