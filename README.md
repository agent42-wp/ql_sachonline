# SachOnline – Triển khai Ứng dụng Web Quản lý Sách Online trên VPS

> **Bài cá nhân 2 – Điện toán đám mây**
> - **Sinh viên**: Nguyễn Minh Khôi — **MSSV**: `2324802010261`
> - **VPS triển khai**: `vps-2324802010261` (Ubuntu 26.04.1 LTS, 2 vCPU, 2 GB RAM, 20 GB Disk, IP tĩnh `192.168.100.20/24`)
> - **Stack**: Python **FastAPI** (Gunicorn + UvicornWorker + `systemd`) · Frontend **HTML/CSS/JS** · **MariaDB** · **Nginx Reverse Proxy** · **UFW**

---

## 1. Kiến trúc Hệ thống

```text
Trình duyệt Laptop (http://192.168.100.20)
        │  HTTP :80
        ▼
  [ UFW Firewall ]  ← Mặc định chặn vào; chỉ mở 80/tcp và 22/tcp từ 192.168.100.0/24
        │
        ▼
  [ Nginx :80 ] ──( / )──────► Frontend tĩnh (HTML/CSS/JS)
        │
        └──( /api/* )────────► FastAPI Backend (systemd, CHỈ lắng nghe 127.0.0.1:8000)
                                      │
                                      ▼ (PyMySQL + user riêng sachonline_app)
                               [ MariaDB ] (CHỈ lắng nghe 127.0.0.1:3306)
```

---

## 2. Chuyển đổi Cơ sở Dữ liệu từ SQL Server (`SachOnline.sql`) sang MariaDB

Tệp gốc `SachOnline.sql` (T-SQL / SQL Server) đã được chuyển đổi hoàn chỉnh sang [database/sachonline_mariadb.sql](database/sachonline_mariadb.sql) với 13 bảng (`CHUDE`, `NHAXUATBAN`, `SACH`, `TACGIA`, `VIETSACH`, `KHACHHANG`, `DONDATHANG`, `CHITIETDATHANG`, `TRANGTIN`, `SLIDER`, `BINHLUAN`, `ADMIN`, `MENU`):

| Hạng mục | SQL Server (`SachOnline.sql`) | MariaDB (`sachonline_mariadb.sql`) |
|---|---|---|
| Tự tăng khóa chính | `INT IDENTITY(1,1)` | `INT AUTO_INCREMENT` |
| Chuỗi Unicode | `NVARCHAR(n)`, `NTEXT`, `N'...'` | `VARCHAR(n)`, `TEXT`, `utf8mb4_unicode_ci` |
| Thời gian | `SMALLDATETIME`, `GETDATE()`, `MM/DD/YYYY` | `DATETIME`, `CURRENT_TIMESTAMP`, ISO `YYYY-MM-DD` |
| Ngày dạng hex | `CAST(0x95450000 AS SmallDateTime)`, `0x93F90000` | `'2004-08-16 00:00:00'`, `'2003-09-19 00:00:00'` |
| Tiền tệ / Logic | `MONEY`, `BIT DEFAULT(0)` | `DECIMAL(12,2)`, `TINYINT(1) DEFAULT 0` |
| Khóa ngoại lỗi gốc | `VIETSACH (MaSach=24, MaTG=2)` không tồn tại trong `SACH` | Đã loại bỏ dòng orphan để đảm bảo toàn vẹn FK |
| Bảo mật mật khẩu | `VARCHAR(64)` + `SHA2_256` không muối | `VARCHAR(255)` + băm **bcrypt** (`$2b$12$...`, có salt ngẫu nhiên) |

---

## 3. Tính năng & Bảo mật đã cài đặt

- **Xác thực người dùng**:
  - `POST /api/auth/register`: Đăng ký tài khoản mới (`KHACHHANG`), kiểm tra trùng tài khoản/email, băm mật khẩu bằng **bcrypt**.
  - `POST /api/auth/login` & `POST /api/auth/logout` & `GET /api/auth/me`: Đăng nhập bằng tài khoản `ADMIN` hoặc `KHACHHANG`, cấp phiên JWT lưu trong **`HttpOnly; SameSite=Lax` cookie** (chống đọc token qua XSS, không dùng `localStorage`) đồng thời hỗ trợ header `Authorization: Bearer`.
