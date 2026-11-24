-- Script khởi tạo Database và tài khoản MariaDB riêng cho ứng dụng SachOnline
-- Chạy bằng quyền quản trị MariaDB trên VPS:
--   sudo mariadb < database/create_db_user.sql
-- LƯU Ý: Đổi 'THAY_BANG_MAT_KHAU_MANH' thành mật khẩu mạnh khớp với DB_PASSWORD trong .env

CREATE DATABASE IF NOT EXISTS sachonline
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS 'sachonline_app'@'127.0.0.1' IDENTIFIED BY 'THAY_BANG_MAT_KHAU_MANH';
CREATE USER IF NOT EXISTS 'sachonline_app'@'localhost' IDENTIFIED BY 'THAY_BANG_MAT_KHAU_MANH';

-- Chỉ cấp đúng các quyền CRUD cần thiết trên cơ sở dữ liệu sachonline (nguyên tắc đặc quyền tối thiểu)
GRANT SELECT, INSERT, UPDATE, DELETE ON sachonline.* TO 'sachonline_app'@'127.0.0.1';
GRANT SELECT, INSERT, UPDATE, DELETE ON sachonline.* TO 'sachonline_app'@'localhost';

FLUSH PRIVILEGES;
