# 화면 구현 현황 보고서

작성일: 2026-07-29. 조사 범위: `lib/` 전체, `API_INTEGRATION.md`, `CLAUDE.md`,
`../backend/FRONTEND_API_GUIDE.md`, `../backend` 내 라우트/스키마 실제 코드. 코드 수정은
수행하지 않았고 조사·문서 작성만 진행함.

## 0. 사전 확인 사항 — 지시받은 문서 중 실존하지 않는 파일

지시에 포함된 `../backend/idea.md`, `../backend/tech-stack.md`는 현재 백엔드 레포
(`C:\src\ppangkal\backend`)에 **실제로 존재하지 않음**. `backend/` 최상위에는
`FRONTEND_API_GUIDE.md`와 `README.md`만 있음 (`Glob **/idea.md`, `**/tech-stack.md` 결과
모두 0건). 라우트 소스(`tours.routes.ts`, `bakeries.routes.ts` 등)의 주석에는 여전히
`idea.md §2`, `tech-stack.md(v2)` 같은 참조가 남아있어, 두 파일이 한때 존재했다가 삭제됐거나
경로가 바뀐 것으로 추정됨 — 단정하지 않고 "확인 필요"로 남김. 이 보고서의 기획/8단계 흐름
관련 서술은 `FRONTEND_API_GUIDE.md`와 `backend/README.md`(기술 스택·핵심 도메인 로직 절)만
근거로 작성함.

CLAUDE.md에 적힌 절대경로(`C:\ppangkal\...`)도 현재 작업 디렉터리(`C:\src\ppangkal\...`)와
다름 — 레포 위치가 이동된 것으로 보이나 내용 자체는 유효함.

---

## 1. 현재 구현 상태 분류

| 파일 | 상태 | 근거 |
| --- | --- | --- |
| `lib/screens/login_screen.dart` | **완성** | `TextField` + `FilledButton`로 실제 폼 UI 구성, `AuthProvider.login()` 호출 후 성공/실패 분기(스낵바) 처리까지 있음. API 확인용 텍스트 덤프 없음. |
| `lib/screens/signup_screen.dart` | **완성** | `Form`+`TextFormField` validator 포함한 실제 회원가입 폼, 제출 시 `AuthProvider.signup()` 호출, 실패 시 에러 메시지 노출. |
| `lib/screens/home_screen.dart` | **완성 (단, 범위는 "인증 성공 확인"에 한정)** | 실제 유저 정보(이름, 목표 칼로리, ID) 표시 + 로그아웃 버튼은 동작하는 UI. 다만 파일 상단 주석(9~11행)에 "Placeholder post-login screen"이라 명시돼 있고, 본문은 디버그 화면 3개로 가는 버튼뿐 — 칼로리 잔액 바 등 실제 홈 화면 기능은 없음. §2의 "홈" 요구사항 기준으로는 미착수로 봐야 함. |
| `lib/screens/bakery_list_screen.dart` | **임시** | 파일 상단 주석에 "Data-verification screen only — no design pass yet"로 명시. `Text('id: ...')` 나열 방식, 위경도 하드코딩(36.3504, 127.3845). |
| `lib/screens/bakery_detail_screen.dart` | **임시** | 주석에 "Data-verification only" 명시. `detail.entries.map((e) => Text('${e.key}: ${e.value}'))`로 raw Map을 그대로 텍스트 덤프. |
| `lib/screens/tour_flow_screen.dart` | **임시** | 주석에 "Data-verification only" 명시. 버튼 1개로 6단계 API를 순서대로 호출하고 결과를 `SelectableText`로 로그 출력. 하드코딩된 테스트 ID(`bak_sungsimdang`, `itm_bak_sungsimdang_소보로빵`) 사용. |
| `lib/screens/stats_screen.dart` | **임시** | 위와 동일한 로그-덤프 패턴. `daily`/`weekly`/`tour/nearby`/`tour/spots` 호출을 순차 실행. |

미착수(파일 자체 없음) 화면은 §2 표에서 별도 정리.

---