- **Quản lý Sách (CRUD)**:
  - `GET /api/books` (tìm kiếm theo tên, lọc theo Chủ đề & NXB, phân trang), `GET /api/books/{id}`.
  - `POST /api/books`, `PUT /api/books/{id}`, `DELETE /api/books/{id}` (yêu cầu đăng nhập; chặn xóa sách đã nằm trong đơn đặt hàng với mã `409`).
- **Tăng cường bảo mật**:
  - Truy vấn tham số hóa qua SQLAlchemy ORM (chống SQL Injection).
  - Frontend tạo DOM bằng `document.createElement` và `textContent` (không dùng `innerHTML` với dữ liệu từ server/người dùng → chống XSS).
  - Nginx cấu hình `server_tokens off`, `X-Frame-Options`, `X-Content-Type-Options`, `Referrer-Policy`, `Content-Security-Policy`.
  - Bí mật (mật khẩu DB, `JWT_SECRET_KEY`) nằm trong `.env` (quyền `600`, bị chặn trong `.gitignore`); repo chỉ chứa `.env.example`.

---

## 4. Hướng dẫn Cài đặt từ đầu trên VPS (`vps-2324802010261`)

### Cách 1: Chạy script tự động (khuyến nghị)

```bash
# SSH vào VPS bằng khóa từ máy quản trị
ssh sv2324802010261@192.168.100.20

# Clone mã nguồn từ GitHub
git clone <LINK_REPO_GITHUB_CUA_BAN> ~/ql_sachonline
cd ~/ql_sachonline

# Chạy script triển khai (cài MariaDB, Nginx, Python venv, systemd, UFW)
sudo bash deploy/setup_vps.sh
```

### Cách 2: Cài đặt thủ công từng bước (thuận tiện chụp ảnh minh chứng báo cáo)

#### Bước 1: Cài đặt MariaDB, Nginx, Python venv và UFW
```bash
sudo apt update && sudo apt install -y mariadb-server nginx python3-venv python3-pip ufw openssl
```

#### Bước 2: Cấu hình MariaDB chỉ lắng nghe `127.0.0.1` và nạp dữ liệu
```bash
# Kiểm tra / chỉnh bind-address = 127.0.0.1 trong /etc/mysql/mariadb.conf.d/50-server.cnf
sudo sed -i 's/^\s*bind-address\s*=.*/bind-address = 127.0.0.1/' /etc/mysql/mariadb.conf.d/50-server.cnf
sudo systemctl enable --now mariadb
sudo systemctl restart mariadb

# Tạo DB và user riêng sachonline_app (đổi mật khẩu mạnh trước khi chạy)
sudo mariadb -e "
CREATE DATABASE IF NOT EXISTS sachonline CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'sachonline_app'@'127.0.0.1' IDENTIFIED BY 'MAT_KHAU_MANH_CUA_BAN';
CREATE USER IF NOT EXISTS 'sachonline_app'@'localhost' IDENTIFIED BY 'MAT_KHAU_MANH_CUA_BAN';
GRANT SELECT, INSERT, UPDATE, DELETE ON sachonline.* TO 'sachonline_app'@'127.0.0.1';
GRANT SELECT, INSERT, UPDATE, DELETE ON sachonline.* TO 'sachonline_app'@'localhost';
FLUSH PRIVILEGES;
"

# Nạp lược đồ & dữ liệu mẫu đã chuyển đổi sang MariaDB
sudo mariadb sachonline < database/sachonline_mariadb.sql
```

#### Bước 3: Cài đặt Backend vào `/opt/sachonline` và tạo tệp `.env`
```bash
sudo mkdir -p /opt/sachonline
sudo cp -r backend frontend database deploy requirements.txt .env.example /opt/sachonline/
sudo chown -R sv2324802010261:www-data /opt/sachonline

cd /opt/sachonline
cp .env.example .env
chmod 600 .env
# Mở .env bằng nano để điền DB_PASSWORD (khớp Bước 2) và JWT_SECRET_KEY (sinh bằng: openssl rand -hex 32)
nano .env

python3 -m venv .venv
.venv/bin/pip install --upgrade pip
.venv/bin/pip install -r requirements.txt
```

