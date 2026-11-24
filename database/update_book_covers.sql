-- Đồng bộ lại tên tệp ảnh bìa trong bảng SACH cho khớp với các ảnh thật trong thư mục Images/
-- Dùng cho VPS đã nạp database trước đó mà không cần xóa dữ liệu hiện tại:
--   sudo mariadb sachonline < database/update_book_covers.sql

UPDATE SACH SET AnhBia = 'KT0005.jpg' WHERE MaSach = 8;
UPDATE SACH SET AnhBia = 'KT0003.jpg' WHERE MaSach = 10;
UPDATE SACH SET AnhBia = 'KT0002.jpg' WHERE MaSach = 11;
UPDATE SACH SET AnhBia = 'KT0004.jpg' WHERE MaSach = 12;
UPDATE SACH SET AnhBia = 'TH006.jpg'  WHERE MaSach = 14;
UPDATE SACH SET AnhBia = 'TH007.jpg'  WHERE MaSach = 15;
UPDATE SACH SET AnhBia = 'TH008.jpg'  WHERE MaSach = 16;
UPDATE SACH SET AnhBia = 'TH003.jpg'  WHERE MaSach = 19;
UPDATE SACH SET AnhBia = 'TH004.jpg'  WHERE MaSach = 20;
UPDATE SACH SET AnhBia = 'TH005.jpg'  WHERE MaSach = 21;
UPDATE SACH SET AnhBia = 'TH002.jpg'  WHERE MaSach = 22;
UPDATE SACH SET AnhBia = '130318.jpg' WHERE MaSach = 23;
