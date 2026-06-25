import 'package:flutter_test/flutter_test.dart';
import 'package:script_automator/core/security/network_policy.dart';

void main() {
  group('NetworkPolicy Security Tests', () {
    test('isBlockedUrl returns true for private, loopback, and metadata domains', () {
      expect(NetworkPolicy.isBlockedUrl('http://localhost'), isTrue);
      expect(NetworkPolicy.isBlockedUrl('https://localhost:8080'), isTrue);
      expect(NetworkPolicy.isBlockedUrl('http://127.0.0.1'), isTrue);
      expect(NetworkPolicy.isBlockedUrl('http://[::1]'), isTrue);
      expect(NetworkPolicy.isBlockedUrl('http://192.168.1.1'), isTrue);
      expect(NetworkPolicy.isBlockedUrl('https://10.0.0.1/path'), isTrue);
      expect(NetworkPolicy.isBlockedUrl('http://172.16.0.1'), isTrue);
      expect(NetworkPolicy.isBlockedUrl('http://172.31.255.255'), isTrue);
      expect(NetworkPolicy.isBlockedUrl('http://169.254.169.254'), isTrue);
      expect(NetworkPolicy.isBlockedUrl('http://metadata.google.internal'), isTrue);
      expect(NetworkPolicy.isBlockedUrl('http://metadata.google'), isTrue);
    });

    test('isBlockedUrl returns false for public domains', () {
      expect(NetworkPolicy.isBlockedUrl('https://api.github.com'), isFalse);
      expect(NetworkPolicy.isBlockedUrl('https://google.com'), isFalse);
      expect(NetworkPolicy.isBlockedUrl('http://my-public-api.org/data'), isFalse);
    });

    test('isPrivateIp returns true for private IP formats', () {
      expect(NetworkPolicy.isPrivateIp('192.168.1.5'), isTrue);
      expect(NetworkPolicy.isPrivateIp('10.255.255.255'), isTrue);
      expect(NetworkPolicy.isPrivateIp('172.16.5.5'), isTrue);
      expect(NetworkPolicy.isPrivateIp('172.30.0.1'), isTrue);
      expect(NetworkPolicy.isPrivateIp('::1'), isTrue);
      expect(NetworkPolicy.isPrivateIp('fc00::1'), isTrue);
      expect(NetworkPolicy.isPrivateIp('fe80::1'), isTrue);
      expect(NetworkPolicy.isPrivateIp('127.0.0.1'), isTrue);
    });

    test('isPrivateIp returns false for public IP formats', () {
      expect(NetworkPolicy.isPrivateIp('8.8.8.8'), isFalse);
      expect(NetworkPolicy.isPrivateIp('1.1.1.1'), isFalse);
      expect(NetworkPolicy.isPrivateIp('2001:4860:4860::8888'), isFalse);
    });

    test('validateUrl returns error messages for unsafe or unsupported URLs', () async {
      final resScheme = await NetworkPolicy.validateUrl('ftp://example.com');
      expect(resScheme, contains('unsupported scheme'));

      final resBlocked = await NetworkPolicy.validateUrl('http://localhost');
      expect(resBlocked, contains('private/loopback'));

      final resPrivateIp = await NetworkPolicy.validateUrl('http://192.168.0.1');
      expect(resPrivateIp, contains('private/loopback'));
    });

    test('validateUrl returns null for valid public URLs', () async {
      final res = await NetworkPolicy.validateUrl('https://api.github.com');
      expect(res, isNull);
    });
  });
}
