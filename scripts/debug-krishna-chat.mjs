import { setTimeout as delay } from 'node:timers/promises';

const INGEST =
  'http://127.0.0.1:7914/ingest/6ac49fb4-6cd8-4bd2-9f4f-411bd80ceae6';
const SESSION_ID = '461672';

function log(hypothesisId, location, message, data) {
  fetch(INGEST, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Debug-Session-Id': SESSION_ID,
    },
    body: JSON.stringify({
      sessionId: SESSION_ID,
      runId: 'pre-fix',
      hypothesisId,
      location,
      message,
      data,
      timestamp: Date.now(),
    }),
  }).catch(() => {});
}

const url = 'https://dharma-backend.vercel.app/chat';
const body = {
  message: 'Test message: please reply with one short sentence.',
  currentVerse: null,
  goals: ['Develop non-attachment'],
  reflection: null,
  conversationHistory: [],
  lastOfferingSummary: null,
};

log(
  'H0',
  'scripts/debug-krishna-chat.mjs:START',
  'Starting /chat probe',
  { url }
);

const ac = new AbortController();
const timeoutMs = 20_000;
const timeout = setTimeout(() => ac.abort('timeout'), timeoutMs);

let res;
try {
  res = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Accept: 'text/event-stream',
    },
    body: JSON.stringify(body),
    signal: ac.signal,
  });
} catch (e) {
  clearTimeout(timeout);
  log(
    'H1',
    'scripts/debug-krishna-chat.mjs:FETCH',
    'Fetch threw before receiving response',
    { name: e?.name, message: e?.message }
  );
  process.exitCode = 1;
  // Give log a moment to flush.
  await delay(250);
  process.exit();
}

log(
  'H1',
  'scripts/debug-krishna-chat.mjs:RESP',
  'Received HTTP response',
  {
    status: res.status,
    ok: res.ok,
    contentType: res.headers.get('content-type'),
    cacheControl: res.headers.get('cache-control'),
  }
);

if (!res.ok) {
  let text = '';
  try {
    text = await res.text();
  } catch {}
  clearTimeout(timeout);
  log(
    'H1',
    'scripts/debug-krishna-chat.mjs:RESP_BODY',
    'Non-2xx response body (truncated)',
    { body: text.slice(0, 400) }
  );
  process.exitCode = 1;
  await delay(250);
  process.exit();
}

// Stream parse: capture first few SSE lines and whether any "data: " frames contain {"text":...}
const reader = res.body?.getReader?.();
if (!reader) {
  clearTimeout(timeout);
  log(
    'H2',
    'scripts/debug-krishna-chat.mjs:STREAM',
    'No readable stream body; cannot SSE parse',
    {}
  );
  process.exitCode = 1;
  await delay(250);
  process.exit();
}

let buf = '';
let linesSeen = 0;
let textFrames = 0;
let doneSeen = false;
let totalBytes = 0;

while (linesSeen < 50 && textFrames < 3 && !doneSeen) {
  const { value, done } = await reader.read();
  if (done) break;
  totalBytes += value.byteLength;
  buf += new TextDecoder().decode(value, { stream: true });

  while (linesSeen < 50) {
    const nl = buf.indexOf('\n');
    if (nl === -1) break;
    const line = buf.slice(0, nl).replace(/\r$/, '');
    buf = buf.slice(nl + 1);
    linesSeen += 1;

    if (linesSeen <= 8) {
      log(
        'H2',
        'scripts/debug-krishna-chat.mjs:SSE_LINE',
        'SSE line',
        { n: linesSeen, line: line.slice(0, 300) }
      );
    }

    if (line.startsWith('data: ')) {
      const payload = line.slice(6);
      if (payload === '[DONE]') {
        doneSeen = true;
        log(
          'H3',
          'scripts/debug-krishna-chat.mjs:DONE',
          'Saw [DONE]',
          {}
        );
        break;
      }
      try {
        const obj = JSON.parse(payload);
        if (typeof obj?.text === 'string') {
          textFrames += 1;
          log(
            'H3',
            'scripts/debug-krishna-chat.mjs:TEXT',
            'Saw {"text":...} frame',
            { sample: obj.text.slice(0, 120) }
          );
        }
      } catch {
        log(
          'H2',
          'scripts/debug-krishna-chat.mjs:DATA_PARSE',
          'data: payload was not JSON (truncated)',
          { payload: payload.slice(0, 200) }
        );
      }
    }
  }
}

clearTimeout(timeout);
log(
  'H4',
  'scripts/debug-krishna-chat.mjs:SUMMARY',
  'Probe summary',
  { linesSeen, textFrames, doneSeen, totalBytes }
);

// Give log a moment to flush.
await delay(250);
