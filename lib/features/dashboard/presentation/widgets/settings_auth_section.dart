import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:script_automator/core/auth/auth_service.dart';
import 'package:script_automator/core/sync/firestore_sync_service.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/core/theme/liquid_colors.dart';
import 'package:script_automator/features/script_management/data/datasources/script_local_data_source.dart';

/// Checks if the current user is anonymous (or auth is not registered).
bool isAnonymousUser() {
  if (!GetIt.I.isRegistered<AuthService>()) return true;
  return GetIt.I<AuthService>().isAnonymous;
}

/// Returns a subtitle string based on current auth state.
String? buildAuthSubtitle() {
  if (!GetIt.I.isRegistered<AuthService>()) return null;
  final auth = GetIt.I<AuthService>();
  if (auth.isAnonymous) return 'Guest mode';
  return auth.email ?? auth.displayName;
}

/// Performs a full cloud sync and shows progress/result snackbars.
Future<void> syncToCloud(BuildContext context) async {
  if (!GetIt.I.isRegistered<AuthService>()) return;
  final auth = GetIt.I<AuthService>();
  final uid = auth.currentUser?.uid;
  if (uid == null) return;

  final messenger = ScaffoldMessenger.of(context);

  // Show "syncing" indicator
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      content: const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 12),
          Text(
            "Syncing to cloud...",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      backgroundColor: LiquidTheme.cyan,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 10),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  try {
    final syncService = GetIt.I<FirestoreSyncService>();
    await syncService.fullSync(uid);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: const Text(
          "☁️ Cloud sync complete",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: LiquidTheme.primary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  } catch (e) {
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          "Sync failed: $e",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

/// Shows a confirmation dialog and signs the user out.
///
/// Returns `true` if sign-out was performed.
Future<bool> confirmAndSignOut(BuildContext context) async {
  if (!GetIt.I.isRegistered<AuthService>()) return false;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final colors = Theme.of(context).extension<LiquidColors>()!;
      return AlertDialog(
        backgroundColor: colors.sheetBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Sign Out",
            style: TextStyle(
                color: colors.textTitle, fontWeight: FontWeight.w800)),
        content: Text(
          "Your local scripts will remain on this device. Cloud data can be synced when you sign back in.",
          style: TextStyle(color: colors.textCaption),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text("Cancel", style: TextStyle(color: colors.textCaption)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Sign Out",
                style: TextStyle(
                    color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
          ),
        ],
      );
    },
  );

  if (confirmed == true) {
    if (GetIt.I.isRegistered<ScriptLocalDataSource>()) {
      await GetIt.I<ScriptLocalDataSource>().reset();
    }
    await GetIt.I<AuthService>().signOut();
    return true;
  }
  return false;
}

/// Shows a bottom sheet for linking a guest account to Google or Apple.
///
/// [onLinked] is called after a successful link to trigger UI refresh.
void showLinkAccountSheet(BuildContext context, {VoidCallback? onLinked}) {
  if (!GetIt.I.isRegistered<AuthService>()) return;
  final auth = GetIt.I<AuthService>();

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final colors = Theme.of(context).extension<LiquidColors>()!;
      return Container(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
        decoration: BoxDecoration(
          color: colors.sheetBackground,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.textCaption.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Upgrade Your Account",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: colors.textTitle),
            ),
            const SizedBox(height: 8),
            Text(
              "Link a provider to keep your scripts and data across devices.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: colors.textCaption),
            ),
            const SizedBox(height: 24),
            _LinkButton(
              icon: Icons.g_mobiledata_rounded,
              label: "Continue with Google",
              color: const Color(0xFF4285F4),
              onTap: () => _linkProvider(
                context,
                linkFn: auth.linkWithGoogle,
                providerName: "Google",
                onLinked: onLinked,
              ),
            ),
            const SizedBox(height: 12),
            _LinkButton(
              icon: Icons.apple_rounded,
              label: "Continue with Apple",
              color: colors.textTitle,
              onTap: () => _linkProvider(
                context,
                linkFn: auth.linkWithApple,
                providerName: "Apple",
                onLinked: onLinked,
              ),
            ),
          ],
        ),
      );
    },
  );
}

Future<void> _linkProvider(
  BuildContext context, {
  required Future<void> Function() linkFn,
  required String providerName,
  VoidCallback? onLinked,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  navigator.pop();
  try {
    await linkFn();
    final uid = GetIt.I<AuthService>().currentUser?.uid;
    if (uid != null) {
      await GetIt.I<FirestoreSyncService>().pushLocalToCloud(uid);
    }
    onLinked?.call();
    messenger.showSnackBar(
      SnackBar(
        content: Text("Account linked with $providerName ✓"),
        backgroundColor: LiquidTheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(
        content: Text("Failed: $e"),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Styled button for linking an auth provider.
class _LinkButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _LinkButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
