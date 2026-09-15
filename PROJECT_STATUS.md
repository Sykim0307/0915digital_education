# 봉투장부 — 프로젝트 현황 (2026-09-15 세션 종료 시점)

## 지금 되는 기능

**앱 기능** (`bongtu-ledger.html`)
- 대시보드: 경조사비 순잔액 + 선물 환산 순잔액을 합친 "총 정산금액", 사람별 통합 정산 리스트
- 기록(경조사비): 입력/수정/삭제, 사람별 필터, 행 클릭 시 상세 모달(날짜·유형·금액·친밀도·반응·메모)
- 계산기: 이름 입력 시 "같은 경조사 유형"으로 받은 과거 금액을 우선 매칭(없으면 최근 금액으로 대체), 친밀도 보정
- 기프티콘: 등록/사용여부 체크/유효기간 임박 알림(14일), 규칙기반 파싱 + AI 텍스트 분석 + **사진 업로드 AI 분석**(카톡 캡처)
- 사람: 프로필(나이/직장/성향/최근이슈/기념일), 반응(좋음/보통/별로) 평균 기반 화이트/블랙리스트 자동 분류, AI 선물 추천 + 👍/👎 피드백
- 도움말: 탭별 사용법 + 저장 방식 설명 + 로컬 서버/Google 로그인 설정 가이드
- 데이터 내보내기(JSON 다운로드) / 가져오기(파일 선택 후 병합, 기존 데이터 안 지움)

**저장 방식 4단계 자동 감지** (우선순위 순서)
1. `cloud` — claude.ai Artifact로 열었을 때 (Claude의 db capability, 기기·계정 동기화)
2. `supabaseAuth` — Google 로그인 상태일 때 (Supabase, 로그인 계정 전용 데이터, RLS로 격리)
3. `server` — 로컬 서버(`node server.js`)로 열었을 때, 로그인 안 한 상태 (`data.json` 자동 저장, 또는 `.env` 있으면 Supabase의 `app_data` 단일 테이블)
4. `local` — HTML 파일을 그냥 더블클릭해서 열었을 때 (브라우저 localStorage만)

**인프라**
- Node.js 서버 `server.js`: `.env`에 `SUPABASE_URL`/`SUPABASE_SERVICE_KEY`가 있으면 Supabase(`app_data` 테이블)를, 없으면 로컬 `data.json`을 자동으로 씀
- Supabase 프로젝트 연결됨: `https://yuxtiibyfntyiccokplt.supabase.co`
  - `app_data` 테이블: 비로그인 서버 모드용 (단일 JSON blob, service_role 키로만 접근, RLS로 외부 차단)
  - `entries` / `gifts` / `people` / `recommendations` 테이블: Google 로그인 사용자별 (RLS로 본인 데이터만 접근 가능)
- GitHub 저장소 초기 커밋 완료: `https://github.com/Sykim0307/0915digital_education.git` (로컬 `main` 브랜치, `origin` 연결됨) — **아직 push는 안 됨**

## 실행 방법

```
cd C:\Users\user\Desktop\project
node server.js
```
브라우저에서 `http://localhost:5173` 접속 (HTML 파일 더블클릭 금지).

⚠️ **지금 이 세션에서 켜둔 node 프로세스가 아직 백그라운드에 살아있을 수 있어요.** 새로 켜기 전에 먼저 기존 걸 내리세요:
```
Get-Process node | Stop-Process -Force
```

콘솔에 뜨는 메시지로 어떤 저장소를 쓰는지 확인:
- `저장소: Supabase (...)` → `.env` 있음, 정상
- `저장소: 로컬 파일 (...)` → `.env` 없거나 값이 비어서 파일로 폴백

**참고**: 이 세션에서는 새 PowerShell 창마다 `git`/`node` 명령이 바로 안 잡혀서 아래 줄을 먼저 실행해야 했음 (환경변수 PATH가 새로 설치된 직후라 갱신 필요했던 것으로 보임 — 재부팅하면 필요 없어질 수도 있음):
```
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
```

## 중요한 결정 사항

- **Vercel 서버리스 = 파일 쓰기 영속성 없음** → 로컬 `server.js`의 파일 기반 저장은 배포 환경에서 그대로 못 씀 → **Supabase(진짜 클라우드 DB)로 전환**하기로 결정. 로컬 개발 때부터 Supabase를 붙여두면 나중에 Vercel 배포해도 데이터 계층은 안 바뀜
- **data.json은 최초 1회만 git에 커밋**하고(지금은 목업+테스트 데이터 상태), 이후 로컬에서 바뀌는 내용은 git이 추적하지 않도록 `git update-index --assume-unchanged data.json` 처리함 (실제 개인 기록이 GitHub에 계속 쌓이는 걸 방지)
- **Google 로그인은 선택사항**으로 설계 — 로그인 안 하면 기존 로컬 파일/브라우저 저장 방식 그대로 동작. 사용자를 강제로 로그인시키지 않음
- **anon 키는 클라이언트 코드에 하드코딩**해도 안전 (공개되도록 설계된 키, RLS가 실제 보안 경계). **service_role 키는 절대 클라이언트에 넣지 않고 `.env`에만 두고 `.gitignore`로 git 제외**
- 비로그인용 `app_data`(단일 blob) 테이블과 로그인용 `entries/gifts/people/recommendations`(정규화 테이블) 테이블은 **서로 다른 용도로 별도 존재** — 헷갈리지 않기

## 아직 안 되는 것 / 미완료

1. **Google 로그인 최종 확인 안 됨** — Client Secret을 방금 입력하고 서버 재가동까지만 했고, 실제로 로그인 버튼을 눌러서 성공하는지는 이 세션에서 확인 못 하고 끝남
2. **GitHub push 안 됨** — 로컬 커밋까지는 완료(`Initial commit`), 실제 push는 브라우저 인증이 필요해서 사용자가 직접 실행해야 함:
   ```
   git push -u origin main
   ```
3. **Vercel 배포는 전혀 시작 안 함** — 나중에 진행하기로 미뤄둔 상태. 배포 시 Supabase 연결(anon 키는 이미 클라이언트에 있음, `.env`의 service_role 키는 Vercel 환경변수로 별도 설정 필요)과 Google OAuth의 Redirect URL / Authorized origin에 배포 도메인 추가가 필요함
4. **UI/UX 다듬기 작업 시작 못 함** — 사용자가 요청했었지만 Supabase/로그인 작업이 우선순위로 들어와서 미뤄짐
5. **claude.ai Artifact 버전이 뒤처져 있음** — Artifact는 Version 6(로컬 서버 모드 추가 직후)에서 멈춰 있고, 이후의 Supabase/사진AI분석 재사용/Google 로그인 관련 변경은 로컬 파일(`bongtu-ledger.html`)에만 반영됨. Artifact 링크로 열면 최신 기능이 안 보임 (다만 Artifact는 애초에 `cloud` 모드라 로그인 로직 자체가 필요 없음)

## 가장 먼저 할 다음 행동

**`http://localhost:5173`에서 "Google로 로그인" 버튼을 눌러서 실제로 로그인이 되는지 확인.**

- 성공하면: 화면 우측 상단 상태가 "Google 계정에 저장됨"으로 바뀌고 이메일이 표시됨 → 그다음 기존 기록(경조사비/선물/사람)을 하나 입력해보고 Supabase 대시보드의 `entries`/`gifts`/`people` 테이블에 실제로 쌓이는지 확인
- 또 에러가 나면: 에러 메시지 그대로 알려주면 이어서 디버깅
