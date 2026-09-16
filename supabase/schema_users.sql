-- 봉투장부: 구글 로그인 사용자별 데이터 분리를 위한 스키마
-- Supabase 대시보드 > SQL Editor 에서 실행하세요.
-- (기존 schema.sql의 app_data 테이블은 로그인 없이 쓰던 로컬 서버용이라 그대로 둬도 되고, 필요 없으면 나중에 지워도 됩니다.)

create table if not exists entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  person text not null,
  date date not null,
  event_type text not null,
  direction text not null check (direction in ('gave','received')),
  amount numeric not null,
  closeness int,
  is_mutual boolean default false,
  reaction text,
  memo text,
  created_at timestamptz not null default now()
);
alter table entries enable row level security;
create policy "entries_owner" on entries
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create table if not exists gifts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  person text not null,
  direction text not null check (direction in ('gave','received')),
  name text not null,
  tier text not null,
  date date not null,
  expiry date,
  used boolean default false,
  reaction text,
  memo text,
  created_at timestamptz not null default now()
);
alter table gifts enable row level security;
create policy "gifts_owner" on gifts
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create table if not exists people (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  age text,
  anniversary text, -- 구버전 필드, birthday로 대체됨 (하위 호환용으로 남겨둠)
  birthday text,
  marital_status text default 'single',
  wedding_anniversary text,
  join_date text,
  student_id text,
  military_id text,
  education text,
  workplace text,
  personality text,
  personality_tags text[],
  recent_issue text,
  unique (user_id, name)
);
alter table people enable row level security;
create policy "people_owner" on people
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create table if not exists recommendations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  person text,
  tier text,
  helpful boolean,
  advice text,
  created_at timestamptz not null default now()
);
alter table recommendations enable row level security;
create policy "recommendations_owner" on recommendations
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