## 2. 화면별 구현 상태 표

8단계 흐름과 통계/마이페이지 요구사항을 기준으로 정리함. "API 백엔드 실존" 열은 실제
라우트 파일(`backend/src/routes/*.ts`)을 읽고 확인한 결과임 (문서만 보고 단정하지 않음).

| 화면 | 상태 | 파일 경로 | 필요한 API | 백엔드 실존 여부 |
| --- | --- | --- | --- | --- |
| 홈(칼로리 잔액 바) | **미착수** | 없음 — `home_screen.dart`는 디버그 진입점만 있고 밸런스 바 없음 | `GET /calories/balance` | ✅ 존재 (`calories.routes.ts:69`) — 서비스 메서드(`CaloriesService.getBalance`)까지는 있으나 홈 화면에 연결 안 됨 |
| 빵집 목록 | **임시(API 확인용)** | `bakery_list_screen.dart` | `GET /bakeries` | ✅ 존재 (`bakeries.routes.ts:43`), `sort=distance/rating/recommended` 3종 이미 지원 |
| 빵집 상세 | **임시(API 확인용)** | `bakery_detail_screen.dart` | `GET /bakeries/:id`, `GET /bakeries/:id/items` | ✅ 존재 (`bakeries.routes.ts:142`, `:203`) |
| 빵 메뉴 선택 | **미착수** | 없음 — `bakery_detail_screen.dart`가 `fetchItems` 결과를 텍스트로만 나열, 선택/수량 UI 없음 | `GET /bakeries/:id/items` (조회는 있음, "선택" UI가 없음) | ✅ 조회 엔드포인트는 존재, 선택 자체는 서버 API 필요 없음(클라이언트에서 계산만 하면 됨 — `FRONTEND_API_GUIDE.md` §2 4단계) |
| 투어 진행 | **임시(API 확인용), 실사용 UI로 보면 미착수** | `tour_flow_screen.dart` | `POST /tours`, `POST /tours/:id/stops` | ✅ 존재 (`tours.routes.ts:26`, `:68`) |
| 섭취 확정 + 0-kcal 밸런스 결과 | **미착수** | 없음 | `POST /food-logs`, `GET /calories/balance` | ✅ 둘 다 존재 (`foodLogs.routes.ts:37`, `calories.routes.ts:69`) — 서비스 레이어까지는 있으나 화면 없음 |
| 투어 종료 리포트 | **미착수** | 없음 (`tour_flow_screen.dart`가 `completeTour`/`getTour`를 호출은 하지만 로그 덤프일 뿐 리포트 UI 아님) | `PATCH /tours/:id/complete`, `GET /tours/:id` | ✅ 둘 다 존재 (`tours.routes.ts:147`, `:205`) |
| 일별/주별 통계 | **임시(API 확인용)** | `stats_screen.dart` | `GET /stats/daily`, `GET /stats/weekly` | ✅ 존재 (`stats.routes.ts:40`, `:90`) |
| 마이페이지 | **미착수** | 없음 | `GET /users/me` (프로필), `GET /calories/balance` 등 조합 예상 | ✅ `GET /users/me` 존재, 서비스 메서드(`fetchMe`)도 있음 — 화면만 없음 |
| 프로필 수정 | **미착수** | 없음 | `PATCH /users/me` | ✅ 백엔드에 구현돼 있음 (`users.routes.ts:66-91`, weight/height/age/activity_level/daily_goal_calories 부분 수정) — **프론트 서비스 메서드가 없는 것만 사실**, `AuthService`에 `updateMe` 계열 메서드 부재 확인(grep 결과 0건) |
| 투어 히스토리 | **미착수** | 없음 | 투어 "목록" 조회 엔드포인트 | ⚠️ **없음 확인** — `tours.routes.ts`에는 `POST /`, `POST /:tourId/stops`, `PATCH /:tourId/complete`, `GET /:tourId`(단건)만 있고, 사용자의 전체 투어 목록을 반환하는 `GET /tours` 같은 엔드포인트가 없음. §6 백엔드 문의 참고 |

