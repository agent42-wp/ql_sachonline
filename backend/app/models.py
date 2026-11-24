from datetime import datetime
from decimal import Decimal

from sqlalchemy import (
    CheckConstraint,
    DateTime,
    ForeignKey,
    Integer,
    Numeric,
    String,
    Text,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class ChuDe(Base):
    __tablename__ = "CHUDE"

    MaCD: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    TenChuDe: Mapped[str] = mapped_column(String(50), nullable=False)

    books: Mapped[list["Sach"]] = relationship("Sach", back_populates="chude")


class NhaXuatBan(Base):
    __tablename__ = "NHAXUATBAN"

    MaNXB: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    TenNXB: Mapped[str] = mapped_column(String(100), nullable=False)
    DiaChi: Mapped[str | None] = mapped_column(String(150), nullable=True)
    DienThoai: Mapped[str | None] = mapped_column(String(20), nullable=True)

    books: Mapped[list["Sach"]] = relationship("Sach", back_populates="nhaxuatban")


class Sach(Base):
    __tablename__ = "SACH"
    __table_args__ = (
        CheckConstraint("SoLuongBan > 0", name="CK_SACH_SoLuongBan"),
        CheckConstraint("GiaBan >= 0", name="CK_SACH_GiaBan"),
    )

    MaSach: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    TenSach: Mapped[str] = mapped_column(String(150), nullable=False)
    MoTa: Mapped[str | None] = mapped_column(Text, nullable=True)
    AnhBia: Mapped[str | None] = mapped_column(String(100), nullable=True)
    NgayCapNhat: Mapped[datetime | None] = mapped_column(
        DateTime, default=datetime.now, server_default=func.current_timestamp()
    )
    SoLuongBan: Mapped[int] = mapped_column(Integer, nullable=False, default=1)
    GiaBan: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False, default=0)
    MaCD: Mapped[int | None] = mapped_column(
        Integer, ForeignKey("CHUDE.MaCD"), nullable=True
    )
    MaNXB: Mapped[int | None] = mapped_column(
        Integer, ForeignKey("NHAXUATBAN.MaNXB"), nullable=True
    )

    chude: Mapped[ChuDe | None] = relationship("ChuDe", back_populates="books")
    nhaxuatban: Mapped[NhaXuatBan | None] = relationship(
        "NhaXuatBan", back_populates="books"
    )
    vietsach_entries: Mapped[list["VietSach"]] = relationship(
        "VietSach", back_populates="sach", cascade="all, delete-orphan"
    )
    binhluan_entries: Mapped[list["BinhLuan"]] = relationship(
        "BinhLuan", back_populates="sach", cascade="all, delete-orphan"
    )


class TacGia(Base):
    __tablename__ = "TACGIA"

    MaTG: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    TenTG: Mapped[str] = mapped_column(String(50), nullable=False)
    DiaChi: Mapped[str | None] = mapped_column(String(100), nullable=True)
    TieuSu: Mapped[str | None] = mapped_column(Text, nullable=True)
    DienThoai: Mapped[str | None] = mapped_column(String(20), nullable=True)

    vietsach_entries: Mapped[list["VietSach"]] = relationship(
        "VietSach", back_populates="tacgia"
    )


class VietSach(Base):
    __tablename__ = "VIETSACH"

    MaTG: Mapped[int] = mapped_column(
        Integer, ForeignKey("TACGIA.MaTG", ondelete="CASCADE"), primary_key=True
    )
    MaSach: Mapped[int] = mapped_column(
        Integer, ForeignKey("SACH.MaSach", ondelete="CASCADE"), primary_key=True
    )
    VaiTro: Mapped[str | None] = mapped_column(String(30), nullable=True)
    ViTri: Mapped[str | None] = mapped_column(String(30), nullable=True)

    tacgia: Mapped[TacGia] = relationship("TacGia", back_populates="vietsach_entries")
    sach: Mapped[Sach] = relationship("Sach", back_populates="vietsach_entries")


class KhachHang(Base):
    __tablename__ = "KHACHHANG"

    MaKH: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    HoTen: Mapped[str] = mapped_column(String(50), nullable=False)
    TaiKhoan: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)
    MatKhau: Mapped[str] = mapped_column(String(255), nullable=False)
    Email: Mapped[str | None] = mapped_column(String(100), unique=True, nullable=True)
    DiaChi: Mapped[str | None] = mapped_column(String(100), nullable=True)
    DienThoai: Mapped[str | None] = mapped_column(String(20), nullable=True)
    NgaySinh: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)


class Admin(Base):
    __tablename__ = "ADMIN"

    MaAd: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    HoTen: Mapped[str | None] = mapped_column(String(50), nullable=True)
    DienThoai: Mapped[str | None] = mapped_column(String(20), nullable=True)
    TenDN: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)
    MatKhau: Mapped[str] = mapped_column(String(255), nullable=False)
    Quyen: Mapped[int] = mapped_column(Integer, default=1)


class DonDatHang(Base):
    __tablename__ = "DONDATHANG"

    MaDonHang: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    DaThanhToan: Mapped[int] = mapped_column(Integer, default=0)
    TinhTrangGiaoHang: Mapped[int] = mapped_column(Integer, default=1)
    NgayDat: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    NgayGiao: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    MaKH: Mapped[int | None] = mapped_column(
        Integer, ForeignKey("KHACHHANG.MaKH"), nullable=True
    )


class ChiTietDatHang(Base):
    __tablename__ = "CHITIETDATHANG"

    MaDonHang: Mapped[int] = mapped_column(
        Integer, ForeignKey("DONDATHANG.MaDonHang"), primary_key=True
    )
    MaSach: Mapped[int] = mapped_column(
        Integer, ForeignKey("SACH.MaSach"), primary_key=True
    )
    SoLuong: Mapped[int] = mapped_column(Integer, nullable=False)
    DonGia: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)


class BinhLuan(Base):
    __tablename__ = "BINHLUAN"

    MaBL: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    MaSach: Mapped[int] = mapped_column(
        Integer, ForeignKey("SACH.MaSach", ondelete="CASCADE"), nullable=False
    )
    MaKH: Mapped[int] = mapped_column(
        Integer, ForeignKey("KHACHHANG.MaKH", ondelete="CASCADE"), nullable=False
    )
    NoiDung: Mapped[str] = mapped_column(String(500), nullable=False)
    NgayBL: Mapped[datetime | None] = mapped_column(
        DateTime, default=datetime.now, server_default=func.current_timestamp()
    )
    DiemDanhGia: Mapped[int | None] = mapped_column(Integer, nullable=True)

    sach: Mapped[Sach] = relationship("Sach", back_populates="binhluan_entries")


class Slider(Base):
    __tablename__ = "SLIDER"

    MaSlider: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    TenSlider: Mapped[str] = mapped_column(String(100), nullable=False)
    ThuTu: Mapped[int] = mapped_column(Integer, nullable=False, default=1)
    HinhAnh: Mapped[str] = mapped_column(String(200), nullable=False)
