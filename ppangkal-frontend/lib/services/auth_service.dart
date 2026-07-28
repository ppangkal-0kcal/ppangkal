import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/api_client.dart';
import '../models/user.dart';

/// Wraps the auth + profile endpoints (FRONTEND_API_GUIDE.md §1) and owns
/// JWT persistence. Login only returns a token (no user payload), so
/// callers need [fetchMe] afterward to populate the profile.
class AuthService {
  static const _tokenKey = 'auth_token';

  final ApiClient _client;
  final FlutterSecureStorage _storage;

  AuthService({ApiClient? client, FlutterSecureStorage? storage})
      : _client = client ?? ApiClient(),
        _storage = storage ?? const FlutterSecureStorage();

  Future<({User user, String token})> signup({
    required String name,
    required String gender,
    required int age,
    required double height,
    required double weight,
    required String activityLevel,
  }) async {
    final json = await _client.post('/auth/signup', body: {
      'name': name,
      'gender': gender,
      'age': age,
      'height': height,
      'weight': weight,
      'activity_level': activityLevel,
    });
    final token = json['token'] as String;
    final user = User.fromJson(json['user'] as Map<String, dynamic>);
    await _storage.write(key: _tokenKey, value: token);
    return (user: user, token: token);
  }

  Future<String> login({required String userId}) async {
    final json = await _client.post('/auth/login', body: {'user_id': userId});
    final token = json['token'] as String;
    await _storage.write(key: _tokenKey, value: token);
    return token;
  }

  Future<User> fetchMe(String token) async {
    final json = await _client.get('/users/me', token: token);
    return User.fromJson(json);
  }

  Future<String?> readStoredToken() => _storage.read(key: _tokenKey);

  Future<void> logout() => _storage.delete(key: _tokenKey);
}
