# ⏱️ TimeTrex Community Edition Stack with ntfy Webhooks

A production-ready containerized deployment of official **TimeTrex Community Edition** (Open Source Workforce Management, Time & Attendance, Payroll) connected to a **PostgreSQL** database and a self-hosted **ntfy push notification server** via webhook bridge.

![TimeTrex Community Edition](https://img.shields.io/badge/TimeTrex-Community_Edition-2563EB?style=for-the-badge)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15_Alpine-336791?style=for-the-badge&logo=postgresql&logoColor=white)
![Docker Compose](https://img.shields.io/badge/Docker-Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Portainer Compatible](https://img.shields.io/badge/Portainer-Stack-13BEF9?style=for-the-badge&logo=portainer&logoColor=white)
![ntfy Integration](https://img.shields.io/badge/ntfy-Push_Notifications-3B82F6?style=for-the-badge)

---

## 🌟 Stack Architecture

```
┌────────────────────────────────────────────────────────┐
│             TIMETREX COMMUNITY EDITION                 │
│      Official PHP 8.2 + Apache (Port 8085)             │
└──────────┬──────────────────────────┬──────────────────┘
           │ Database Queries         │ Webhook Alerts
           ▼                          ▼
┌──────────────────────┐   ┌─────────────────────────────┐
│ POSTGRESQL DATABASE  │   │  TIMETREX NTFY BRIDGE       │
│  PostgreSQL 15       │   │  HTTP Relay (Port 5000)     │
└──────────────────────┘   └──────────┬──────────────────┘
                                      │ Push POST Request
                                      ▼
                           ┌─────────────────────────────┐
                           │      NTFY PUSH SERVER       │
                           │ binwiederhier/ntfy (8080)   │
                           └──────────┬──────────────────┘
                                      │ Push Notification
                                      ▼
                           ┌─────────────────────────────┐
                           │   USER MOBILE & DESKTOP     │
                           └─────────────────────────────┘
```

---

## 🚀 Portainer Stack Deployment Guide (`breeves3622`)

1. Open **Portainer** -> **Stacks** -> **+ Add stack**.
2. **Name**: `timetrex-stack`.
3. **Build Method**: Select **Repository**.
4. **Repository Details**:
   - **Repository URL**: `https://github.com/breeves3622/timetrax-stack.git`
   - **Repository reference**: `refs/heads/main`
   - **Compose path**: `docker-compose.yml`
5. **Environment Variables**:
   | Key | Default Value | Description |
   |---|---|---|
   | `TIMETREX_PORT` | `8085` | TimeTrex Web Interface Port |
   | `POSTGRES_USER` | `timetrex` | PostgreSQL DB User |
   | `POSTGRES_PASSWORD` | `timetrexpass` | PostgreSQL DB Password |
   | `POSTGRES_DB` | `timetrex` | PostgreSQL Database Name |
   | `NTFY_PORT` | `8080` | Self-Hosted ntfy Push Server Port |
   | `BRIDGE_PORT` | `5000` | Webhook Relay Bridge Port |
   | `NTFY_SERVER_URL` | `http://ntfy:8080` | Internal ntfy Server Endpoint |
   | `NTFY_TOPIC` | `timetrax-alerts` | Target Push Notification Topic |
   | `TZ` | `America/New_York` | Container Timezone |

6. Click **Deploy the stack**.

---

## ⚙️ Initial TimeTrex Setup Wizard

1. Open **TimeTrex Web Interface**: `http://<YOUR_SERVER_IP>:8085`.
2. Complete the initial installation wizard:
   - **Database Driver**: `PostgreSQL`
   - **Database Host**: `timetrex-db`
   - **Database Name**: `timetrex`
   - **Database User**: `timetrex`
   - **Database Password**: `timetrexpass`
3. Configure your company, departments, and employees inside TimeTrex.

---

## 🔔 Webhook Integration to ntfy

To forward attendance events, clock-in/out alerts, and overtime notifications from TimeTrex to **ntfy**:
- Set the webhook notification target in TimeTrex or external integrations to:
  `http://timetrex-bridge:5000/webhook` (or `http://<YOUR_SERVER_IP>:5000/webhook`).
- The bridge automatically transforms the payload and sends push notifications to your ntfy topic (`timetrax-alerts`) on your phone or desktop.

---

## 📄 License

MIT License - TimeTrex Community Edition is open-source under AGPLv3.
