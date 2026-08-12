const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;
const DATA_DIR = process.env.DATA_DIR || path.join(__dirname, '..', 'data');
const DATA_FILE = path.join(DATA_DIR, 'timetrax-store.json');

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Optional API Key Middleware
const API_KEY = process.env.API_KEY || '';
app.use('/api', (req, res, next) => {
  if (API_KEY && req.headers['x-api-key'] !== API_KEY && req.query.apiKey !== API_KEY) {
    // Only protect write endpoints if API_KEY is configured
    if (['POST', 'PUT', 'DELETE'].includes(req.method)) {
      return res.status(401).json({ error: 'Unauthorized: Invalid API Key' });
    }
  }
  next();
});

// Ensure data directory exists
if (!fs.existsSync(DATA_DIR)) {
  fs.mkdirSync(DATA_DIR, { recursive: true });
}

// Initial state
const defaultStore = {
  settings: {
    ntfyServerUrl: process.env.NTFY_SERVER_URL || 'http://ntfy:8080',
    ntfyTopic: process.env.NTFY_TOPIC || 'timetrax-alerts',
    ntfyAuthToken: process.env.NTFY_AUTH_TOKEN || '',
    defaultPriority: process.env.DEFAULT_PRIORITY || '3',
    defaultUser: process.env.DEFAULT_USER || 'Developer',
    defaultProject: process.env.DEFAULT_PROJECT || 'General Tasks',
    enableClockInWebhooks: process.env.ENABLE_CLOCK_IN_WEBHOOKS !== 'false',
    enableClockOutWebhooks: process.env.ENABLE_CLOCK_OUT_WEBHOOKS !== 'false',
    enableBreakWebhooks: process.env.ENABLE_BREAK_WEBHOOKS !== 'false',
    enableAlertWebhooks: true
  },
  currentShift: null,
  logs: []
};

// Load persistent data
function loadStore() {
  try {
    if (fs.existsSync(DATA_FILE)) {
      const raw = fs.readFileSync(DATA_FILE, 'utf8');
      const parsed = JSON.parse(raw);
      return {
        settings: { ...defaultStore.settings, ...(parsed.settings || {}) },
        currentShift: parsed.currentShift || null,
        logs: parsed.logs || []
      };
    }
  } catch (err) {
    console.error('⚠️ Error reading data store, falling back to default:', err.message);
  }
  return defaultStore;
}

let store = loadStore();

function saveStore() {
  try {
    fs.writeFileSync(DATA_FILE, JSON.stringify(store, null, 2), 'utf8');
  } catch (err) {
    console.error('❌ Failed to save data store:', err.message);
  }
}

// Helper: Dispatch notification to ntfy
async function sendNtfyNotification({ title, message, priority, tags, actions, topicOverride }) {
  const targetTopic = topicOverride || store.settings.ntfyTopic || 'timetrax-alerts';
  let serverUrl = store.settings.ntfyServerUrl || 'http://ntfy:8080';
  
  serverUrl = serverUrl.replace(/\/+$/, '');
  
  const targetEndpoint = `${serverUrl}/${targetTopic}`;
  const payload = {
    topic: targetTopic,
    title: title || 'TimeTrax Notification',
    message: message || '',
    priority: parseInt(priority || store.settings.defaultPriority || 3, 10),
    tags: tags || ['clock']
  };

  if (actions) {
    payload.actions = actions;
  }

  const headers = {
    'Content-Type': 'application/json'
  };

  if (store.settings.ntfyAuthToken) {
    headers['Authorization'] = `Bearer ${store.settings.ntfyAuthToken}`;
  }

  console.log(`📤 [Webhook Dispatch] -> ${targetEndpoint} (${payload.title})`);

  try {
    const response = await fetch(targetEndpoint, {
      method: 'POST',
      headers,
      body: JSON.stringify(payload)
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`ntfy server returned HTTP ${response.status}: ${errorText}`);
    }

    const resData = await response.json().catch(() => ({ status: 'ok' }));
    return { success: true, endpoint: targetEndpoint, response: resData };
  } catch (err) {
    console.error(`❌ [Webhook Error]: ${err.message}`);
    return { success: false, endpoint: targetEndpoint, error: err.message };
  }
}

// Format duration into readable string
function formatDuration(ms) {
  const seconds = Math.floor((ms / 1000) % 60);
  const minutes = Math.floor((ms / (1000 * 60)) % 60);
  const hours = Math.floor(ms / (1000 * 60 * 60));
  return `${hours}h ${minutes}m ${seconds}s`;
}