---

## 3. API 커버리지 점검

### 3-1. 프론트 서비스 레이어에 메서드가 없는 엔드포인트

`FRONTEND_API_GUIDE.md` §3 전체 엔드포인트 표(18개) 대비 `lib/services/*.dart`를 대조한 결과:

| 엔드포인트 | 상태 |
| --- | --- |
| `PATCH /users/me` | **없음.** `auth_service.dart`에 `signup`/`login`/`fetchMe`/`readStoredToken`/`logout`만 있고 프로필 수정 메서드 없음. 인수인계 노트(`API_INTEGRATION.md` §9 "아직 없는 것")와 실제 코드가 일치함 — 사실로 확인됨. |

나머지 17개 엔드포인트(`/auth/signup`, `/auth/login`, `/users/me` GET, `/bakeries`,
`/bakeries/:id`, `/bakeries/:id/items`, `/tours`, `/tours/:id/stops`, `/tours/:id`,
`/tours/:id/complete`, `/calories/calculate`, `/calories/balance`, `/food-logs` POST/GET,
`/stats/daily`, `/stats/weekly`, `/tour/nearby`, `/tour/spots/:id`)는 전부 `lib/services/`에
대응 메서드가 존재함 (`API_INTEGRATION.md` §3 표와 실제 서비스 파일을 하나씩 대조 완료).

### 3-2. 프론트가 호출하는데 문서에 없는 엔드포인트

**없음.** `lib/services/`의 모든 `_client.get/post/patch` 호출 경로를 `FRONTEND_API_GUIDE.md`
§3 표와 대조한 결과, 문서에 없는 엔드포인트를 호출하는 코드는 발견되지 않음.

---

## 4. 기존 코드 컨벤션 정리

### 상태관리
**Provider**(`ChangeNotifier`) 패턴, 현재 인스턴스는 `AuthProvider` 1개뿐. `setState`/Riverpod/Bloc
혼용 없음. 단, 데이터 확인용 화면들(`bakery_list_screen.dart` 등)은 전역 상태 없이
`StatefulWidget` + 로컬 `Future` 필드로 처리:

```dart
// lib/providers/auth_provider.dart:11-16
class AuthProvider extends ChangeNotifier {
  final AuthService _service;
  AuthProvider({AuthService? service}) : _service = service ?? AuthService();
  AuthStatus status = AuthStatus.unknown;
```

```dart
// lib/screens/bakery_list_screen.dart:20-21
class _BakeryListScreenState extends State<BakeryListScreen> {
  late Future<List<Bakery>> _future;
```

### API 서비스 레이어 구조
`lib/core`(공통 HTTP) → `lib/services`(엔드포인트별 클래스) → `lib/screens`(UI) 3단 구조.
서비스 클래스는 전부 `ApiClient`를 주입받는 동일한 생성자 패턴을 따름:

```dart
// lib/services/bakery_service.dart:6-9
class BakeryService {
  final ApiClient _client;
  BakeryService({ApiClient? client}) : _client = client ?? ApiClient();
```

### 모델 클래스 작성 방식
`json_serializable`(코드 생성) 미사용 — 전부 수동 `factory X.fromJson(Map<String, dynamic> json)`.
snake_case → camelCase 변환은 필드 단위로 수동 매핑:

```dart
// lib/models/bakery.dart:41-49
distanceM: (json['distance_m'] as num?)?.toDouble(),
isOpenNow: json['is_open_now'] as bool?,
walkRecommended: json['walk_recommended'] as bool?,
```

필드가 많거나 화면 요구사항이 미정인 응답(투어 전체, `food-logs`, `stats/*`, `tour/*`)은
모델화하지 않고 `Map<String, dynamic>` raw 그대로 반환 — `API_INTEGRATION.md` §4에 문서화돼
있고 실제 서비스 코드(`tour_service.dart` 전체가 `Future<Map<String, dynamic>>` 반환)와 일치함.

