# API 연동 코드 가이드 (인수인계용)

이 문서는 지금까지 만들어진 Flutter 쪽 API 연동 코드가 **어느 파일이 어떤 백엔드 엔드포인트와
연결되어 있는지, 어떤 의미인지**를 정리한 문서다. 디자인/화면 UI를 새로 만드는 개발자가 이
문서를 보고 기존 서비스 코드를 그대로 갖다 쓸 수 있게 하는 게 목적이다.

전체 API 계약(요청/응답 필드, 에러 코드 등)의 최종 소스는 백엔드 레포의
`backend/FRONTEND_API_GUIDE.md`와 서버 실행 중 `/api-docs`(Swagger UI)다. 이 문서는 그걸
"Flutter 코드의 어디에 이미 구현돼 있는지"로 연결하는 인덱스 역할만 한다 — 필드 하나하나의
최종 확인은 항상 저 두 곳을 참고할 것.

---

## 1. 레이어 구조

```
lib/
├── core/            공통 HTTP 레이어 — 새 서비스를 추가할 때도 이걸 그대로 씀
│   ├── api_config.dart      base URL 상수
│   ├── api_client.dart      get/post/patch 래퍼, 응답 계약 파싱
│   └── api_exception.dart   실패 응답을 감싸는 예외 타입
├── models/          응답을 파싱하는 타입 (일부 엔드포인트만 모델화, 아래 §4 참고)
├── services/        엔드포인트별 호출 함수 모음 — 새 화면은 이 클래스들만 호출하면 됨
├── providers/
│   └── auth_provider.dart   로그인 상태 + JWT 토큰 전역 관리 (Provider 패턴)
└── screens/         화면. 실사용 화면과 "API 확인용" 디버그 화면이 섞여 있음 (§5 참고)
```

새 화면에서 API를 부르는 흐름은 항상: **`screens/` 위젯 → `services/`의 메서드 호출 →
필요하면 `context.read<AuthProvider>().token`으로 토큰 전달 → 결과를 화면 상태에 반영**.
`core/`나 `services/`를 다시 만들 필요는 없고, 없는 엔드포인트만 §6 방식대로 추가하면 된다.

---

## 2. 인증 토큰 사용법

```dart
final token = context.read<AuthProvider>().token; // String? — null이면 비로그인 상태
```

- `AuthProvider`(`lib/providers/auth_provider.dart`)가 앱 전역에서 로그인 상태를 들고 있다.
  `main.dart`에서 `ChangeNotifierProvider(create: (_) => AuthProvider()..tryAutoLogin())`로
  이미 등록돼 있어서, 어느 화면에서든 `context.read<AuthProvider>()` / `context.watch<...>()`로
  꺼내 쓸 수 있다.
- `auth.user` (`User?` 모델, `lib/models/user.dart`)에 로그인한 유저의 프로필이 들어있다.
- 인증이 필요한 서비스 메서드는 전부 `token` 파라미터를 받는다 — 비워서 호출하면 백엔드가
  401을 던진다.

---

## 3. 서비스 ↔ 엔드포인트 매핑 표

