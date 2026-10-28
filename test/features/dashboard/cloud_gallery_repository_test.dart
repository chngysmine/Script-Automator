import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:script_automator/core/sync/firestore_sync_service.dart';
import 'package:script_automator/features/dashboard/data/repositories/cloud_gallery_repository.dart';
import 'package:script_automator/features/dashboard/domain/repositories/gallery_repository.dart';
import 'package:script_automator/features/dashboard/domain/services/notification_service.dart';

void main() {
  group('CloudGalleryRepository.reportScript', () {
    test('creates one canonical report per user and script', () async {
      final firestore = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'alice', email: 'alice@example.com'),
      );
      final repo = CloudGalleryRepository(firestore: firestore, auth: auth);

      final first = await repo.reportScript('weather_pro', reason: '  spam  ');
      final second = await repo.reportScript('weather_pro');

      expect(first, ReportResult.reported);
      expect(second, ReportResult.alreadyReported);
      final doc = await firestore.doc('script_reports/weather_pro_alice').get();
      expect(doc.data()!['script_id'], 'weather_pro');
      expect(doc.data()!['reporter_uid'], 'alice');
      expect(doc.data()!['reason'], 'spam');
      // The counter moves once, in the same transaction as the report.
      final moderation = await firestore.doc('script_moderation/weather_pro').get();
      expect(moderation.data()!['reports_count'], 1);
      expect(moderation.data()!['is_blocked'], isFalse);
    });

    test('auto-blocks at the threshold and respects admin override', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.doc('app_config/global').set({'report_auto_block_threshold': 2});
      await firestore.doc('script_moderation/a').set({'reports_count': 1, 'is_blocked': false});
      await firestore.doc('script_moderation/b').set({
        'reports_count': 9,
        'is_blocked': false,
        'admin_override': true,
      });
      final repo = CloudGalleryRepository(
        firestore: firestore,
        auth: MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'bob')),
      );

      await repo.reportScript('a');
      await repo.reportScript('b');

      final a = (await firestore.doc('script_moderation/a').get()).data()!;
      expect(a['reports_count'], 2);
      expect(a['is_blocked'], isTrue);
      expect(a['blocked_reason'], 'auto_reports_threshold');
      final b = (await firestore.doc('script_moderation/b').get()).data()!;
      expect(b['reports_count'], 10);
      expect(b['is_blocked'], isFalse);
    });

    test('guests must link an account before reporting', () async {
      final repo = CloudGalleryRepository(
        firestore: FakeFirebaseFirestore(),
        auth: MockFirebaseAuth(
          signedIn: true,
          mockUser: MockUser(uid: 'guest', isAnonymous: true),
        ),
      );
      expect(
        () => repo.reportScript('weather_pro'),
        throwsA(isA<GuestAccountRequiredException>()),
      );
    });
  });

  group('CloudGalleryRepository.submitScript', () {
    test('guests cannot publish', () async {
      final firestore = FakeFirebaseFirestore();
      final repo = CloudGalleryRepository(
        firestore: firestore,
        auth: MockFirebaseAuth(
          signedIn: true,
          mockUser: MockUser(uid: 'guest', isAnonymous: true),
        ),
      );
      await expectLater(
        repo.submitScript({'name': 'Timer', 'content': ''}),
        throwsA(isA<GuestAccountRequiredException>()),
      );
      expect((await firestore.collection('gallery_submissions').get()).docs, isEmpty);
    });

    test('registered users create a pending submission', () async {
      final firestore = FakeFirebaseFirestore();
      final repo = CloudGalleryRepository(
        firestore: firestore,
        auth: MockFirebaseAuth(
          signedIn: true,
          mockUser: MockUser(uid: 'alice', displayName: 'Alice'),
        ),
      );
      // Empty content skips the Storage upload.
      await repo.submitScript({'script_id': 's1', 'name': 'Timer', 'content': ''});
      final docs = (await firestore.collection('gallery_submissions').get()).docs;
      expect(docs, hasLength(1));
      expect(docs.single.data()['status'], 'pending');
      expect(docs.single.data()['user_id'], 'alice');
      expect(docs.single.data()['author'], 'Alice');
    });
  });

  group('FirestoreSyncService.parseRemoteNotification', () {
    test('appends reject_reason when the body lacks it', () {
      final parsed = FirestoreSyncService.parseRemoteNotification({
        'type': 2,
        'title': 'Script Rejected',
        'body': 'Your script "Timer" was rejected.',
        'reject_reason': 'Uses eval()',
      });
      expect(parsed.type, NotificationType.system);
      expect(parsed.body, contains('Reason: Uses eval()'));
    });

    test('does not duplicate a reason already in the body and tolerates bad types', () {
      final parsed = FirestoreSyncService.parseRemoteNotification({
        'type': 'oops',
        'body': 'Rejected. Reason: Broken',
        'reject_reason': 'Broken',
      });
      expect(parsed.title, 'Notification');
      expect('Reason: Broken'.allMatches(parsed.body).length, 1);
    });
  });
}