### 에러 처리 패턴
모든 실패는 `ApiException`(`core/api_exception.dart`)으로 통일, `ApiClient._send`에서
HTTP 상태코드 ≥400을 감지해 백엔드의 `{error:{code,message}}`를 그대로 파싱해 던짐:

```dart
// lib/core/api_client.dart:61-68
if (response.statusCode >= 400) {
  final error = decoded['error'] as Map<String, dynamic>?;
  throw ApiException(
    statusCode: response.statusCode,
    code: error?['code'] as String? ?? 'UNKNOWN_ERROR',
    message: error?['message'] as String? ?? '알 수 없는 오류가 발생했습니다.',
  );
}
```

화면에서는 `on ApiException catch (e)`로 잡아 `e.message`(백엔드가 이미 한국어로 내려줌)를
스낵바에 그대로 노출 (`login_screen.dart:39-42`, `signup_screen.dart:52-55`). 디버그 화면들은
`catch (e)`로 뭉뚱그려 잡아 로그에 문자열로 append (`tour_flow_screen.dart:85-86`).

### 라우팅 방식
순수 `Navigator.push`/`pushReplacement` + `MaterialPageRoute`. `go_router`, named route
테이블 모두 없음:

```dart
// lib/screens/home_screen.dart:48-50
onPressed: () => Navigator.of(context).push(
  MaterialPageRoute(builder: (_) => const BakeryListScreen()),
),
```

### 테마·색상 정의 위치
테마 정의는 `lib/main.dart` 딱 한 곳뿐:

```dart
// lib/main.dart:21
theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange)),
```

화면 파일들 안에서는 `Color(0x...)` 같은 하드코딩된 색상값이 검색되지 않음(`Colors.deepOrange`
1건 외 없음) — 대신 `Theme.of(context).textTheme` 참조(`home_screen.dart:37`)만 사용. 별도
`AppTheme`/`AppColors` 상수 파일은 없음.

---

## 5. 구조적 문제점

- **"디자인 없음" 4개 화면은 API 호출 로직과 렌더링이 완전히 한 위젯에 섞여 있음.** 예를 들어
  `tour_flow_screen.dart`는 `_run()` 메서드 안에서 6개 API를 순차 호출하며 `setState`로 로그를
  누적하는데, 디자인 담당자가 이 파일을 그대로 고치기 시작하면 UI 코드와 호출 순서/파라미터
  로직을 구분하기 어려워 실수로 API 호출 순서(`tour_id`→`tour_stop_id` 전달 등)를 깨뜨리기
  쉬움. API_INTEGRATION.md §5도 "그대로 쓰지 말고 API 호출 부분만 참고해 새 위젯으로 교체"를
  권장하고 있으나, 로직/표현이 분리돼 있지 않아 "참고만 하기"가 실제로는 전체 재작성에
  가까움 — 최소한 각 단계의 호출+파라미터 구성을 UI 프레임워크에 의존하지 않는 별도 함수/클래스
  (컨트롤러 성격)로 뽑아두면 디자인 교체 시 안전망이 될 수 있음.
- **`home_screen.dart`가 실제 홈 화면이 아니라 디버그 허브다.** §2 요구사항의 "홈(칼로리 잔액
  바)"을 만들려면 이 파일 자체를 새로 쓰거나 큰 폭으로 바꿔야 함 — 지금 상태로 새 화면들을
  이어붙이면 디버그 버튼 3개가 실제 화면 사이에 계속 남아있게 될 위험이 있음.
- **색상/크기 하드코딩은 현재 시점에는 문제로 확인되지 않음.** 시드컬러 1곳(`main.dart:21`)
  외에 하드코딩된 `Color`/`EdgeInsets` 상수가 화면 전반에 흩어져 있지 않아(각 화면이 대체로
  기본 `Material` 위젯 + `Theme.of(context)` 사용) 테마 교체 자체의 걸림돌은 적어 보임. 다만
  지금 테마가 딱 하나뿐이라 "여러 테마를 교체 가능하게" 만드는 인프라(예: `AppTheme` 정의,
  다크모드 대응)는 아직 전혀 없음 — 필요해지면 새로 설계해야 함.
