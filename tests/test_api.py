"""Bộ kiểm thử tự động cho SachOnline API, bảo mật bcrypt/HttpOnly cookie và tính toàn vẹn MariaDB SQL."""
from __future__ import annotations

import os
import re
import sys
from pathlib import Path

import bcrypt
import pytest

PROJECT_ROOT = Path(__file__).resolve().parents[1]
BACKEND_DIR = PROJECT_ROOT / "backend"
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

# Thiết lập SQLite in-memory trước khi import app để chạy test độc lập không cần MariaDB cục bộ
os.environ["DATABASE_URL_OVERRIDE"] = "sqlite:///:memory:"
os.environ["JWT_SECRET_KEY"] = "test-secret-key-for-pytest-only-32bytes"
os.environ["COOKIE_SECURE"] = "false"

from fastapi.testclient import TestClient  # noqa: E402
from sqlalchemy import create_engine, select  # noqa: E402
from sqlalchemy.orm import sessionmaker  # noqa: E402
from sqlalchemy.pool import StaticPool  # noqa: E402

from app.database import Base, get_db  # noqa: E402
from app.main import app  # noqa: E402
from app.models import (  # noqa: E402
    Admin,
    ChiTietDatHang,
    ChuDe,
    DonDatHang,
    KhachHang,
    NhaXuatBan,
    Sach,
    TacGia,
    VietSach,
)
from app.security import hash_password  # noqa: E402


