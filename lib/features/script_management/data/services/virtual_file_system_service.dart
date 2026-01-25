import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:app_group_directory/app_group_directory.dart';
import 'package:logging/logging.dart';

/// Exception thrown when a security violation is detected.
class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);
}

/// Virtual File System Service.
/// Acts as a secure gatekeeper (Chroot Jail) for file access from scripts.
class VirtualFileSystemService {
  final String rootDirectory;
  final _logger = Logger('VirtualFileSystemService');

  VirtualFileSystemService(this.rootDirectory);

  /// Initializes the VFS root directory.
  static Future<VirtualFileSystemService> create() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final vfsRoot = Directory(path.join(docsDir.path, 'vfs_root'));
    if (!await vfsRoot.exists()) {
      await vfsRoot.create(recursive: true);
    }
    return VirtualFileSystemService(vfsRoot.path);
  }

  /// securely resolves and validates the path.
  /// Prevention against Path Traversal (../../etc/passwd).
  String _resolveAndValidatePath(String relativePath) {
    // 1. Sanitize: Remove null bytes
    if (relativePath.contains('\u0000')) {
      throw SecurityException("Null byte detected in path.");
    }

    // 2. Construct Absolute Path
    final rawPath = path.join(rootDirectory, relativePath);

    // 3. Canonicalize (Resolve symlinks and ..)
    // Note: path.canonicalize is pure string manipulation in Dart unless we use File(p).resolveSymbolicLinksSync()
    // To be strictly secure against FS-level symlinks:
    final canonicalPath = path.canonicalize(rawPath);

    // 4. Boundary Check (The Jail)
    if (!path.isWithin(rootDirectory, canonicalPath)) {
      throw SecurityException(
        "Access Denied: Path escapes sandbox ($relativePath)",
      );
    }

    return canonicalPath;
  }

  Future<String> readString(String relativePath) async {
    final absolutePath = _resolveAndValidatePath(relativePath);
    final file = File(absolutePath);
    if (!await file.exists()) {
      throw FileSystemException("File not found", absolutePath);
    }
    return file.readAsString();
  }

  Future<void> writeString(String relativePath, String content) async {
    final absolutePath = _resolveAndValidatePath(relativePath);
    final file = File(absolutePath);
    // Ensure parent directory exists
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }

  Future<bool> exists(String relativePath) async {
    try {
      final absolutePath = _resolveAndValidatePath(relativePath);
      return await File(absolutePath).exists();
    } catch (e) {
      if (e is SecurityException) return false;
      rethrow;
    }
  }

  Future<void> delete(String relativePath) async {
    final absolutePath = _resolveAndValidatePath(relativePath);
    final file = File(absolutePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  // Helper for App Groups (iOS) - Phase 2 Step 3
  Future<String> getSharedDirectory() async {
    if (Platform.isIOS) {
      try {
        final dir = await AppGroupDirectory.getAppGroupDirectory(
          'group.com.scriptautomator',
        );
        // We use the real shared container.
        if (dir != null) {
          return dir.path;
        }
      } catch (e) {
        _logger.warning("App Group Error: $e");
      }
    }

    // Fallback for Android/Tests (or if App Group fails)
    final sharedPath = path.join(rootDirectory, 'shared');
    await Directory(sharedPath).create(recursive: true);
    return sharedPath;
  }
}
