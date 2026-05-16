import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Centralized Firebase Authentication wrapper.
///
/// Provides a unified API for all auth flows: anonymous, Google, Apple,
/// and email/password. Supports account linking (Guest → permanent) while
/// preserving the original UID and all associated Firestore data.
///
/// Uses google_sign_in v7 singleton API (GoogleSignIn.instance).
class AuthService {
  final FirebaseAuth _auth;
  bool _googleInitialized = false;

  AuthService({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  // ────────────────────── Reactive State ──────────────────────

  /// Stream that fires whenever the auth state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// The currently signed-in user, or null.
  User? get currentUser => _auth.currentUser;

  /// Whether the current session is an anonymous (guest) account.
  bool get isAnonymous => _auth.currentUser?.isAnonymous ?? true;

  /// Whether any user is signed in (including anonymous).
  bool get isSignedIn => _auth.currentUser != null;

  // ────────────────────── Google Init (v7) ──────────────────────

  /// Initializes the GoogleSignIn singleton. Safe to call multiple times.
  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    try {
      await GoogleSignIn.instance.initialize();
      _googleInitialized = true;
    } catch (e) {
      debugPrint('[Auth] Google Sign-In init failed: $e');
    }
  }

  // ────────────────────── Sign-In Methods ──────────────────────

  /// Creates an anonymous account. Used for zero-friction first launch.
  Future<UserCredential> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();
      debugPrint('[Auth] Anonymous sign-in: ${credential.user?.uid}');
      return credential;
    } catch (e) {
      debugPrint('[Auth] Anonymous sign-in failed: $e');
      rethrow;
    }
  }

  /// Google OAuth sign-in flow (google_sign_in v7).
  ///
  /// Uses `GoogleSignIn.instance.authenticate()` which returns a
  /// [GoogleSignInAccount] with `authentication.idToken` for Firebase.
  Future<UserCredential> signInWithGoogle() async {
    await _ensureGoogleInitialized();

    final googleUser = await GoogleSignIn.instance.authenticate();
    final idToken = googleUser.authentication.idToken;

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final result = await _auth.signInWithCredential(credential);
    debugPrint('[Auth] Google sign-in: ${result.user?.email}');
    return result;
  }

  /// Apple Sign-In flow (iOS/macOS only).
  Future<UserCredential> signInWithApple() async {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    final result = await _auth.signInWithCredential(oauthCredential);

    // Apple only sends the name on first sign-in; persist it.
    if (result.user?.displayName == null || result.user!.displayName!.isEmpty) {
      final fullName = [
        appleCredential.givenName,
        appleCredential.familyName,
      ].where((n) => n != null && n.isNotEmpty).join(' ');

      if (fullName.isNotEmpty) {
        await result.user!.updateDisplayName(fullName);
      }
    }

    debugPrint('[Auth] Apple sign-in: ${result.user?.email}');
    return result;
  }

  /// Email/Password sign-in for existing accounts.
  Future<UserCredential> signInWithEmail(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    debugPrint('[Auth] Email sign-in: ${result.user?.email}');
    return result;
  }

  /// Create a new email/password account.
  Future<UserCredential> createAccount(String email, String password) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    debugPrint('[Auth] Account created: ${result.user?.email}');
    return result;
  }

  // ────────────────────── Account Linking ──────────────────────

  /// Links the current anonymous account with Google credentials.
  Future<UserCredential> linkWithGoogle() async {
    await _ensureGoogleInitialized();

    final googleUser = await GoogleSignIn.instance.authenticate();
    final idToken = googleUser.authentication.idToken;

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final result = await _auth.currentUser!.linkWithCredential(credential);
    debugPrint('[Auth] Linked anonymous → Google: ${result.user?.email}');
    return result;
  }

  /// Links the current anonymous account with Apple credentials.
  Future<UserCredential> linkWithApple() async {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    final result = await _auth.currentUser!.linkWithCredential(oauthCredential);
    debugPrint('[Auth] Linked anonymous → Apple: ${result.user?.email}');
    return result;
  }

  /// Links the current anonymous account with email/password.
  Future<UserCredential> linkWithEmail(String email, String password) async {
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    final result = await _auth.currentUser!.linkWithCredential(credential);
    debugPrint('[Auth] Linked anonymous → Email: ${result.user?.email}');
    return result;
  }

  // ────────────────────── Session Management ──────────────────────

  /// Signs out the current user and clears all cached credentials.
  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.disconnect();
    } catch (_) {}
    await _auth.signOut();
    debugPrint('[Auth] Signed out.');
  }

  /// Deletes the current user account permanently.
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
      debugPrint('[Auth] Account deleted.');
    } catch (e) {
      debugPrint('[Auth] Account deletion failed: $e');
      rethrow;
    }
  }

  // ────────────────────── Helpers ──────────────────────

  /// Returns a human-readable display name or fallback.
  String get displayName {
    final user = _auth.currentUser;
    if (user == null) return 'Guest';
    if (user.isAnonymous) return 'Guest';
    return user.displayName ?? user.email?.split('@').first ?? 'User';
  }

  /// Returns the user's email or null.
  String? get email => _auth.currentUser?.email;

  /// Returns the user's photo URL or null.
  String? get photoURL => _auth.currentUser?.photoURL;

  /// Returns the provider ID (google.com, apple.com, password, anonymous).
  String get providerId {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) return 'anonymous';
    if (user.providerData.isEmpty) return 'unknown';
    return user.providerData.first.providerId;
  }
}
