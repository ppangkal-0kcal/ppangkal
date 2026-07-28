/// Backend base URL. `/health` lives outside this prefix; every other
/// endpoint in FRONTEND_API_GUIDE.md is under it.
///
/// NOTE: `localhost` only resolves to the host machine on Chrome/Windows
/// desktop (the two working dev targets per ppangkal-frontend/CLAUDE.md).
/// Once the Android emulator toolchain is finished, this needs to become
/// `10.0.2.2` there instead — the emulator's `localhost` points at itself,
/// not the host.
const String apiBaseUrl = 'http://localhost:4000/api';
