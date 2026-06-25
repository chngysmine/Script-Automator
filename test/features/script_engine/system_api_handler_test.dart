import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:script_automator/features/script_engine/domain/system_api_handler.dart';
import 'package:script_automator/features/script_engine/domain/system_api_polyfills.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SystemAPIHandler Clipboard & Share Tests', () {
    late SystemAPIHandler handler;
    final List<MethodCall> log = [];

    setUp(() {
      handler = SystemAPIHandler();
      log.clear();
      
      // Intercept Clipboard and Share system channels
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (methodCall) async {
        log.add(methodCall);
        if (methodCall.method == 'Clipboard.setData') {
          return null;
        } else if (methodCall.method == 'Clipboard.getData') {
          return {'text': 'mocked_clipboard_text'};
        }
        return null;
      });

      // Mock share_plus method channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/share'),
        (methodCall) async {
          log.add(methodCall);
          if (methodCall.method == 'share') {
            return null;
          }
          return null;
        },
      );
    });

    tearDown(() {
      handler.dispose();
    });

    test('handleClipboard write should store text', () async {
      final payload = jsonEncode({
        'action': 'write',
        'text': 'hello sandbox',
      });

      final resultStr = await handler.handleClipboard(payload);
      final result = jsonDecode(resultStr);

      expect(result['success'], isTrue);
      final setCall = log.firstWhere((c) => c.method == 'Clipboard.setData');
      expect(setCall.arguments['text'], 'hello sandbox');
    });

    test('handleClipboard read should retrieve text', () async {
      final payload = jsonEncode({
        'action': 'read',
      });

      final resultStr = await handler.handleClipboard(payload);
      final result = jsonDecode(resultStr);

      expect(result['value'], 'mocked_clipboard_text');
    });

    test('handleShare should validate and execute', () async {
      final payload = jsonEncode({
        'text': 'share content',
        'title': 'share title',
      });

      final resultStr = await handler.handleShare(payload);
      final result = jsonDecode(resultStr);

      // share_plus might use system channel on android/ios
      expect(result['success'], isTrue);
    });

    test('handleShare with empty text should return error', () async {
      final payload = jsonEncode({
        'text': '',
      });

      final resultStr = await handler.handleShare(payload);
      final result = jsonDecode(resultStr);

      expect(result['error'], isNotNull);
    });
   group('SystemAPIPolyfills test', () {
    // Sanity check that clipboard, share and alert classes are in polyfills
    test('polyfills contains custom classes', () {
      final all = SystemAPIPolyfills.allPolyfills;
      expect(all.contains('var Clipboard ='), isTrue);
      expect(all.contains('var Share ='), isTrue);
      expect(all.contains('var Alert ='), isTrue);
    });
  });
  });
}
