#!/usr/bin/env bash
# =====================================================================
# TorBox Media Server Host Setup Script
# Run this script on your Linux Docker host BEFORE deploying in Portainer
# Usage: sudo bash scripts/setup-host.sh
# =====================================================================

set -e

echo "🚀 Starting TorBox Media Server Host Setup..."

# 1. Install FUSE3
echo "📦 Installing FUSE3 and dependencies..."
if command -v apt-get &> /dev/null; then
    apt-get update && apt-get install -y fuse3
elif command -v dnf &> /dev/null; then
    dnf install -y fuse3
elif command -v pacman &> /dev/null; then
    pacman -Sy --noconfirm fuse3
fi

# Load fuse module
modprobe fuse || true

# 2. Create required directories
echo "📁 Creating directory structure..."
MEDIA_DIR="${MEDIA_DIR:-/mnt/torbox/media}"
DATA_DIR="${DATA_DIR:-/opt/torbox-stack}"

mkdir -p "$MEDIA_DIR"
mkdir -p "$DATA_DIR/jellyfin/config" "$DATA_DIR/jellyfin/cache"
mkdir -p "$DATA_DIR/jellyseerr/config"
mkdir -p "$DATA_DIR/riven/data" "$DATA_DIR/riven/db"

# Set permissions
CH_USER="${SUDO_USER:-$USER}"
chown -R "$CH_USER:$CH_USER" "$DATA_DIR" "$MEDIA_DIR"

# 3. Configure systemd service for mount propagation (rshared)
echo "⚙️ Creating systemd service for mount propagation..."
cat <<EOF > /etc/systemd/system/torbox-mount-prep.service
[Unit]
Description=Prepare TorBox Mount Directory for Shared Propagation
Before=docker.service

[Service]
Type=oneshot
ExecStart=/usr/bin/mount --make-rshared $MEDIA_DIR
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now torbox-mount-prep.service

echo "✅ Host setup complete!"
echo "📍 Media Mount Point: $MEDIA_DIR"
echo "📍 Data Directory:    $DATA_DIR"
echo "👉 You can now deploy the stack in Portainer using this Git Repository or docker-compose.yml."
