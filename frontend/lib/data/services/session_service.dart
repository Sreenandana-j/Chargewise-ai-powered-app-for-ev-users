import 'package:shared_preferences/shared_preferences.dart';

/// Manages the JWT session token across the app lifecycle.
/// Tokens are persisted in SharedPreferences so they survive app restarts.
class SessionService {
  SessionService._();
  static final SessionService instance = SessionService._();

  static const _tokenKey = 'ev_auth_token';
  static const _userEmailKey = 'ev_user_email';
  static const _userNameKey = 'ev_user_name';

  // ── Token ────────────────────────────────────────────────────────────────

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ── User Info ────────────────────────────────────────────────────────────

  Future<void> saveUserInfo({required String email, required String name}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userEmailKey, email);
    await prefs.setString(_userNameKey, name);
  }

  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  // ── Logout ───────────────────────────────────────────────────────────────

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userNameKey);
  }
}
