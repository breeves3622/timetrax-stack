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
- ⚡ **Live Webhook Tester**: Test button in the Web UI to verify endpoint delivery instantly.
- 🐳 **Portainer & GitHub Ready**: Deployable directly as a Portainer Stack linked to your GitHub repository.

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
└──────────────────────────?─────────────────────────────┘
```

---

## 🐙 Step 1: Push Code to Your GitHub Repository

Run the following commands in your local workspace terminal:

```bash
# 1. Add all project files
git add .

# 2. Commit the changes
git commit -m "Setup TimeTrax Host with self-hosted ntfy stack"

# 3. Rename branch to main (if preferred)
git branch -M main

# 4. Connect your GitHub remote repository (replace with your GitHub URL)
git remote add origin https://github.com/YOUR_GITHUB_USERNAME/YOUR_REPO_NAME.git

# 5. Push to GitHub
git push -u origin main
```

---

## 🐳 Step 2: Deploying via Portainer Stacks

1. Open **Portainer** -> **Stacks** -> **+ Add stack**.
2. **Name**: `timetrax-stack`.
3. **Build Method**: Select **Repository**.
4. **Repository Details**:
   - **Repository URL**: `https://github.com/YOUR_GITHUB_USERNAME/YOUR_REPO_NAME.git`
   - **Repository reference**: `refs/heads/main` (or `refs/heads/master`)
   - **Compose path**: `docker-compose.yml`
5. **Environment variables**:
   Click **+ Add environment variable** for each parameter:
   | Key | Value | Description |
   |---|---|---|
   | `TIMETRAX_PORT` | `3000` | Port for TimeTrax Host Web UI |
   | `NTFY_PORT` | `8080` | Port for self-hosted ntfy Push Server |
   | `NTFY_SERVER_URL` | `http://ntfy:8080` | Internal container URL for ntfy |
   | `NTFY_TOPIC` | `timetrax-alerts` | Target notification topic name |
   | `TZ` | `America/New_York` | Server timezone |
   | `DATA_DIR` | `/opt/timetrax/data` | Host persistent directory for TimeTrax |
   | `NTFY_DATA_DIR` | `/opt/timetrax/ntfy` | Host persistent directory for ntfy |

6. Click **Deploy the stack**.

> [!TIP]
> Portainer will clone your GitHub repository, automatically build the `timetrax-host` Docker container from the `Dockerfile`, spin up the `ntfy` container, and attach them on the `timetrax-net` bridge network!

---

## ⚙️ Step 3: Access & Configuration

### 1. Open TimeTrax Host UI
Navigate to `http://<YOUR_SERVER_IP>:3000` in your web browser.

### 2. Connect Your Mobile / Desktop ntfy App
1. Download the **ntfy** app on your phone ([iOS App Store](https://apps.apple.com/app/ntfy/id1625396386) / [Google Play](https://play.google.com/store/apps/details?id=io.heckel.ntfy)).
2. Tap **+ Add subscription**.
3. Set **Server URL**: `http://<YOUR_SERVER_IP>:8080` (or `https://ntfy.sh` if using cloud ntfy).
4. Set **Topic name**: `timetrax-alerts` (or your custom topic name configured in settings).

### 3. Test Your Webhook Integration
In the TimeTrax Web UI:
1. Click **Test Webhook** under the **ntfy Webhook Settings** panel.
2. Confirm that a push notification arrives immediately on your phone/device.

---

## 📄 License

MIT License - feel free to customize and expand!
