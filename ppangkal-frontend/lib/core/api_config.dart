// Build-time configuration, injected with `--dart-define` so the same code
// runs on Chrome, a USB-connected phone, and a phone on Wi-Fi without edits:
//
//   flutter run --dart-define=API_BASE_URL=http://192.168.0.10:4000/api \
//               --dart-define=NAVER_MAP_CLIENT_ID=<NCP Maps Client ID>
//
// Or keep them in `dart_defines.json` (gitignored, see
// `dart_defines.example.json`) and pass `--dart-define-from-file=dart_defines.json`.

/// Backend base URL. `/health` lives outside this prefix; every other
/// endpoint in FRONTEND_API_GUIDE.md is under it.
///
/// The `localhost` default works on Chrome and on a USB phone after
/// `adb reverse tcp:4000 tcp:4000`. A phone on Wi-Fi needs the PC's LAN IP.
const String apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:4000/api');

/// Naver Cloud Platform Maps (Dynamic Map) Client ID for the bakery map.
/// Empty means no in-app map — the list screen falls back to a Naver Map
/// app/web handoff instead (see `BakeryMapView`).
const String naverMapClientId = String.fromEnvironment('NAVER_MAP_CLIENT_ID');
