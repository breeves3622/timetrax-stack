#!/usr/bin/env bash
set -e

echo "🚀 Starting TimeTrex Community Edition..."

# Wait for PostgreSQL database to be ready
echo "⌛ Waiting for PostgreSQL database connection..."
until php -r "
  \$conn = @pg_connect('host=${TIMETREX_DB_HOST:-timetrex-db} port=${TIMETREX_DB_PORT:-5432} dbname=${TIMETREX_DB_NAME:-timetrex} user=${TIMETREX_DB_USER:-timetrex} password=${TIMETREX_DB_PASSWORD:-timetrexpass}');
  if (\$conn) { exit(0); } else { exit(1); }
"; do
  echo "Database is unavailable - sleeping 2 seconds..."
  sleep 2
done
echo "✅ Database connection established!"

# Ensure permissions
chown -R www-data:www-data /var/www/html/storage /var/www/html/includes 2>/dev/null || true

# Generate timetrex.ini.php configuration if not present
INI_FILE="/var/www/html/timetrex.ini.php"
if [ ! -f "$INI_FILE" ]; then
    echo "⚙️ Creating TimeTrex configuration file (timetrex.ini.php)..."
    cat <<EOF > "$INI_FILE"
[database]
adapter = mysqli
host = ${TIMETREX_DB_HOST:-timetrex-db}
database_name = ${TIMETREX_DB_NAME:-timetrex}
user = ${TIMETREX_DB_USER:-timetrex}
password = ${TIMETREX_DB_PASSWORD:-timetrexpass}
port = ${TIMETREX_DB_PORT:-5432}

[path]
storage_dir = /var/www/html/storage
log_dir = /var/www/html/storage/logs

[webhook]
ntfy_server_url = ${NTFY_SERVER_URL:-http://ntfy:8080}
ntfy_topic = ${NTFY_TOPIC:-timetrax-alerts}
EOF
    chown www-data:www-data "$INI_FILE"
    cp "$INI_FILE" /var/www/html/includes/timetrex.ini.php 2>/dev/null || true
fi

exec "$@"
