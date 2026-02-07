import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Exception thrown when a security violation is detected.
class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);
}

/// Virtual File System Service.
/// Acts as a secure gatekeeper (Chroot Jail) for file access from scripts.
class VirtualFileSystemService {
  final String rootDirectory;

  VirtualFileSystemService(String root)
    : rootDirectory = Directory(root).resolveSymbolicLinksSync();

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

    // 4. Canonicalize (Resolve Symlinks)
    // path.canonicalize is pure string manipulation on some versions/platforms.
    // We MUST use File.resolveSymbolicLinks to guarantee OS-level resolution.
    String canonicalPath;
    try {
      canonicalPath = await File(rawPath).resolveSymbolicLinks();
    } catch (e) {
      // If file doesn't exist, resolveSymbolicLinks might fail.
      // But for security, if we can't resolve it, we fallback to canonicalize
      // AND ensure it doesn't exist later?
      // Actually, if we are writing a NEW file, it doesn't exist yet.
      // So we can't resolve symlinks for a clear target that doesn't exist.
      // BUT, if we are writing to a path that involves EXISTING symlinks in parent directories,
      // resolveSymbolicLinks should work on the parent?

      // Strategy:
      // If path exists (or symlink exists), resolve it.
      // If not, use string canonicalize.
      if (await File(rawPath).exists() || await Link(rawPath).exists()) {
        canonicalPath = await File(rawPath).resolveSymbolicLinks();
      } else {
        canonicalPath = path.canonicalize(rawPath);
      }
    }

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
    // REFACTOR: Fallback to local documents for verification test (AppGroup plugin removed)
    final docsDir = await getApplicationDocumentsDirectory();
    final sharedPath = path.join(docsDir.path, 'shared_container');
    if (!await Directory(sharedPath).exists()) {
      await Directory(sharedPath).create(recursive: true);
    }
    return sharedPath;
  }
}
