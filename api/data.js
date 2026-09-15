const { createClient } = require('@supabase/supabase-js');

const EMPTY_DATA = { entries: [], gifts: [], people: [], recommendations: [] };

function readBody(req) {
  return new Promise((resolve, reject) => {
    let data = '';
    req.on('data', chunk => { data += chunk; });
    req.on('end', () => resolve(data));
    req.on('error', reject);
  });
}

// 로그인하지 않은 방문자용 저장소 — 하나의 공유 문서(app_data/main)를 씁니다.
// (Google 로그인 사용자는 이 API를 쓰지 않고, 브라우저에서 Supabase의
//  entries/gifts/people/recommendations 테이블에 RLS로 보호된 채 직접 접근합니다.)
module.exports = async (req, res) => {
  const SUPABASE_URL = process.env.SUPABASE_URL;
  const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY;

  if (!SUPABASE_URL || !SUPABASE_SERVICE_KEY) {
    res.status(500).json({ ok: false, error: 'not_configured' });
    return;
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

  if (req.method === 'GET') {
    const { data, error } = await supabase.from('app_data').select('payload').eq('id', 'main').maybeSingle();
    if (error) {
      res.status(500).json({ ok: false, error: 'read_failed' });
      return;
    }
    res.setHeader('Content-Type', 'application/json; charset=utf-8');
    res.status(200).send(JSON.stringify(data ? data.payload : EMPTY_DATA));
    return;
  }

  if (req.method === 'POST') {
    const raw = await readBody(req);
    let parsed;
    try {
      parsed = JSON.parse(raw);
    } catch (e) {
      res.status(400).json({ ok: false, error: 'invalid_json' });
      return;
    }
    const { error } = await supabase.from('app_data').upsert({ id: 'main', payload: parsed, updated_at: new Date().toISOString() });
    if (error) {
      res.status(500).json({ ok: false, error: 'write_failed' });
      return;
    }
    res.status(200).json({ ok: true });
    return;
  }

  res.status(405).json({ ok: false, error: 'method_not_allowed' });
};
