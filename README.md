# SachOnline – Triển khai Ứng dụng Web Quản lý Sách Online trên VPS

> **Bài cá nhân 2 – Điện toán đám mây**
> - **Sinh viên**: Nguyễn Minh Khôi — **MSSV**: `2324802010261`
> - **VPS triển khai**: `vps-2324802010261` (Ubuntu 26.04.1 LTS, 2 vCPU, 2 GB RAM, 20 GB Disk, IP tĩnh `192.168.100.20/24`)
> - **Stack**: Python **FastAPI** (Gunicorn + UvicornWorker + `systemd`) · Frontend **HTML/CSS/JS** · **MariaDB** · **Nginx Reverse Proxy** · **UFW Firewall**
> - **Mã nguồn Repo**: [https://github.com/agent42-wp/ql_sachonline.git](https://github.com/agent42-wp/ql_sachonline.git)

---

## 1. Kiến trúc Hệ thống & Luồng Mạng

Hệ thống được thiết kế theo mô hình 3 lớp (3-tier architecture). Tiến trình Backend và Cơ sở dữ liệu **chỉ lắng nghe địa chỉ nội bộ `127.0.0.1`**, mọi truy cập bên ngoài đều phải đi qua Nginx Reverse Proxy cổng `80` và tường lửa UFW:

```text
[ Trình duyệt Laptop Ubuntu / Máy chủ Mạng ]
 ├── Kết nối trực tiếp (nếu nằm cùng dải mạng ảo 192.168.100.0/24):
 │     ► http://192.168.100.20
 └── Kết nối qua Hyper-V NAT Port-Forwarding (từ máy 192.168.146.1):
       ► http://192.168.146.123:80  ──(NetNatStaticMapping :80)──► 192.168.100.20:80
                                                                       │
                                                                       ▼
                                                             [ UFW Firewall ] (Mở 80/tcp, 22/tcp từ 192.168.100.0/24 & 192.168.146.1)
                                                                       │
                                                                       ▼
                                                             [ Nginx Proxy :80 ]
                                                               ├── (/ & /Images/) ─► Static Files /opt/sachonline/frontend
                                                               └── (/api/*) ──────► FastAPI Backend (127.0.0.1:8000 via Gunicorn + systemd)
                                                                                           │
                                                                                           ▼
                                                                                    [ MariaDB ] (127.0.0.1:3306, user: sachonline_app)
```

---

## 2. Chuyển đổi Cơ sở Dữ liệu từ SQL Server sang MariaDB

Lược đồ cơ sở dữ liệu và dữ liệu mẫu gốc từ hệ thống SQL Server đã được chuyển đổi hoàn chỉnh sang MariaDB tại [database/sachonline_mariadb.sql](database/sachonline_mariadb.sql) gồm 13 bảng (`CHUDE`, `NHAXUATBAN`, `SACH`, `TACGIA`, `VIETSACH`, `KHACHHANG`, `DONDATHANG`, `CHITIETDATHANG`, `TRANGTIN`, `SLIDER`, `BINHLUAN`, `ADMIN`, `MENU`):

| Hạng mục | SQL Server (`SachOnline.sql`) | MariaDB (`database/sachonline_mariadb.sql`) |
|---|---|---|
| Tự tăng khóa chính | `INT IDENTITY(1,1)` | `INT AUTO_INCREMENT` |
| Chuỗi Unicode | `NVARCHAR(n)`, `NTEXT`, `N'...'` | `VARCHAR(n)`, `TEXT`, `utf8mb4_unicode_ci` |
| Thời gian | `SMALLDATETIME`, `GETDATE()`, `MM/DD/YYYY` | `DATETIME`, `CURRENT_TIMESTAMP`, ISO `YYYY-MM-DD` |
| Ngày dạng hex | `CAST(0x95450000 AS SmallDateTime)` | Chuyển đổi thành chuỗi ISO `'2004-08-16 00:00:00'` |
| Kiểu dữ liệu | `MONEY`, `BIT DEFAULT(0)` | `DECIMAL(12,2)`, `TINYINT(1) DEFAULT 0` |
| Ràng buộc Khóa ngoại | Bảng `VIETSACH` chứa dữ liệu orphan | Loại bỏ dòng mâu thuẫn FK để đảm bảo toàn vẹn dữ liệu |
| Mật khẩu người dùng | Mật khẩu văn bản thuần / SHA2_256 | Băm **bcrypt** (`$2b$12$...`, tự động sinh salt ngẫu nhiên) |

---

## 3. Chức năng chính & Các biện pháp Bảo mật

- **Xác thực phiên làm việc (Authentication & Session)**:
  - `POST /api/auth/register`: Đăng ký tài khoản khách hàng, băm mật khẩu bằng **bcrypt**.
  - `POST /api/auth/login`: Xác thực tài khoản `ADMIN` hoặc `KHACHHANG`, cấp token JWT lưu trong cookie **`HttpOnly; SameSite=Lax`** (chống đánh cắp token qua XSS).
  - `GET /api/auth/me` & `POST /api/auth/logout`: Kiểm tra và hủy phiên làm việc.
- **Quản lý Sách (CRUD - Create, Read, Update, Delete)**:
  - `GET /api/books`: Tìm kiếm theo tên sách, lọc theo chủ đề/NXB, phân trang.
  - `POST /api/books`, `PUT /api/books/{id}`, `DELETE /api/books/{id}`: Yêu cầu quyền quản trị viên; kiểm tra ràng buộc không cho xóa sách đang thuộc đơn đặt hàng (`409 Conflict`).
- **An toàn bảo mật**:
  - Truy vấn tham số hóa chống **SQL Injection** thông qua SQLAlchemy ORM.
  - Frontend render dữ liệu bằng `textContent` và `document.createElement` chống **XSS**.
  - Nginx cấu hình các header an toàn: `server_tokens off`, `X-Frame-Options`, `X-Content-Type-Options`, `Referrer-Policy`.
  - Toàn bộ tham số nhạy cảm (mật khẩu DB, `JWT_SECRET_KEY`) lưu trong `/opt/sachonline/.env` (phân quyền `600`, không đưa lên Git).

---

## 4. Hướng dẫn Triển khai Chi tiết trên VPS (`vps-2324802010261`)

### Cách 1: Chạy script tự động (Khuyên dùng)

```bash
# 1. SSH vào VPS (qua cổng 2222 nếu đi từ máy thật 192.168.146.1)
ssh -p 2222 sv2324802010261@192.168.146.123

# 2. Clone mã nguồn repo
git clone https://github.com/agent42-wp/ql_sachonline.git ~/ql_sachonline
cd ~/ql_sachonline

# 3. Chạy script cài đặt tự động
sudo bash deploy/setup_vps.sh
```

### Cách 2: Cài đặt thủ công từng bước

#### Bước 1: Cài các gói phần mềm cần thiết
```bash
sudo apt update && sudo apt install -y mariadb-server nginx python3-venv python3-pip ufw openssl
```

#### Bước 2: Cấu hình MariaDB và nạp dữ liệu
```bash
# Giới hạn MariaDB chỉ lắng nghe nội bộ
sudo sed -i 's/^\s*bind-address\s*=.*/bind-address = 127.0.0.1/' /etc/mysql/mariadb.conf.d/50-server.cnf
sudo systemctl enable --now mariadb

# Tạo Database và User riêng sachonline_app
sudo mariadb -e "
CREATE DATABASE IF NOT EXISTS sachonline CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'sachonline_app'@'127.0.0.1' IDENTIFIED BY 'SachOnline_DB_Pass_2026';
CREATE USER IF NOT EXISTS 'sachonline_app'@'localhost' IDENTIFIED BY 'SachOnline_DB_Pass_2026';
GRANT SELECT, INSERT, UPDATE, DELETE ON sachonline.* TO 'sachonline_app'@'127.0.0.1';
GRANT SELECT, INSERT, UPDATE, DELETE ON sachonline.* TO 'sachonline_app'@'localhost';
FLUSH PRIVILEGES;
"

# Nạp CSDL đã chuyển đổi
sudo mariadb sachonline < database/sachonline_mariadb.sql
```

#### Bước 3: Thiết lập ứng dụng tại `/opt/sachonline` và tạo `.env`
```bash
sudo mkdir -p /opt/sachonline
sudo cp -r backend frontend Images database deploy requirements.txt .env.example /opt/sachonline/
sudo chown -R sv2324802010261:www-data /opt/sachonline

cd /opt/sachonline
cp .env.example .env
chmod 600 .env

# Cập nhật thông tin DB_PASSWORD và tạo bí mật JWT
sed -i 's/DB_PASSWORD=.*/DB_PASSWORD=SachOnline_DB_Pass_2026/' .env
sed -i "s/JWT_SECRET_KEY=.*/JWT_SECRET_KEY=$(openssl rand -hex 32)/" .env

python3 -m venv .venv
.venv/bin/pip install --upgrade pip
.venv/bin/pip install -r requirements.txt
```

#### Bước 4: Tạo và kích hoạt dịch vụ `systemd` cho Backend
```bash
sudo cp /opt/sachonline/deploy/sachonline.service /etc/systemd/system/sachonline.service
sudo systemctl daemon-reload
sudo systemctl enable --now sachonline
```

#### Bước 5: Cấu hình Nginx Reverse Proxy
```bash
sudo cp /opt/sachonline/deploy/nginx-sachonline.conf /etc/nginx/sites-available/sachonline
sudo ln -sf /etc/nginx/sites-available/sachonline /etc/nginx/sites-enabled/sachonline
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl enable --now nginx
sudo systemctl reload nginx
```

#### Bước 6: Cấu hình quy tắc tường lửa UFW
```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow from 192.168.100.0/24 to any port 22 proto tcp
sudo ufw allow from 192.168.146.1 to any port 22 proto tcp
sudo ufw allow 80/tcp
sudo ufw enable
```

---

## 5. Tài khoản Đăng nhập & Kiểm thử

*Tài khoản Quản trị mẫu (dùng cho môi trường lab nội bộ, mật khẩu đã được băm bcrypt trong CSDL):*
- **Tài khoản**: `admin`
- **Mật khẩu**: `admin`

### Thao tác đăng nhập trên Web:
1. Mở trình duyệt tại `http://192.168.146.123` (hoặc `http://192.168.100.20`).
2. Chọn **Đăng nhập**, nhập `admin` / `admin`.
3. Hệ thống sẽ hiển thị nhãn **Quản trị viên (@admin)** và kích hoạt các nút **Thêm sách**, **Sửa**, **Xóa**.

### Kiểm thử qua REST API (`curl`):
```bash
# 1. Kiểm tra API Health
curl -i http://127.0.0.1/api/health

# 2. Đăng nhập lấy Cookie
curl -i -c /tmp/cookies.txt -X POST http://127.0.0.1/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin"}'

# 3. Truy vấn API với cookie vừa lấy
curl -s -b /tmp/cookies.txt http://127.0.0.1/api/auth/me
```

---

## 6. Lệnh Kiểm chứng Nghiệm thu (Chụp ảnh Báo cáo)

```bash
# 1. Kiểm tra trạng thái tự khởi động cùng hệ thống của 3 dịch vụ
sudo systemctl is-enabled sachonline mariadb nginx
sudo systemctl status sachonline mariadb nginx --no-pager

# 2. Kiểm tra danh sách cổng lắng nghe (xác nhận 8000 và 3306 chỉ mở tại 127.0.0.1)
sudo ss -tlnp

# 3. Kiểm tra quy tắc tường lửa UFW
sudo ufw status verbose

# 4. Kiểm tra mật khẩu lưu dạng băm bcrypt trong MariaDB
sudo mariadb -e "SELECT MaKH, TaiKhoan, LEFT(MatKhau,30) AS MatKhauHash FROM sachonline.KHACHHANG ORDER BY MaKH DESC LIMIT 5;"

# 5. Chạy bộ tự động test (Unit Test)
cd /opt/sachonline && .venv/bin/pytest -v tests/test_api.py
```