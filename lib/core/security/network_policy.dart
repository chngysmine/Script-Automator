import 'dart:io';

/// Security Policy for sandbox network requests.
/// Prevents SSRF attacks, access to loopback, private ranges, metadata servers, and invalid schemes.
class NetworkPolicy {
  /// Blocked URL regex patterns.
  static final List<RegExp> _blockedPatterns = [
    RegExp(r'^https?://(localhost|127\.0\.0\.1|0\.0\.0\.0)', caseSensitive: false),
    RegExp(r'^https?://\[::1\]'),
    RegExp(r'^https?://10\.'),
    RegExp(r'^https?://172\.(1[6-9]|2\d|3[01])\.'),
    RegExp(r'^https?://192\.168\.'),
    RegExp(r'^https?://169\.254\.'),
    RegExp(r'^https?://metadata\.google'),
  ];

  /// Returns `true` if the [url] is blocked (private, loopback, or metadata).
  static bool isBlockedUrl(String url) {
    return _blockedPatterns.any((pattern) => pattern.hasMatch(url));
  }

  /// Returns `true` if the [ip] falls into a private or loopback IP range (IPv4 or IPv6).
  static bool isPrivateIp(String ip) {
    if (ip.startsWith('10.') ||
        ip.startsWith('192.168.') ||
        ip.startsWith('169.254.')) {
      return true;
    }
    if (ip.startsWith('172.')) {
      final parts = ip.split('.');
      if (parts.length >= 2) {
        final secondPart = int.tryParse(parts[1]);
        if (secondPart != null && secondPart >= 16 && secondPart <= 31) {
          return true;
        }
      }
    }
    if (ip == '::1' || ip == '0:0:0:0:0:0:0:1' || ip == '127.0.0.1' || ip == '0.0.0.0') {
      return true;
    }
    final lowerIp = ip.toLowerCase();
    if (lowerIp.startsWith('fc00:') ||
        lowerIp.startsWith('fd00:') ||
        lowerIp.startsWith('fe80:')) {
      return true;
    }
    return false;
  }

  /// Validates a URL and returns `null` if allowed, or an error message if blocked.
  static Future<String?> validateUrl(String url) async {
    try {
      final uri = Uri.tryParse(url);
      if (uri == null) return 'Invalid URL format';

      final scheme = uri.scheme.toLowerCase();
      if (scheme != 'http' && scheme != 'https') {
        return 'Request blocked: unsupported scheme. Only http and https are allowed';
      }

      if (isBlockedUrl(url)) {
        return 'Request blocked: private/loopback addresses are not allowed';
      }

      String resolvedIp = uri.host;
      bool isHostIp = false;
      try {
        InternetAddress(uri.host);
        isHostIp = true;
      } catch (_) {}

      if (!isHostIp) {
        try {
          final resolvedHosts = await InternetAddress.lookup(uri.host)
              .timeout(const Duration(seconds: 5));
          if (resolvedHosts.isEmpty) {
            return 'Request blocked: unable to resolve host securely';
          }
          final address = resolvedHosts.first;
          resolvedIp = address.address;

          if (address.isLoopback || address.isLinkLocal || isPrivateIp(resolvedIp)) {
            return 'Request blocked: resolved address is private or loopback';
          }
        } catch (_) {
          return 'Request blocked: unable to resolve host securely or DNS lookup timed out';
        }
      } else {
        if (isPrivateIp(resolvedIp)) {
          return 'Request blocked: target IP is private or loopback';
        }
      }
      return null; // Allowed
    } catch (e) {
      return 'Request blocked: validation error: $e';
    }
  }
}
