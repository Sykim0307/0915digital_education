-- 기프티콘에 실제 가격(amount)을 저장할 수 있도록 컬럼 추가
-- Supabase 대시보드 > SQL Editor 에서 실행하세요. (Google 로그인 사용자용 gifts 테이블에만 필요합니다.
-- 로그인 안 한 로컬/서버 모드는 JSON으로 저장되어 스키마 변경이 필요 없어요.)

alter table gifts add column if not exists amount numeric;
