import 'dart:io';

import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/features/dashboard/domain/services/notification_service.dart';
import 'package:script_automator/features/dashboard/presentation/pages/notification_page.dart';

void main() {
  late Directory tempDir;
  late NotificationService service;

  setUp(() async {
    // Real Hive IO runs here, outside the widget test's FakeAsync zone.
    tempDir = await Directory.systemTemp.createTemp('notification_page_test');
    Hive.init(tempDir.path);
    service = NotificationService(auth: MockFirebaseAuth());
    await service.init();
    GetIt.I.registerSingleton<NotificationService>(service);
  });

  tearDown(() async {
    await GetIt.I.reset();
    service.dispose();
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  Widget app() => MaterialApp(
        theme: LiquidTheme.lightTheme,
        home: const NotificationPage(),
      );

  testWidgets('shows empty state, not a spinner, when already initialized',
      (tester) async {
    await tester.pumpWidget(app());
    // MeshGradientBackground animates forever, so no pumpAndSettle.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('No notifications yet'), findsOneWidget);
  });

  testWidgets('renders items present before the page opens', (tester) async {
    // The Hive write must run on the real event loop, not in FakeAsync.
    await tester.runAsync(() async {
      service.addNotification(
        type: NotificationType.system,
        title: 'Hello test',
        body: 'b',
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });

    await tester.pumpWidget(app());
    await tester.pump();
    // Let StaggeredEntrance delays elapse so no timers stay pending.
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Hello test'), findsOneWidget);
  });
}
