#!/usr/bin/env bash
# =============================================================================
#  MedCare CRM — Server Setup & Seed Script
#  Запуск: bash setup-server.sh
#  Робить: перевіряє БД, накочує схему, сідить тестові дані, виводить логіни
# =============================================================================
set -euo pipefail

# ── Кольори ──────────────────────────────────────────────────────────────────
G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[1;34m'; NC='\033[0m'
ok()   { echo -e "${G}✅  $*${NC}"; }
info() { echo -e "${B}ℹ   $*${NC}"; }
warn() { echo -e "${Y}⚠   $*${NC}"; }
fail() { echo -e "${R}❌  $*${NC}"; exit 1; }

echo -e "${B}"
echo "╔══════════════════════════════════════════╗"
echo "║   MedCare CRM — Server Setup Script      ║"
echo "╚══════════════════════════════════════════╝${NC}"

# ── 1. Зчитуємо .env ─────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/backend/.env"

if [[ -f "$ENV_FILE" ]]; then
  export $(grep -v '^#' "$ENV_FILE" | xargs)
  ok "Loaded $ENV_FILE"
else
  warn ".env not found — using environment variables or defaults"
fi

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_USERNAME="${DB_USERNAME:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-postgres}"
DB_NAME="${DB_NAME:-medcare}"
JWT_SECRET="${JWT_SECRET:-medcare-super-secret-jwt-key-change-in-production}"
PORT="${PORT:-3000}"

info "DB: postgresql://$DB_USERNAME@$DB_HOST:$DB_PORT/$DB_NAME"

# ── 2. Перевіряємо PostgreSQL ─────────────────────────────────────────────────
info "Checking PostgreSQL connection..."
PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" -d postgres -c '\q' 2>/dev/null \
  || fail "Cannot connect to PostgreSQL at $DB_HOST:$DB_PORT as $DB_USERNAME"
ok "PostgreSQL is reachable"

# ── 3. Створюємо базу якщо не існує ──────────────────────────────────────────
DB_EXISTS=$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" -tAc \
  "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" 2>/dev/null || echo "0")

if [[ "$DB_EXISTS" != "1" ]]; then
  info "Creating database '$DB_NAME'..."
  PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" -d postgres \
    -c "CREATE DATABASE $DB_NAME;" 2>/dev/null
  ok "Database '$DB_NAME' created"
else
  ok "Database '$DB_NAME' already exists"
fi

# ── 4. Розширення PostgreSQL ──────────────────────────────────────────────────
info "Installing PostgreSQL extensions..."
PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" -d "$DB_NAME" <<-SQL 2>/dev/null
  CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
  CREATE EXTENSION IF NOT EXISTS "pg_trgm";
SQL
ok "Extensions: uuid-ossp, pg_trgm"

# ── 5. Встановлюємо npm залежності ───────────────────────────────────────────
cd "$SCRIPT_DIR/backend"

if [[ ! -d "node_modules" ]]; then
  info "Installing npm dependencies..."
  npm install --cache /tmp/npm-cache --silent 2>/dev/null || npm install --cache /tmp/npm-cache
  ok "npm install done"
else
  ok "node_modules already present"
fi

# ── 6. Запускаємо seed через TypeORM ─────────────────────────────────────────
info "Running database seed..."

# Перевіряємо чи таблиця users вже заповнена
USER_COUNT=$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" \
  -d "$DB_NAME" -tAc "SELECT COUNT(*) FROM users" 2>/dev/null || echo "0")

if [[ "$USER_COUNT" -gt "0" ]]; then
  warn "Database already has $USER_COUNT users."
  echo -n "  Re-seed (wipe existing data)? [y/N]: "
  read -r RESEED
  if [[ "$RESEED" != "y" && "$RESEED" != "Y" ]]; then
    info "Skipping seed — keeping existing data"
    SKIP_SEED=true
  else
    info "Wiping existing data..."
    PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" -d "$DB_NAME" <<-SQL 2>/dev/null
      TRUNCATE prescriptions, invoices, medical_records, appointments,
               patients, doctors, medications, wards, audit_logs, users
               RESTART IDENTITY CASCADE;
SQL
    ok "Data wiped"
    SKIP_SEED=false
  fi
else
  SKIP_SEED=false
fi

if [[ "$SKIP_SEED" != "true" ]]; then
  DB_HOST="$DB_HOST" DB_PORT="$DB_PORT" DB_USERNAME="$DB_USERNAME" \
  DB_PASSWORD="$DB_PASSWORD" DB_NAME="$DB_NAME" \
  npx ts-node -r tsconfig-paths/register src/database/seed.ts
  ok "Seed completed"
fi

# ── 7. Підсумок облікових записів ─────────────────────────────────────────────
echo ""
echo -e "${B}╔══════════════════════════════════════════════════════════════╗"
echo "║           ОБЛІКОВІ ЗАПИСИ MEDCARE CRM                        ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  РОЛЬ          EMAIL                     ПАРОЛЬ             ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  admin         admin@medcare.ua          admin123           ║"
echo "║  doctor        doctor@medcare.ua         password123        ║"
echo "║  doctor        kardio@medcare.ua         password123        ║"
echo "║  doctor        neuro@medcare.ua          password123        ║"
echo "║  doctor        surgeon@medcare.ua        password123        ║"
echo "╚══════════════════════════════════════════════════════════════╝${NC}"

# ── 8. Показуємо поточний стан БД ────────────────────────────────────────────
echo ""
info "Current database state:"
PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" -d "$DB_NAME" <<-SQL
  SELECT
    (SELECT COUNT(*) FROM users)       AS users,
    (SELECT COUNT(*) FROM doctors)     AS doctors,
    (SELECT COUNT(*) FROM patients)    AS patients,
    (SELECT COUNT(*) FROM appointments) AS appointments,
    (SELECT COUNT(*) FROM medications) AS medications,
    (SELECT COUNT(*) FROM invoices)    AS invoices;
SQL

# ── 9. Запускаємо сервер (опціонально) ───────────────────────────────────────
echo ""
echo -n "  Start NestJS server now? [y/N]: "
read -r START_SERVER

if [[ "$START_SERVER" == "y" || "$START_SERVER" == "Y" ]]; then
  info "Starting NestJS on port $PORT..."
  DB_HOST="$DB_HOST" DB_PORT="$DB_PORT" DB_USERNAME="$DB_USERNAME" \
  DB_PASSWORD="$DB_PASSWORD" DB_NAME="$DB_NAME" JWT_SECRET="$JWT_SECRET" PORT="$PORT" \
  npx ts-node -r tsconfig-paths/register src/main.ts &

  SERVER_PID=$!
  echo "$SERVER_PID" > /tmp/medcare-server.pid

  sleep 6
  if kill -0 "$SERVER_PID" 2>/dev/null; then
    ok "Server running (PID $SERVER_PID) → http://localhost:$PORT/api"
    ok "Swagger docs → http://localhost:$PORT/api/docs"
    echo ""
    info "To stop: kill \$(cat /tmp/medcare-server.pid)"
  else
    fail "Server failed to start — check logs above"
  fi
else
  echo ""
  info "To start server manually:"
  echo "  cd backend"
  echo "  npx ts-node -r tsconfig-paths/register src/main.ts"
fi

echo ""
ok "Setup complete!"
