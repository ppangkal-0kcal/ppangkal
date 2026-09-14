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
| | `fetchMe(token)` | GET | `/users/me` | ✓ | 회원가입 직후에도 호출 — signup 응답엔 id/name/목표만 있음 |
| | `updateMe(token, fields)` | PATCH | `/users/me` | ✓ | 응답이 부분 필드라 성공 후 `fetchMe`로 전체 프로필 재조회 |
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

---

## 4. 모델

화면에서 쓰는 응답은 전부 `models/`의 모델 클래스(수동 `fromJson`)로 감싼다: `User`,
`Bakery`, `BreadItem`, `TourInfo`, `SuggestedWalk`, `Tour`, `TourStop`, `FoodLog`,
`CalorieBalance`, `DailyStats`, `WeeklyStats`, `BreadSelection`(클라이언트 전용 선택 상태),
`ActivityLevel`(문자열 상수 3개). 아직 화면이 없는 `tour/nearby`, `tour/spots/:id`만 raw Map으로
남아 있다 — 화면을 붙일 때 같은 패턴으로 모델을 추가할 것.

---

## 5. 화면·흐름 안내

| 화면 | 파일 | 호출 |
| --- | --- | --- |
| 로그인/회원가입 | `login_screen.dart`, `signup_screen.dart` (`widgets/auth_layout.dart`) | `/auth/*`, `/users/me` |
| 홈 (칼로리 잔액 + 투어 진입) | `home_screen.dart` | `/calories/balance` |
| 빵집 목록 | `bakery_list_screen.dart` | `/bakeries` (현재 위치, 실패 시 대전 중심 좌표) |
| 빵집 상세 | `bakery_detail_screen.dart` | `/bakeries/:id`, `/bakeries/:id/items`, 네이버 지도 딥링크 |
| 빵 메뉴 선택 | `bread_menu_screen.dart` | 없음 (예상 칼로리는 클라이언트 계산) |
| 투어 진행 | `tour_progress_screen.dart` | `/tours`, `/tours/:id/stops` |
| 섭취 확정 | `food_confirm_screen.dart` | `/food-logs`, 갤러리 저장 |
| 투어 리포트 | `tour_report_screen.dart` | `/tours/:id/complete`, `/tours/:id` |
| 통계 | `stats_screen.dart` | `/stats/daily`, `/stats/weekly` |
| 마이페이지 | `profile_screen.dart` | `PATCH /users/me` |

투어 API 호출 순서와 ID 전달(`tour_id`, `tour_stop_id`)은 화면이 아니라
`controllers/tour_flow_controller.dart`가 전담한다. 화면을 갈아엎어도 이 컨트롤러는 그대로 둘 것.
`tour_flow_screen.dart`는 `kDebugMode`에서만 열리는 raw 호출 검증용이다.

---

## 6. 새 엔드포인트 추가하는 법

기존 서비스 파일과 같은 패턴을 따르면 된다. 예: `auth_service.dart`의 `updateMe`:

```dart
Future<User> updateMe(String token, Map<String, dynamic> fields) async {
  await _client.patch('/users/me', token: token, body: fields);
  return fetchMe(token);
}
```

`ApiClient`(`core/api_client.dart`)가 성공/실패 응답 파싱(평문 snake_case JSON vs
`{error:{code,message}}`)을 이미 처리해주므로, 서비스 메서드는 엔드포인트 경로와 바디만
신경 쓰면 된다.

---

## 7. 플랫폼 관련 주의사항

- **Android 실기기**: 절차는 `DEVICE_TESTING.md`, 실행은 `tool/run_on_device.ps1`. USB는
  `adb reverse tcp:4000 tcp:4000` 후 localhost, Wi-Fi는 PC LAN IP를 `API_BASE_URL`로 넣는다
  (에뮬레이터는 `10.0.2.2`). USB 재연결 시 reverse 설정이 풀린다.
- **웹(Chrome)**: 백엔드 `src/app.ts`에 `cors()` 미들웨어를 열어뒀다(로컬 개발용, 모든
  origin 허용 — JWT Bearer 인증이라 쿠키 기반 세션이 없어서 안전). 그대로 유지하면 됨.
- `core/api_config.dart`의 `apiBaseUrl`은 `--dart-define=API_BASE_URL`로 바꾼다 (기본값
  `http://localhost:4000/api`). 배포 서버도 코드 수정 없이 빌드 옵션으로 붙인다.

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

## 9. 백엔드 API 없이 클라이언트가 구현한 것 (`backend/FRONTEND_API_GUIDE.md` §4)

| 기능 | 파일 | 비고 |
| --- | --- | --- |
| GPS 속도 필터 (20km/h 초과 제외) | `services/walk_filter.dart` | 순수 Dart, `test/walk_filter_test.dart`. 정확도 50m 초과 fix·5분 초과 공백은 무시, 1km/h 미만은 대기 시간으로 보고 시간에서 제외 |
| 위치 추적 + 상주 알림 | `services/location_service.dart` | `geolocator`의 Android 위치 포그라운드 서비스로 화면 꺼짐에도 유지 (아래 참고) |
| 만보기 | `services/step_counter.dart` | `pedometer`. 첫 값(부팅 후 누적)은 기준점으로만 사용, 차량 이동 중 걸음은 버림. 웹/데스크톱은 `FakeStepCounter` |
| 네이버 지도 길찾기 | `services/naver_map_launcher.dart` | `nmap://route/walk` → 실패 시 `m.map.naver.com` 검색 |
| 섭취 사진 | `services/food_photo_service.dart` | `image_picker` 촬영 → `gal`로 "빵칼" 앨범에만 저장, 업로드 없음 |

센서가 없거나 권한이 거부되면 투어는 실패하지 않고 대체값을 쓴다: 거리 = 걸음 × 0.7m,
시간 = 경과 시각. 권한 프롬프트는 15초 안에 응답이 없으면 거부로 간주한다.

**백그라운드 방식 결정**: 스펙 문서는 `flutter_background_service`를 적었지만, 추적 로직이 UI
isolate의 `TourFlowController`에 있어 별도 isolate로 옮기면 상태 동기화가 크게 복잡해진다.
대신 `geolocator`의 포그라운드 서비스(상주 알림 + wake lock)로 위치 스트림을 유지하고, 걸음은
센서 허브가 누적하는 `TYPE_STEP_COUNTER`로 받는다. 백엔드 `FRONTEND_API_GUIDE.md` §4 갱신을
backend 세션에서 제안할 것.

## 10. 아직 없는 것

- 네이버 지도 Client ID — NCP 콘솔 발급 필요 (없으면 지도 모드는 대체 목록, `DEVICE_TESTING.md` §0)
- 투어 히스토리 — 백엔드에 투어 목록 API 없음
- 실기기에서 확인 필요: 화면 꺼짐 상태 추적 지속, 네이버 지도 앱/웹 폴백 URL, 갤러리 저장
