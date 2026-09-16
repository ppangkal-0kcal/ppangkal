/// Form validators shared by signup, login, and 마이페이지 이메일 연결 —
/// same rules as `backend/src/services/passwordService.ts`.
class Validators {
  Validators._();

  static const int minPasswordLength = 8;

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return '이메일을 입력하세요';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v)) return '이메일 형식이 올바르지 않습니다';
    return null;
  }

  static String? password(String? value) {
    if ((value ?? '').length < minPasswordLength) return '비밀번호는 $minPasswordLength자 이상이어야 합니다';
    return null;
  }
}
