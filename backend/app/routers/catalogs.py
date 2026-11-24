from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select, text
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import ChuDe, NhaXuatBan
from app.schemas import CategoryOut, PublisherOut

router = APIRouter(prefix="/api", tags=["Catalogs & Health"])


@router.get("/health")
def health_check(db: Session = Depends(get_db)) -> dict[str, str]:
    try:
        db.execute(text("SELECT 1"))
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Không thể kết nối tới cơ sở dữ liệu.",
        ) from exc
    return {
        "status": "ok",
        "database": "connected",
        "service": "sachonline-vps-2324802010261",
    }


@router.get("/categories", response_model=list[CategoryOut])
def list_categories(db: Session = Depends(get_db)) -> list[ChuDe]:
    return list(db.scalars(select(ChuDe).order_by(ChuDe.MaCD.asc())).all())


@router.get("/publishers", response_model=list[PublisherOut])
def list_publishers(db: Session = Depends(get_db)) -> list[NhaXuatBan]:
    return list(db.scalars(select(NhaXuatBan).order_by(NhaXuatBan.MaNXB.asc())).all())
