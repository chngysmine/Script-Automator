// Notifications page smoke test with the real DI graph:
//   flutter test integration_test/notification_page_test.dart -d <device>
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'package:script_automator/core/services/firebase_bootstrap.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/features/dashboard/domain/services/notification_service.dart';
import 'package:script_automator/features/dashboard/presentation/pages/notification_page.dart';
import 'package:script_automator/features/script_management/data/models/script_model.dart';
import 'package:script_automator/features/widget_renderer/data/services/widget_registry_service.dart';
import 'package:script_automator/main.dart' show setupDependencies;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  setUpAll(() async {
    // setupDependencies() runs NotificationService.init() before the page
    // exists, which is the production order that caused the endless spinner.
    await FirebaseBootstrap.initialize();
    await setupDependencies();
  });

  testWidgets('notifications page renders list or empty state, no spinner',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: LiquidTheme.lightTheme,
      home: const NotificationPage(),
    ));
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(CircularProgressIndicator), findsNothing);
    final hasEmptyState = find.text('No notifications yet').evaluate().isNotEmpty;
    final hasItems = find.byType(Dismissible).evaluate().isNotEmpty;
    expect(hasEmptyState || hasItems, isTrue);

    final service = GetIt.I<NotificationService>();
    service.addNotification(
      type: NotificationType.system,
      title: 'IT notification probe',
      body: 'probe',
    );
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('IT notification probe'), findsOneWidget);

    // Keep the real user box clean.
    final probe = service.allNotifications
        .firstWhere((n) => n.title == 'IT notification probe');
    await service.dismiss(probe.id);
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
  });

  testWidgets('widget registry DB opens on device (WAL pragma)',
      (tester) async {
    // If the open fails, the service swallows the error and every call is a
    // no-op, so a round-trip through the real App Group DB proves it opened.
    final registry = GetIt.I<WidgetRegistryService>();
    const probeId = 'it_registry_probe';
    final now = DateTime.now();
    await registry.syncScript(
      ScriptModel(id: probeId, name: 'probe', createdAt: now, updatedAt: now),
    );
    expect(await registry.getActiveWidgetIds(), contains(probeId));

    await registry.removeScript(probeId);
    expect(await registry.getActiveWidgetIds(), isNot(contains(probeId)));
  });
}
