/// Mirrors the backend's uniform failure shape:
/// `{ "error": { "code": "...", "message": "..." } }` — see
/// FRONTEND_API_GUIDE.md §5. `message` is already a user-presentable
/// Korean sentence, safe to show as-is.
class ApiException implements Exception {
  final int statusCode;
  final String code;
  final String message;

  const ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
  });

  @override
  String toString() => 'ApiException($statusCode, $code, $message)';
}
