# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this
repository.

## Repository status

No longer boilerplate (as of 2026-07-28) — the counter-app default is gone. Currently implemented:
auth flow (`login_screen.dart`/`signup_screen.dart`/`home_screen.dart`, backed by
`AuthProvider`/`AuthService`, real screens), plus four **"디자인 없음" data-verification screens**
(`bakery_list_screen.dart`, `bakery_detail_screen.dart`, `tour_flow_screen.dart`,
`stats_screen.dart`) that exercise the rest of the API surface with plain `Text` dumps — these are
reference code for a design pass, not final UI; don't polish them, replace them. Full
service-layer ↔ endpoint mapping is in `API_INTEGRATION.md` — read that before adding a new
screen, it's the actual up-to-date map of what's built vs. what a new screen still needs to call.

Dependencies added beyond the Flutter defaults: `http`, `provider`, `flutter_secure_storage`.
Flutter 3.44.8 stable, Dart 3.12.2 (verify with `flutter --version` if this drifts). Common
commands:

- `flutter pub get` — install dependencies.
- `flutter run` — run on a connected device/emulator (see **Toolchain status** below for what's
  currently available).
- `flutter analyze` — static analysis (flat `analysis_options.yaml`, default `flutter_lints`).
- `flutter test` — widget/unit tests under `test/`.
- `flutter build <platform>` — release build.
- `flutter doctor -v` — check toolchain health.

**Project identity**: package name `ppangkal`, org `com.ppangkal` (Android applicationId /
iOS bundle id `com.ppangkal.ppangkal`).

## Repo location: `C:\ppangkal\ppangkal-frontend`, inside the `ppangkal` monorepo

Both this project and `backend` live under `C:\ppangkal` (ASCII-only, no spaces — kept that way
because a Korean-character/space OneDrive path used to crash Flutter's Dart analysis server; see
git history if the details matter again). **As of 2026-07-28 this is no longer a standalone git
repo** — `.git` here was removed and both projects were folded into one monorepo at
`github.com/ppangkal-0kcal/ppangkal` (pushed from `C:\ppangkal` as the repo root, `main` branch).
This repo's prior detailed history (there wasn't much — it had never been pushed anywhere) is
gone; `backend`'s old standalone history is still preserved at the old
`github.com/ppangkal-0kcal/backend` repo if ever needed, just no longer the actively-pushed copy.

Practical consequence: `git commit`/`git push` from inside `ppangkal-frontend/` now affect the
**shared monorepo** (also containing `backend/`) — always check `git status` from the repo root
(`C:\ppangkal`) before committing, not just this subfolder, since a change in one project's
working tree doesn't imply the other project's tree is clean.

## What this app is for

**빵칼 (0-kcal)** — Flutter client for a calorie-balance-aware bakery/travel guide for Daejeon.
Full product concept, the 8-step tour flow, and calorie-balance logic are documented in the
backend repo, not duplicated here:

- `C:\ppangkal\backend\idea.md` — service concept, 8-step flow, 0-kcal balance concept, roadmap.
- `C:\ppangkal\backend\tech-stack.md` — architecture rationale, including *why* there's no in-app
  map SDK and no server-side routing.
- `C:\ppangkal\backend\FRONTEND_API_GUIDE.md` — **the contract for this app**: which screen calls
  which endpoint, in what order, full endpoint table, and exactly what has no backend API and must
  be built client-side. Read this before wiring up any screen.
- These are read from the backend repo live (absolute path above) — treat them as the source of
  truth, don't copy/paste snapshots into this repo where they'd drift out of sync.

Target users: 20–40대 health-conscious travelers who want to eat local bakery food in Daejeon
without derailing a diet/calorie goal.

## Backend API

- Base URL (local dev): `http://localhost:4000/api` (`GET /health` outside the `/api` prefix).
- Auth: JWT via `Authorization: Bearer <token>`, obtained from `POST /api/auth/login`. Store it
  locally (e.g. `flutter_secure_storage`) — no refresh-token flow yet, 30-day expiry. No API keys
  live client-side (TourAPI calls are backend-only; Naver Map is a deep link, no key needed).
- Success responses: unwrapped snake_case JSON (`{ met_value, calories_burned, ... }`) — no
  `{ data: ... }` wrapper. Failure responses: always `{ "error": { "code": "...", "message": "..." } }`.
  Parse both shapes consistently — see `FRONTEND_API_GUIDE.md` §5 for the code table.
- `null` is a normal value for optional fields (`suggested_walk`, `tour_info`) — don't treat it as
  an error case.

## What this app must implement itself (no backend API — see `FRONTEND_API_GUIDE.md` §4)

- Background sensor tracking that survives screen-off (`flutter_background_service` + Android
  Foreground Service notification).
- Step counting (platform pedometer).
- GPS speed filter: only count movement ≤20km/h as walking (bike/bus speeds excluded); aggregate
  distance/duration/steps client-side and report the summary via `POST /api/tours/:tourId/stops`.
- Naver Map handoff via `url_launcher` deep link, with `m.map.naver.com` web fallback if the app
  isn't installed. **No embedded map SDK, no server-side routing** — this is a deliberate
  architecture decision (`tech-stack.md` §5), not a gap.
- Consumption photos: camera → device gallery only. Never uploaded; `food_logs` has no photo field.
- Map pin rendering for the bakery list screen is **still undecided** — backend only returns raw
  lat/lng. Don't pick a map SDK unilaterally; flag it for discussion first.

## Toolchain status (verify with `flutter doctor -v` if stale)

