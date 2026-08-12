#!/usr/bin/env bash
set -e

echo "🚀 Starting TimeTrex Community Edition..."

# Set global environment variable for TimeTrex Config File
export TIMETREX_CONFIG_FILE="/var/www/html/timetrex.ini.php"

# Ensure php.ini exists at runtime so php_ini_loaded_file() is never false
if [ ! -f "/usr/local/etc/php/php.ini" ]; then
    echo "⚙️ Creating /usr/local/etc/php/php.ini..."
    if [ -f "/usr/local/etc/php/php.ini-production" ]; then
        cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini
    else
        touch /usr/local/etc/php/php.ini
    fi
    { \
        echo 'memory_limit = 512M'; \
        echo 'max_execution_time = 300'; \
        echo 'post_max_size = 100M'; \
        echo 'upload_max_filesize = 100M'; \
        echo 'display_errors = Off'; \
        echo 'display_startup_errors = Off'; \
        echo 'log_errors = On'; \
        echo 'error_reporting = E_ALL & ~E_NOTICE & ~E_STRICT & ~E_DEPRECATED & ~E_WARNING'; \
        echo 'date.timezone = UTC'; \
    } >> /usr/local/etc/php/php.ini
fi

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

[directories]
storage_dir = /var/www/storage/storage
cache_dir = /var/www/storage/cache
log_dir = /var/www/storage/logs

[cache]
enable = TRUE
dir = /var/www/storage/cache
cache_dir = /var/www/storage/cache

[storage]
enable = TRUE
dir = /var/www/storage/storage
storage_dir = /var/www/storage/storage

[logging]
enable = TRUE
log_dir = /var/www/storage/logs
dir = /var/www/storage/logs

[log]
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

# Create config symlinks across all candidate paths for Web API and CLI
mkdir -p /etc/timetrex 2>/dev/null || true
ln -sf /var/www/html/timetrex.ini.php /etc/timetrex/timetrex.ini.php 2>/dev/null || true
ln -sf /var/www/html/timetrex.ini.php /etc/timetrex.ini.php 2>/dev/null || true
ln -sf /var/www/html/timetrex.ini.php /var/www/html/includes/timetrex.ini.php 2>/dev/null || true
ln -sf /var/www/html/timetrex.ini.php /var/www/html/interface/timetrex.ini.php 2>/dev/null || true
ln -sf /var/www/html/timetrex.ini.php /var/www/html/interface/install/timetrex.ini.php 2>/dev/null || true

exec "$@"
