import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, authenticating, authenticated, unauthenticated }

/// App-wide auth state. `unknown` is the initial splash state before
/// [tryAutoLogin] resolves whether a stored token is still valid.
class AuthProvider extends ChangeNotifier {
  final AuthService _service;

  AuthProvider({AuthService? service}) : _service = service ?? AuthService();

  AuthStatus status = AuthStatus.unknown;
  User? user;
  String? token;
  String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  Future<void> tryAutoLogin() async {
    final stored = await _service.readStoredToken();
    if (stored == null) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      user = await _service.fetchMe(stored);
      token = stored;
      status = AuthStatus.authenticated;
    } catch (_) {
      await _service.logout();
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> signup({
    required String name,
    required String gender,
    required int age,
    required double height,
    required double weight,
    required String activityLevel,
  }) async {
    status = AuthStatus.authenticating;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await _service.signup(
        name: name,
        gender: gender,
        age: age,
        height: height,
        weight: weight,
        activityLevel: activityLevel,
      );
      token = result.token;
      // The signup response carries only id/name/goal — refetch the full
      // profile so weight (bakery walk-calorie estimates) and the 마이페이지
      // fields aren't blank until the next app launch. If that refetch
      // fails the account still exists, so fall back to the partial user.
      try {
        user = await _service.fetchMe(result.token);
      } on ApiException {
        user = result.user;
      }
      status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String userId) async {
    status = AuthStatus.authenticating;
    errorMessage = null;
    notifyListeners();
    try {
      final loggedInToken = await _service.login(userId: userId);
      user = await _service.fetchMe(loggedInToken);
      token = loggedInToken;
      status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> fields) async {
    if (token == null) return false;
    errorMessage = null;
    try {
      user = await _service.updateMe(token!, fields);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _service.logout();
    token = null;
    user = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
