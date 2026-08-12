# ⏱️ TimeTrax Host with ntfy Push Webhooks

A production-ready, containerized **TimeTrax Host Application** with real-time **ntfy push notification webhooks**. Track work hours, shifts, and breaks while receiving instant push alerts on mobile devices (iOS/Android) and desktop apps when status changes occur.

![TimeTrax + ntfy Stack](https://img.shields.io/badge/Docker-Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Portainer Compatible](https://img.shields.io/badge/Portainer-Stack-13BEF9?style=for-the-badge&logo=portainer&logoColor=white)
![ntfy Integration](https://img.shields.io/badge/ntfy-Push_Notifications-3B82F6?style=for-the-badge)

---

## 🌟 Key Features

- ⏰ **Interactive Time Tracker**: Clock in, clock out, toggle breaks, and track shift durations in real time.
- 🔔 **Instant ntfy Webhooks**: Dispatches HTTP POST webhooks to ntfy on every status event (Clock In, Clock Out, Break Start, Break End).
- 📱 **Mobile & Desktop Push Alerts**: Subscribe to your ntfy topic on iOS, Android, or browser to receive alerts with priority levels and custom tags (`alarm_clock`, `coffee`, `stopwatch`).
- 🏠 **Self-Hosted ntfy Included**: Includes a pre-configured `binwiederhier/ntfy` container in Docker Compose (or connect to `https://ntfy.sh`).
- ⚙️ **Fully Configurable via Environment Variables**: Customize ports, defaults, priorities, webhook toggles, and API keys directly from Portainer's environment panel.
- ⚡ **Live Webhook Tester**: Test button in the Web UI to verify endpoint delivery instantly.

---

## 🏗️ Architecture

```
┌────────────────────────────────────────────────────────┐
│                   TIMETRAX HOST UI                     │
│      Web Dashboard (http://localhost:3000)             │
└──────────────────────────┬─────────────────────────────┘
                           │ Clock Event / Trigger
                           ▼
┌────────────────────────────────────────────────────────┐
│               TIMETRAX HOST ENGINE                     │
│      Node.js REST API & Webhook Dispatcher             │
└──────────────────────────┬─────────────────────────────┘
                           │ Outgoing HTTP POST Webhook
                           ▼
┌────────────────────────────────────────────────────────┐
│             SELF-HOSTED NTFY PUSH SERVER               │
│         binwiederhier/ntfy (http://localhost:8080)     │
└──────────────────────────┬─────────────────────────────┘
                           │ Push Notification
                           ▼
┌────────────────────────────────────────────────────────┐
│                   USER DEVICES                         │
│     ntfy Mobile App (iOS/Android) / Desktop / Web      │
└──────────────────────────┬─────────────────────────────┘
```

---

## 🐳 Environment Variables Reference for Portainer

| Variable | Default Value | Description |
|---|---|---|
| `TIMETRAX_PORT` | `3000` | Port for TimeTrax Host Web UI |
| `NTFY_PORT` | `8080` | Port for self-hosted ntfy Push Server |
| `NTFY_SERVER_URL` | `http://ntfy:8080` | Internal container URL for ntfy dispatch |
| `NTFY_TOPIC` | `timetrax-alerts` | Target notification topic name |
| `NTFY_AUTH_TOKEN` | *(optional)* | Token for private ntfy authentication |
| `DEFAULT_USER` | `Developer` | Pre-filled default employee name |
| `DEFAULT_PROJECT` | `General Tasks` | Pre-filled default project name |
| `DEFAULT_PRIORITY` | `3` | Default ntfy notification priority (`1-5`) |
| `ENABLE_CLOCK_IN_WEBHOOKS` | `true` | Send ntfy push alert on Clock In |
| `ENABLE_CLOCK_OUT_WEBHOOKS` | `true` | Send ntfy push alert on Clock Out |
| `ENABLE_BREAK_WEBHOOKS` | `true` | Send ntfy push alert on Break Toggle |
| `API_KEY` | *(optional)* | Security API Key for REST API endpoints |
| `DATA_DIR` | `/opt/timetrax/data` | Host persistent directory for TimeTrax store |
| `NTFY_DATA_DIR` | `/opt/timetrax/ntfy` | Host persistent directory for ntfy cache |
| `TZ` | `America/New_York` | Container timezone setting |

---

## 🚀 Portainer Stack Deployment

1. Open **Portainer** -> **Stacks** -> **+ Add stack**.
2. **Name**: `timetrax-stack`.
3. **Build Method**: Select **Repository**.
4. **Repository Details**:
   - **Repository URL**: `https://github.com/breeves3622/timetrax-stack.git`
   - **Repository reference**: `refs/heads/main`
   - **Compose path**: `docker-compose.yml`
5. **Environment variables**: Add any of the environment variables from the table above.
6. Click **Deploy the stack**.

---

## 📄 License

MIT License - feel free to customize and expand!
