# 마음장부 (구 봉투장부) — 프로젝트 현황 (2026-09-16 기준)

## 지금 되는 기능

**앱 기능** (`bongtu-ledger.html`)
- 대시보드: 경조사비 순잔액 + 선물 환산 순잔액을 합친 "총 정산금액", 사람별 통합 정산 리스트
- 기록(경조사비): 입력/수정/삭제, 사람별 필터, 행 클릭 시 상세 모달(날짜·유형·금액·친밀도·반응·메모)
- 계산기: 이름 입력 시 "같은 경조사 유형"으로 받은 과거 금액을 우선 매칭(없으면 최근 금액으로 대체), 친밀도 보정
- 기프티콘: 등록/사용여부 체크/유효기간 임박 알림(14일), 규칙기반 파싱 + AI 텍스트 분석 + **사진 업로드 AI 분석**(카톡 캡처)
- 사람: 프로필(나이/직장/성향/최근이슈/기념일), 반응(좋음/보통/별로) 평균 기반 화이트/블랙리스트 자동 분류, AI 선물 추천 + 👍/👎 피드백
- 도움말: 탭별 사용법 + 저장 방식 설명 + 로컬 서버/Google 로그인 설정 가이드
- 데이터 내보내기(JSON 다운로드) / 가져오기(파일 선택 후 병합, 기존 데이터 안 지움)
- **Google 로그인 (Supabase Auth)**: 로그인 자체는 정상 동작 확인됨 (Google → Supabase 인증 성공, 이메일까지 정상 확인). 다만 로그인 후 리다이렉트 목적지 설정이 아직 안 맞음 (아래 "안 되는 것" 참고)

**저장 방식 4단계 자동 감지** (우선순위 순서)
1. `cloud` — claude.ai Artifact로 열었을 때 (Claude의 db capability, 기기·계정 동기화)
2. `supabaseAuth` — Google 로그인 상태일 때 (Supabase, 로그인 계정 전용 데이터, RLS로 격리)
3. `server` — 로컬 서버(`node server.js`)로 열었을 때, 로그인 안 한 상태 (`data.json` 자동 저장, 또는 `.env` 있으면 Supabase의 `app_data` 단일 테이블)
4. `local` — HTML 파일을 그냥 더블클릭해서 열었을 때 (브라우저 localStorage만)

**인프라**
- Node.js 서버 `server.js`: `.env`에 `SUPABASE_URL`/`SUPABASE_SERVICE_KEY`가 있으면 Supabase(`app_data` 테이블)를, 없으면 로컬 `data.json`을 자동으로 씀 (로컬 개발 전용)
- **Vercel 배포용 서버리스 함수 `api/data.js`** 추가됨 — `server.js`의 Supabase 연동 로직을 Vercel Functions 형태로 이식한 것 (로그인 안 한 배포 사이트 방문자용). `vercel.json`으로 `/` → `bongtu-ledger.html` 라우팅 설정
- Supabase 프로젝트 연결됨: `https://yuxtiibyfntyiccokplt.supabase.co`
  - `app_data` 테이블: 비로그인 서버/Vercel 모드용 (단일 JSON blob, service_role 키로만 접근, RLS로 외부 차단)
  - `entries` / `gifts` / `people` / `recommendations` 테이블: Google 로그인 사용자별 (RLS로 본인 데이터만 접근 가능)
- **GitHub push 완료됨**: `https://github.com/Sykim0307/0915digital_education.git` — `main` 브랜치, 로컬/원격 모두 최신 커밋(`7532273`)까지 일치
- **Vercel 배포 진행 중** — 배포 자체는 시도했으나, 이 세션에서 실제 배포 URL을 아직 공유받지 못함

## 실행 방법 (로컬 개발)

```
cd C:\Users\user\Desktop\project
node server.js
```
브라우저에서 `http://localhost:5173` 접속 (HTML 파일 더블클릭 금지).

⚠️ **9/15에 띄운 로컬 서버(PID 11820)가 지금도 계속 백그라운드에 켜져 있을 수 있어요.** 새로 켜기 전에 먼저 기존 걸 내리세요:
```
Get-Process node | Stop-Process -Force
```