| 서비스 파일 | 메서드 | HTTP | 엔드포인트 | 인증 | 비고 |
| --- | --- | --- | --- | --- | --- |
| `services/auth_service.dart` | `signup(...)` | POST | `/auth/signup` | ✗ | 성공 시 토큰을 `flutter_secure_storage`에 저장까지 함 |
| | `login(userId: ...)` | POST | `/auth/login` | ✗ | 응답에 유저 정보 없음 — 로그인 후 `fetchMe` 필요 |
| | `fetchMe(token)` | GET | `/users/me` | ✓ | |
| | `readStoredToken()` / `logout()` | — | (로컬) | — | secure storage 읽기/삭제, API 호출 아님 |
| `services/bakery_service.dart` | `fetchNearby(...)` | GET | `/bakeries` | ✗ | `userWeight` 넘기면 `estimated_walk_calories`/`suggested_walk` 채워짐 |
| | `fetchDetail(bakeryId)` | GET | `/bakeries/:id` | ✗ | `tour_info`는 raw Map, TourAPI 미등록이면 `null` |
| | `fetchItems(bakeryId)` | GET | `/bakeries/:id/items` | ✗ | |
| `services/tour_service.dart` | `startTour(token)` | POST | `/tours` | ✓ | 8단계 흐름 1단계 |
| | `addStop(...)` | POST | `/tours/:tourId/stops` | ✓ | 8단계 흐름 6~7단계, 클라이언트 실측값(distance_m/duration_minutes/steps) 필요 |
| | `completeTour(token, tourId)` | PATCH | `/tours/:tourId/complete` | ✓ | 8단계 흐름 8단계, `balance_kcal` 확정 |
| | `getTour(token, tourId)` | GET | `/tours/:tourId` | ✓ | 리포트 카드용 `stops[]` 포함 |
| `services/food_log_service.dart` | `create(...)` | POST | `/food-logs` | ✓ | 실제 섭취 확정 시점에만 호출 (예상치는 저장 안 함) |
| | `list(token, {from, to})` | GET | `/food-logs` | ✓ | |
| `services/calories_service.dart` | `getBalance(token)` | GET | `/calories/balance` | ✓ | 0-kcal 밸런스 바 실시간 값 |
| | `calculatePreview(...)` | POST | `/calories/calculate` | ✗ | 미리보기 단건 계산 |
| `services/stats_service.dart` | `daily(token, {date})` | GET | `/stats/daily` | ✓ | |
| | `weekly(token, {to})` | GET | `/stats/weekly` | ✓ | |
| `services/sightseeing_service.dart` | `nearby(...)` | GET | `/tour/nearby` | ✓ | **`/tour`(단수, TourAPI 프록시)** — `/tours`(투어 세션)와 다른 리소스 |
| | `spotDetail(token, contentId)` | GET | `/tour/spots/:contentId` | ✓ | |

이 표에 없는 엔드포인트(`PATCH /users/me`)는 아직 클라이언트 서비스 메서드가 없다 — §6 참고.

---

## 4. 모델 vs raw Map 사용 기준

| 타입 모델 있음 (`models/`) | raw `Map<String, dynamic>` 그대로 반환 |
| --- | --- |
| `User` (`user.dart`) | 투어 관련 전체 응답 (tour 시작/도착/완료/상세) |
| `Bakery` (`bakery.dart`) | `bakeries/:id`의 `tour_info` |
| `BreadItem` (`bread_item.dart`) | `food-logs`, `calories/balance`, `stats/*`, `tour/nearby`, `tour/spots/:id` 전체 응답 |
| `ActivityLevel` (문자열 상수 3개) | `suggested_walk` (bakeries 응답 내부 필드) |

오른쪽 목록은 필드가 많고 화면 요구사항에 따라 어떻게 쪼갤지가 아직 정해지지 않아서 일부러
모델화하지 않고 raw Map으로 남겨뒀다. **새 화면을 만들면서 이 데이터를 UI에 바인딩하려면,
그 화면에 맞는 모델 클래스를 새로 만들어서 `Map.fromJson` 패턴(기존 `Bakery`/`BreadItem`
참고)으로 감싸는 걸 권장** — raw Map을 위젯 트리 깊숙이 그대로 넘기지 말 것.

---

## 5. 화면 파일 안내 (`screens/`)

| 파일 | 상태 | 설명 |
| --- | --- | --- |
| `login_screen.dart` | 실사용 | user_id 기반 간편 로그인 (MVP, 비밀번호 없음) |
| `signup_screen.dart` | 실사용 | 회원가입 폼 |
| `home_screen.dart` | 실사용 | 로그인 후 첫 화면. 현재는 아래 디버그 화면 3개로 가는 버튼만 있음 — **디자인 새로 입힐 때 이 버튼들을 실제 네비게이션(빵집 검색 화면 등)으로 교체하면 됨** |
| `bakery_list_screen.dart` | **디자인 없음, API 확인용** | `BakeryService.fetchNearby` 호출 예제. 위경도는 대전 시내 좌표로 하드코딩(GPS 미연동) |
| `bakery_detail_screen.dart` | **디자인 없음, API 확인용** | `fetchDetail` + `fetchItems`를 나란히 호출하는 예제 |
| `tour_flow_screen.dart` | **디자인 없음, API 확인용** | 투어 시작→도착기록→섭취기록→밸런스조회→완료→상세조회 **6단계를 순서대로 호출하는 예제** — 새 투어 화면을 만들 때 호출 순서와 각 단계에서 이전 응답의 어떤 필드(`tour.id`, `stop.id` 등)를 다음 요청에 넘겨야 하는지 그대로 참고하면 됨 |
| `stats_screen.dart` | **디자인 없음, API 확인용** | 통계 + TourAPI 프록시 호출 예제 |