- **파일 크기 자체는 문제 아님.** 가장 큰 화면 파일도 130줄 내외(`signup_screen.dart`)로,
  위젯이 큰 파일에 뭉쳐 있는 문제는 현재 관찰되지 않음.
- **Raw `Map<String, dynamic>` 응답을 위젯 트리에 그대로 흘리는 패턴**(`bakery_detail_screen.dart`
  의 `detail.entries.map(...)`, `tour_flow_screen.dart`의 `$tour`/`$stop` 문자열 보간)이 "임시"
  화면 전반에 있음. `API_INTEGRATION.md` §4가 이미 "새 화면에서는 raw Map을 위젯 깊숙이 넘기지
  말고 모델 클래스를 만들라"고 권고하고 있으므로, 이 원칙을 실제로 지키는지가 디자인 인계 이후
  코드 품질을 가르는 지점이 될 것으로 보임(현재는 지켜지지 않은 상태로 남아있음 — 검증용
  코드라서 의도된 것).
- **`core/api_config.dart`의 주석이 최신 상태와 다름.** 9행 주석은 "Android 에뮬레이터
  구축이 끝나면 `10.0.2.2`로 바꿔야 한다"는 내용인데, `CLAUDE.md`의 최신 Toolchain 상태는
  실기기 + `adb reverse`로 이미 확인이 끝난 상태(에뮬레이터 경로 언급 없음) — 주석이 실제
  운용 방식(실기기/`adb reverse`)을 반영하지 못하고 있어 다음에 이 파일을 만지는 사람이
  혼동할 수 있음. 코드 동작 자체에는 영향 없음.

---

## 6. 백엔드에 문의할 사항

- **투어 히스토리 목록 조회 엔드포인트가 있는지.** `backend/src/routes/tours.routes.ts`를 직접
  읽은 결과 `POST /tours`, `POST /tours/:tourId/stops`, `PATCH /tours/:tourId/complete`,
  `GET /tours/:tourId`(단건) 4개만 존재하고, 사용자의 과거 투어 전체를 나열하는 엔드포인트
  (`GET /tours` 목록형)는 코드상 없음. "투어 히스토리" 화면을 만들려면 이게 필요한데, 없다면
  추가해야 하는지 확인 필요.
- **게이미피케이션(스탬프/티어) 관련 API가 존재하는지.** `backend/prisma/schema.prisma`
  전체를 확인한 결과 `User`/`Bakery`/`BreadItem`/`TouristSpot`/`SpotImage`/`Tour`/`TourStop`/
  `FoodLog` 7개 테이블뿐이고 스탬프·티어·배지 관련 테이블/필드는 전혀 없음. 기획에 이 기능이
  있다면 DB 스키마 자체가 없는 상태이므로 백엔드 작업이 선행돼야 함 — 프론트만으로는 판단
  불가.
- **빵집 목록의 필터(카테고리/가격대 등) 지원 여부.** 정렬(`sort=distance|rating|recommended`)은
  `bakeries.routes.ts:31`에서 확인했듯 이미 구현돼 있으나, 정렬 외의 필터 파라미터는 라우트
  코드에 전혀 없음(반경 필터만 있음). 디자인 단계에서 카테고리/가격 필터 UI가 필요하다면
  백엔드 확장이 먼저 필요한지 확인 필요.
- **`idea.md`/`tech-stack.md` 실종 경위.** §0에서 언급했듯 두 파일이 라우트 주석에는 계속
  인용되는데 실제로는 없음 — 삭제/이동됐는지, 아니면 프론트 레포의 CLAUDE.md 경로 설명이
  갱신이 안 된 것인지 백엔드 세션에서 확인 필요 (이번 작업 지시에도 "구현이 문서와 달라지면
  조용히 다르게 만들지 말고 문서를 먼저 고치자고 제안" 규칙이 있으므로, 정식 확인이 있어야
  8단계 흐름 관련 세부 사항을 문서 대신 코드로만 판단하지 않아도 됨).
