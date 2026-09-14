import 'package:url_launcher/url_launcher.dart';

/// 5단계 네이버 지도 외부 호출 (FRONTEND_API_GUIDE.md §2, §4). No map SDK
/// and no routing API — hands walking directions off to the Naver Map app,
/// or the mobile web if the app isn't installed.
class NaverMapLauncher {
  static const _appName = 'com.ppangkal.ppangkal';

  /// Returns false only if neither the app nor the browser could be opened.
  static Future<bool> walkTo({
    required double latitude,
    required double longitude,
    required String name,
  }) async {
    final appUri = Uri(
      scheme: 'nmap',
      host: 'route',
      path: '/walk',
      queryParameters: {
        'dlat': '$latitude',
        'dlng': '$longitude',
        'dname': name,
        'appname': _appName,
      },
    );
    try {
      if (await launchUrl(appUri, mode: LaunchMode.externalApplication)) return true;
    } catch (_) {
      // Not installed (or web target) — fall through to the web fallback.
    }

    final webUri = Uri.https('m.map.naver.com', '/search2/search.naver', {'query': name});
    return launchUrl(webUri, mode: LaunchMode.externalApplication);
  }
}
