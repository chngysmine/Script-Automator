import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:script_automator/core/auth/auth_service.dart';
import 'package:script_automator/core/sync/firestore_sync_service.dart';
import 'package:script_automator/core/theme/liquid_colors.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
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

/// Shows a beautiful popup dialog with account information.
void showAccountInfoDialog(BuildContext context) {
  if (!GetIt.I.isRegistered<AuthService>()) return;
  final auth = GetIt.I<AuthService>();
  
  showDialog(
    context: context,
    builder: (context) {
      final colors = Theme.of(context).extension<LiquidColors>()!;
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.sheetBackground,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: colors.cardBorder, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              CircleAvatar(
                radius: 44,
                backgroundColor: LiquidTheme.primary.withValues(alpha: 0.15),
                backgroundImage: auth.photoURL != null ? NetworkImage(auth.photoURL!) : null,
                child: auth.photoURL == null
                    ? Icon(Icons.person_rounded, size: 44, color: LiquidTheme.primary)
                    : null,
              ),
              const SizedBox(height: 20),
              
              // Name
              Text(
                auth.displayName.isEmpty ? 'Guest User' : auth.displayName,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: colors.textTitle,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              
              // Email Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.cardBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.email_rounded, size: 18, color: colors.textCaption),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        auth.email ?? 'No email linked',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.textBody,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Close button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: LiquidTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Close",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Performs a full cloud sync and shows progress/result snackbars.
Future<void> syncToCloud(BuildContext context) async {
  if (!GetIt.I.isRegistered<AuthService>()) return;
  final auth = GetIt.I<AuthService>();
  final uid = auth.currentUser?.uid;
  if (uid == null) return;

  // Removed SnackBars

  try {
    final syncService = GetIt.I<FirestoreSyncService>();
    await syncService.fullSync(uid);
  } catch (e) {
    debugPrint("Sync failed: $e");
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
            if (Theme.of(context).platform == TargetPlatform.iOS) ...[
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
            const SizedBox(height: 12),
            _LinkButton(
              icon: Icons.email_rounded,
              label: "Continue with Email",
              color: LiquidTheme.primary,
              onTap: () async {
                final navigator = Navigator.of(context);
                final creds = await _askEmailPassword(context);
                if (creds == null || !navigator.mounted) return;
                navigator.pop();
                final host = navigator.context;
                if (!host.mounted) return;
                await _linkProvider(
                  host,
                  linkFn: () => auth.linkWithEmail(creds.email, creds.password),
                  providerName: "Email",
                  onLinked: onLinked,
                  popSheet: false,
                );
              },
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
  bool popSheet = true,
}) async {
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  if (popSheet) navigator.pop();
  // The sheet's context is gone after pop; dialogs use the navigator's.
  final host = navigator.context;
  try {
    await linkFn();
    final uid = GetIt.I<AuthService>().currentUser?.uid;
    if (uid != null) {
      try {
        await GetIt.I<FirestoreSyncService>().pushLocalToCloud(uid);
      } on SyncConflictException catch (e) {
        if (host.mounted) {
          await _showSyncConflictDialog(host, uid, e, onLinked);
        }
        return;
      }
    }
    messenger.showSnackBar(
      SnackBar(content: Text('$providerName linked. Your data is now backed up.')),
    );
    onLinked?.call();
  } on AccountAlreadyExistsException catch (e) {
    if (!host.mounted) return;
    final switchAccount = await showDialog<bool>(
      context: host,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Account already exists'),
        content: Text(
          '${e.email ?? 'This $providerName account'} is already registered. '
          'Sign in with it instead? Guest scripts on this device stay local and '
          'can be re-synced after signing in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign in'),
          ),
        ],
      ),
    );
    if (switchAccount != true) return;
    try {
      await GetIt.I<AuthService>().signInWithExistingCredential(e.credential);
      onLinked?.call();
    } catch (signInError) {
      messenger.showSnackBar(
        SnackBar(content: Text(_authErrorMessage(signInError)), backgroundColor: Colors.red),
      );
    }
  } catch (e) {
    debugPrint('[Auth] Link $providerName failed: $e');
    final message = _authErrorMessage(e);
    if (message.isNotEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }
}

/// Maps auth errors to short user-facing messages ('' for user cancellation).
String _authErrorMessage(Object error) {
  final text = error.toString();
  if (text.contains('canceled') || text.contains('cancelled')) return '';
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'network-request-failed':
        return 'No internet connection. Please try again.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'requires-recent-login':
        return 'Please sign out and sign in again, then retry.';
      case 'provider-already-linked':
        return 'This provider is already linked to your account.';
      default:
        return error.message ?? 'Authentication failed (${error.code}).';
    }
  }
  return 'Something went wrong: $text';
}

Future<({String email, String password})?> _askEmailPassword(BuildContext context) async {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final result = await showDialog<({String email, String password})>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Link Email'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: passCtrl,
            obscureText: true,
            autofillHints: const [AutofillHints.newPassword],
            decoration: const InputDecoration(labelText: 'Password (min. 6 characters)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final email = emailCtrl.text.trim();
            if (email.isEmpty || passCtrl.text.length < 6) return;
            Navigator.pop(dialogContext, (email: email, password: passCtrl.text));
          },
          child: const Text('Link'),
        ),
      ],
    ),
  );
  emailCtrl.dispose();
  passCtrl.dispose();
  return result;
}

