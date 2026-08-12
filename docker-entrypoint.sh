#!/usr/bin/env bash
set -e

echo "🚀 Starting TimeTrex Community Edition..."

DB_HOST="${TIMETREX_DB_HOST:-timetrex-db}"
DB_PORT="${TIMETREX_DB_PORT:-5432}"
DB_NAME="${TIMETREX_DB_NAME:-timetrex}"
DB_USER="${TIMETREX_DB_USER:-timetrex}"
DB_PASS="${TIMETREX_DB_PASSWORD:-timetrexpass}"

# Wait for PostgreSQL database connection
echo "⌛ Waiting for PostgreSQL database connection (${DB_HOST}:${DB_PORT})..."
until php -r "
  \$conn = @pg_connect('host=${DB_HOST} port=${DB_PORT} dbname=${DB_NAME} user=${DB_USER} password=${DB_PASS}');
  if (\$conn) { exit(0); } else { exit(1); }
"; do
  echo "Database is unavailable - sleeping 2 seconds..."
  sleep 2
done
echo "✅ Database connection established!"

# Ensure PHP CLI symlinks exist in all standard paths
ln -sf /usr/local/bin/php /usr/bin/php 2>/dev/null || true

# Create interface symlinks for web installer and HTML5 UI
if [ -d "/var/www/html/interface" ]; then
    ln -sf /var/www/html/interface /var/www/html/html5 2>/dev/null || true
    ln -sf /var/www/html/interface/install /var/www/html/install 2>/dev/null || true
    if [ -d "/var/www/html/interface/html5" ]; then
        ln -sf /var/www/html/interface/html5 /var/www/html/html5 2>/dev/null || true
    fi
fi

# Ensure storage directories OUTSIDE web root (/var/www/html) exist & are writable
mkdir -p /var/www/storage/storage /var/www/storage/cache /var/www/storage/logs
chown -R www-data:www-data /var/www/storage 2>/dev/null || true
chmod -R 777 /var/www/storage 2>/dev/null || true

# Generate timetrex.ini.php configuration
INI_FILE="/var/www/html/timetrex.ini.php"
echo "⚙️ Writing TimeTrex configuration file (timetrex.ini.php)..."
cat <<EOF > "$INI_FILE"
[other]
installer_enabled = TRUE
min_free_disk_space = 0
check_disk_space = FALSE

[installer]
enabled = TRUE
installer_enabled = TRUE

[system]
installer_enabled = TRUE
min_free_disk_space = 0
check_disk_space = FALSE

[database]
type = postgres
adapter = pgsql
host = ${DB_HOST}
database_name = ${DB_NAME}
user = ${DB_USER}
password = ${DB_PASS}
port = ${DB_PORT}

[path]
base_url = /interface
storage_dir = /var/www/storage/storage
cache_dir = /var/www/storage/cache
log_dir = /var/www/storage/logs
php_cli = /usr/local/bin/php

[cache]
enable = TRUE
dir = /var/www/storage/cache

[logging]
enable = TRUE
log_dir = /var/www/storage/logs
dir = /var/www/storage/logs

[debug]
production = FALSE
enable = FALSE
enable_display_errors = FALSE
verbose = 0

[webhook]
ntfy_server_url = ${NTFY_SERVER_URL:-http://ntfy:8080}
ntfy_topic = ${NTFY_TOPIC:-timetrax-alerts}
EOF

chown www-data:www-data "$INI_FILE"

# Create config symlinks in /etc/timetrex/ and /var/www/html/includes/ so CLI and Web API find it
mkdir -p /etc/timetrex 2>/dev/null || true
ln -sf /var/www/html/timetrex.ini.php /etc/timetrex/timetrex.ini.php 2>/dev/null || true
ln -sf /var/www/html/timetrex.ini.php /var/www/html/includes/timetrex.ini.php 2>/dev/null || true

exec "$@"
