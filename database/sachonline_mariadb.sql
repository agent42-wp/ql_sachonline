-- =============================================================================
-- Cơ sở dữ liệu: SachOnline (Chuyển đổi từ SQL Server T-SQL sang MariaDB)
-- Sinh viên: Nguyễn Minh Khôi - MSSV: 2324802010261 (vps-2324802010261)
-- Bộ mã: utf8mb4_unicode_ci | Engine: InnoDB | Mật khẩu mẫu: băm bcrypt
-- =============================================================================

SET NAMES utf8mb4;
SET time_zone = '+07:00';
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS BINHLUAN;
DROP TABLE IF EXISTS CHITIETDATHANG;
DROP TABLE IF EXISTS DONDATHANG;
DROP TABLE IF EXISTS VIETSACH;
DROP TABLE IF EXISTS SACH;
DROP TABLE IF EXISTS MENU;
DROP TABLE IF EXISTS SLIDER;
DROP TABLE IF EXISTS TRANGTIN;
DROP TABLE IF EXISTS ADMIN;
DROP TABLE IF EXISTS KHACHHANG;
DROP TABLE IF EXISTS TACGIA;
DROP TABLE IF EXISTS NHAXUATBAN;
DROP TABLE IF EXISTS CHUDE;

SET FOREIGN_KEY_CHECKS = 1;

