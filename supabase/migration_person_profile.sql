-- 사람 프로필 세분화: 생일/결혼기념일(기혼 여부)/입사일/학번/군번/학력/성향 태그 컬럼 추가
-- Supabase 대시보드 > SQL Editor 에서 실행하세요. (Google 로그인 사용자용 people 테이블에만 필요합니다.
-- 로그인 안 한 로컬/서버 모드는 JSON으로 저장되어 스키마 변경이 필요 없어요.)

alter table people add column if not exists birthday text;
alter table people add column if not exists marital_status text default 'single';
alter table people add column if not exists wedding_anniversary text;
alter table people add column if not exists join_date text;
alter table people add column if not exists student_id text;
alter table people add column if not exists military_id text;
alter table people add column if not exists education text;
alter table people add column if not exists personality_tags text[];

-- 기존에 저장돼있던 기념일(anniversary)은 생일로 이관
update people set birthday = anniversary where birthday is null and anniversary is not null;
