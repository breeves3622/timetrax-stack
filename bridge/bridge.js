const http = require('http');
const PORT = process.env.BRIDGE_PORT || 5000;
const NTFY_SERVER_URL = (process.env.NTFY_SERVER_URL || 'http://ntfy:8080').replace(/\/+$/, '');
const NTFY_TOPIC = process.env.NTFY_TOPIC || 'timetrax-alerts';
const NTFY_AUTH_TOKEN = process.env.NTFY_AUTH_TOKEN || '';

const server = http.createServer(async (req, res) => {
  if (req.method === 'POST' && (req.url === '/webhook' || req.url === '/')) {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', async () => {
      try {
        let payload = {};
        try {
          payload = JSON.parse(body);
        } catch {
          payload = { message: body };
        }

        const title = payload.title || payload.subject || 'TimeTrex Alert';
        const message = payload.message || payload.text || payload.details || body || 'Event triggered in TimeTrex';
        const priority = payload.priority || 3;
        const tags = payload.tags || ['clock', 'calendar'];

        const ntfyEndpoint = `${NTFY_SERVER_URL}/${NTFY_TOPIC}`;
        const ntfyPayload = JSON.stringify({
          topic: NTFY_TOPIC,
          title,
          message,
          priority: parseInt(priority, 10),
          tags
        });

        const headers = { 'Content-Type': 'application/json' };
        if (NTFY_AUTH_TOKEN) {
          headers['Authorization'] = `Bearer ${NTFY_AUTH_TOKEN}`;
        }

        console.log(`📤 Forwarding TimeTrex event to ntfy (${ntfyEndpoint}): ${title}`);

        const response = await fetch(ntfyEndpoint, {
          method: 'POST',
          headers,
          body: ntfyPayload
        });

        const resData = await response.text();
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ status: 'success', ntfyResponse: resData }));
      } catch (err) {
        console.error('❌ Webhook bridge error:', err.message);
        res.writeHead(500, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: err.message }));
      }
    });
  } else if (req.method === 'GET' && req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'healthy', ntfyTopic: NTFY_TOPIC }));
  } else {
    res.writeHead(404, { 'Content-Type': 'text/plain' });
    res.end('Not Found');
  }
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`📡 TimeTrex-ntfy Webhook Bridge running on port ${PORT}`);
  console.log(`🎯 Forwarding webhooks to: ${NTFY_SERVER_URL}/${NTFY_TOPIC}`);
});
