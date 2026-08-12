#!/usr/bin/env bash
# =====================================================================
# TimeTrax Host Setup Script
# Run this script on your Linux Docker host BEFORE deploying in Portainer/Docker
# Usage: sudo bash scripts/setup-host.sh
# =====================================================================

set -e

echo "🚀 Starting TimeTrax Host Setup..."

# 1. Create required directories
echo "📁 Creating directory structure..."
DATA_DIR="${DATA_DIR:-/opt/timetrax/data}"
NTFY_DATA_DIR="${NTFY_DATA_DIR:-/opt/timetrax/ntfy}"

mkdir -p "$DATA_DIR"
mkdir -p "$NTFY_DATA_DIR/cache" "$NTFY_DATA_DIR/config"

# Set permissions
CH_USER="${SUDO_USER:-$USER}"
chown -R "$CH_USER:$CH_USER" "$DATA_DIR" "$NTFY_DATA_DIR" 2>/dev/null || true

echo "✅ Host directory setup complete!"
echo "📍 TimeTrax Data Directory: $DATA_DIR"
echo "📍 ntfy Data Directory:     $NTFY_DATA_DIR"
echo "👉 You can now deploy the stack using Docker Compose or Portainer."
