# 빵칼 (0-kcal)

대전 빵집 투어 + 칼로리 밸런스 트래킹 서비스. 빵을 먹은 만큼 걸어서 상쇄하는 "0-kcal 밸런스"
컨셉의 여행 가이드 앱이다. 전체 기획은 `backend/idea.md`, 아키텍처는 `backend/tech-stack.md`
참고.

이 저장소는 **모노레포**로, 백엔드와 프론트엔드가 각각 독립된 프로젝트로 들어있다 (별개 배포
단위 — 서로 import하지 않는다).

```
ppangkal/
├── backend/            Node + Express + Prisma(PostgreSQL/Supabase) API 서버
└── ppangkal-frontend/  Flutter 클라이언트 (iOS/Android/Web/Windows)
```

## 시작하기 전에

두 프로젝트 모두 비밀값(`.env`)이 git에 올라가 있지 않다. **DB 접속 정보, TourAPI 서비스키,
Cloudflare R2 자격증명은 별도 채널(Slack/1Password 등)로 전달받아야 한다** — GitHub Issue나
커밋 메시지에 절대 붙여넣지 말 것.

## 1. 백엔드 실행

```bash
cd backend
npm install
npx prisma generate
```

`.env` 파일을 만들고(`.env.example` 참고) 전달받은 값을 채운다:
- `DATABASE_URL` — Supabase Postgres 접속 문자열
- `JWT_SECRET`
- `TOUR_API_SERVICE_KEY` — 한국관광공사 TourAPI (필수, 공모전 제출 요건)
- `R2_ACCOUNT_ID` / `R2_ACCESS_KEY_ID` / `R2_SECRET_ACCESS_KEY` / `R2_BUCKET_NAME` / `R2_PUBLIC_URL` — Cloudflare R2 (빵 이미지 업로드용, 관리자 스크립트에서만 씀)

```bash
npm run dev
```

확인:
- `http://localhost:4000/health` → `{"status":"ok"}`
- `http://localhost:4000/api-docs` → Swagger UI로 전체 API 스펙 확인 가능
- `curl "http://localhost:4000/api/bakeries?lat=36.3504&lng=127.3845&radius_km=10"` → 빵집 목록(Supabase 데이터) 확인

자세한 커맨드/작업 규칙은 `backend/CLAUDE.md`, API 계약 전체는 `backend/FRONTEND_API_GUIDE.md` 참고.

## 2. 프론트엔드 실행

```bash
cd ppangkal-frontend
flutter pub get
flutter analyze
flutter test
```

빠르게 확인하려면 웹으로:
```bash
flutter run -d chrome
```

`lib/core/api_config.dart`의 `apiBaseUrl`이 로컬에서 띄운 백엔드(`http://localhost:4000/api`)를
가리키는지 확인. Android 실기기로 테스트할 땐 `adb reverse tcp:4000 tcp:4000`으로 포트포워딩
필요(에뮬레이터는 `10.0.2.2` 사용 — 파일 내 주석 참고).

확인 순서: 회원가입 → 홈 화면(목표 칼로리 표시) → "bakeries API 확인" 버튼으로 빵집 목록이
실제로 뜨는지.

어떤 화면/코드가 어떤 API와 연결되는지는 `ppangkal-frontend/API_INTEGRATION.md`에 정리돼 있다
— 새 화면 만들 때 이 문서부터 볼 것. 작업 규칙은 `ppangkal-frontend/CLAUDE.md` 참고.

## 브랜치 전략 (Git Flow)

- **`main`** — 항상 배포 가능한 상태. 직접 커밋하지 않는다.
- **`develop`** — 통합 브랜치. 새 작업은 전부 여기서 갈라져 나가고, 여기로 다시 합쳐진다.
- **`feature/<설명>`** — `develop`에서 분기, 작업 끝나면 `develop`로 PR/머지 (예:
  `feature/bakery-list-ui`, `feature/tour-flow-ui`).
- **`release/<버전>`** — 배포 준비할 때 `develop`에서 분기, QA 끝나면 `main`과 `develop` 양쪽에 머지.
- **`hotfix/<설명>`** — `main`에서 긴급 수정할 때만 분기, 끝나면 `main`과 `develop` 양쪽에 머지.

작업 시작할 땐 `git checkout develop && git pull && git checkout -b feature/작업명`으로 시작하고,
직접 `main`/`develop`에 push하지 말고 PR로 머지하는 걸 권장.

## 참고 문서 모음

| 문서 | 내용 |
| --- | --- |
| `backend/idea.md` | 서비스 기획, 8단계 흐름, 0-kcal 밸런스 개념 |
| `backend/tech-stack.md` | 아키텍처 결정 사항과 이유 |
| `backend/FRONTEND_API_GUIDE.md` | 프론트가 봐야 하는 API 계약 전체 |
| `ppangkal-frontend/API_INTEGRATION.md` | 프론트 코드 ↔ API 엔드포인트 매핑, 서비스 구조 |
| `backend/CLAUDE.md` / `ppangkal-frontend/CLAUDE.md` | 각 프로젝트 작업 습관/경계 (Claude Code용이지만 사람이 봐도 유용) |
