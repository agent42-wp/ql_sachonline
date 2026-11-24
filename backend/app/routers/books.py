from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session, joinedload

from app.database import get_db
from app.models import ChiTietDatHang, ChuDe, NhaXuatBan, Sach, VietSach
from app.schemas import (
    AuthorRoleOut,
    BookCreate,
    BookListResponse,
    BookOut,
    BookUpdate,
    UserProfile,
)
from app.security import get_current_user

router = APIRouter(prefix="/api/books", tags=["Books"])


def _serialize_book(book: Sach) -> BookOut:
    authors = [
        AuthorRoleOut(
            MaTG=entry.tacgia.MaTG,
            TenTG=entry.tacgia.TenTG,
            VaiTro=entry.VaiTro,
        )
        for entry in book.vietsach_entries
        if entry.tacgia is not None
    ]
    return BookOut(
        MaSach=book.MaSach,
        TenSach=book.TenSach.strip(),
        MoTa=book.MoTa,
        AnhBia=book.AnhBia,
        NgayCapNhat=book.NgayCapNhat,
        SoLuongBan=book.SoLuongBan,
        GiaBan=float(book.GiaBan),
        MaCD=book.MaCD,
        TenChuDe=book.chude.TenChuDe if book.chude else None,
        MaNXB=book.MaNXB,
        TenNXB=book.nhaxuatban.TenNXB if book.nhaxuatban else None,
        TacGia=authors,
    )


def _validate_relations(db: Session, ma_cd: int, ma_nxb: int) -> None:
    if db.get(ChuDe, ma_cd) is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Chủ đề (MaCD={ma_cd}) không tồn tại.",
        )
    if db.get(NhaXuatBan, ma_nxb) is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Nhà xuất bản (MaNXB={ma_nxb}) không tồn tại.",
        )


@router.get("", response_model=BookListResponse)
def list_books(
    q: str | None = Query(default=None, max_length=100),
    ma_cd: int | None = Query(default=None, ge=1),
    ma_nxb: int | None = Query(default=None, ge=1),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=12, ge=1, le=100),
    db: Session = Depends(get_db),
) -> BookListResponse:
    filters = []
    if q and q.strip():
        pattern = f"%{q.strip()}%"
        filters.append(Sach.TenSach.ilike(pattern))
    if ma_cd is not None:
        filters.append(Sach.MaCD == ma_cd)
    if ma_nxb is not None:
        filters.append(Sach.MaNXB == ma_nxb)

    total_stmt = select(func.count(Sach.MaSach)).where(*filters)
    total = int(db.scalar(total_stmt) or 0)

    stmt = (
        select(Sach)
        .options(
            joinedload(Sach.chude),
            joinedload(Sach.nhaxuatban),
            joinedload(Sach.vietsach_entries).joinedload(VietSach.tacgia),
        )
        .where(*filters)
        .order_by(Sach.MaSach.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    )
    books = db.execute(stmt).unique().scalars().all()
    return BookListResponse(
        total=total,
        page=page,
        page_size=page_size,
        items=[_serialize_book(b) for b in books],
    )


@router.get("/{ma_sach}", response_model=BookOut)
def get_book(ma_sach: int, db: Session = Depends(get_db)) -> BookOut:
    stmt = (
        select(Sach)
        .options(
            joinedload(Sach.chude),
            joinedload(Sach.nhaxuatban),
            joinedload(Sach.vietsach_entries).joinedload(VietSach.tacgia),
        )
        .where(Sach.MaSach == ma_sach)
    )
    book = db.execute(stmt).unique().scalar_one_or_none()
    if book is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy cuốn sách yêu cầu.",
        )
    return _serialize_book(book)


@router.post("", response_model=BookOut, status_code=status.HTTP_201_CREATED)
def create_book(
    payload: BookCreate,
    _user: UserProfile = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> BookOut:
    _validate_relations(db, payload.MaCD, payload.MaNXB)

    book = Sach(
        TenSach=payload.TenSach.strip(),
        MoTa=payload.MoTa.strip() if payload.MoTa else None,
        AnhBia=payload.AnhBia.strip() if payload.AnhBia else None,
        NgayCapNhat=datetime.now(),
        SoLuongBan=payload.SoLuongBan,
        GiaBan=payload.GiaBan,
        MaCD=payload.MaCD,
        MaNXB=payload.MaNXB,
    )
    db.add(book)
    db.commit()
    db.refresh(book)
    return get_book(book.MaSach, db)


@router.put("/{ma_sach}", response_model=BookOut)
def update_book(
    ma_sach: int,
    payload: BookUpdate,
    _user: UserProfile = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> BookOut:
    book = db.get(Sach, ma_sach)
    if book is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy cuốn sách cần cập nhật.",
        )
    _validate_relations(db, payload.MaCD, payload.MaNXB)

    book.TenSach = payload.TenSach.strip()
    book.MoTa = payload.MoTa.strip() if payload.MoTa else None
    book.AnhBia = payload.AnhBia.strip() if payload.AnhBia else None
    book.SoLuongBan = payload.SoLuongBan
    book.GiaBan = payload.GiaBan
    book.MaCD = payload.MaCD
    book.MaNXB = payload.MaNXB
    book.NgayCapNhat = datetime.now()

    db.commit()
    db.refresh(book)
    return get_book(book.MaSach, db)


@router.delete("/{ma_sach}")
def delete_book(
    ma_sach: int,
    _user: UserProfile = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict[str, str | int]:
    book = db.get(Sach, ma_sach)
    if book is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy cuốn sách cần xóa.",
        )

    in_order = db.scalar(
        select(func.count(ChiTietDatHang.MaSach)).where(
            ChiTietDatHang.MaSach == ma_sach
        )
    )
    if in_order and in_order > 0:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Không thể xóa sách này vì đã tồn tại trong đơn đặt hàng.",
        )

    db.delete(book)
    db.commit()
    return {"message": "Đã xóa sách thành công.", "ma_sach": ma_sach}
