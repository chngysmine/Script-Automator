import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:script_automator/core/services/app_config_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('app_config_test');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  Future<void> pump() => Future<void>.delayed(const Duration(milliseconds: 20));

  test('uses default AI models when app_config/global has no AI fields', () async {
    final firestore = FakeFirebaseFirestore();
    await firestore.doc('app_config/global').set({'maintenance_mode': false});
    final service = AppConfigService(firestore: firestore);

    await service.fetch();
    await pump();

    expect(service.loaded, isTrue);
    expect(service.maintenanceMode, isFalse);
    expect(service.aiChatModel, AppConfigService.defaultChatModel);
    expect(service.aiCompletionModel, AppConfigService.defaultCompletionModel);
    expect(service.reportAutoBlockThreshold,
        AppConfigService.defaultReportAutoBlockThreshold);
    service.dispose();
  });

  test('reads remote values and reacts to live updates', () async {
    final firestore = FakeFirebaseFirestore();
    final doc = firestore.doc('app_config/global');
    await doc.set({
      'maintenance_mode': false,
      'gallery_submissions_enabled': false,
      'ai_chat_model': 'gemini-test-chat',
      'ai_completion_model': 'gemini-test-fast',
      'report_auto_block_threshold': 3,
    });
    final service = AppConfigService(firestore: firestore);

    await service.fetch();
    await pump();
    expect(service.gallerySubmissionsEnabled, isFalse);
    expect(service.aiChatModel, 'gemini-test-chat');
    expect(service.aiCompletionModel, 'gemini-test-fast');
    expect(service.reportAutoBlockThreshold, 3);

    await doc.update({'ai_chat_model': 'gemini-next'});
    await pump();
    expect(service.aiChatModel, 'gemini-next');
    service.dispose();
  });

  test('blank or invalid values fall back to defaults', () {
    final service = AppConfigService(firestore: FakeFirebaseFirestore());
    service.applyRemoteData({
      'ai_chat_model': '   ',
      'ai_completion_model': 42,
      'report_auto_block_threshold': 0,
    });
    expect(service.aiChatModel, AppConfigService.defaultChatModel);
    expect(service.aiCompletionModel, AppConfigService.defaultCompletionModel);
    expect(service.reportAutoBlockThreshold,
        AppConfigService.defaultReportAutoBlockThreshold);
  });

  test('cached model names are available before the first snapshot', () async {
    final box = await Hive.openBox<dynamic>('app_config_cache');
    await box.put('ai_chat_model', 'cached-chat');
    final service = AppConfigService(firestore: FakeFirebaseFirestore(), cacheBox: box);

    await service.initialize();

    expect(service.aiChatModel, 'cached-chat');
    expect(service.aiCompletionModel, AppConfigService.defaultCompletionModel);
  });
}
