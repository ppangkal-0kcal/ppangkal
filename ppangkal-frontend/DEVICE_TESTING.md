# 실기기 테스트 가이드 (Android)

코드·빌드 준비는 끝났다 (2026-09-14: debug/release APK 빌드 확인). 아래는 폰을 연결한 뒤 할 일이다.

## 0. 한 번만 준비

| 항목 | 방법 |
| --- | --- |
| 폰 USB 디버깅 | 설정 → 휴대전화 정보 → 소프트웨어 정보 → 빌드번호 7번 탭 → 개발자 옵션 → USB 디버깅 켜기 |
| 네이버 지도 키 (선택) | [NCP 콘솔 → Maps → Application](https://console.ncloud.com/maps/application) 등록, **Dynamic Map** 선택, Android 패키지 `com.ppangkal.ppangkal` / iOS Bundle ID `com.ppangkal.ppangkal` 입력 → Client ID를 `dart_defines.json`의 `NAVER_MAP_CLIENT_ID`에 넣기. 키가 없으면 지도 모드는 "네이버 지도 앱에서 보기" 목록으로 대체된다 (다른 기능은 전부 동작) |
| 설정 파일 | `dart_defines.example.json` → `dart_defines.json` 복사 (스크립트가 없으면 자동 생성, git 제외) |

## 1. 실행

```powershell
# 터미널 1 — 백엔드 (Supabase 연결)
cd backend; npm run dev

# 터미널 2 — 앱
cd ppangkal-frontend
.\tool\run_on_device.ps1            # USB: adb reverse 설정 후 실행 (권장)
.\tool\run_on_device.ps1 -Wifi      # 같은 Wi-Fi: PC LAN IP 사용 — Windows 방화벽 TCP 4000 인바운드 허용 필요
.\tool\run_on_device.ps1 -Release   # 릴리스 모드 (GPS·스크롤 성능 확인)
```

USB를 뽑았다 꽂으면 `adb reverse`가 풀린다 — API 호출이 전부 실패하면 스크립트를 다시 실행.

APK로 직접 설치할 때는 주소를 빌드에 넣어야 한다:
`flutter build apk --release --split-per-abi --dart-define-from-file=dart_defines.json`
→ `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`

## 2. 확인 체크리스트

**빵집·빵 정보 (이번 데이터 반영분)**
- [ ] 빵집 탭: 16곳이 사진·평점·메뉴 수와 함께 거리순으로 나온다 (반경 15km, 어썸80더대청은 "메뉴 준비 중")
- [ ] 지도 아이콘: 핀 16개가 보이고, 핀 탭 → 미리보기 카드 → 상세로 이동 (키 없으면 대체 목록)
- [ ] 빵집 상세: 외관 사진, 메뉴 사진 가로 스크롤, "추정" 칼로리 표시, 썸네일 탭 → 빵 상세 시트("걸어서 약 N분")
- [ ] 메뉴 선택: 빵/디저트 필터, 사진, 수량 선택 시 예상 칼로리 합계

**기기 기능**
- [ ] 첫 실행 시 위치 권한 → 허용하면 "대전 시내 기준" 안내 문구가 사라지고 실제 거리로 정렬
- [ ] 투어 시작 → 신체 활동(걸음) 권한, 알림 권한 → 상단에 "빵투어 진행 중" 상주 알림
- [ ] 실제로 걸으면 걸음·거리 증가, "GPS로 걸은 거리를 측정 중" 표시
- [ ] 화면을 끄고 5분 걸은 뒤 켜도 걸음·거리가 이어져 있다
- [ ] 버스/차로 이동하면 "빠르게 이동 중" 표시, 거리가 늘지 않는다
- [ ] 길찾기 → 네이버 지도 앱 도보 길안내가 열린다 (앱 삭제 상태에서는 모바일 웹이 열리는지도 확인)
- [ ] 섭취 확정 → 빵 사진 남기기 → 갤러리 "빵칼" 앨범에 저장
- [ ] 투어 종료 → 리포트, 홈/통계 숫자 갱신

문제가 생기면 `flutter logs` 또는 `adb logcat | Select-String flutter`로 로그 확인.

## 3. 알려진 제약

- 네이버 지도 인증 실패(키 오타, 패키지명 미등록, 무료 사용량 초과) 시 지도 모드 상단 카드에 사유가 표시된다.
- iOS는 Mac이 필요해 미확인. Info.plist 권한 문구·백그라운드 위치는 선언돼 있다.
- 파이룸 좌표는 원본 문서가 성심당 좌표를 복사해 둔 오류가 있어 주소 기준 근사값을 넣었다 — 현장에서 핀 위치 확인 필요
  (`backend/prisma/scripts/extract_bakery_docs.py`의 `BAKERY_OVERRIDES`).
