from datetime import date, datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field


# --- Auth Schemas ---
class RegisterRequest(BaseModel):
    ho_ten: str = Field(..., min_length=2, max_length=50)
    tai_khoan: str = Field(
        ..., min_length=3, max_length=50, pattern=r"^[A-Za-z0-9_.-]+$"
    )
    mat_khau: str = Field(..., min_length=6, max_length=72)
    email: str = Field(
        ..., min_length=5, max_length=100, pattern=r"^[^@\s]+@[^@\s]+\.[^@\s]+$"
    )
    dia_chi: str | None = Field(default=None, max_length=100)
    dien_thoai: str | None = Field(default=None, max_length=20)
    ngay_sinh: date | None = None


class LoginRequest(BaseModel):
    username: str = Field(..., min_length=1, max_length=50)
    password: str = Field(..., min_length=1, max_length=72)


class UserProfile(BaseModel):
    user_id: int
    username: str
    full_name: str
    email: str | None = None
    role: str  # "admin" | "customer"


class AuthTokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserProfile


# --- Catalog Schemas ---
class CategoryOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    MaCD: int
    TenChuDe: str


class PublisherOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    MaNXB: int
    TenNXB: str
    DiaChi: str | None = None
    DienThoai: str | None = None


class AuthorRoleOut(BaseModel):
    MaTG: int
    TenTG: str
    VaiTro: str | None = None


# --- Book CRUD Schemas ---
class BookCreate(BaseModel):
    TenSach: str = Field(..., min_length=1, max_length=150)
    MoTa: str | None = None
    AnhBia: str | None = Field(default=None, max_length=100)
    SoLuongBan: int = Field(..., gt=0)
    GiaBan: Decimal = Field(..., ge=0)
    MaCD: int
    MaNXB: int


class BookUpdate(BaseModel):
    TenSach: str = Field(..., min_length=1, max_length=150)
    MoTa: str | None = None
    AnhBia: str | None = Field(default=None, max_length=100)
    SoLuongBan: int = Field(..., gt=0)
    GiaBan: Decimal = Field(..., ge=0)
    MaCD: int
    MaNXB: int


class BookOut(BaseModel):
    MaSach: int
    TenSach: str
    MoTa: str | None = None
    AnhBia: str | None = None
    NgayCapNhat: datetime | None = None
    SoLuongBan: int
    GiaBan: float
    MaCD: int | None = None
    TenChuDe: str | None = None
    MaNXB: int | None = None
    TenNXB: str | None = None
    TacGia: list[AuthorRoleOut] = Field(default_factory=list)


class BookListResponse(BaseModel):
    total: int
    page: int
    page_size: int
    items: list[BookOut]
