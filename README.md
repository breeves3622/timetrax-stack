# 🎬 TorBox Netflix-Style Media Stack

A production-ready, zero-local-storage **Netflix-style cloud media server** deployed via **Portainer Stacks** (Docker Compose). Powered by **TorBox** debrid, **Riven**, **Jellyfin**, and **Jellyseerr**.

![Jellyfin + Jellyseerr + TorBox Stack Architecture](https://img.shields.io/badge/Docker-Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Portainer Compatible](https://img.shields.io/badge/Portainer-Stack-13BEF9?style=for-the-badge&logo=portainer&logoColor=white)
![TorBox Debrid](https://img.shields.io/badge/TorBox-Cloud_Debrid-6C5CE7?style=for-the-badge)

---

## 🌟 Key Features

- 🍿 **Zero Local Storage**: Movies and TV shows stream directly from TorBox cloud cache via virtual filesystem (VFS/FUSE).
- 📺 **Netflix-Style UI**: Watch on web browsers, Smart TVs (FireStick, Roku, Apple TV, Android TV), iOS, and Android using **Jellyfin**.
- 🔍 **Discovery & Requests**: Search trending releases, cast recommendations, and request content in 1 click using **Jellyseerr**.
- ⚡ **Automated Scrapers**: **Riven** automatically queries scrapers (Torrentio, Comet, KnightCrawler) to fetch cached streams instantly from TorBox.
- 🐳 **Portainer Native**: Deployable directly via Portainer Stacks (Git Repo or Web Editor).

---

## 🏗️ Architecture

```
┌───────────────────────────────────────────────────────────┐
│                      USER INTERFACE                       │
│    Jellyfin (Player / UI)   │   Jellyseerr (Requests)     │
└──────────────────────────────┬────────────────────────────┘
                               │ Request Trigger
                               ▼
┌───────────────────────────────────────────────────────────┐
│                      MEDIA ENGINE                         │
│       Riven (Scraper Engine & Virtual File System)        │
└──────────────────────────────┬────────────────────────────┘
                               │ Instant Stream Fetch
                               ▼
┌───────────────────────────────────────────────────────────┐
│                     CLOUD PROVIDER                        │
│                   TorBox Debrid API                       │
└───────────────────────────────────────────────────────────┘
```

---

## 🛠️ Step 1: Prepare the Host Machine

Run the host setup script on your Linux Docker host via SSH:

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
cd YOUR_REPO_NAME

# Run setup script (Installs FUSE3, creates directories, sets up mount propagation)
sudo bash scripts/setup-host.sh
```

---

## 🚀 Step 2: Deploying via Portainer

You can deploy this stack in **Portainer** using **Option A (Git Repository)** or **Option B (Copy & Paste)**:

### Option A: Deploy via Git Repository in Portainer (Recommended)

1. Open **Portainer** -> **Stacks** -> **+ Add stack**.
2. Name the stack: `torbox-media-stack`.
3. Select **Repository** as the build method.
4. Set **Repository URL**: `https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git`
5. Set **Repository reference**: `refs/heads/main`
6. Set **Compose path**: `docker-compose.yml`
7. Under **Environment variables**, click **+ Add environment variable** and set your variables (or reference `.env`):
   - `TORBOX_API_KEY`: Your TorBox API Key (from [TorBox Settings](https://torbox.app/settings))
   - `SERVER_IP`: Your server's local or public IP
   - `TZ`: `America/New_York` (or your timezone)
8. Click **Deploy the stack**.

---

### Option B: Deploy via Web Editor in Portainer

1. Open **Portainer** -> **Stacks** -> **+ Add stack**.
2. Name the stack: `torbox-media-stack`.
3. Select **Web editor**, copy the contents of [`docker-compose.yml`](docker-compose.yml), and paste them into the editor.
4. Add environment variables under the **Environment variables** panel.
5. Click **Deploy the stack**.

---

## ⚙️ Step 3: Service Configuration

Once deployed, access and configure the services in the following order:

### 1. Riven Admin Interface (`http://<YOUR_SERVER_IP>:8080`)
- **Debrid Provider**: Select **TorBox** and enter your API Key.
- **Scrapers**: Enable **Torrentio**, **Comet**, and **KnightCrawler**.
- **Mount Path**: Ensure it points to `/mnt/torbox/media`.

### 2. Jellyfin Media Server (`http://<YOUR_SERVER_IP>:8096`)
- Complete setup wizard and create an admin user.
- Add Media Libraries:
  - **Movies**: `/data/media/movies`
  - **TV Shows**: `/data/media/tv`
- Go to **Dashboard** -> **API Keys** -> Create an API key named `Jellyseerr`.

### 3. Jellyseerr Frontend (`http://<YOUR_SERVER_IP>:5055`)
- Sign in with Jellyfin (`http://jellyfin:8096` using your Jellyfin admin credentials).
- Enable **Discovery Sync** for automatic Netflix-style categories.

---

## 🔒 Remote Streaming

- **Tailscale**: Install Tailscale on your host to securely stream from anywhere via `http://<tailscale-ip>:8096`.
- **Nginx Proxy Manager / Cloudflare Tunnel**: Point your custom domain (e.g. `https://netflix.yourdomain.com`) to `http://localhost:8096`.

---

## 📄 License

MIT License - feel free to customize and share!
