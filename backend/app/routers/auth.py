from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Admin, KhachHang
from app.schemas import AuthTokenResponse, LoginRequest, RegisterRequest, UserProfile
from app.security import (
    clear_session_cookie,
    create_access_token,
    get_current_user,
    hash_password,
    set_session_cookie,
    verify_password,
)

router = APIRouter(prefix="/api/auth", tags=["Authentication"])


@router.post(
    "/register",
    response_model=AuthTokenResponse,
    status_code=status.HTTP_201_CREATED,
)
def register(
    payload: RegisterRequest,
    response: Response,
    db: Session = Depends(get_db),
) -> AuthTokenResponse:
    username = payload.tai_khoan.strip()
    email = payload.email.strip().lower()

    existing_user = db.scalar(
        select(KhachHang).where(KhachHang.TaiKhoan == username)
    )
    if existing_user is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Tên tài khoản đã được sử dụng.",
        )

    existing_admin = db.scalar(select(Admin).where(Admin.TenDN == username))
    if existing_admin is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Tên tài khoản đã được sử dụng.",
        )

    existing_email = db.scalar(select(KhachHang).where(KhachHang.Email == email))
    if existing_email is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email này đã được đăng ký.",
        )

    ngay_sinh_dt = (
        datetime.combine(payload.ngay_sinh, datetime.min.time())
        if payload.ngay_sinh
        else None
    )

    customer = KhachHang(
        HoTen=payload.ho_ten.strip(),
        TaiKhoan=username,
        MatKhau=hash_password(payload.mat_khau),
        Email=email,
        DiaChi=payload.dia_chi.strip() if payload.dia_chi else None,
        DienThoai=payload.dien_thoai.strip() if payload.dien_thoai else None,
        NgaySinh=ngay_sinh_dt,
    )
    db.add(customer)
    db.commit()
    db.refresh(customer)

    profile = UserProfile(
        user_id=customer.MaKH,
        username=customer.TaiKhoan,
        full_name=customer.HoTen,
        email=customer.Email,
        role="customer",
    )
    token = create_access_token(profile)
    set_session_cookie(response, token)
    return AuthTokenResponse(access_token=token, user=profile)


@router.post("/login", response_model=AuthTokenResponse)
def login(
    payload: LoginRequest,
    response: Response,
    db: Session = Depends(get_db),
) -> AuthTokenResponse:
    username = payload.username.strip()

    # Ưu tiên kiểm tra tài khoản quản trị (ADMIN), sau đó đến khách hàng (KHACHHANG)
    admin = db.scalar(select(Admin).where(Admin.TenDN == username))
    if admin is not None and verify_password(payload.password, admin.MatKhau):
        profile = UserProfile(
            user_id=admin.MaAd,
            username=admin.TenDN,
            full_name=admin.HoTen or admin.TenDN,
            email=None,
            role="admin",
        )
        token = create_access_token(profile)
        set_session_cookie(response, token)
        return AuthTokenResponse(access_token=token, user=profile)

    customer = db.scalar(select(KhachHang).where(KhachHang.TaiKhoan == username))
    if customer is not None and verify_password(payload.password, customer.MatKhau):
        profile = UserProfile(
            user_id=customer.MaKH,
            username=customer.TaiKhoan,
            full_name=customer.HoTen,
            email=customer.Email,
            role="customer",
        )
        token = create_access_token(profile)
        set_session_cookie(response, token)
        return AuthTokenResponse(access_token=token, user=profile)

    # Thông báo chung để tránh lộ thông tin tài khoản có tồn tại hay không
    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Tên đăng nhập hoặc mật khẩu không chính xác.",
    )


@router.post("/logout")
def logout(response: Response) -> dict[str, str]:
    clear_session_cookie(response)
    return {"message": "Đã đăng xuất thành công."}


@router.get("/me", response_model=UserProfile)
def me(current_user: UserProfile = Depends(get_current_user)) -> UserProfile:
    return current_user
