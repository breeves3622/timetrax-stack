#!/usr/bin/env bash
set -e

echo "🛠️ Creating TimeTrax Host storage directories at /opt/timetrax..."

sudo mkdir -p /opt/timetrax/trackable/data /opt/timetrax/trackable/media /opt/timetrax/ntfy
sudo chmod -R 777 /opt/timetrax

echo "✅ Storage directories created successfully:"
echo "   - /opt/timetrax/trackable/data"
echo "   - /opt/timetrax/trackable/media"
echo "   - /opt/timetrax/ntfy"