콘솔에 뜨는 메시지로 어떤 저장소를 쓰는지 확인:
- `저장소: Supabase (...)` → `.env` 있음, 정상
- `저장소: 로컬 파일 (...)` → `.env` 없거나 값이 비어서 파일로 폴백

**참고**: 이 컴퓨터에서는 새 PowerShell 창마다 `git`/`node` 명령이 바로 안 잡혀서 아래 줄을 먼저 실행해야 했음:
```
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
```

## 중요한 결정 사항

- **Vercel 서버리스 = 파일 쓰기 영속성 없음** → 로컬 `server.js`의 파일 기반 저장은 배포 환경에서 그대로 못 씀 → **Supabase(진짜 클라우드 DB)로 전환**하기로 결정. `api/data.js`가 그 결과물
- **data.json은 최초 1회만 git에 커밋**하고, 이후 로컬 변경은 `git update-index --assume-unchanged data.json`으로 git이 추적하지 않게 처리함 (실제 개인 기록이 GitHub에 쌓이는 걸 방지)
- **Google 로그인은 선택사항**으로 설계 — 로그인 안 하면 기존 로컬 파일/브라우저 저장 방식 그대로 동작
- **anon 키는 클라이언트 코드에 하드코딩**해도 안전 (공개되도록 설계된 키, RLS가 실제 보안 경계). **service_role 키는 `.env`/Vercel 환경변수에만 두고 절대 클라이언트나 git에 넣지 않음**
- Vercel 환경변수 등록 시: `SUPABASE_URL`은 일반(Plain), `SUPABASE_SERVICE_KEY`는 **Secret/Sensitive**로 등록하기로 함
- 비로그인용 `app_data`(단일 blob) 테이블과 로그인용 `entries/gifts/people/recommendations`(정규화 테이블)은 서로 다른 용도로 별도 존재 — 헷갈리지 않기

## 아직 안 되는 것 / 미완료

1. **Google 로그인 리다이렉트 문제** — 로그인(Google↔Supabase 인증)은 성공하는데, 로그인 완료 후 죽어있는 `http://localhost:3000`으로 리다이렉트됨.
   - 원인: Supabase Authentication → URL Configuration의 **Site URL**이 아직 기본값(`http://localhost:3000`)으로 남아있고, 요청한 리다이렉트 주소(배포 도메인)가 **Redirect URLs** 허용 목록에 없어서 기본 Site URL로 튕겨나감
   - **해결하려면 실제 Vercel 배포 URL이 필요함** (아직 안 받음) → Site URL을 그 주소로 바꾸고, Redirect URLs에도 추가해야 함
2. **Vercel 배포 URL 미확인** — 배포를 진행 중이셨는데 정확한 URL을 공유받지 못하고 세션이 끊김. 배포가 됐는지, 환경변수(`SUPABASE_URL`, `SUPABASE_SERVICE_KEY`)를 Vercel에 등록했는지도 미확인
3. **UI/UX 다듬기 작업 시작 못 함** — 계속 뒤로 밀리는 중
4. **claude.ai Artifact 버전이 뒤처져 있음** — Version 6에서 멈춤, 이후 변경사항 미반영 (Artifact는 `cloud` 모드라 로그인 로직 자체가 불필요하긴 함)
5. **보안 메모**: 어제 세션 중 사용자가 실제 Supabase 세션 토큰(access_token/refresh_token/provider_token)을 채팅에 붙여넣은 적이 있음 — 로그아웃으로 세션 무효화 권장했으나 실제로 로그아웃했는지는 미확인

## 가장 먼저 할 다음 행동

**Vercel 배포 URL을 확인해서 알려주기.** 그러면:
1. Supabase 대시보드 → Authentication → URL Configuration → **Site URL**을 그 주소로 변경
2. **Redirect URLs**에도 그 주소 추가 (기존 `http://localhost:5173`은 유지)
3. Vercel 프로젝트에 `SUPABASE_URL`(Plain), `SUPABASE_SERVICE_KEY`(Secret) 환경변수가 등록됐는지 확인 — 안 됐으면 등록 후 Redeploy
4. 배포 사이트에서 Google 로그인 다시 테스트 → 로그인 후 정상적으로 배포 사이트로 돌아오는지 확인
5. 로그인 없이도 기록 추가가 되는지(`/api/data` 서버리스 함수 동작 확인)도 같이 테스트
