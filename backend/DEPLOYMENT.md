# 백엔드 배포 가이드

케이블 없이(LTE·야외) 실기기 테스트를 하기 위한 테스트 서버 배포 절차다. 서버는 상태가 없고
DB(Supabase)·사진(R2)·관광정보(TourAPI)는 전부 외부 서비스라, 컨테이너 하나만 띄우면 된다.

준비된 것 (2026-09-14 로컬 검증 완료):
- `backend/Dockerfile` — 운영 이미지. 로컬에서 빌드·기동·Supabase 조회·SIGTERM 종료까지 확인
- `render.yaml` (저장소 루트) — Render Blueprint
- `NODE_ENV=production`에서 `DATABASE_URL`/`JWT_SECRET`이 없으면 부팅 실패 (기본값으로 조용히 뜨지 않음)

## 1. Render에 올리기 (권장 — 무료, 싱가포르 리전, Docker 그대로)

1. PR이 `develop`에 머지돼 있어야 한다 (`render.yaml`은 `develop` 브랜치를 배포).
2. [render.com](https://render.com) 가입 → GitHub 연동에서 `ppangkal-0kcal/ppangkal` 저장소 접근 허용
3. Dashboard → **New → Blueprint** → 저장소 선택 → `render.yaml` 인식 → 환경변수 입력:

| 키 | 값 |
| --- | --- |
| `DATABASE_URL` | 로컬 `backend/.env`와 같은 Supabase **session pooler** 주소 (`...pooler.supabase.com:5432/...`) |
| `JWT_SECRET` | 새 긴 랜덤 문자열 권장 — PowerShell: `[Convert]::ToBase64String((1..48 \| % { Get-Random -Max 256 }))` |
| `TOUR_API_SERVICE_KEY` | 로컬 `.env`와 같은 값 |

   R2 키는 넣지 않는다 — 서버 런타임은 R2를 쓰지 않는다 (업로드는 관리자 로컬 스크립트 전용).
4. **Apply** → 빌드 로그에서 `빵칼 백엔드 서버 실행 중` 확인 → 발급된 주소(`https://ppangkal-api-xxxx.onrender.com`)로 확인:
   - `https://…/health` → `{"status":"ok"}`
   - `https://…/api/bakeries?lat=36.3504&lng=127.3845&radius_km=15` → 빵집 17곳
   - `https://…/api-docs` → Swagger

`JWT_SECRET`을 로컬과 다르게 하면, 로컬 서버로 로그인해 둔 앱은 한 번 로그아웃된다. 마이페이지의
로그인 ID로 다시 로그인하면 된다.

### 무료 플랜 주의
- 15분간 요청이 없으면 잠든다 → 다음 첫 요청이 30~60초 걸린다. 테스트 시작 전에 `/health`를 한 번 열어 깨워둘 것.
- 투어 중(요청 간격이 긴 경우)에도 잠들 수 있다. 실제 사용자 대상이면 유료 플랜(Starter)로 올린다.

## 2. 앱을 배포 서버로 빌드

`ppangkal-frontend/dart_defines.json`의 `API_BASE_URL`을 배포 주소로 바꾼다:

```json
{ "API_BASE_URL": "https://ppangkal-api-xxxx.onrender.com/api", "NAVER_MAP_CLIENT_ID": "" }
```

```powershell
cd ppangkal-frontend
.\tool\run_on_device.ps1 -Release     # localhost가 아니면 adb reverse 없이 그 주소를 쓴다
# 또는 APK로 설치
flutter build apk --release --split-per-abi --dart-define-from-file=dart_defines.json
adb install -r build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
```

HTTPS 주소라 방화벽·케이블과 무관하게 LTE에서도 동작한다.

## 3. 스키마가 바뀔 때

부팅 시 자동 마이그레이션은 하지 않는다 (공유 Supabase DB를 배포마다 건드리지 않기 위해).
`prisma/migrations`에 새 마이그레이션이 생겼으면, 배포 **전에** 로컬에서 한 번:

```powershell
cd backend
npx prisma migrate deploy     # .env의 DATABASE_URL = Supabase
```

빵집/메뉴 데이터 갱신은 서버 배포와 무관하다 — `prisma/scripts/importCuratedBakeries.ts`를 로컬에서 실행하면
DB에 바로 반영된다 (backend/CLAUDE.md "Curated bakery data").

## 다른 플랫폼

같은 `Dockerfile`로 Railway·Fly.io·Google Cloud Run에도 올릴 수 있다. 공통 요구사항:
- 컨테이너 포트는 `PORT` 환경변수 (기본 4000)
- 헬스체크 `GET /health`
- 환경변수는 위 표와 동일, `NODE_ENV=production`