- Flutter SDK installed at `C:\flutter` (added to user PATH) — ASCII path, keep it that way for
  the same LSP-encoding reason as above.
- **Chrome (web)**: working, the fastest iteration loop. Backend has `cors()` wide open for this.
- **Windows desktop**: `flutter run -d windows` **fails** — Visual Studio ("Desktop development
  with C++" workload) isn't installed. Not fixed yet; not currently blocking anything since Chrome
  and Android both work.
- **Android**: **fully working now** (fixed 2026-07-28) — `cmdline-tools` installed, licenses
  accepted, SDK 36 + build-tools present. Tested live on a physical Samsung device
  (`SM_S928N`/API 36) over USB, full signup→home→bakeries flow confirmed. Two things to remember
  for physical-device testing specifically (not needed for the emulator):
  - `http://localhost:4000` on the phone means the phone itself, not the PC — run
    `adb reverse tcp:4000 tcp:4000` (over the same USB debugging connection) so the app's
    `apiBaseUrl` reaches the backend running on the dev machine. This **resets on USB
    reconnect/reboot** — if API calls start failing on-device, check this first before assuming a
    code bug.
  - Samsung phones need Windows to auto-resolve the "SAMSUNG Android ADB Interface" driver over
    USB; if `adb devices` shows nothing, toggling the phone's USB mode (notification shade → USB
    options) sometimes retriggers driver enumeration.
- **iOS**: not evaluated (Windows dev machine — iOS builds need a Mac or CI).

## Claude Code 작업 습관

`backend`와 동일한 5가지 습관을 이 프론트엔드 레포에 맞게 적용한다. 슬래시 커맨드는
`.claude/commands/`에 이미 있음 (`/goal`, `/plan`, `/recap`, `/review`, `/commit`).

### 1. 수정 범위 (경계) — `.claude/settings.json`의 `permissions`로도 강제됨

- 자유롭게 수정: `lib/**`, `test/**`
- 확인 필요 (`permissions.ask`): `pubspec.yaml`(의존성 변경), `flutter pub add/remove`,
  `flutter build`/`flutter run`(디바이스/에뮬레이터 실행)
- 절대 수정 금지: `build/**`(빌드 산출물), `android/**`/`ios/**`는 기본적으로 건드리지 않는다
  (네이티브 설정 변경이 필요하면 먼저 논의 — 특히 Android manifest의 백그라운드 서비스/위치 권한
  설정은 실수하면 조용히 깨지는 부분이라 신중하게).
- 백엔드 스펙 문서(`idea.md`, `tech-stack.md`, `FRONTEND_API_GUIDE.md`)는 이 레포 밖(backend repo)
  에 있으므로 이 레포의 `permissions`로는 강제되지 않는다 — 구현이 그 문서와 달라지면 조용히
  다르게 만들지 말고, 문서를 먼저 backend 세션에서 고치자고 제안한다.

### 2. 착수 전: 목표·완료 기준 고정 — `/goal`

새 화면/기능 착수 전 `/goal <설명>`으로 영역(`lib/screens`, `lib/services` 등)/대상 파일/DoD/
리스크를 3~5줄로 고정하고 바로 착수.

### 3. 계약 일관성 규칙

- API 응답 파싱은 `FRONTEND_API_GUIDE.md`의 성공/실패 모양을 그대로 따른다 — 래퍼를 새로
  만들지 않는다.
- 상태 관리는 **Provider**로 정함 (`lib/providers/auth_provider.dart`가 첫 사례). 새 도메인
  상태가 필요하면 같은 `ChangeNotifier` 패턴을 따른다.
- `lib/core`(HTTP 클라이언트) → `lib/services`(엔드포인트별 호출) → `lib/screens`(UI) 3단
  레이어 구조로 API 연동 코드를 짠다. 어떤 파일이 어떤 엔드포인트와 연결되는지, 디자인 담당
  개발자에게 인계할 내용은 `API_INTEGRATION.md`에 정리돼 있다 — 새 서비스 추가 시 이 문서도
  같이 갱신할 것.

### 4. 종단 검증 (verify before done)

- `flutter analyze` + `flutter test`로 기본 검증.
- 실제 화면 동작 확인은 `flutter run -d chrome`(빠른 UI 반복)로. `flutter run -d windows`는 지금
  안 됨(위 **Toolchain status** 참고). 실기기(Android)로 확인할 땐 `adb reverse tcp:4000 tcp:4000`
  먼저 걸어야 함 — 안 걸려있으면 앱에서 API 호출이 전부 실패함(코드 문제로 착각하지 말 것).
- 백엔드 연동 확인이 필요하면 `../backend`를 별도 터미널에서 `npm run dev`로 띄워두고 이 앱에서
  `http://localhost:4000/api`로 호출해 확인한다 (같은 모노레포 안이지만 여전히 별개 프로세스라
  둘 다 띄워야 함).

### 5. 위험한 작업 전에는 확인부터 — `.claude/settings.json`의 `permissions.ask`로도 강제됨

항상 먼저 물어보고 진행: `git commit`/`git push`, `pubspec.yaml` 의존성 추가/삭제, 네이티브
설정(`android/**`, `ios/**`) 수정, 파일/디렉터리 삭제.

물어보지 않고 바로 진행: `lib/**`/`test/**` 안에서의 파일 수정, `flutter analyze`/`flutter test`.

### 6. 세션 마무리 습관 — `/recap`

### 7. 리뷰는 "위젯 하나"가 아니라 "흐름 전체"로 — `/review`
