# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this
repository.

## Repository status

A freshly scaffolded Flutter project (`flutter create`, Flutter 3.44.8 stable, Dart 3.12.2).
Only the default counter-app boilerplate exists under `lib/` so far — the actual 빵칼(0-kcal)
screens/services have not been built yet. Common commands:

- `flutter pub get` — install dependencies.
- `flutter run` — run on a connected device/emulator (see **Toolchain status** below for what's
  currently available).
- `flutter analyze` — static analysis (flat `analysis_options.yaml`, default `flutter_lints`).
- `flutter test` — widget/unit tests under `test/`.
- `flutter build <platform>` — release build.
- `flutter doctor -v` — check toolchain health.

**Project identity**: package name `ppangkal`, org `com.ppangkal` (Android applicationId /
iOS bundle id `com.ppangkal.ppangkal`).

## Repo location: `C:\ppangkal\ppangkal-frontend`, sibling to `backend`

Both repos now live under `C:\ppangkal` (ASCII-only, no spaces): this one at
`C:\ppangkal\ppangkal-frontend`, backend at `C:\ppangkal\backend`. Originally this Flutter project
was kept on a separate ASCII path because the backend repo lived under
`OneDrive\바탕 화면\관광데이터\backend` (Korean characters + a space), which crashed Flutter's Dart
analysis server (LSP) — `flutter analyze` failed with `FormatException: Unterminated string`
because the LSP byte-stream channel miscounts the message-length header once the file URI gets
percent-encoded (multi-byte Korean chars + space; the same class of problem is known to also hit
Android/Gradle builds on Windows). The backend repo has since been moved to `C:\ppangkal\backend`,
so that specific hazard no longer applies — but keep both repos on ASCII-only, space-free paths
regardless; re-verify with `flutter analyze` first if a path change is ever considered.

Consequence: this is still a **separate git repo** from `backend` (no shared history, no
submodule) — being siblings on disk doesn't change that. Not yet pushed to GitHub — still
local-only, standalone `git init`, no commits yet.

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

## Toolchain status (as of scaffolding, verify with `flutter doctor -v` if stale)

- Flutter SDK installed at `C:\flutter` (added to user PATH) — ASCII path, keep it that way for
  the same LSP-encoding reason as above.
- Working now, no extra setup: **Windows desktop** and **Chrome (web)** run targets.
- **Android**: SDK present at `%LOCALAPPDATA%\Android\sdk`, but `cmdline-tools` component is
  missing and licenses aren't accepted (`flutter doctor` flags both). Since this app is
  mobile-first (background service, pedometer, GPS), Android is the real target platform — finish
  that setup before doing serious device-facing work; Chrome/Windows runs are fine for pure-UI
  iteration in the meantime.
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
- 실제 화면 동작 확인은 `flutter run -d chrome`(빠른 UI 반복) 또는
  `flutter run -d windows`로 — Android 에뮬레이터는 위 **Toolchain status** 정리 전까지 사용 불가.
- 백엔드 연동 확인이 필요하면 backend repo를 별도로 `npm run dev`로 띄워두고 이 앱에서
  `http://localhost:4000/api`로 호출해 확인한다 (두 레포는 별개 프로세스/레포이므로 동시 실행 필요).

### 5. 위험한 작업 전에는 확인부터 — `.claude/settings.json`의 `permissions.ask`로도 강제됨

항상 먼저 물어보고 진행: `git commit`/`git push`, `pubspec.yaml` 의존성 추가/삭제, 네이티브
설정(`android/**`, `ios/**`) 수정, 파일/디렉터리 삭제.

물어보지 않고 바로 진행: `lib/**`/`test/**` 안에서의 파일 수정, `flutter analyze`/`flutter test`.

### 6. 세션 마무리 습관 — `/recap`

### 7. 리뷰는 "위젯 하나"가 아니라 "흐름 전체"로 — `/review`
