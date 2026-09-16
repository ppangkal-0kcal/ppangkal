# 출시 가이드 (원스토어 / 구글 플레이)

## 0. 출시 전 코드 상태 (2026-09-15 준비 완료)

| 항목 | 상태 |
| --- | --- |
| 출시 서명 키 | `tool/create_release_key.ps1`로 생성. 키스토어는 저장소 밖 `%USERPROFILE%\.ppangkal-release\`, 설정은 `android/key.properties` (git 제외) |
| 앱 이름 | `빵칼` (Android `android:label`, iOS `CFBundleDisplayName`) |
| 앱 아이콘 | 디자이너 아이콘(리포지토리 루트 `빵칼_아이콘.png`) — `tool/generate_app_icon.py`로 Android/iOS 아이콘 생성 |
| 패키지명 | `com.ppangkal.ppangkal` — **등록 후 절대 변경 금지** |
| 위치 정보 | 빵집 거리 계산을 기기 안에서 수행 — 사용자 좌표를 서버로 보내지 않음 |
| 업로드용 빌드 | `tool/build_store_release.ps1` — 출시 키 서명·배포 주소를 검사하고 AAB/APK 생성 |

## 1. 출시 키 (한 번만)

```powershell
cd ppangkal-frontend
.\tool\create_release_key.ps1
```

- 키스토어와 비밀번호 백업 파일이 `%USERPROFILE%\.ppangkal-release\`에 생긴다.
- **이 폴더 전체를 즉시 안전한 곳(비밀번호 관리자, 개인 클라우드 등)에 백업한다.** 잃어버리면 같은 앱으로 업데이트를 올릴 수 없다.
- 다른 PC에서 빌드할 때는 폴더를 복사하고 `key.properties.backup`을 `android/key.properties`로 복사한다 (`storeFile` 경로가 다르면 수정).
- 원스토어/구글 플레이에 "앱 서명키 관리"를 맡기는 경우, 이 키는 **업로드 키**가 된다.

## 2. 빌드

**반드시 백엔드가 먼저 배포돼 있어야 한다.** 이 버전의 앱은 빵집 목록을 사용자 좌표 없이 요청한다
(`GET /api/bakeries`, lat/lng 생략). 이를 지원하지 않는 이전 서버에서는 목록이 400 오류로 뜨지 않는다.

```powershell
# dart_defines.json: API_BASE_URL = https 배포 주소, NAVER_MAP_CLIENT_ID = NCP 키(있으면)
.\tool\build_store_release.ps1           # AAB + APK
```

| 결과물 | 경로 | 용도 |
| --- | --- | --- |
| AAB | `build/app/outputs/bundle/release/app-release.aab` | 원스토어(권장)·구글 플레이 |
| APK | `build/app/outputs/flutter-apk/app-release.apk` | 원스토어 APK 등록, 직접 설치 |

원스토어는 AAB/APK 둘 다 받지만 **AAB로 한 번 올리면 APK로 되돌릴 수 없다.**

### 업데이트할 때
`pubspec.yaml`의 `version: 1.0.0+1`에서 `+` 뒤 빌드 번호를 **매번 올린다** (`1.0.1+2`, `1.0.2+3` …). 같은 번호는 스토어가 거부한다.

### 기존 테스트 설치본과의 관계
지금까지 폰에 설치한 테스트 앱은 **디버그 키**로 서명됐다. 출시 키로 서명한 앱은 그 위에 덮어 설치되지 않으므로
(`INSTALL_FAILED_UPDATE_INCOMPATIBLE`), 테스트 폰에서는 기존 앱을 삭제한 뒤 설치한다.

## 3. 스토어 등록에 필요한 것 (코드 밖)

- [ ] 원스토어 개발자 계정·개발자 정보
- [ ] **개인정보처리방침 URL** — 아래 "수집·전송 항목"을 반영
- [ ] 스크린샷, 앱 설명, 카테고리, 연령 등급
- [ ] (권장) 네이버 지도 Client ID — NCP 콘솔에 `com.ppangkal.ppangkal` 등록
- [ ] (권장) 백엔드 유료 플랜 — Render 무료 플랜은 유휴 시 잠들어 첫 요청이 30~60초 걸린다

### 수집·전송 항목 (개인정보처리방침 작성용, 코드 기준)
| 항목 | 서버 전송 | 서버 저장 | 비고 |
| --- | --- | --- | --- |
| 이름·성별·나이·키·체중·활동 수준 | O | O | 회원가입/프로필, 목표 칼로리 계산 |
| 현재 위치(GPS) | **X** | X | 빵집 거리 계산·투어 속도 필터 모두 기기 안에서 처리 |
| 투어 구간 걸음 수·거리·시간 | O | O | 좌표 없이 합산값만 |
| 섭취한 빵·수량 | O | O | 칼로리 밸런스/통계 |
| 섭취 사진 | X | X | 기기 갤러리에만 저장 |
| 네이버 지도 길찾기 | 빵집 좌표만 네이버 지도 앱에 전달 | — | 사용자 위치 아님 |

위치정보를 서버로 보내지 않더라도, 기기에서 위치를 이용하는 서비스의 위치정보법상 신고 필요 여부는 출시 전에 별도로 확인할 것.
