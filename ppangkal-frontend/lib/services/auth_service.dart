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

  /// PATCH /users/me — 체중/키/나이/활동량/목표 칼로리 부분 수정. 응답은
  /// 수정된 필드만 담고 있어 (name/gender 없음) [User]로 바로 파싱할 수
  /// 없으므로, 성공 후 [fetchMe]로 전체 프로필을 다시 받아온다.
  Future<User> updateMe(String token, Map<String, dynamic> fields) async {
    await _client.patch('/users/me', token: token, body: fields);
    return fetchMe(token);
  }

  Future<String?> readStoredToken() => _storage.read(key: _tokenKey);

  Future<void> logout() => _storage.delete(key: _tokenKey);
}
