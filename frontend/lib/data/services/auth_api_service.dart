import 'api_client.dart';
export 'api_client.dart';
import 'session_service.dart';

/// Handles user registration and login via the real FastAPI backend.
/// On successful login, the JWT token is persisted via [SessionService].
class AuthApiService {
  final _client = ApiClient.instance;
  final _session = SessionService.instance;

  /// Register a new user account.
  ///
  /// Throws [ApiException] on validation errors (e.g. duplicate email,
  /// weak password) or network failures.
  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    await _client.post(
      '/auth/signup',
      {
        'name': fullName,
        'email': email,
        'password': password,
      },
      requiresAuth: false,
    );
  }

  /// Authenticate with email + password. Saves the JWT token and user
  /// info to [SessionService] on success.
  ///
  /// Throws [ApiException] on bad credentials or network failures.
  Future<void> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      '/auth/login',
      {'email': email, 'password': password},
      requiresAuth: false,
    );

    final token = response['access_token'] as String?;
    if (token == null || token.isEmpty) {
      throw const ApiException('Server returned an invalid token. Please try again.');
    }

    await _session.saveToken(token);
    await _session.saveUserInfo(email: email, name: email.split('@').first);
  }

  /// Clear the session (logout).
  Future<void> logout() async {
    await _session.clearSession();
  }
}
