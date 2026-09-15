const http = require('http');
const fs = require('fs');
const path = require('path');

try { process.loadEnvFile(path.join(__dirname, '.env')); } catch (e) { /* .env 없으면 무시 */ }

const PORT = process.env.PORT || 5173;
const ROOT = __dirname;
const DATA_FILE = path.join(ROOT, 'data.json');
const HTML_FILE = path.join(ROOT, 'bongtu-ledger.html');
const EMPTY_DATA = { entries: [], gifts: [], people: [], recommendations: [] };

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY;

let supabase = null;
if (SUPABASE_URL && SUPABASE_SERVICE_KEY) {
  const { createClient } = require('@supabase/supabase-js');
  supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
}

function ensureDataFile() {
  if (!fs.existsSync(DATA_FILE)) {
    fs.writeFileSync(DATA_FILE, JSON.stringify(EMPTY_DATA, null, 2));
  }
}

async function readData() {
  if (supabase) {
    const { data, error } = await supabase.from('app_data').select('payload').eq('id', 'main').maybeSingle();
    if (error) throw error;
    return data ? data.payload : EMPTY_DATA;
  }
  ensureDataFile();
  return JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'));
}

async function writeData(payload) {
  if (supabase) {
    const { error } = await supabase.from('app_data').upsert({ id: 'main', payload, updated_at: new Date().toISOString() });
    if (error) throw error;
    return;
  }
  fs.writeFileSync(DATA_FILE, JSON.stringify(payload, null, 2));
}

const server = http.createServer((req, res) => {
  if (req.method === 'GET' && (req.url === '/' || req.url === '/index.html')) {
    fs.readFile(HTML_FILE, (err, data) => {
      if (err) { res.writeHead(500); res.end('bongtu-ledger.html을 찾을 수 없어요.'); return; }
      res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
      res.end(data);
    });
    return;
  }

  if (req.method === 'GET' && req.url === '/api/data') {
    readData()
      .then(data => {
        res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
        res.end(JSON.stringify(data));
      })
      .catch(err => {
        console.error(err);
        res.writeHead(500, { 'Content-Type': 'application/json' });
        res.end('{"ok":false,"error":"read_failed"}');
      });
    return;
  }

  if (req.method === 'POST' && req.url === '/api/data') {
    let body = '';
    let tooLarge = false;
    req.on('data', chunk => {
      body += chunk;
      if (body.length > 20 * 1024 * 1024) { tooLarge = true; req.destroy(); }
    });
    req.on('end', () => {
      if (tooLarge) { res.writeHead(413); res.end('{"ok":false,"error":"too_large"}'); return; }
      let parsed;
      try {
        parsed = JSON.parse(body);
      } catch (e) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end('{"ok":false,"error":"invalid_json"}');
        return;
      }
      writeData(parsed)
        .then(() => {
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end('{"ok":true}');
        })
        .catch(err => {
          console.error(err);
          res.writeHead(500, { 'Content-Type': 'application/json' });
          res.end('{"ok":false,"error":"write_failed"}');
        });
    });
    return;
  }

  res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
  res.end('찾을 수 없는 경로예요.');
});

server.listen(PORT, () => {
  console.log('봉투장부 로컬 서버 실행 중: http://localhost:' + PORT);
  if (supabase) {
    console.log('저장소: Supabase (' + SUPABASE_URL + ')');
  } else {
    console.log('저장소: 로컬 파일 (' + DATA_FILE + ')');
    console.log('Supabase를 쓰려면 .env.example을 .env로 복사하고 값을 채운 뒤 다시 실행하세요.');
  }
});
