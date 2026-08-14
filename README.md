# ⏱️ TimeTrax Host Stack (trackable. Open-Source Time Tracker + ntfy Webhooks)

A complete, self-hosted, lightweight time tracking & management system built using **trackable.** ([webcommits/trackable](https://github.com/webcommits/trackable)).

---

## 🚀 Features

- **trackable. Open Source Time Tracker**: Modern Django + SQLite PWA time tracker with live timers, activity logs, break tracking, client PDF/CSV exports, and team management on Port `8090`.
- **Automatic Database Persistence**: SQLite database stored cleanly in `/opt/timetrax/trackable/data`.
- **ntfy Push Notification Server**: Self-hosted alert server on Port `8080`.
- **TimeTrax Webhook Bridge**: Micro-service on Port `8095` forwarding alert events to ntfy topics.

---

## 🛠️ Portainer Deployment Instructions

1. Go to **Portainer** -> **Stacks** -> **Add stack** (or update existing `timetrax-stack`).
2. Select **Repository** and set:
   - **Repository URL**: `https://github.com/breeves3622/timetrax-stack.git`
   - **Repository Reference**: `refs/heads/main`
   - **Compose Path**: `docker-compose.yml`
3. Check the toggle **`Re-build image`** (or **`Pull latest image and re-deploy`**).
4. Click **Deploy the stack**.

---

## 🌐 Access Points & Initial Setup

| Service | Access URL | Initial Setup |
| :--- | :--- | :--- |
| **trackable. Time Tracker** | `http://<YOUR_SERVER_IP>:8090` | Register your admin account on first load |
| **ntfy Push Server** | `http://<YOUR_SERVER_IP>:8080` | Web UI Notification Panel |
| **Webhook Bridge** | `http://<YOUR_SERVER_IP>:8095` | HTTP POST Webhooks |

---

## ⚙️ Environment Variables

| Variable | Default Value | Description |
| :--- | :--- | :--- |
| `TIMETREX_PORT` | `8090` | Host port for trackable. Web UI |
| `SECRET_KEY` | *(Auto-generated)* | Django Secret Encryption Key |
| `ALLOWED_HOSTS` | `*` | Allowed domain/IP host headers |
| `DISABLE_REGISTRATION` | `False` | Enable initial user sign-up |
| `NTFY_PORT` | `8080` | Host port for ntfy web UI |
| `BRIDGE_PORT` | `8095` | Webhook bridge port |
