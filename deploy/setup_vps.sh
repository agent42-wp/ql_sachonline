#!/usr/bin/env bash
# Script triển khai tự động ứng dụng SachOnline lên VPS Ubuntu (vps-2324802010261)
# Chạy bằng quyền sudo trên VPS:
#   sudo bash deploy/setup_vps.sh
set -euo pipefail

APP_DIR="/opt/sachonline"
APP_USER="${APP_USER:-sv2324802010261}"
DB_NAME="sachonline"
DB_USER="sachonline_app"
ADMIN_SUBNET="${ADMIN_SUBNET:-192.168.100.0/24}"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "[LỖI] Vui lòng chạy script bằng sudo: sudo bash deploy/setup_vps.sh"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "=== [1/7] Cài đặt gói hệ thống (MariaDB, Nginx, Python venv, UFW) ==="
apt-get update -y
apt-get install -y mariadb-server nginx python3-venv python3-pip ufw openssl

echo "=== [2/7] Cấu hình MariaDB chỉ lắng nghe 127.0.0.1 ==="
MARIADB_CONF="/etc/mysql/mariadb.conf.d/50-server.cnf"
if grep -qE '^\s*bind-address\s*=' "${MARIADB_CONF}"; then
  sed -i 's/^\s*bind-address\s*=.*/bind-address = 127.0.0.1/' "${MARIADB_CONF}"
else
  printf '\n[mysqld]\nbind-address = 127.0.0.1\n' >> "${MARIADB_CONF}"
fi
systemctl enable --now mariadb
systemctl restart mariadb

echo "=== [3/7] Đồng bộ mã nguồn tới ${APP_DIR} ==="
mkdir -p "${APP_DIR}"
cp -r "${REPO_DIR}/backend" "${REPO_DIR}/frontend" "${REPO_DIR}/database" "${REPO_DIR}/deploy" \
  "${REPO_DIR}/requirements.txt" "${REPO_DIR}/.env.example" "${APP_DIR}/"

echo "=== [4/7] Khởi tạo .env, Database và tài khoản MariaDB riêng ==="
if [[ ! -f "${APP_DIR}/.env" ]]; then
  DB_PASS="$(openssl rand -hex 18)"
  JWT_KEY="$(openssl rand -hex 32)"
  cat > "${APP_DIR}/.env" <<EOF
DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=${DB_NAME}
DB_USER=${DB_USER}
DB_PASSWORD=${DB_PASS}

JWT_SECRET_KEY=${JWT_KEY}
JWT_ALGORITHM=HS256
JWT_EXPIRE_MINUTES=120
COOKIE_SECURE=false

APP_TITLE=SachOnline - Quan Ly Sach Online (vps-2324802010261)
APP_HOST=127.0.0.1
APP_PORT=8000
EOF
  chmod 600 "${APP_DIR}/.env"
  echo "[OK] Đã tạo ${APP_DIR}/.env với mật khẩu DB và JWT secret ngẫu nhiên."
else
  echo "[INFO] Đã có ${APP_DIR}/.env, giữ nguyên cấu hình hiện tại."
  DB_PASS="$(grep '^DB_PASSWORD=' "${APP_DIR}/.env" | cut -d= -f2-)"
fi

mariadb <<SQL
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}';
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
ALTER USER '${DB_USER}'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}';
ALTER USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT SELECT, INSERT, UPDATE, DELETE ON \`${DB_NAME}\`.* TO '${DB_USER}'@'127.0.0.1';
GRANT SELECT, INSERT, UPDATE, DELETE ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
SQL

TABLE_COUNT="$(mariadb -N -s -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${DB_NAME}';")"
if [[ "${TABLE_COUNT}" -eq 0 ]]; then
  echo "[INFO] Đang nạp dữ liệu ban đầu từ database/sachonline_mariadb.sql..."
  mariadb "${DB_NAME}" < "${APP_DIR}/database/sachonline_mariadb.sql"
else
  echo "[INFO] Database ${DB_NAME} đã có ${TABLE_COUNT} bảng, bỏ qua bước nạp lại."
fi

echo "=== [5/7] Tạo Python virtualenv & cài thư viện ==="
python3 -m venv "${APP_DIR}/.venv"
"${APP_DIR}/.venv/bin/pip" install --upgrade pip
"${APP_DIR}/.venv/bin/pip" install -r "${APP_DIR}/requirements.txt"

if id "${APP_USER}" &>/dev/null; then
  chown -R "${APP_USER}:www-data" "${APP_DIR}"
  chmod 600 "${APP_DIR}/.env"
fi

echo "=== [6/7] Cấu hình dịch vụ systemd & Nginx reverse proxy ==="
cp "${APP_DIR}/deploy/sachonline.service" /etc/systemd/system/sachonline.service
systemctl daemon-reload
systemctl enable --now sachonline
systemctl restart sachonline

cp "${APP_DIR}/deploy/nginx-sachonline.conf" /etc/nginx/sites-available/sachonline
ln -sf /etc/nginx/sites-available/sachonline /etc/nginx/sites-enabled/sachonline
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl enable --now nginx
systemctl reload nginx

echo "=== [7/7] Thiết lập tường lửa UFW ==="
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow from "${ADMIN_SUBNET}" to any port 22 proto tcp
ufw allow 80/tcp
ufw --force enable

echo ""
echo "=== HOÀN TẤT TRIỂN KHAI SACHONLINE TRÊN $(hostname) ==="
echo "- Kiểm tra dịch vụ : sudo systemctl status sachonline mariadb nginx --no-pager"
echo "- Kiểm tra cổng    : sudo ss -tlnp"
echo "- Kiểm tra tường lửa: sudo ufw status verbose"
echo "- Truy cập ứng dụng : http://192.168.100.20"
