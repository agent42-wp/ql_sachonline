"""Tiện ích chuẩn hóa tên tệp ảnh và liệt kê tài nguyên trong thư mục Images/."""
from __future__ import annotations

import re
from pathlib import Path
from urllib.parse import quote

from app.config import PROJECT_ROOT

IMAGES_DIR: Path = PROJECT_ROOT / "Images"
SLIDER_IMAGES_DIR: Path = IMAGES_DIR / "Slider"

ALLOWED_IMAGE_EXTENSIONS: frozenset[str] = frozenset({".jpg", ".jpeg", ".png", ".webp"})
EXCLUDED_LEGACY_ICONS: frozenset[str] = frozenset(
    {"cancel.jpg", "delete.jpg", "edit.png", "save.jpg", "momo.png"}
)
MIN_COVER_BYTES: int = 5_000
_SAFE_FILENAME_RE = re.compile(r"^[A-Za-z0-9._-]+$")


def sanitize_image_filename(raw: str | None) -> str | None:
    """Chuẩn hóa tên tệp ảnh bìa và chặn path traversal (.., /, \\)."""
    if raw is None:
        return None
    cleaned = raw.strip()
    if not cleaned:
        return None

    # Cho phép người dùng dán "/Images/THCB.jpg" hoặc "Images/THCB.jpg"
    for prefix in ("/Images/", "Images/", "/images/", "images/"):
        if cleaned.startswith(prefix):
            cleaned = cleaned[len(prefix) :]
            break

    if "/" in cleaned or "\\" in cleaned or ".." in cleaned or cleaned.startswith("."):
        raise ValueError("Tên tệp ảnh bìa không hợp lệ (không được chứa đường dẫn).")
    if not _SAFE_FILENAME_RE.match(cleaned):
        raise ValueError("Tên tệp ảnh bìa chỉ chấp nhận chữ, số và ký tự . _ -")

    ext = Path(cleaned).suffix.lower()
    if ext not in ALLOWED_IMAGE_EXTENSIONS:
        raise ValueError("Ảnh bìa chỉ hỗ trợ định dạng .jpg, .jpeg, .png hoặc .webp.")
    return cleaned


def build_book_image_url(filename: str | None) -> str | None:
    if not filename:
        return None
    cleaned = filename.strip()
    if not cleaned or "/" in cleaned or "\\" in cleaned or ".." in cleaned:
        return None
    return f"/Images/{quote(cleaned)}"


def build_slider_image_url(filename: str | None) -> str | None:
    if not filename:
        return None
    cleaned = filename.strip()
    if not cleaned or "/" in cleaned or "\\" in cleaned or ".." in cleaned:
        return None
    return f"/Images/Slider/{quote(cleaned)}"


def list_available_book_images() -> list[dict[str, str | int]]:
    """Liệt kê các tệp ảnh bìa sách hợp lệ trong thư mục Images/."""
    if not IMAGES_DIR.exists():
        return []

    assets: list[dict[str, str | int]] = []
    for entry in sorted(IMAGES_DIR.iterdir(), key=lambda p: p.name.lower()):
        if not entry.is_file():
            continue
        if entry.suffix.lower() not in ALLOWED_IMAGE_EXTENSIONS:
            continue
        if entry.name.lower() in EXCLUDED_LEGACY_ICONS:
            continue
        size = entry.stat().st_size
        if size < MIN_COVER_BYTES:
            continue
        assets.append(
            {
                "filename": entry.name,
                "url": f"/Images/{quote(entry.name)}",
                "size_bytes": size,
            }
        )
    return assets