#### Bước 4: Cài dịch vụ `systemd` cho Backend (`127.0.0.1:8000`)
```bash
sudo cp /opt/sachonline/deploy/sachonline.service /etc/systemd/system/sachonline.service
sudo systemctl daemon-reload
sudo systemctl enable --now sachonline
sudo systemctl status sachonline --no-pager
```

#### Bước 5: Cấu hình Nginx Reverse Proxy ở cổng 80
```bash
sudo cp /opt/sachonline/deploy/nginx-sachonline.conf /etc/nginx/sites-available/sachonline
sudo ln -sf /etc/nginx/sites-available/sachonline /etc/nginx/sites-enabled/sachonline
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl enable --now nginx
sudo systemctl reload nginx
```

#### Bước 6: Bật tường lửa UFW theo yêu cầu đề bài
```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow from 192.168.100.0/24 to any port 22 proto tcp
sudo ufw allow 80/tcp
sudo ufw enable
sudo ufw status verbose
```

---

## 5. Tài khoản mẫu để kiểm thử đăng nhập

Tất cả tài khoản mẫu trong `database/sachonline_mariadb.sql` đã được băm sẵn bằng **bcrypt**:

| Loại tài khoản | Tên đăng nhập | Mật khẩu gốc (để test) | Vai trò |
|---|---|---|---|
| Quản trị (`ADMIN`) | `khoidz` | `khoikhoi` | `admin` |
| Khách hàng (`KHACHHANG`) | `khoi` | `khoikhoi` | `customer` |
| Khách hàng (`KHACHHANG`) | `luongvq` | `12345` | `admin` / `customer` |

*(Ngoài ra có thể bấm nút **Đăng ký** trực tiếp trên giao diện để tạo tài khoản mới và kiểm tra mật khẩu băm `$2b$12$...` trong bảng `KHACHHANG`.)*

---

## 6. Lệnh Kiểm chứng Nghiệm thu & Chụp Minh chứng Báo cáo

> Lưu ý quy định chung: **Mọi ảnh chụp màn hình phải thấy MSSV `2324802010261`** (dòng nhắc `sv2324802010261@vps-2324802010261` hoặc tiêu đề web `vps-2324802010261`).

```bash
# 1. Xác nhận các dịch vụ đều active và tự khởi động cùng VPS
sudo systemctl is-enabled sachonline mariadb nginx
sudo systemctl status sachonline mariadb nginx --no-pager

# 2. Xác nhận backend (8000) và MariaDB (3306) CHỈ lắng nghe 127.0.0.1, Nginx mở 80
sudo ss -tlnp

# 3. Xác nhận quy tắc tường lửa UFW
sudo ufw status verbose

# 4. Xác nhận mật khẩu lưu dạng băm bcrypt trong MariaDB
sudo mariadb -e "SELECT MaKH, TaiKhoan, LEFT(MatKhau, 35) AS MatKhauHash FROM sachonline.KHACHHANG ORDER BY MaKH DESC LIMIT 5;"

# 5. Kiểm tra API qua Nginx
curl -i http://192.168.100.20/api/health
```

### Chạy bộ kiểm thử tự động (Unit & API Tests)
```bash
cd /opt/sachonline   # hoặc thư mục repo cục bộ
.venv/bin/pytest -v tests/test_api.py
```

### Checklist sản phẩm nộp Bài cá nhân 2
- [ ] Link GitHub công khai chứa đủ mã nguồn, `database/sachonline_mariadb.sql`, `deploy/`, `.env.example`, `README.md` (**KHÔNG có tệp `.env`**).
- [ ] Báo cáo PDF 5–8 trang (mọi ảnh chụp rõ MSSV `2324802010261`, có mục ghi nhận việc sử dụng AI hỗ trợ).
- [ ] Video demo 3–5 phút: truy cập `http://192.168.100.20`, đăng ký/đăng nhập, thêm–xem–sửa–xóa sách, chạy `sudo ufw status verbose` và `sudo ss -tlnp`.