// --- REST API ENDPOINTS ---

app.get('/api/status', (req, res) => {
  const now = Date.now();
  let shiftInfo = null;

  if (store.currentShift) {
    const elapsed = now - new Date(store.currentShift.clockInTime).getTime();
    let currentBreakElapsed = 0;
    if (store.currentShift.status === 'ON_BREAK' && store.currentShift.breakStartTime) {
      currentBreakElapsed = now - new Date(store.currentShift.breakStartTime).getTime();
    }
    const netWorked = elapsed - (store.currentShift.totalBreakMinutes * 60000) - currentBreakElapsed;

    shiftInfo = {
      ...store.currentShift,
      elapsedMs: Math.max(0, netWorked),
      elapsedFormatted: formatDuration(Math.max(0, netWorked))
    };
  }

  res.json({
    status: store.currentShift ? store.currentShift.status : 'CLOCKED_OUT',
    currentShift: shiftInfo,
    settings: store.settings
  });
});

app.post('/api/clock-in', async (req, res) => {
  if (store.currentShift) {
    return res.status(400).json({ error: 'Already clocked in!' });
  }

  const {
    user = store.settings.defaultUser || 'Employee',
    project = store.settings.defaultProject || 'General Tasks',
    notes = ''
  } = req.body;

  const nowIso = new Date().toISOString();

  const newShift = {
    id: `shift_${Date.now()}`,
    user,
    project,
    notes,
    clockInTime: nowIso,
    clockOutTime: null,
    breakStartTime: null,
    totalBreakMinutes: 0,
    status: 'CLOCKED_IN'
  };

  store.currentShift = newShift;
  
  const logEntry = {
    id: `log_${Date.now()}`,
    timestamp: nowIso,
    type: 'CLOCK_IN',
    user,
    project,
    details: `Clocked in for ${project}`
  };
  store.logs.unshift(logEntry);
  saveStore();

  let webhookResult = null;
  if (store.settings.enableClockInWebhooks) {
    webhookResult = await sendNtfyNotification({
      title: `⏰ Clocked In: ${user}`,
      message: `Project: ${project}\nStarted at: ${new Date(nowIso).toLocaleTimeString()}${notes ? `\nNotes: ${notes}` : ''}`,
      priority: 4,
      tags: ['alarm_clock', 'briefcase', 'green_circle']
    });
  }

  res.json({
    message: 'Clocked in successfully',
    shift: store.currentShift,
    webhook: webhookResult
  });
});

app.post('/api/break', async (req, res) => {
  if (!store.currentShift) {
    return res.status(400).json({ error: 'No active shift found.' });
  }

  const now = new Date();
  const nowIso = now.toISOString();
  let actionType = '';
  let msg = '';

  if (store.currentShift.status === 'CLOCKED_IN') {
    store.currentShift.status = 'ON_BREAK';
    store.currentShift.breakStartTime = nowIso;
    actionType = 'BREAK_START';
    msg = `${store.currentShift.user} started break at ${now.toLocaleTimeString()}`;
  } else if (store.currentShift.status === 'ON_BREAK') {
    const breakStart = new Date(store.currentShift.breakStartTime).getTime();
    const breakMs = now.getTime() - breakStart;
    const breakMins = Math.round(breakMs / 60000);
    
    store.currentShift.totalBreakMinutes += breakMins;
    store.currentShift.status = 'CLOCKED_IN';
    store.currentShift.breakStartTime = null;
    actionType = 'BREAK_END';
    msg = `${store.currentShift.user} returned from break (${breakMins} mins)`;
  }

  const logEntry = {
    id: `log_${Date.now()}`,
    timestamp: nowIso,
    type: actionType,
    user: store.currentShift.user,
    project: store.currentShift.project,
    details: msg
  };
  store.logs.unshift(logEntry);
  saveStore();

  let webhookResult = null;
  if (store.settings.enableBreakWebhooks) {
    webhookResult = await sendNtfyNotification({
      title: actionType === 'BREAK_START' ? `☕ Break Started: ${store.currentShift.user}` : `💪 Back To Work: ${store.currentShift.user}`,
      message: msg,
      priority: store.settings.defaultPriority || 3,
      tags: actionType === 'BREAK_START' ? ['coffee', 'pause_button'] : ['play_or_pause_button', 'muscle']
    });
  }

  res.json({
    message: msg,
    shift: store.currentShift,
    webhook: webhookResult
  });
});

