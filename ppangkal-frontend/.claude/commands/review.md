---
description: 변경된 코드를 흐름 전체 기준으로 리뷰 (CLAUDE.md §7)
---
현재 변경사항(git diff)을 위젯/함수 하나가 아니라 "흐름 전체" 기준으로 리뷰해줘.
변경된 화면/서비스가 속한 전체 흐름(사용자 입력 → 상태 변경 → API 호출 →
응답 파싱 → 화면 반영, 관련 있다면 백그라운드 센서/위치 흐름까지)을 각
단계별로 따라가면서:

1. CLAUDE.md §3 계약(백엔드 API는 snake_case 평문 JSON 성공 응답, 실패는
   `{ error: { code, message } }` — FRONTEND_API_GUIDE.md 기준으로 파싱하는지)을 지키는지
2. CLAUDE.md §1 경계를 넘지 않았는지
3. 버그, 엣지 케이스, 네이밍/컨벤션 위반, 보안 이슈(토큰 저장 방식, 민감정보 로깅 등)

발견 사항은 막힘(blocking) / 계약위반(contract) / 개선(nit)으로 분류하고,
각각 파일:라인 + 최소 수정안을 붙여줘.

!git diff HEAD