@pytest.fixture()
def test_db():
    engine = create_engine(
        "sqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    TestingSession = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    Base.metadata.create_all(bind=engine)

    db = TestingSession()
    try:
        cd = ChuDe(MaCD=1, TenChuDe="Công nghệ thông tin")
        nxb = NhaXuatBan(MaNXB=1, TenNXB="Nhà xuất bản Trẻ", DiaChi="TP.HCM", DienThoai="19001560")
        tg = TacGia(MaTG=1, TenTG="Nguyễn Minh Khôi")
        admin = Admin(
            MaAd=1,
            HoTen="Nguyễn Minh Khôi",
            DienThoai="0973955448",
            TenDN="khoidz",
            MatKhau=hash_password("khoikhoi"),
            Quyen=1,
        )
        kh = KhachHang(
            MaKH=1,
            HoTen="Nguyễn Minh Khôi",
            TaiKhoan="khoi",
            MatKhau=hash_password("khoikhoi"),
            Email="2324802010261@student.tdmu.edu.vn",
            DiaChi="TP.HCM",
            DienThoai="0973955448",
        )
        book_free = Sach(
            MaSach=1,
            TenSach="Giáo trình Tin học cơ bản",
            MoTa="Sách cơ bản",
            AnhBia="THCB.jpg",
            SoLuongBan=120,
            GiaBan=26000,
            MaCD=1,
            MaNXB=1,
        )
        book_ordered = Sach(
            MaSach=2,
            TenSach="Giáo trình SQL và MariaDB",
            MoTa="Sách đã có đơn đặt hàng",
            AnhBia="SQL.jpg",
            SoLuongBan=20,
            GiaBan=50000,
            MaCD=1,
            MaNXB=1,
        )
        vs = VietSach(MaTG=1, MaSach=1, VaiTro="Tác giả", ViTri="")
        order = DonDatHang(MaDonHang=1, MaKH=1, DaThanhToan=0, TinhTrangGiaoHang=1)
        order_item = ChiTietDatHang(MaDonHang=1, MaSach=2, SoLuong=1, DonGia=50000)

        db.add_all([cd, nxb, tg, admin, kh, book_free, book_ordered, vs, order, order_item])
        db.commit()
    finally:
        db.close()

    def override_get_db():
        session = TestingSession()
        try:
            yield session
        finally:
            session.close()

    app.dependency_overrides[get_db] = override_get_db
    yield TestingSession
    app.dependency_overrides.clear()
    Base.metadata.drop_all(bind=engine)


@pytest.fixture()
def client(test_db):
    return TestClient(app)


def test_health_and_catalogs(client: TestClient):
    res = client.get("/api/health")
    assert res.status_code == 200
    assert res.json()["status"] == "ok"

    cats = client.get("/api/categories")
    assert cats.status_code == 200
    assert len(cats.json()) == 1

    pubs = client.get("/api/publishers")
    assert pubs.status_code == 200
    assert len(pubs.json()) == 1


def test_register_hashes_password_with_bcrypt_and_sets_httponly_cookie(client: TestClient, test_db):
    payload = {
        "ho_ten": "Sinh Viên Test",
        "tai_khoan": "svtest01",
        "mat_khau": "MatKhauManh@2026",
        "email": "svtest01@tdmu.edu.vn",
        "dien_thoai": "0901234567",
        "dia_chi": "Bình Dương",
    }
    res = client.post("/api/auth/register", json=payload)
    assert res.status_code == 201
    body = res.json()
    assert body["user"]["username"] == "svtest01"
    assert "sachonline_session" in res.cookies
    assert "httponly" in res.headers.get("set-cookie", "").lower()

    # Xác nhận DB lưu bcrypt hash, tuyệt đối không lưu plaintext
    with test_db() as db:
        saved = db.scalar(select(KhachHang).where(KhachHang.TaiKhoan == "svtest01"))
        assert saved is not None
        assert saved.MatKhau != payload["mat_khau"]
        assert saved.MatKhau.startswith("$2b$12$")
        assert bcrypt.checkpw(payload["mat_khau"].encode(), saved.MatKhau.encode())

    # Không cho đăng ký trùng tài khoản hoặc trùng email
    dup_user = client.post("/api/auth/register", json={**payload, "email": "other@tdmu.edu.vn"})
    assert dup_user.status_code == 409
    dup_email = client.post("/api/auth/register", json={**payload, "tai_khoan": "svtest02"})
    assert dup_email.status_code == 409


def test_login_logout_and_me_flow(client: TestClient):
    # Sai mật khẩu -> 401
    bad = client.post("/api/auth/login", json={"username": "khoidz", "password": "wrong"})
    assert bad.status_code == 401

    # Đăng nhập đúng tài khoản admin
    ok = client.post("/api/auth/login", json={"username": "khoidz", "password": "khoikhoi"})
    assert ok.status_code == 200
    data = ok.json()
    assert data["user"]["role"] == "admin"
    assert data["access_token"]

    # Xác thực bằng HttpOnly cookie tự động
    me_cookie = client.get("/api/auth/me")
    assert me_cookie.status_code == 200
    assert me_cookie.json()["username"] == "khoidz"

    # Đăng xuất -> cookie bị xóa -> /api/auth/me trả 401
    out = client.post("/api/auth/logout")
    assert out.status_code == 200
    assert client.get("/api/auth/me").status_code == 401

    # Vẫn hỗ trợ Authorization: Bearer token cho REST clients
    me_bearer = client.get(
        "/api/auth/me",
        headers={"Authorization": f"Bearer {data['access_token']}"},
    )
    assert me_bearer.status_code == 200


def test_books_crud_and_authorization(client: TestClient):
    # Xem danh sách & tìm kiếm công khai
    res_list = client.get("/api/books?q=Tin%20h%E1%BB%8Dc")
    assert res_list.status_code == 200
    assert res_list.json()["total"] == 1
    assert res_list.json()["items"][0]["TacGia"][0]["TenTG"] == "Nguyễn Minh Khôi"

    # Thêm sách khi chưa đăng nhập -> 401
    new_book = {
        "TenSach": "Điện Toán Đám Mây Thực Chiến",
        "MoTa": "Tài liệu triển khai VPS, Nginx, MariaDB và UFW.",
        "AnhBia": "cloud.jpg",
        "SoLuongBan": 50,
        "GiaBan": 95000,
        "MaCD": 1,
        "MaNXB": 1,
    }
    assert client.post("/api/books", json=new_book).status_code == 401

    # Đăng nhập và thực hiện đủ Thêm -> Xem -> Sửa -> Xóa
    login_res = client.post("/api/auth/login", json={"username": "khoi", "password": "khoikhoi"})
    assert login_res.status_code == 200

    created = client.post("/api/books", json=new_book)
    assert created.status_code == 201
    book_id = created.json()["MaSach"]
    assert created.json()["TenSach"] == new_book["TenSach"]

    detail = client.get(f"/api/books/{book_id}")
    assert detail.status_code == 200
    assert detail.json()["GiaBan"] == 95000.0

    updated = client.put(
        f"/api/books/{book_id}",
        json={**new_book, "TenSach": "Điện Toán Đám Mây (Bản Cập Nhật)", "GiaBan": 110000},
    )
    assert updated.status_code == 200
    assert updated.json()["TenSach"] == "Điện Toán Đám Mây (Bản Cập Nhật)"
    assert updated.json()["GiaBan"] == 110000.0

    deleted = client.delete(f"/api/books/{book_id}")
    assert deleted.status_code == 200
    assert client.get(f"/api/books/{book_id}").status_code == 404

    # Không cho xóa sách đã có trong đơn đặt hàng (MaSach=2) -> 409
    blocked = client.delete("/api/books/2")
    assert blocked.status_code == 409


def test_mariadb_sql_migration_integrity():
    import sqlite3

    sql_path = PROJECT_ROOT / "database" / "sachonline_mariadb.sql"
    assert sql_path.exists(), "Chưa có file database/sachonline_mariadb.sql"
    sql = sql_path.read_text(encoding="utf-8")

    # Chỉ kiểm tra phần câu lệnh SQL thực thi (bỏ qua dòng chú thích --)
    executable_sql = "\n".join(
        line for line in sql.splitlines() if not line.lstrip().startswith("--")
    )

    # Không còn cú pháp đặc thù SQL Server
    forbidden_patterns = [
        r"\bIDENTITY\s*\(",
        r"\[dbo\]",
        r"\bNVARCHAR\b",
        r"\bNTEXT\b",
        r"\bSMALLDATETIME\b",
        r"CAST\(0x",
        r"\bHASHBYTES\b",
        r"SET IDENTITY_INSERT",
        r"^\s*GO\s*$",
    ]
    for pat in forbidden_patterns:
        assert not re.search(
            pat, executable_sql, re.IGNORECASE | re.MULTILINE
        ), f"Còn sót cú pháp T-SQL: {pat}"

    # Đủ 13 bảng
    expected_tables = [
        "CHUDE", "NHAXUATBAN", "TACGIA", "SACH", "VIETSACH",
        "KHACHHANG", "ADMIN", "DONDATHANG", "CHITIETDATHANG",
        "TRANGTIN", "SLIDER", "BINHLUAN", "MENU",
    ]
    for tbl in expected_tables:
        assert f"CREATE TABLE {tbl} (" in executable_sql

    # Đã giải mã 2 ngày hex SmallDateTime
    assert "'2004-08-16 00:00:00'" in executable_sql
    assert "'2003-09-19 00:00:00'" in executable_sql

    # Đã loại bỏ dòng orphan VIETSACH MaSach=24
    assert "INSERT INTO VIETSACH (MaSach, MaTG, VaiTro, ViTri) VALUES (24," not in executable_sql

    # Xác nhận mật khẩu mẫu trong KHACHHANG và ADMIN đều là bcrypt hợp lệ và đối khớp mật khẩu gốc
    kh_hashes = dict(
        re.findall(
            r"INSERT INTO KHACHHANG .*?VALUES \(\d+, .*?, '([^']+)', '(\$2[aby]\$12\$[^']+)'",
            executable_sql,
        )
    )
    ad_hashes = dict(
        re.findall(
            r"INSERT INTO ADMIN .*?VALUES \(\d+, .*?, '([^']+)', '(\$2[aby]\$12\$[^']+)'",
            executable_sql,
        )
    )
    assert len(kh_hashes) == 15
    assert len(ad_hashes) == 4
    assert bcrypt.checkpw(b"khoikhoi", kh_hashes["khoi"].encode())
    assert bcrypt.checkpw(b"12345", kh_hashes["luongvq"].encode())
    assert bcrypt.checkpw(b"khoikhoi", ad_hashes["khoidz"].encode())
    assert bcrypt.checkpw(b"12345", ad_hashes["luongvq"].encode())

    # Thực thi thực tế toàn bộ 13 bảng + dữ liệu mẫu trên SQLite có bật FOREIGN KEYS để chứng minh toàn vẹn khóa ngoại
    sqlite_script = re.sub(r"^SET\s+.*;\s*$", "", executable_sql, flags=re.MULTILINE)
    sqlite_script = re.sub(r"\bAUTO_INCREMENT\b", "", sqlite_script)
    sqlite_script = re.sub(r"\)\s*ENGINE=InnoDB[^;]*;", ");", sqlite_script)
    sqlite_script = sqlite_script.replace("\\\\", "\\")

    conn = sqlite3.connect(":memory:")
    conn.execute("PRAGMA foreign_keys = ON;")
    conn.executescript(sqlite_script)
    counts = {
        tbl: conn.execute(f"SELECT COUNT(*) FROM {tbl}").fetchone()[0]
        for tbl in expected_tables
    }
    conn.close()
    assert counts["CHUDE"] == 12
    assert counts["NHAXUATBAN"] == 9
    assert counts["TACGIA"] == 16
    assert counts["SACH"] == 23
    assert counts["VIETSACH"] == 29
    assert counts["KHACHHANG"] == 15
    assert counts["ADMIN"] == 4
    assert counts["DONDATHANG"] == 2
    assert counts["CHITIETDATHANG"] == 4
    assert counts["TRANGTIN"] == 2
    assert counts["SLIDER"] == 6
    assert counts["MENU"] == 9
    assert counts["BINHLUAN"] == 0