app.post('/api/clock-out', async (req, res) => {
  if (!store.currentShift) {
    return res.status(400).json({ error: 'No active shift to clock out from.' });
  }

  const now = new Date();
  const nowIso = now.toISOString();

  if (store.currentShift.status === 'ON_BREAK' && store.currentShift.breakStartTime) {
    const breakStart = new Date(store.currentShift.breakStartTime).getTime();
    const breakMins = Math.round((now.getTime() - breakStart) / 60000);
    store.currentShift.totalBreakMinutes += breakMins;
  }

  const clockIn = new Date(store.currentShift.clockInTime).getTime();
  const grossDuration = now.getTime() - clockIn;
  const netWorkedMs = Math.max(0, grossDuration - (store.currentShift.totalBreakMinutes * 60000));
  const workedFormatted = formatDuration(netWorkedMs);

  const completedShift = {
    ...store.currentShift,
    clockOutTime: nowIso,
    status: 'CLOCKED_OUT',
    totalWorkedMs: netWorkedMs,
    totalWorkedFormatted: workedFormatted
  };

  const logEntry = {
    id: `log_${Date.now()}`,
    timestamp: nowIso,
    type: 'CLOCK_OUT',
    user: completedShift.user,
    project: completedShift.project,
    details: `Clocked out after working ${workedFormatted} (Breaks: ${completedShift.totalBreakMinutes} mins)`
  };
  store.logs.unshift(logEntry);

  store.currentShift = null;
  saveStore();

  let webhookResult = null;
  if (store.settings.enableClockOutWebhooks) {
    webhookResult = await sendNtfyNotification({
      title: `🏁 Shift Completed: ${completedShift.user}`,
      message: `Project: ${completedShift.project}\nDuration: ${workedFormatted}\nTotal Breaks: ${completedShift.totalBreakMinutes} min(s)`,
      priority: store.settings.defaultPriority || 3,
      tags: ['checkered_flag', 'stopwatch', 'red_circle']
    });
  }

  res.json({
    message: 'Clocked out successfully',
    completedShift,
    webhook: webhookResult
  });
});

app.get('/api/logs', (req, res) => {
  res.json({ logs: store.logs });
});

app.get('/api/settings', (req, res) => {
  res.json({ settings: store.settings });
});

app.post('/api/settings', (req, res) => {
  const {
    ntfyServerUrl,
    ntfyTopic,
    ntfyAuthToken,
    defaultPriority,
    defaultUser,
    defaultProject,
    enableClockInWebhooks,
    enableClockOutWebhooks,
    enableBreakWebhooks
  } = req.body;

  store.settings = {
    ...store.settings,
    ...(ntfyServerUrl !== undefined && { ntfyServerUrl }),
    ...(ntfyTopic !== undefined && { ntfyTopic }),
    ...(ntfyAuthToken !== undefined && { ntfyAuthToken }),
    ...(defaultPriority !== undefined && { defaultPriority }),
    ...(defaultUser !== undefined && { defaultUser }),
    ...(defaultProject !== undefined && { defaultProject }),
    ...(enableClockInWebhooks !== undefined && { enableClockInWebhooks: Boolean(enableClockInWebhooks) }),
    ...(enableClockOutWebhooks !== undefined && { enableClockOutWebhooks: Boolean(enableClockOutWebhooks) }),
    ...(enableBreakWebhooks !== undefined && { enableBreakWebhooks: Boolean(enableBreakWebhooks) })
  };

  saveStore();
  res.json({ message: 'Settings updated successfully', settings: store.settings });
});

app.post('/api/webhook/test', async (req, res) => {
  const { customTopic } = req.body;
  const nowStr = new Date().toLocaleTimeString();

  const testResult = await sendNtfyNotification({
    title: '🔔 TimeTrax Webhook Test',
    message: `Test notification generated at ${nowStr} from TimeTrax Host!\nWebhooks are connected and functioning properly.`,
    priority: 4,
    tags: ['tada', 'zap', 'robot'],
    topicOverride: customTopic || undefined
  });

  res.json({
    message: testResult.success ? 'Test webhook sent successfully!' : 'Failed to send test webhook.',
    details: testResult
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 TimeTrax Host Application running on http://0.0.0.0:${PORT}`);
  console.log(`📡 Connected ntfy Endpoint: ${store.settings.ntfyServerUrl}/${store.settings.ntfyTopic}`);
});
