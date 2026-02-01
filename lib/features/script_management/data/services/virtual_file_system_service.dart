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
  /// Updated Phase 2.5: Mounts 'shared/' to App Group Directory.
  Future<String> _resolveAndValidatePath(String relativePath) async {
    // 1. Sanitize
    if (relativePath.contains('\u0000')) {
      throw SecurityException("Null byte detected in path.");
    }

    // Normalize path separators
    String normalizedPath = path.normalize(relativePath);
    if (path.isAbsolute(normalizedPath)) {
      // VFS works on relative paths only. Strip leading slash.
      if (normalizedPath.startsWith(path.separator)) {
        normalizedPath = normalizedPath.substring(1);
      }
    }

    String baseDir = rootDirectory;
    String effectiveRelativePath = normalizedPath;

    // 2. Check for Mount Points
    if (normalizedPath.startsWith('shared/') || normalizedPath == 'shared') {
      baseDir = await getSharedDirectory();
      if (normalizedPath == 'shared') {
        effectiveRelativePath = '.';
      } else {
        effectiveRelativePath = normalizedPath.substring(7); // remove 'shared/'
      }
    }

    // 3. Construct Absolute Path
    final rawPath = path.join(baseDir, effectiveRelativePath);

    // 4. Canonicalize
    final canonicalPath = path.canonicalize(rawPath);

    // 5. Boundary Check
    // We must check if it is within the SPECIFIC base dir (root vs shared)
    // Beware: path.canonicalize might resolve symlinks.
    // For Shared Dir on iOS, it is a separate volume.
    if (!path.isWithin(baseDir, canonicalPath) && canonicalPath != baseDir) {
      throw SecurityException(
        "Access Denied: Path escapes sandbox ($relativePath -> $canonicalPath not in $baseDir)",
      );
    }

    return canonicalPath;
  }

  Future<String> readString(String relativePath) async {
    final absolutePath = await _resolveAndValidatePath(relativePath);
    final file = File(absolutePath);
    if (!await file.exists()) {
      throw FileSystemException("File not found", absolutePath);
    }
    return file.readAsString();
  }

  Future<void> writeString(String relativePath, String content) async {
    final absolutePath = await _resolveAndValidatePath(relativePath);
    final file = File(absolutePath);
    // Ensure parent directory exists
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }

  Future<bool> exists(String relativePath) async {
    try {
      final absolutePath = await _resolveAndValidatePath(relativePath);
      return await File(absolutePath).exists();
    } catch (e) {
      if (e is SecurityException) return false;
      // If shared path fails to resolve (e.g. app group error), treat as not exists
      return false;
    }
  }

  Future<void> delete(String relativePath) async {
    final absolutePath = await _resolveAndValidatePath(relativePath);
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
        if (dir != null) return dir.path;
      } catch (e) {
        _logger.warning("App Group Error: $e");
      }
    }
    // Android Support (Phase 3 Spec): Use MethodChannel or Fallback
    // For VFS simplicity, we stick to a local 'shared' folder on Android
    // UNLESS Headless Service is configured to use the same path.
    // Ideally, Headless Service and VFS should agree on the path.
    // Current VFS Fallback:
    final sharedPath = path.join(rootDirectory, 'shared_container');
    await Directory(sharedPath).create(recursive: true);
    return sharedPath;
  }
}
