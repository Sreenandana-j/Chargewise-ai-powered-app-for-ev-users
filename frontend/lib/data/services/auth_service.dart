/// Thrown by [AuthService] for expected, user-facing auth failures
/// (bad credentials, duplicate email, ...) as opposed to unexpected
/// exceptions — lets the UI show `.message` directly.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Stands in for a real authentication backend (Firebase Auth, a
/// custom REST API, etc.). Screens only depend on this interface, so
/// swapping in real auth later is a one-file change.
///
/// Intentionally returns no user object: the app's [UserProfile] model
/// (used by the Profile screen) carries account/stats fields that a
/// login/sign-up call has no data for yet. Once a real backend or a
/// session/user provider is wired up, thread its result through here.
class AuthService {
  /// Simulates an email/password login.
  ///
  /// Dummy rule: any well-formed email works as long as the password
  /// is at least 6 characters — anything shorter simulates a
  /// "wrong credentials" response from the server.
  Future<void> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1100));

    if (password.length < 6) {
      throw const AuthException('Incorrect email or password. Please try again.');
    }
  }

  /// Simulates account creation.
  ///
  /// Dummy rule: emails containing "taken" simulate an already
  /// registered address, so the error UI path is exercisable on demand.
  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1300));

    if (email.toLowerCase().contains('taken')) {
      throw const AuthException('An account with this email already exists.');
    }
  }

  /// Simulates a Google sign-in/up.
  Future<void> continueWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 900));
  }
}