-- 1. Bảng CHUDE
CREATE TABLE CHUDE (
    MaCD INT AUTO_INCREMENT PRIMARY KEY,
    TenChuDe VARCHAR(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Bảng NHAXUATBAN
CREATE TABLE NHAXUATBAN (
    MaNXB INT AUTO_INCREMENT PRIMARY KEY,
    TenNXB VARCHAR(100) NOT NULL,
    DiaChi VARCHAR(150),
    DienThoai VARCHAR(20)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Bảng TACGIA
CREATE TABLE TACGIA (
    MaTG INT AUTO_INCREMENT PRIMARY KEY,
    TenTG VARCHAR(50) NOT NULL,
    DiaChi VARCHAR(100),
    TieuSu TEXT,
    DienThoai VARCHAR(20)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Bảng SACH
CREATE TABLE SACH (
    MaSach INT AUTO_INCREMENT PRIMARY KEY,
    TenSach VARCHAR(150) NOT NULL,
    MoTa TEXT,
    AnhBia VARCHAR(100),
    NgayCapNhat DATETIME DEFAULT CURRENT_TIMESTAMP,
    SoLuongBan INT NOT NULL CHECK (SoLuongBan > 0),
    GiaBan DECIMAL(12,2) NOT NULL CHECK (GiaBan >= 0),
    MaCD INT,
    MaNXB INT,
    CONSTRAINT FK_S_CD FOREIGN KEY (MaCD) REFERENCES CHUDE(MaCD),
    CONSTRAINT FK_Sach_NXB FOREIGN KEY (MaNXB) REFERENCES NHAXUATBAN(MaNXB)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. Bảng VIETSACH
CREATE TABLE VIETSACH (
    MaTG INT NOT NULL,
    MaSach INT NOT NULL,
    VaiTro VARCHAR(30),
    ViTri VARCHAR(30),
    PRIMARY KEY (MaTG, MaSach),
    CONSTRAINT FK_VS_TG FOREIGN KEY (MaTG) REFERENCES TACGIA(MaTG) ON DELETE CASCADE,
    CONSTRAINT FK_VS_S FOREIGN KEY (MaSach) REFERENCES SACH(MaSach) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. Bảng KHACHHANG (MatKhau mở rộng VARCHAR(255) lưu chuỗi băm bcrypt)
CREATE TABLE KHACHHANG (
    MaKH INT AUTO_INCREMENT PRIMARY KEY,
    HoTen VARCHAR(50) NOT NULL,
    TaiKhoan VARCHAR(50) NOT NULL UNIQUE,
    MatKhau VARCHAR(255) NOT NULL,
    Email VARCHAR(100) UNIQUE,
    DiaChi VARCHAR(100),
    DienThoai VARCHAR(20),
    NgaySinh DATETIME
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7. Bảng ADMIN (MatKhau mở rộng VARCHAR(255) lưu chuỗi băm bcrypt)
CREATE TABLE ADMIN (
    MaAd INT AUTO_INCREMENT PRIMARY KEY,
    HoTen VARCHAR(50),
    DienThoai VARCHAR(20),
    TenDN VARCHAR(50) NOT NULL UNIQUE,
    MatKhau VARCHAR(255) NOT NULL,
    Quyen INT NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 8. Bảng DONDATHANG
CREATE TABLE DONDATHANG (
    MaDonHang INT AUTO_INCREMENT PRIMARY KEY,
    DaThanhToan TINYINT(1) NOT NULL DEFAULT 0,
    TinhTrangGiaoHang INT NOT NULL DEFAULT 1,
    NgayDat DATETIME,
    NgayGiao DATETIME,
    MaKH INT,
    CONSTRAINT FK_DDH_KH FOREIGN KEY (MaKH) REFERENCES KHACHHANG(MaKH)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 9. Bảng CHITIETDATHANG
CREATE TABLE CHITIETDATHANG (
    MaDonHang INT NOT NULL,
    MaSach INT NOT NULL,
    SoLuong INT NOT NULL CHECK (SoLuong > 0),
    DonGia DECIMAL(12,2) NOT NULL CHECK (DonGia >= 0),
    PRIMARY KEY (MaDonHang, MaSach),
    CONSTRAINT FK_CTDH_DDH FOREIGN KEY (MaDonHang) REFERENCES DONDATHANG(MaDonHang),
    CONSTRAINT FK_CTDH_S FOREIGN KEY (MaSach) REFERENCES SACH(MaSach)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 10. Bảng TRANGTIN
CREATE TABLE TRANGTIN (
    MaTT INT AUTO_INCREMENT PRIMARY KEY,
    TenTrang VARCHAR(100) NOT NULL,
    NoiDung TEXT,
    NgayTao DATETIME,
    MetaTitle VARCHAR(100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 11. Bảng SLIDER
CREATE TABLE SLIDER (
    MaSlider INT AUTO_INCREMENT PRIMARY KEY,
    TenSlider VARCHAR(100) NOT NULL,
    ThuTu INT NOT NULL DEFAULT 1,
    HinhAnh VARCHAR(200) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 12. Bảng BINHLUAN
CREATE TABLE BINHLUAN (
    MaBL INT AUTO_INCREMENT PRIMARY KEY,
    MaSach INT NOT NULL,
    MaKH INT NOT NULL,
    NoiDung VARCHAR(500) NOT NULL,
    NgayBL DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    DiemDanhGia INT CHECK (DiemDanhGia BETWEEN 1 AND 5),
    CONSTRAINT FK_BL_SACH FOREIGN KEY (MaSach) REFERENCES SACH(MaSach) ON DELETE CASCADE,
    CONSTRAINT FK_BL_KH FOREIGN KEY (MaKH) REFERENCES KHACHHANG(MaKH) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 13. Bảng MENU
CREATE TABLE MENU (
    Id INT AUTO_INCREMENT PRIMARY KEY,
    MenuName VARCHAR(50),
    MenuLink VARCHAR(100),
    ParentId INT,
    OrderNumber INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================================================
-- DỮ LIỆU MẪU
-- =============================================================================

-- Dữ liệu bảng CHUDE
INSERT INTO CHUDE (MaCD, TenChuDe) VALUES (1, 'Nguyễn Minh Khôi');
INSERT INTO CHUDE (MaCD, TenChuDe) VALUES (2, 'Ngoại ngữ');
INSERT INTO CHUDE (MaCD, TenChuDe) VALUES (3, 'Công nghệ thông tin');
INSERT INTO CHUDE (MaCD, TenChuDe) VALUES (4, 'Luật');
INSERT INTO CHUDE (MaCD, TenChuDe) VALUES (5, 'Văn học');
INSERT INTO CHUDE (MaCD, TenChuDe) VALUES (6, 'Khoa học kỹ thuật');
INSERT INTO CHUDE (MaCD, TenChuDe) VALUES (7, 'Nông nghiệp');
INSERT INTO CHUDE (MaCD, TenChuDe) VALUES (8, 'Triết học-Chính trị');
INSERT INTO CHUDE (MaCD, TenChuDe) VALUES (9, 'Lịch sử, địa lý');
INSERT INTO CHUDE (MaCD, TenChuDe) VALUES (10, 'Kinh tế');
INSERT INTO CHUDE (MaCD, TenChuDe) VALUES (11, 'Sách giáo khoa');
INSERT INTO CHUDE (MaCD, TenChuDe) VALUES (12, 'Nghệ thuật sống');

-- Dữ liệu bảng NHAXUATBAN
INSERT INTO NHAXUATBAN (MaNXB, TenNXB, DiaChi, DienThoai) VALUES (1, 'Nguyễn Minh Khôi', 'Tp.HCM', '0973955448');
INSERT INTO NHAXUATBAN (MaNXB, TenNXB, DiaChi, DienThoai) VALUES (2, 'Nhà xuất bản Trẻ', '124 Nguyễn Văn Cừ Q.1 Tp.HCM', '19001560');
INSERT INTO NHAXUATBAN (MaNXB, TenNXB, DiaChi, DienThoai) VALUES (3, 'NXB Thống kê', 'Đồng Nai', '19001511');
INSERT INTO NHAXUATBAN (MaNXB, TenNXB, DiaChi, DienThoai) VALUES (4, 'Kim đồng', 'Tp.HCM', '19001570');
INSERT INTO NHAXUATBAN (MaNXB, TenNXB, DiaChi, DienThoai) VALUES (5, 'Đại học quốc gia', 'Tp.HCM', '0908419981');
INSERT INTO NHAXUATBAN (MaNXB, TenNXB, DiaChi, DienThoai) VALUES (6, 'Văn hóa nghệ thuật', 'Đà Nẵng', '0903118833');
INSERT INTO NHAXUATBAN (MaNXB, TenNXB, DiaChi, DienThoai) VALUES (7, 'Văn hóa', 'Bình Dương', '0913336677');
INSERT INTO NHAXUATBAN (MaNXB, TenNXB, DiaChi, DienThoai) VALUES (8, 'Lao động - Xã hội', 'Tp.HCM', '0989888888');
INSERT INTO NHAXUATBAN (MaNXB, TenNXB, DiaChi, DienThoai) VALUES (9, 'Khoa Học & Kỹ Thuật', 'Hà Nội', '8351056');

-- Dữ liệu bảng TACGIA
INSERT INTO TACGIA (MaTG, TenTG, DiaChi, DienThoai) VALUES (1, 'Phạm Công Anh', '197 Trần Hưng Đạo', '98877668');
INSERT INTO TACGIA (MaTG, TenTG, DiaChi, DienThoai) VALUES (2, 'Nguyễn Thế Giang', '179 Chánh hưng - F.4 - Q.8 Tp.HCM', '19001611');
INSERT INTO TACGIA (MaTG, TenTG, DiaChi, DienThoai) VALUES (3, 'Lê Việt Nhân', '45 Lý Thái Tổ-F2.Q.3 Tp.HCM', '19001570');
INSERT INTO TACGIA (MaTG, TenTG, DiaChi, DienThoai) VALUES (4, 'Hồng Phúc', '', '');
INSERT INTO TACGIA (MaTG, TenTG, DiaChi, DienThoai) VALUES (5, 'Ks.Phạm Quang Huy', '', '');
INSERT INTO TACGIA (MaTG, TenTG, DiaChi, DienThoai) VALUES (6, 'Nguyễn Bá Tiến', '', '');
INSERT INTO TACGIA (MaTG, TenTG, DiaChi, DienThoai) VALUES (7, 'Phạm Hữu Khang', '', '');
INSERT INTO TACGIA (MaTG, TenTG, DiaChi, DienThoai) VALUES (8, 'Nguyễn Minh Đức', NULL, NULL);
INSERT INTO TACGIA (MaTG, TenTG, DiaChi, DienThoai) VALUES (9, 'Trần Văn Lăng', NULL, NULL);
INSERT INTO TACGIA (MaTG, TenTG, DiaChi, DienThoai) VALUES (10, 'Quách Tuấn Ngọc', NULL, NULL);
INSERT INTO TACGIA (MaTG, TenTG, DiaChi, DienThoai) VALUES (11, 'Nguyễn Xuân Huy', NULL, NULL);
INSERT INTO TACGIA (MaTG, TenTG, DiaChi, DienThoai) VALUES (12, 'Đoàn Khắc Độ', NULL, NULL);
INSERT INTO TACGIA (MaTG, TenTG, DiaChi, DienThoai) VALUES (13, 'Nguyễn Tấn Tín', '179 Chánh Hưng F.4 Q.8 Tp.HCM', '8504122');
INSERT INTO TACGIA (MaTG, TenTG, DiaChi, DienThoai) VALUES (14, 'Phạm Phan Trung', '124 Bắc Hải P.6 Q.TB', '0918121188');
INSERT INTO TACGIA (MaTG, TenTG, DiaChi, DienThoai) VALUES (15, 'TS. Nguyễn Phương Liên', '', '');
INSERT INTO TACGIA (MaTG, TenTG, DiaChi, DienThoai) VALUES (16, 'BS. Vũ Thị Uyên Thanh', '', '');

-- Dữ liệu bảng SACH (đã chuẩn hóa ngày MM/DD/YYYY và giải mã 2 giá trị hex SmallDateTime)
INSERT INTO SACH (MaSach, TenSach, GiaBan, MoTa, AnhBia, MaCD, MaNXB, NgayCapNhat, SoLuongBan) VALUES (1, 'Giáo trình Tin học cơ bản', 26000, 'Nội dung của cuốn: Tin Học Cơ Bản Windows XP gồm có 7 chương:
Chương 1: Một số vấn đề cơ bản.     
Chương 2: Sử dụng nhanh thanh công cụ và thanh thực đơn trong My Computer và Windows Explorer.    
Chương 3: Các thao tác trong windows XP. 
Chương 4: Các thiết lập trong Windows XP. 
Chương 5: Bảo trì máy tính. 
Chương 6: Các phím tắt 
Chương 7: Hỏi và đáp các thắc mắc.
Xin trân trọng giới thiệu cuốn sách cùng bạn', 'THCB.jpg', 7, 1, '2021-04-12 00:00:00', 120);
INSERT INTO SACH (MaSach, TenSach, GiaBan, MoTa, AnhBia, MaCD, MaNXB, NgayCapNhat, SoLuongBan) VALUES (2, 'Giáo trình Tin học văn phòng', 12000, 'Cuốn sách này gồm 3 phần sau:
Phần 1: Xử lý văn bản trong Microsoft Office Word 2007. 
Phần 2: Xử lý bảng tính trong Microsoft Office Excel 2007. 
Phần 3: Quản lý cơ sở dữ liệu trong Microsoft Office Access 2007.
Xin trân trọng giới thiệu cùng các bạn.', 'TH004.jpg', 2, 2, '2020-04-12 00:00:00', 25);
INSERT INTO SACH (MaSach, TenSach, GiaBan, MoTa, AnhBia, MaCD, MaNXB, NgayCapNhat, SoLuongBan) VALUES (3, 'Lập Trình Cơ Sở Dữ Liệu Với Visual Basic 2005 Và ADO.NET 2.0', 11500, 'Cuốn sách "Lập Trình Cơ Sở Dữ Liệu Với Visual Basic 2005 Và ADO.NET 2.0" này giới thiệu các nội dung sau:
Chương 1: Căn bản về cơ sở dữ liệu.
Chương 2: Các bộ kết nối và tương tác dữ liệu.
Chương 3: Bộ chứa dữ liệu DataSet.
Chương 4: Bộ điều hợp dữ liệu DataAdapter.
Chương 5: Sử dụng các điều khiển ràng buộc dữ liệu.
Chương 6: Tạo báo cáo với Crystal Report.
Chương 7: ADO.NET và XML.
Xin trân trọng giới thiệu cùng các bạn.', 'Gt_Thcb.jpg', 7, 3, '2021-04-20 00:00:00', 23);
INSERT INTO SACH (MaSach, TenSach, GiaBan, MoTa, AnhBia, MaCD, MaNXB, NgayCapNhat, SoLuongBan) VALUES (4, 'Visual Basic 2005 Tập 3, Quyển 2: Lập Trình Web', 20000, '"Visual Basic 2005 Tập 3, Quyển 2: Lập Trình Web Với Cơ Sở Dữ Liệu" sẽ cung cấp kỹ thuật và hướng dẫn bạn:
Tự học xây dựng ứng dụng Web quản lý CSDL toàn diện với ADO.NET 2.0 và ASP.NET. 
Khai thác các đối tượng và nguồn dữ liệu dành cho WebForm. 
Sử dụng các điều khiển dữ liệu đặc thù dành riêng cho ASP.NET và Web. 
Làm quen với những khái niệm xử lý dữ liệu hoàn toàn mới. 
Ràng buộc dữ liệu với các thành phần giao diện Web Forms. 
Thiết kế ứng dụng Web "Quản lý CD Shop" trực quan và thực tế. 
Cung cấp một kiến thức hoàn chỉnh về Web cho các bạn yêu thích ngôn ngữ Visual Basic và .NET Framework.
Sách có kèm theo CD-ROM bài tập.
Xin trân trọng giới thiệu cùng các bạn.', 'LTWeb2005.jpg', 8, 4, '2019-05-12 00:00:00', 240);
INSERT INTO SACH (MaSach, TenSach, GiaBan, MoTa, AnhBia, MaCD, MaNXB, NgayCapNhat, SoLuongBan) VALUES (5, 'Giáo trình Tin học quản lý 1', 21000, 'Mạng Máy Tính Và Hệ Thống Bảo Mật gồm 7 chương:
Chương I: Tổng quan về công nghệ mạng máy tính và mạng cục bộ.
Chương II: Các thiết bị mạng thông dụng và các chuẩn kết nối vật lý.
Chương III: TCP/IP và mạng Internet.
Chương IV: Hệ điều hành mạng đặc điểm của hệ điều hành mạng.
Chương V: Một số vấn đề an toàn và bảo mật thông tin trên mạng máy tính.
Chương VI: Giới thiệu hệ điều hành Windows NT.
Chương VII: Giới thiệu hệ điều hành UNIX.
Trân trọng giới thiệu.', 'TH001.jpg', 3, 1, '2021-04-10 00:00:00', 16);
INSERT INTO SACH (MaSach, TenSach, GiaBan, MoTa, AnhBia, MaCD, MaNXB, NgayCapNhat, SoLuongBan) VALUES (6, 'Giáo trình Tin học quản lý 2', 21000, 'Mục đích của bộ sách này giúp bạn trở nên thành thạo cơ sở dữ liệu (CSDL) Oracle9i, đề cập đến tất cả những kiến thức cần thiết từ mô hình dữ liệu, quản trị CSDL, sao lưu phục hồi, mạng và xử lý sự cố cũng như hiệu chỉnh hiệu suất thực thi..., với sự kết hợp lý thuyết và thực hành về điều mà Nhà quản trị CSDL Oracle9i cần biết để sử dụng CSDL Oracle9i một cách hiệu quả từ chính bộ sách này.
Bộ sách được chia làm 2 tập, tập 1 đề cập các kiến thức cơ bản về CSDL, mô hình dữ liệu. Bạn sẽ được biết về hệ quản trị CSDL Oracle9i, tạo CSDL, kết nối và quản lý người dùng. Tập 2 hướng dẫn bạn cách nạp, sao lưu và phục hồi dữ liệu, quản lý hoạt động CSDL Oracle9i, thực hiện hiệu chỉnh hiệu suất thực thi và xử lý sự cố cho CSDL.
Xin trân trọng giới thiệu Tập 1 cùng các bạn.', '130499.jpg', 10, 5, '2020-10-12 00:00:00', 65);
INSERT INTO SACH (MaSach, TenSach, GiaBan, MoTa, AnhBia, MaCD, MaNXB, NgayCapNhat, SoLuongBan) VALUES (7, 'Giáo trình SQL Server', 18000, 'Hệ quản trị cơ sở dữ liệu SQl Server 2003
Test thu', 'Gt_Thcb.jpg', 3, 6, '2004-08-16 00:00:00', 5);
INSERT INTO SACH (MaSach, TenSach, GiaBan, MoTa, AnhBia, MaCD, MaNXB, NgayCapNhat, SoLuongBan) VALUES (8, 'Phong Cách Quản Lý Kinh Doanh Hiện Đại', 61000, 'Cuốn sách này không đi vào chi tiết những chủ đề quản lý cổ điển đã được nhắc đến trong nhiều cuốn sách khác như tổ chức cuộc họp, cung cấp số liệu, quản lý thời gian. Mục đích của cuốn sách này là mang lại cho bạn "nhiều hơn", một giá trị gia tăng so với những gì bạn đã biết và đã áp dụng, và giúp bạn tối ưu hóa việc quản lý chuyên môn và quản lý nhân sự.
Nội dung sách bao gồm 9 chương:
Chương 1: Bốn cách nhìn quản lý theo sắc màu.
Chương 2: Quản lý các sắc màu của một cộng tác viên.
Chương 3: Quản lý nhóm theo màu sắc.
Chương 4: Quyết định cách thích hợp dựa vào bản thân, người khác và hoàn cảnh.
Chương 5: Phát triển hiệu quả tối ưu theo sắc màu.
Chương 6: Hiểu rõ những sai lệch trong cách quản lý của mình.
Chương 7: Nền tảng cơ sở của hệ thống Success Insights: Bốn màu với tám kiểu.
Chương 8: Nhận biết và quản lý tám kiểu cộng tác viên.
Chương 9: Cải thiện người quản lý.
Xin trân trọng giới thiệu. 
', 'KT0005.jpg', 9, 8, '2021-01-10 00:00:00', 5);
INSERT INTO SACH (MaSach, TenSach, GiaBan, MoTa, AnhBia, MaCD, MaNXB, NgayCapNhat, SoLuongBan) VALUES (9, 'Cán Bộ Quản Lý Trong Sản Xuất Công Nghiệp', 25000, 'Cuốn sách này gồm những nội dung chính sau:
Phần 1: Quản lý sản xuất công nghiệp trong kinh tế thị trường
- Kinh doanh sản xuất công nghiệp trong kinh tế thị trường
- Sự cần thiết và các chức năng của quản lý nhà nước đối với doanh nghiệp sản xuất công nghiệp
- Nội dung và tính chất của những công việc mà cán bộ quản lý sản xuất công nghiệp phải đảm nhiệm, hoàn thành.
- Kinh nghiệm đào tạo và đánh giá cán bộ quản lý kinh doanh ở Nhật.
Phần 2: Thực trạng và một số giải pháp nhằm nâng cao chất lượng đội ngũ cán bộ quản lý sản xuất công nghiệp Việt Nam
- Thực trạng cán bộ quản lý doanh nghiệp công nghiệp của Việt Nam
- Tiêu chuẩn hóa cán bộ quản lý sản xuất công nghiệp Việt Nam
- Đổi mới căn bản nội dung và phương pháp đào tạo cán bộ quản lý sản xuất công nghiệp Việt Nam
Xin trân trọng giới thiệu. 
 
', 'KT0001.jpg', 5, 6, '2018-04-12 00:00:00', 89);
INSERT INTO SACH (MaSach, TenSach, GiaBan, MoTa, AnhBia, MaCD, MaNXB, NgayCapNhat, SoLuongBan) VALUES (10, 'Tư Duy Chiến Lược (Quản Lý - Tại Sao? Thế Nào?', 18000, 'Khả năng hoạch định dài hạn đồng thời tối ưu hóa tình hình hoạt động ngắn hạn là một yêu cầu bắt buộc phải có đối với các nhà quản lý.Tư Duy Chiến Lược sẽ giúp bạn vạch ra con đường đến thành công đồng thời giúp hình thành các kỹ năng phân tích và hoạch định theo nhóm. Tất cả các lĩnh vực then chốt để hình thành và thực thi một chiến lược đều được trình bày cặn kẽ trong cuốn sách này, từ việc nghiên cứu và thu thập thông tin nền tảng, hình thành một chiến lược mới đến việc xem xét và ứng dụng chiến lược ấy. Cả thảy có 101 chỉ dẫn nhằm cung cấp cho các bạn những lời khuyên thực tiễn hơn, đồng thời bài tập tự đánh giá sẽ giúp bạn xác định xem mình là một nhà tư duy chiến lược hiệu quả đến mức nào. Khi bạn có nhiều tham vọng hơn về việc hoạch định cho tương lai, cẩm nang này sẽ là quyển sách tham khảo không thể thiếu, giúp suy nghĩ của bạn đi đúng hướng.
Xin trân trọng giới thiệu cuốn sách cùng bạn. ', 'KT0003.jpg', 11, 3, '2003-09-19 00:00:00', 8);
INSERT INTO SACH (MaSach, TenSach, GiaBan, MoTa, AnhBia, MaCD, MaNXB, NgayCapNhat, SoLuongBan) VALUES (11, 'Quản Lý Dự Án (Quản Lý - Tại Sao? Thế Nào?)', 61000, 'Để thành công trong môi trường kinh doanh cạnh tranh hiện nay, các giám đốc dự án phải đạt được kết quả trong phạm thời gian và ngân sách đưa ra. Biết cách áp dụng các quy trình, phương pháp và kỹ thuật chỉ dẫn trong cuốn Quản Lý Dự Án này, bạn sẽ tăng tối đa khả năng thực hiện công việc và đảm bảo đạt kết quả tối ưu khi thực hiện dự án.
Được thiết kế phù hợp với tất cả các nhà quản lý ở đủ mọi trình độ, cẩm nang này sẽ trang bị cho bạn những kiến thức cần thiết trong việc quản lý mọi dự án, dù lớn hay nhỏ, để đạt đến thành công. Từ việc khởi xướng một dự án, thúc đẩy, phát triển nhóm dự án đến việc vượt qua những khó khăn, trở ngại; mỗi một khía cạnh của quản lý dự án chuyện nghiệp đều được trình bày một cách rõ nét. Cẩm nang bao gồm các hướng dẫn từng bước về hoạch định dự án và 101 mẹo vặt cung cấp cho bạn những lời khuyên thực tế. 
', 'KT0002.jpg', 4, 8, '2020-02-12 00:00:00', 4);
INSERT INTO SACH (MaSach, TenSach, GiaBan, MoTa, AnhBia, MaCD, MaNXB, NgayCapNhat, SoLuongBan) VALUES (12, 'Điều Chỉnh Một Số Chính Sách Kinh Tế Ở Trung Quốc (Giai Đoạn 1992 - 2010)', 21000, 'Cuốn sách này tập trung vào một số nội dung chính sau đây:

Tìm hiểu về những nhân tố đòi hỏi Trung Quốc phải điều chỉnh chính sách kinh tế.

Tìm hiểu về những nội dung chính trong điều chỉnh kinh tế ở Trung Quốc giai đoạn từ năm 1992 - 2010.

Tìm hiểu về tác động của việc điều chỉnh chính sách kinh tế của Trung Quốc đối với thế giới và khu vực trong đó có Việt Nam, sau đó rút tỉa một số kinh nghiệm của Trung Quốc trong quá trình điều chỉnh chính sách kinh tế mà Việt Nam có thể tham khảo.
Tập thể tác giả tham gia công trình này đều là những người chuyên nghiên cứu về Trung Quốc, hy vọng sẽ đem lại cho các bạn nhiều thông tin bổ ích.', 'KT0004.jpg', 1, 7, '2021-04-02 00:00:00', 19);
INSERT INTO SACH (MaSach, TenSach, GiaBan, MoTa, AnhBia, MaCD, MaNXB, NgayCapNhat, SoLuongBan) VALUES (13, '30 phút mỗi ngày để luyện kỹ năng viết câu tiếng Anh', 85000, '30 phút mỗi ngày để luyện kỹ năng viết câu tiếng Anh là một cuốn sách bài tập dành cho những học sinh/sinh viên nghiêm túc quan tâm đến tầm quan trọng của việc nâng cao những yếu tố kỹ thuật cho kỹ năng viết của mình. Rèn luyện để viết cho tốt chẳng khác gì tự trang bị cho mình một sức mạnh cần thiết để thành công - khi đi học cũng như khi ra ngoài xã hội. Trui rèn được một trình độ viết “cứng” không hề là chuyện bỗng nhiên trời cho mà có được; đó phải là kết quả của một quá trình phấn đấu bền bỉ và rèn luyện chăm chỉ.

Đặc nét của sách này là sử dụng cách tiếp cận những kỹ thuật kết hợp câu cơ bản, có nghĩa là, sách không chỉ quan tâm đến việc tránh những sai lỗi, mà còn đặt mục tiêu tạo dựng được những câu hay, linh hoạt, và thể hiện một phong cách riêng. Cạnh đó, sách còn có những điểm đáng lưu ý như: 

- Bàn thảo rõ ràng về những qui tắc và kỹ thuật giúp viết tốt.

- Giải thích súc tích, hạn chế dùng những thuật ngữ ngữ pháp.

- Lượng bài tập phong phú, đa dạng, từ những câu hỏi điền vào chỗ trống với mục đích xác định các từ loại cho đến những câu hỏi kết hợp những câu ngắn thành những câu văn dài hơn, ý tứ “duyên” hơn.

- Đáp án cuối sách nhằm giúp học sinh/sinh viên học và nghiên cứu nhanh chậm theo trình độ và ý thích của mình, đồng thời kiểm tra được bài làm trong quá trình học tập.

Học sinh/sinh viên tiếp thu tốt nhất khi họ tham gia tích cực và quá trình học. Họ rất thích những bài tập nào rèn cho họ được những kỹ năng viết họ cần đồng thời có giá trị thông tin nào đó hoặc vui vui. Đó chính là lý do cuốn sách này sử dụng đủ loại chủ đề thú vị trong các bài tập. Cũng vì lý do tương tự, sách có phần trình bày và giảng giải rất ngắn gọn những đưa ra rất nhiều những ví dụ và minh họa mở rộng.

Sử dụng cuốn 30 phút mỗi ngày để luyện kỹ năng viết câu tiếng Anh này sẽ giúp học sinh/sinh viên viết “có nghề” và tự tin hơn".', 'TiengAnh01.jpg', 2, 1, '2016-02-10 00:00:00', 7);
INSERT INTO SACH (MaSach, TenSach, GiaBan, MoTa, AnhBia, MaCD, MaNXB, NgayCapNhat, SoLuongBan) VALUES (14, 'Tin Học Ứng Dụng: Thành Thạo Oracle 9i - Quản Trị Cơ Sở Dữ Liệu (Tập 1)', 21000, 'Mục đích của bộ sách này giúp bạn trở nên thành thạo cơ sở dữ liệu (CSDL) Oracle9i, đề cập đến tất cả những kiến thức cần thiết từ mô hình dữ liệu, quản trị CSDL, sao lưu phục hồi, mạng và xử lý sự cố cũng như hiệu chỉnh hiệu suất thực thi..., với sự kết hợp lý thuyết và thực hành về điều mà Nhà quản trị CSDL Oracle9i cần biết để sử dụng CSDL Oracle9i một cách hiệu quả từ chính bộ sách này.
Bộ sách được chia làm 2 tập, tập 1 đề cập các kiến thức cơ bản về CSDL, mô hình dữ liệu. Bạn sẽ được biết về hệ quản trị CSDL Oracle9i, tạo CSDL, kết nối và quản lý người dùng. Tập 2 hướng dẫn bạn cách nạp, sao lưu và phục hồi dữ liệu, quản lý hoạt động CSDL Oracle9i, thực hiện hiệu chỉnh hiệu suất thực thi và xử lý sự cố cho CSDL.
Xin trân trọng giới thiệu Tập 1 cùng các bạn. ', 'TH006.jpg', 1, 2, '2019-04-12 00:00:00', 28);
INSERT INTO SACH (MaSach, TenSach, GiaBan, MoTa, AnhBia, MaCD, MaNXB, NgayCapNhat, SoLuongBan) VALUES (15, 'Mạng Máy Tính Và Hệ Thống Bảo Mật', 23000, 'Mạng Máy Tính Và Hệ Thống Bảo Mật gồm 7 chương:
Chương I: Tổng quan về công nghệ mạng máy tính và mạng cục bộ.
Chương II: Các thiết bị mạng thông dụng và các chuẩn kết nối vật lý.
Chương III: TCP/IP và mạng Internet.
Chương IV: Hệ điều hành mạng đặc điểm của hệ điều hành mạng.
Chương V: Một số vấn đề an toàn và bảo mật thông tin trên mạng máy tính.
Chương VI: Giới thiệu hệ điều hành Windows NT.
Chương VII: Giới thiệu hệ điều hành UNIX.
Trân trọng giới thiệu. 
', 'TH007.jpg', 4, 1, '2020-04-29 00:00:00', 4);
INSERT INTO SACH (MaSach, TenSach, GiaBan, MoTa, AnhBia, MaCD, MaNXB, NgayCapNhat, SoLuongBan) VALUES (16, 'Thủ Thuật Lập Trình Visual Basic 6', 18000, 'Mục Lục:
Chương 1: Multimedia.
Chương 2: String.
Chương 3: Form.
Chương 4:Windows Control.
Chương 5: Common Control.
Chương 6: System.
Chương 7: Disk - File.
Chương 8: Graphics.
Chương 9: Internet.
Chương 10: Microsoft Office.
Chương 11: Database.
Chương 12: Clipboard.
Chương 13: Các vấn đề khác.
Phụ lục A: Giới thiệu một số ActiveX Control.
Phụ lục B: Một số tiện ích hỗ trợ lập trình Win32 API.
Phụ lục C: Một số vấn đề về đóng gói phần mềm.
Phụ lục D: Giới thiệu một số Website về Visual Basic.
Trân trọng giới thiệu. 
', 'TH008.jpg', 6, 7, '2020-07-29 00:00:00', 5);
INSERT INTO SACH (MaSach, TenSach, GiaBan, MoTa, AnhBia, MaCD, MaNXB, NgayCapNhat, SoLuongBan) VALUES (17, 'Lập Trình Mạng Trên Windows (Ấn bản dành cho sinh viên)', 16800, 'Chào mừng đến với "Lập Trình Mạng Trên Windows (Ấn bản dành cho sinh viên)". Quyển sách này sẽ hướng dẫn bạn sử dụng một cách hiệu quả bao gồm một số lượng lớn và đa dạng các hàm mạng sẵn có trong Windows 95, Windows 98, Windows NT 4, Windows CE, và Windows 2000/XP/. NET. Sách được chủ định viết dành cho những lập trình viên từ trung cấp đến cao cấp, tuy nhiên những lập trình viên mới bắt đầu tìm hiểu lập trình mạng cũng sẽ nhận thấy đây là một quyển sách không thể thiếu cho các bước xây dựng ứng dụng mạng sau này.
', 'TH001.jpg', 5, 5, '2020-03-29 00:00:00', 8);
INSERT INTO SACH (MaSach, TenSach, GiaBan, MoTa, AnhBia, MaCD, MaNXB, NgayCapNhat, SoLuongBan) VALUES (18, 'Căn Bản Về Photoshop CS Tinh Chỉnh Và Xử Lý Màu', 25000, '"Căn Bản Về Photoshop CS Tinh Chỉnh Và Xử Lý Màu" gồm 12 chương:
Chương 1: Những điểm cơ bản.
Chương 2: Màu Photoshop.
Chương 3: Các tác vụ xử lý ảnh căn bản.
Chương 4: Các điểm cơ bản về pixel.
Chương 5: Các điểm cơ bản về lớp.
Chương 6: Làm việc với các công cụ chọn.
Chương 7: Ghép ảnh.
Chương 8: Làm việc với các palette History.
Chương 9: Các kỹ thuật điều chỉnh hình ảnh.
Chương 10: Chọn các màu.
Chương 11: Tô màu lại.
Chương 12: Làm việc với các công cụ tô vẽ.
Xin trân trọng giới thiệu. ', 'TH002.jpg', 1, 6, '2019-07-23 00:00:00', 56);
INSERT INTO SACH (MaSach, TenSach, GiaBan, MoTa, AnhBia, MaCD, MaNXB, NgayCapNhat, SoLuongBan) VALUES (19, 'Hướng Dẫn Sử Dụng Norton AntiVirus 2004 (Hướng dẫn bằng hình)', 16800, '"Hướng Dẫn Sử Dụng Norton AntiVirus 2004 (Hướng dẫn bằng hình)" bao gồm 6 phần, 23 chương:
Phần I: Bắt đầu với Norton AntiVirus 2004.
Chương 1: Bắt đầu với Norton AntiVirus 2004.
Chương 2: Cài đặt Norton System Works Professional.
Chương 3: Các điểm cơ bản về Norton AntiVirus 2004.
Chương 4: Các tùy chọn trong Norton SystemWorks.
Chương 5: Cải tiến sự trình duyệt Web và phục hồi đĩa cứng.
Chương 6: Duy trì tính bảo mật password và cập nhật với LiveUpdate.
Phần II: Làm việc với Norton AntiVirus 2004.
Chương 7: Bảo vệ đĩa, file và dữ liệu để tránh bị nhiễm Virus.
Chương 8: Những điều cần làm nếu phát hiện virus.
', 'TH003.jpg', 5, 7, '2020-07-29 00:00:00', 4);
INSERT INTO SACH (MaSach, TenSach, GiaBan, MoTa, AnhBia, MaCD, MaNXB, NgayCapNhat, SoLuongBan) VALUES (20, 'Tin Học Văn Phòng - Microsoft Word 2000 (Tái Bản Lần Thứ Nhất)', 15600, ' ', 'TH004.jpg', 2, 8, '2020-02-23 00:00:00', 6);
INSERT INTO SACH (MaSach, TenSach, GiaBan, MoTa, AnhBia, MaCD, MaNXB, NgayCapNhat, SoLuongBan) VALUES (21, 'Adobe Photoshop 6.0 và ImageReady 3.0', 21000, 'Cuốn sách Adobe Photoshop 6.0 và ImageReady 3.0 này sẽ giúp bạn tìm hiểu những tính năng tuyệt vời của phiên bản 6.0, nó cũng là con đường ngắn nhất cho những người mới sử dụng Photoshop lần đầu. Với bạn đọc đã sử dụng cuốn sách "Adobe Photoshop 5.5 và ImageReady 2.0" do MK.PUB biên soạn trước đây, cuốn sách này là một cách cập nhật nhanh chóng nhất.
Adobe Photoshop 6.0 và ImageReady 3.0 gồm hai phần chính, đan xen nhau: 

Adobe Photoshop 6.0: trình bày các kỹ thuật xử lý ảnh cao cấp, các tính năng mới, giúp bạn tạo được các ảnh đẹp, rõ nét và mang tính mỹ thuật cao, hỗ trợ đắc lực cho các chương trình dàn trang và tách màu điện tử. Đặc biệt trong phiên bản này, để đáp ứng cho mong mỏi từ lâu của người dùng, các hình thể vector bắt đầu được đưa vào sử dụng trong môi trường Photoshop.

', 'TH005.jpg', 5, 5, '2020-02-20 00:00:00', 8);
INSERT INTO SACH (MaSach, TenSach, GiaBan, MoTa, AnhBia, MaCD, MaNXB, NgayCapNhat, SoLuongBan) VALUES (22, 'Hướng Dẫn Tự Học Photoshop CS (Photoshop 8.0)', 25000, ' ', 'TH002.jpg', 8, 4, '2019-07-29 00:00:00', 9);
INSERT INTO SACH (MaSach, TenSach, GiaBan, MoTa, AnhBia, MaCD, MaNXB, NgayCapNhat, SoLuongBan) VALUES (23, 'Tin Học Văn Phòng - Microsoft Excel 2000 (Tái Bản Lần Thứ Nhất)', 16800, 'Cuốn sách này gồm những nội dung chính sau:
Chương 1: Giới thiệu
Chương 2: Soạn thảo văn bản
Chương 3: Trình bày Font chữ
Chương 4: Trình bày Paragraph
Chương 5: Trình bày trang in
Chương 6: Bảng biểu - Table
Chương 7: Cột chữ - Column
Chương 8: Hình vẽ
Chương 9: Microsoft Equation
Chương 10: Trình bày văn bản nhanh
Chương 11: Bài tập mẫu
Xin trân trọng giới thiệu. 
', '130318.jpg', 6, 5, '2020-01-29 00:00:00', 1);

-- Dữ liệu bảng VIETSACH (đã bỏ qua dòng MaSach=24 không tồn tại trong SACH để đảm bảo toàn vẹn FK)
INSERT INTO VIETSACH (MaSach, MaTG, VaiTro, ViTri) VALUES (1, 1, 'Tác giả', '');
INSERT INTO VIETSACH (MaSach, MaTG, VaiTro, ViTri) VALUES (1, 3, 'Đồng tác giả', '');
INSERT INTO VIETSACH (MaSach, MaTG, VaiTro, ViTri) VALUES (1, 4, 'Hiệu đính', '');
INSERT INTO VIETSACH (MaSach, MaTG, VaiTro, ViTri) VALUES (1, 10, 'Chủ biên', '');
INSERT INTO VIETSACH (MaSach, MaTG, VaiTro, ViTri) VALUES (2, 3, 'Tác giả', '');
INSERT INTO VIETSACH (MaSach, MaTG, VaiTro, ViTri) VALUES (2, 14, 'Đồng tác giả', '');
INSERT INTO VIETSACH (MaSach, MaTG, VaiTro, ViTri) VALUES (3, 5, 'Tác giả', '');
INSERT INTO VIETSACH (MaSach, MaTG, VaiTro, ViTri) VALUES (3, 6, 'Hiệu đính', '');
INSERT INTO VIETSACH (MaSach, MaTG, VaiTro, ViTri) VALUES (4, 5, 'Tác giả', '');
INSERT INTO VIETSACH (MaSach, MaTG, VaiTro, ViTri) VALUES (5, 6, 'Tác giả', '');
INSERT INTO VIETSACH (MaSach, MaTG, VaiTro, ViTri) VALUES (5, 12, 'Chủ biên', '');
INSERT INTO VIETSACH (MaSach, MaTG, VaiTro, ViTri) VALUES (6, 14, 'Sưu tầm và biên soạn', '');
INSERT INTO VIETSACH (MaSach, MaTG, VaiTro, ViTri) VALUES (7, 8, 'Tác giả', '');
INSERT INTO VIETSACH (MaSach, MaTG, VaiTro, ViTri) VALUES (8, 7, 'Tác giả', '');
INSERT INTO VIETSACH (MaSach, MaTG, VaiTro, ViTri) VALUES (10, 11, 'Tác giả', '');
INSERT INTO VIETSACH (MaSach, MaTG, VaiTro, ViTri) VALUES (11, 6, 'Tác giả', '');
INSERT INTO VIETSACH (MaSach, MaTG, VaiTro, ViTri) VALUES (12, 13, 'Tác giả', '');
INSERT INTO VIETSACH (MaSach, MaTG, VaiTro, ViTri) VALUES (13, 16, 'Tác giả', '');
INSERT INTO VIETSACH (MaSach, MaTG, VaiTro, ViTri) VALUES (14, 7, 'Tác giả', '');
INSERT INTO VIETSACH (MaSach, MaTG, VaiTro, ViTri) VALUES (15, 12, 'Tác giả', '');
INSERT INTO VIETSACH (MaSach, MaTG, VaiTro, ViTri) VALUES (16, 14, 'Tác giả', '');
INSERT INTO VIETSACH (MaSach, MaTG, VaiTro, ViTri) VALUES (17, 14, 'Chủ biên', '');
INSERT INTO VIETSACH (MaSach, MaTG, VaiTro, ViTri) VALUES (17, 15, 'Tác giả', '');
INSERT INTO VIETSACH (MaSach, MaTG, VaiTro, ViTri) VALUES (18, 15, 'Tác giả', '');
INSERT INTO VIETSACH (MaSach, MaTG, VaiTro, ViTri) VALUES (19, 5, 'Tác giả', '');
INSERT INTO VIETSACH (MaSach, MaTG, VaiTro, ViTri) VALUES (20, 8, 'Tác giả', '');
INSERT INTO VIETSACH (MaSach, MaTG, VaiTro, ViTri) VALUES (21, 13, 'Tác giả', '');
INSERT INTO VIETSACH (MaSach, MaTG, VaiTro, ViTri) VALUES (22, 10, 'Tác giả', '');
INSERT INTO VIETSACH (MaSach, MaTG, VaiTro, ViTri) VALUES (23, 11, 'Tác giả', '');

-- Dữ liệu bảng KHACHHANG (toàn bộ mật khẩu đã băm bằng bcrypt rounds=12)
INSERT INTO KHACHHANG (MaKH, HoTen, DiaChi, DienThoai, TaiKhoan, MatKhau, NgaySinh, Email) VALUES (1, 'Võ Quốc Lương', 'Phú Hòa', '0988936592', 'luongvq', '$2b$12$qV9sAmje/4n9a3VuCGnIouXO.rafjPRQEvRzUbVTgcZ0GdhWUY9Le', '1982-02-10 00:00:00', 'luongvq@tdmu.edu.vn');
INSERT INTO KHACHHANG (MaKH, HoTen, DiaChi, DienThoai, TaiKhoan, MatKhau, NgaySinh, Email) VALUES (2, 'Nguyễn Tiến Luân', 'Quận 6', 'Chua có', 'thang', '$2b$12$4ec3Rns5vVjDk/uLowji0OwHobUsbZF9r2fuJ9qy7WFedP58o//sS', '1981-03-10 00:00:00', 'ntluan@hcmuns.edu.vn');
INSERT INTO KHACHHANG (MaKH, HoTen, DiaChi, DienThoai, TaiKhoan, MatKhau, NgaySinh, Email) VALUES (3, 'Đặng Quốc Hòa', 'Sư Vạn Hạnh', 'Chua có', 'dqhoa', '$2b$12$HSQTXoJ51Z6ltiF7R7GDV.3r5/i8xHhVHJoyAo0K92.IxKMIHqQgW', '1980-04-10 00:00:00', 'dqhoa@hcmuns.edu.vn');
INSERT INTO KHACHHANG (MaKH, HoTen, DiaChi, DienThoai, TaiKhoan, MatKhau, NgaySinh, Email) VALUES (4, 'Ngô Ngọc Ngân', 'Khu chung cư', '0918544699', 'nnngan', '$2b$12$Eaj8a2H.lkWIgd1ET/8WFO1/cDVJ7s7x8sz6TfqTrfhqWlwKHX4BO', '1982-02-19 00:00:00', 'nnngan@hcmuns.edu.vn');
INSERT INTO KHACHHANG (MaKH, HoTen, DiaChi, DienThoai, TaiKhoan, MatKhau, NgaySinh, Email) VALUES (5, 'Đỗ Quỳnh Hương', 'Cống Quỳnh', '0908123456', 'dqhuong', '$2b$12$IvGlkMzax.yxaelSL0JFguniKz9jVHn96qq5DrzSCqpJF7e7nXQPu', '1985-06-13 00:00:00', 'dqhuong@hcmuns.edu.vn');
INSERT INTO KHACHHANG (MaKH, HoTen, DiaChi, DienThoai, TaiKhoan, MatKhau, NgaySinh, Email) VALUES (6, 'Trần Thị Thu Trang', 'Nơ Trang Long', 'Chua có', 'ttttrang', '$2b$12$eJmdw5j0x1/gxWHsAhccCuSoRAOsu1V4gdxcizqUAtco0esA1X9wy', '1990-12-10 00:00:00', 'ttrang@yahoo.com');
INSERT INTO KHACHHANG (MaKH, HoTen, DiaChi, DienThoai, TaiKhoan, MatKhau, NgaySinh, Email) VALUES (7, 'Nguyễn Thiên Thanh', 'Hai Bà Trưng', '0908320111', 'ntthanh', '$2b$12$KVC2Rpp0B2lhq9Nl6ftYROiq7H5EGg8n9TUZ2wppT5zwqUHcDPOYa', '1986-12-12 00:00:00', 'ntthanh@t3h.hcmuns.edu.vn');
INSERT INTO KHACHHANG (MaKH, HoTen, DiaChi, DienThoai, TaiKhoan, MatKhau, NgaySinh, Email) VALUES (8, 'Trần Thị Hải Yến', 'Trần Hưng Đạo', '8111111', 'tthyen', '$2b$12$JAt/88QCmbbsvsWygI/FbuNs2Seh26vYBlX1jJtTvpT0MoRn/mSw.', '1988-02-07 00:00:00', 'tthyan@vol.vnn.vn');
INSERT INTO KHACHHANG (MaKH, HoTen, DiaChi, DienThoai, TaiKhoan, MatKhau, NgaySinh, Email) VALUES (9, 'Nguyễn Thị Thanh Mai', 'Trần Quang Diệu', '81111222', 'nttmai', '$2b$12$lHbFEpHw5fxYgkhgH6A18eZr6RKDQtOM6jsyS.PfWguUN7l2GmZhe', '1992-06-10 00:00:00', NULL);
INSERT INTO KHACHHANG (MaKH, HoTen, DiaChi, DienThoai, TaiKhoan, MatKhau, NgaySinh, Email) VALUES (10, 'Nguyễn Thành Danh', 'Cộng Hòa', '8103751', 'ntdanh', '$2b$12$qVwtFzWl0V/9/OVP.VDPR.VTrbwHD0nWQ8G2dLXVooJ.8nnhfBw6e', '1978-07-10 00:00:00', 'ntdanh@yahoo.com');
INSERT INTO KHACHHANG (MaKH, HoTen, DiaChi, DienThoai, TaiKhoan, MatKhau, NgaySinh, Email) VALUES (11, 'Phạm Thị Nga', 'Q6 - Tp.HCM', '0831564512', 'ptnga', '$2b$12$P6KxeB27/dhIfghEBO8iG.lWwShOJa2HVfoFKB87g3P/JQ4ABsPEa', '1986-03-20 00:00:00', 'ptnhung@hcmuns.edu.vn');
INSERT INTO KHACHHANG (MaKH, HoTen, DiaChi, DienThoai, TaiKhoan, MatKhau, NgaySinh, Email) VALUES (12, 'Lê Doanh Doanh', '2Bis Hùng Vương', '07077865', 'lddoanh', '$2b$12$OVXHMmDIiXVTseFUqVsbqOwxFgjIhnm9HFI3ZK8fmwf4w0ua7HCUq', '1982-02-11 00:00:00', 'lddoanh@yahoo.com');
INSERT INTO KHACHHANG (MaKH, HoTen, DiaChi, DienThoai, TaiKhoan, MatKhau, NgaySinh, Email) VALUES (13, 'Đòan Ngọc Minh Tâm', '2 Đinh Tiên Hòang', '0909092222', 'dnmtam', '$2b$12$r12cIMEThiJY3Bc5DZWWQeyFSV5SE1WhSO6K5rMfX6UitcRs0FknK', '1982-10-21 00:00:00', 'ndmtam@yahoo.com');
INSERT INTO KHACHHANG (MaKH, HoTen, DiaChi, DienThoai, TaiKhoan, MatKhau, NgaySinh, Email) VALUES (14, 'Trần Khải Nhi', '3 Bùi Hữu Nghĩa', '0909095555', 'tknhi', '$2b$12$q6z4IavqtBGhWSveOX4oL.IGt0OKCvde334wKRZDE2RuXPrQcfaqO', '1982-11-24 00:00:00', 'tknhi@yahoo.com');
INSERT INTO KHACHHANG (MaKH, HoTen, DiaChi, DienThoai, TaiKhoan, MatKhau, NgaySinh, Email) VALUES (15, 'Nguyễn Minh Khôi', 'TP.HCM', '0973955448', 'khoi', '$2b$12$2WFvdwmXCNg95sqAtkn1FO1tiawE7kzmcGi9V43stAhnRUdR5fSh6', '2005-02-04 00:00:00', '2324802010261@student.tdmu.edu.vn');

-- Dữ liệu bảng ADMIN (toàn bộ mật khẩu đã băm bằng bcrypt rounds=12)
INSERT INTO ADMIN (MaAd, HoTen, DienThoai, TenDN, MatKhau, Quyen) VALUES (1, 'Nguyễn Minh Khôi', '0973955448', 'khoidz', '$2b$12$SwXlE6I/jhBxUqkQriU4lOi.Iqih5h18/h/o7yrMF9bghzbVMwrbS', 1);
INSERT INTO ADMIN (MaAd, HoTen, DienThoai, TenDN, MatKhau, Quyen) VALUES (2, 'Võ Quốc Lương', '0988936592', 'luongvq', '$2b$12$dbuEqshRTr3LtKCcWh3Ul.gaA1Dn5exTorP1KMnSCMmHiClX4Kqva', 2);
INSERT INTO ADMIN (MaAd, HoTen, DienThoai, TenDN, MatKhau, Quyen) VALUES (3, 'Võ Nguyễn Nhật Minh', '012344444', 'minhvnn', '$2b$12$bgyt5BrwAy7OjGlDmukCXu.vBDSgBdpT6Y64ai7awFWcNFJXabUHi', 2);
INSERT INTO ADMIN (MaAd, HoTen, DienThoai, TenDN, MatKhau, Quyen) VALUES (4, 'Võ Nguyễn Thái Hoàng', '012344444', 'hoangvnt', '$2b$12$i8ZQYIAucpCAj6C6moX9MOnbS8aCmqoYlRIg214mOYhP.hZ6kVf1u', 2);
INSERT INTO ADMIN (MaAd, HoTen, DienThoai, TenDN, MatKhau, Quyen) VALUES (5, 'Quản trị viên', '', 'admin', '$2b$12$OYESdcjWxPdePYsjYZRDPebjoymNbHdlI8facsmDg8gBL0TNb/cjW', 1);

-- Dữ liệu bảng DONDATHANG
INSERT INTO DONDATHANG (MaDonHang, MaKH, TinhTrangGiaoHang, NgayDat, NgayGiao) VALUES (1, 1, 4, '2021-05-10 00:00:00', '2021-05-12 00:00:00');
INSERT INTO DONDATHANG (MaDonHang, MaKH, TinhTrangGiaoHang, NgayDat, NgayGiao) VALUES (2, 1, 2, '2021-05-07 00:00:00', '2021-05-11 00:00:00');

-- Dữ liệu bảng CHITIETDATHANG
INSERT INTO CHITIETDATHANG (MaDonHang, MaSach, SoLuong, DonGia) VALUES (1, 19, 1, 25000);
INSERT INTO CHITIETDATHANG (MaDonHang, MaSach, SoLuong, DonGia) VALUES (1, 23, 2, 25000);
INSERT INTO CHITIETDATHANG (MaDonHang, MaSach, SoLuong, DonGia) VALUES (2, 1, 1, 26000);
INSERT INTO CHITIETDATHANG (MaDonHang, MaSach, SoLuong, DonGia) VALUES (2, 17, 3, 18000);

-- Dữ liệu bảng MENU
INSERT INTO MENU (Id, MenuName, MenuLink, ParentId, OrderNumber) VALUES (1, 'TRANG CHỦ', '', NULL, 1);
INSERT INTO MENU (Id, MenuName, MenuLink, ParentId, OrderNumber) VALUES (2, 'GIỚI THIỆU', 'gioi-thieu', NULL, 2);
INSERT INTO MENU (Id, MenuName, MenuLink, ParentId, OrderNumber) VALUES (3, 'DANH MỤC', 'danh-muc', NULL, 3);
INSERT INTO MENU (Id, MenuName, MenuLink, ParentId, OrderNumber) VALUES (6, 'Sách Ngoại ngữ', 'sach-theo-chu-de-1', 3, 1);
INSERT INTO MENU (Id, MenuName, MenuLink, ParentId, OrderNumber) VALUES (7, 'Sách CNTT', 'sach-theo-chu-de-2', 3, 2);
INSERT INTO MENU (Id, MenuName, MenuLink, ParentId, OrderNumber) VALUES (8, 'Tin học văn phòng', 'chi-tiet-sach-21', 7, 1);
INSERT INTO MENU (Id, MenuName, MenuLink, ParentId, OrderNumber) VALUES (9, 'Tin học ứng dụng', 'chi-tiet-sach-15', 7, 2);
INSERT INTO MENU (Id, MenuName, MenuLink, ParentId, OrderNumber) VALUES (4, 'LIÊN HỆ', 'lien-he', NULL, 4);
INSERT INTO MENU (Id, MenuName, MenuLink, ParentId, OrderNumber) VALUES (5, 'TDMU Link tự do', 'https://tdmu.edu.vn', NULL, 5);

-- Dữ liệu bảng SLIDER
INSERT INTO SLIDER (MaSlider, TenSlider, ThuTu, HinhAnh) VALUES (1, 'Quảng cáo 1', 1, '01.jpg');
INSERT INTO SLIDER (MaSlider, TenSlider, ThuTu, HinhAnh) VALUES (2, 'Quảng cáo 2', 2, '02.jpg');
INSERT INTO SLIDER (MaSlider, TenSlider, ThuTu, HinhAnh) VALUES (3, 'Quảng cáo 3', 3, '03.jpg');
INSERT INTO SLIDER (MaSlider, TenSlider, ThuTu, HinhAnh) VALUES (4, 'Quảng cáo 4', 4, '04.jpg');
INSERT INTO SLIDER (MaSlider, TenSlider, ThuTu, HinhAnh) VALUES (5, 'Quảng cáo 5', 5, '05.jpg');
INSERT INTO SLIDER (MaSlider, TenSlider, ThuTu, HinhAnh) VALUES (6, 'Quảng cáo 6', 6, '06.jpg');

-- Dữ liệu bảng TRANGTIN
INSERT INTO TRANGTIN (MaTT, TenTrang, NoiDung, NgayTao, MetaTitle) VALUES (1, 'GIỚI THIỆU', 'Đây là nội dung trang giới thiệu', '2021-04-12 00:00:00', 'gioi-thieu');
INSERT INTO TRANGTIN (MaTT, TenTrang, NoiDung, NgayTao, MetaTitle) VALUES (2, 'LIÊN HỆ', 'Đây là nội dung trang liên hệ', '2022-04-10 00:00:00', 'lien-he');