"디자인 없음" 4개 화면은 텍스트만 나열하는 검증용 코드다. 실제 UI 개발 시 그대로 쓰지 말고
**API 호출 부분(어떤 서비스를, 어떤 순서로, 어떤 파라미터로 부르는지)만 참고해서 새 위젯으로
교체**하는 걸 권장한다.

---

## 6. 새 엔드포인트 추가하는 법

기존 서비스 파일과 같은 패턴을 따르면 된다. 예: `PATCH /users/me`를 추가한다면
`auth_service.dart`에 아래처럼 메서드 하나 추가:

```dart
Future<User> updateMe(String token, Map<String, dynamic> fields) async {
  final json = await _client.patch('/users/me', token: token, body: fields);
  return User.fromJson(json);
}
```

`ApiClient`(`core/api_client.dart`)가 성공/실패 응답 파싱(평문 snake_case JSON vs
`{error:{code,message}}`)을 이미 처리해주므로, 서비스 메서드는 엔드포인트 경로와 바디만
신경 쓰면 된다.

---

## 7. 플랫폼 관련 주의사항

- **Android 실기기(USB)**: 폰에서 `http://localhost:4000`은 폰 자신을 가리키므로, PC에서
  `adb reverse tcp:4000 tcp:4000`을 실행해둬야 폰의 앱이 PC 백엔드에 붙는다(에뮬레이터라면
  대신 `10.0.2.2`를 쓰면 됨 — `core/api_config.dart` 주석 참고). USB가 재연결되면 이 설정이
  풀릴 수 있어 매번 확인 필요.
- **웹(Chrome)**: 백엔드 `src/app.ts`에 `cors()` 미들웨어를 열어뒀다(로컬 개발용, 모든
  origin 허용 — JWT Bearer 인증이라 쿠키 기반 세션이 없어서 안전). 그대로 유지하면 됨.
- `core/api_config.dart`의 `apiBaseUrl`이 `http://localhost:4000/api`로 하드코딩돼 있다.
  실제 배포/원격 서버로 붙일 땐 이 값을 바꿔야 한다.

---

## 8. 에러 처리 패턴

모든 서비스 메서드는 실패 시 `ApiException`(`core/api_exception.dart`)을 던진다:

```dart
try {
  await bakeryService.fetchDetail(id);
} on ApiException catch (e) {
  // e.statusCode (400/401/404/500), e.code, e.message
  // e.message는 그대로 사용자에게 보여줘도 되는 한국어 문장
}
```

`null`이 정상인 필드(`suggested_walk`, `tour_info` 등)를 에러로 착각하지 말 것 — 백엔드
`FRONTEND_API_GUIDE.md` §6 참고.

---

## 9. 아직 없는 것 (다음 개발자가 채워야 할 부분)

- `PATCH /users/me` 클라이언트 서비스 메서드 (프로필 수정 화면 필요 시)
- 실제 지도/GPS 연동 — 지금 좌표는 전부 하드코딩(대전 시내)이고, 백엔드도 마찬가지로 프론트가
  GPS를 넣어줄 거라 가정하고 만들어져 있음
- 네이버 지도 딥링크(`url_launcher`), 백그라운드 만보기/GPS 속도 필터, 촬영 후 갤러리 저장
  — 백엔드 API가 아예 없는 영역이라 (`backend/FRONTEND_API_GUIDE.md` §4) 이 레포에 아직
  코드 없음
- 상태 관리는 지금 `AuthProvider` 하나뿐 — 빵집/투어 등 새 도메인 상태를 전역으로 관리하려면
  같은 `ChangeNotifier` 패턴으로 `BakeryProvider`/`TourProvider` 등을 추가하는 걸 권장
  (강제는 아님, 화면 로컬 상태로도 충분하면 그렇게 해도 됨)
