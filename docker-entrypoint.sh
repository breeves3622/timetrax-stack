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

# Create interface symlinks for web installer and HTML5 UI
if [ -d "/var/www/html/interface" ]; then
    ln -sf /var/www/html/interface /var/www/html/html5 2>/dev/null || true
    ln -sf /var/www/html/interface/install /var/www/html/install 2>/dev/null || true
    if [ -d "/var/www/html/interface/html5" ]; then
        ln -sf /var/www/html/interface/html5 /var/www/html/html5 2>/dev/null || true
    fi
fi

# Ensure storage directory permissions
mkdir -p /var/www/html/storage/storage /var/www/html/storage/logs
chown -R www-data:www-data /var/www/html/storage /var/www/html/includes 2>/dev/null || true

# Generate timetrex.ini.php configuration
INI_FILE="/var/www/html/timetrex.ini.php"
echo "⚙️ Writing TimeTrex configuration file (timetrex.ini.php)..."
cat <<EOF > "$INI_FILE"
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
storage_dir = /var/www/html/storage
log_dir = /var/www/html/storage/logs

[debug]
production = TRUE
enable = FALSE
enable_display_errors = FALSE
verbose = 0

[webhook]
ntfy_server_url = ${NTFY_SERVER_URL:-http://ntfy:8080}
ntfy_topic = ${NTFY_TOPIC:-timetrax-alerts}
EOF

chown www-data:www-data "$INI_FILE"
cp "$INI_FILE" /var/www/html/includes/timetrex.ini.php 2>/dev/null || true

# Check if PostgreSQL database tables exist
HAS_TABLES=$(php -r "
  \$conn = @pg_connect('host=${DB_HOST} port=${DB_PORT} dbname=${DB_NAME} user=${DB_USER} password=${DB_PASS}');
  if (\$conn) {
    \$res = @pg_query(\$conn, \"SELECT to_regclass('public.system_setting')\");
    if (\$res) {
      \$row = pg_fetch_row(\$res);
      if (!empty(\$row[0])) { echo 'YES'; exit(0); }
    }
  }
  echo 'NO';
")

if [ "$HAS_TABLES" = "NO" ]; then
    echo "⚠️ PostgreSQL database '${DB_NAME}' tables are not initialized yet!"
    echo "👉 Please navigate to http://<YOUR_SERVER_IP>:8090/interface/install/install.php in your web browser to run the TimeTrex Setup Wizard."
fi

exec "$@"
