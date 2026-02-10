import 'package:flutter_test/flutter_test.dart';
import 'package:script_automator/features/ai/data/ai_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FakeFlutterSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _data = {};
  @override
  Future<String?> read({
    required String key,
    iOptions,
    aOptions,
    lOptions,
    mOptions,
    wOptions,
    webOptions,
  }) async => _data[key];
  @override
  Future<void> write({
    required String key,
    required String? value,
    iOptions,
    aOptions,
    lOptions,
    mOptions,
    wOptions,
    webOptions,
  }) async {
    if (value != null) _data[key] = value;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('AIService Tests', () {
    late AIService aiService;
    late FakeFlutterSecureStorage fakeStorage;

    setUp(() {
      fakeStorage = FakeFlutterSecureStorage();
      aiService = AIService(storage: fakeStorage);
    });

    test('isReady should be false initially', () {
      expect(aiService.isReady, isFalse);
    });

    test('initialize should check storage for API key', () async {
      await fakeStorage.write(key: 'gemini_api_key', value: 'fake_key');
      await aiService.initialize();
      expect(aiService.isReady, isTrue);
    });
  });
}
