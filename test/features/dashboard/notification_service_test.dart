import 'dart:io';

import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:script_automator/features/dashboard/domain/services/notification_service.dart';

void main() {
  const timeout = Duration(seconds: 1);
  late Directory tempDir;
  late NotificationService service;

  // Mixed-case uid exercises the lowercased box-name early return in init().
  MockFirebaseAuth signedInAuth() => MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'AbC123'),
      );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('notification_service_test');
    Hive.init(tempDir.path);
    service = NotificationService(auth: signedInAuth());
  });

  tearDown(() async {
    service.dispose();
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  Future<void> tick() => Future<void>.delayed(const Duration(milliseconds: 2));

  test('new subscriber gets the empty list and zero unread after init', () async {
    await service.init();

    expect(await service.notifications.first.timeout(timeout), isEmpty);
    expect(await service.unreadCount.first.timeout(timeout), 0);
  });

  test('new subscriber still gets current state after a repeated init', () async {
    await service.init();
    // Second init for the same user hits the early return and does not emit.
    await service.init();

    expect(await service.notifications.first.timeout(timeout), isEmpty);
    expect(await service.unreadCount.first.timeout(timeout), 0);
  });

  test('new subscriber gets the current list and unread count', () async {
    await service.init();
    service.addNotification(
      type: NotificationType.scriptRun,
      title: 'first',
      body: 'b',
    );
    await tick(); // ids are millisecond timestamps
    service.addNotification(
      type: NotificationType.system,
      title: 'second',
      body: 'b',
    );
    final firstId =
        service.allNotifications.singleWhere((n) => n.title == 'first').id;
    await service.markAsRead(firstId);

    final list = await service.notifications.first.timeout(timeout);
    expect(list.map((n) => n.title), ['second', 'first']);
    expect(await service.unreadCount.first.timeout(timeout), 1);
    expect(service.allNotifications.length, 2);
    expect(service.currentUnreadCount, 1);
  });

  test('existing subscriber gets the replayed value, then updates', () async {
    await service.init();
    final lists = <List<AppNotification>>[];
    final counts = <int>[];
    final subs = [
      service.notifications.listen(lists.add),
      service.unreadCount.listen(counts.add),
    ];
    await tick();

    service.addNotification(
      type: NotificationType.system,
      title: 'hello',
      body: 'b',
    );
    await tick();

    expect(lists.map((l) => l.length), [0, 1]);
    expect(counts, [0, 1]);
    for (final s in subs) {
      await s.cancel();
    }
  });

  test('persisted notifications are replayed by a new service instance', () async {
    await service.init();
    service.addNotification(
      type: NotificationType.widgetDeploy,
      title: 'deployed',
      body: 'b',
    );
    await service.markAllAsRead(); // awaits the disk write
    service.dispose();

    service = NotificationService(auth: signedInAuth());
    await service.init();

    final list = await service.notifications.first.timeout(timeout);
    expect(list.map((n) => n.title), ['deployed']);
    expect(await service.unreadCount.first.timeout(timeout), 0);
  });
}
