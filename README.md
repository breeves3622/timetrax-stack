# ⏱️ TimeTrax Host Stack (Kimai 2 Open-Source Time Clock + ntfy Webhooks)

A complete, self-hosted, production-ready time clock & attendance tracking system.

> **Note on OpenTimeClock vs Kimai**: OpenTimeClock is a cloud-only SaaS product without a self-hosted Docker edition. **Kimai 2** is the leading open-source, self-hosted time tracking & time clock alternative.

---

## 🚀 Features

- **Kimai 2 Open Source Time Clock**: Modern UI, employee clock-in / clock-out, team management, timesheets, and reporting on Port `8090`.
- **Zero-Setup Database Initialization**: Automatic database migrations and default admin user creation (`admin@example.com` / `AdminPass123!`).
- **ntfy Push Notification Server**: Self-hosted alert server on Port `8080`.
- **TimeTrax Webhook Bridge**: Micro-service on Port `5000` forwarding punch & event webhooks to ntfy topics.

---

## 🛠️ Portainer Deployment Instructions

1. Go to **Portainer** -> **Stacks** -> **Add stack**.
2. Select **Repository** and set:
   - **Repository URL**: `https://github.com/breeves3622/timetrax-stack.git`
   - **Repository Reference**: `refs/heads/main`
   - **Compose Path**: `docker-compose.yml`
3. Click **Deploy the stack**.

---

## 🌐 Access Points

| Service | Access URL | Default Credentials |
| :--- | :--- | :--- |
| **Kimai Time Clock** | `http://<YOUR_SERVER_IP>:8090` | `admin@example.com` / `AdminPass123!` |
| **ntfy Push Server** | `http://<YOUR_SERVER_IP>:8080` | None (Open Web Panel) |
| **Webhook Bridge** | `http://<YOUR_SERVER_IP>:5000/webhook` | HTTP POST Webhooks |

---

## ⚙️ Environment Variables

| Variable | Default Value | Description |
| :--- | :--- | :--- |
| `TIMETREX_PORT` | `8090` | Host port for Kimai Time Clock Web UI |
| `ADMIN_EMAIL` | `admin@example.com` | Kimai Admin Account Email |
| `ADMIN_PASSWORD` | `AdminPass123!` | Kimai Admin Account Password |
| `NTFY_PORT` | `8080` | Host port for ntfy web UI |
| `NTFY_TOPIC` | `timetrax-alerts` | Default notification topic |
| `BRIDGE_PORT` | `5000` | Webhook bridge port |
