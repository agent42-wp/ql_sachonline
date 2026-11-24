-- Thêm tài khoản quản trị (TenDN='admin', mật khẩu gốc đã băm bcrypt rounds=12)
-- Dùng cho VPS đã nạp DB trước đó (không cần xóa dữ liệu):
--   sudo mariadb sachonline < database/add_admin.sql

INSERT INTO ADMIN (HoTen, DienThoai, TenDN, MatKhau, Quyen)
VALUES ('Quản trị viên', '', 'admin', '$2b$12$OYESdcjWxPdePYsjYZRDPebjoymNbHdlI8facsmDg8gBL0TNb/cjW', 1)
ON DUPLICATE KEY UPDATE
    MatKhau = VALUES(MatKhau),
    Quyen = VALUES(Quyen);