/// Confirms and permanently deletes the signed-in account and local data.
///
/// Returns `true` when the account was deleted.
Future<bool> confirmAndDeleteAccount(BuildContext context) async {
  if (!GetIt.I.isRegistered<AuthService>()) return false;
  final messenger = ScaffoldMessenger.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete account?'),
      content: const Text(
        'This permanently deletes your account and signs you out. Scripts on '
        'this device are removed. This cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed != true) return false;
  try {
    await GetIt.I<AuthService>().deleteAccount();
    if (GetIt.I.isRegistered<ScriptLocalDataSource>()) {
      await GetIt.I<ScriptLocalDataSource>().reset();
    }
    return true;
  } catch (e) {
    final message = _authErrorMessage(e);
    if (message.isNotEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
    }
    return false;
  }
}

Future<void> _showSyncConflictDialog(
  BuildContext context,
  String uid,
  SyncConflictException exception,
  VoidCallback? onLinked,
) async {
  final result = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      final colors = Theme.of(dialogContext).extension<LiquidColors>()!;
      return AlertDialog(
        backgroundColor: colors.sheetBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Sync Conflict",
          style: TextStyle(color: colors.textTitle, fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Drafts with the same names already exist on your Cloud account:",
              style: TextStyle(color: colors.textBody),
            ),
            const SizedBox(height: 10),
            ...exception.conflictingNames.map((name) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange.shade600),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            color: colors.textBody,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'JetBrainsMono',
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            Text(
              "How would you like to resolve these conflicts?",
              style: TextStyle(color: colors.textBody),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, 'merge'),
                  style: FilledButton.styleFrom(
                    backgroundColor: LiquidTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Keep Both (Merge & Rename)"),
                ),
                const SizedBox(height: 6),
                OutlinedButton(
                  onPressed: () => Navigator.pop(dialogContext, 'overwrite'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colors.cardBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text("Overwrite Cloud with Local", style: TextStyle(color: colors.textBody)),
                ),
                const SizedBox(height: 6),
                OutlinedButton(
                  onPressed: () => Navigator.pop(dialogContext, 'discard'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Discard Local Drafts", style: TextStyle(color: Colors.redAccent)),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      );
    },
  );

  if (result == null) return;

  try {
    final syncService = GetIt.I<FirestoreSyncService>();
    if (result == 'merge') {
      await syncService.pushLocalToCloud(uid, forceMerge: true);
    } else if (result == 'overwrite') {
      await syncService.pushLocalToCloud(uid, forceOverwrite: true);
    } else if (result == 'discard') {
      await syncService.pushLocalToCloud(uid, forceDiscard: true);
      await syncService.pullCloudToLocal(uid);
    }
    onLinked?.call();
  } catch (e) {
    debugPrint("Failed to resolve sync conflict: $e");
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
