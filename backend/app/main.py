from pathlib import Path

from fastapi import FastAPI
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles

from app.config import PROJECT_ROOT, settings
from app.media import IMAGES_DIR
from app.routers import auth, books, catalogs

app = FastAPI(
    title=settings.app_title,
    version="1.0.0",
    docs_url="/api/docs",
    openapi_url="/api/openapi.json",
)

app.include_router(catalogs.router)
app.include_router(auth.router)
app.include_router(books.router)

if IMAGES_DIR.exists():
    app.mount("/Images", StaticFiles(directory=IMAGES_DIR), name="images")

FRONTEND_DIR: Path = PROJECT_ROOT / "frontend"
if FRONTEND_DIR.exists():
    app.mount("/css", StaticFiles(directory=FRONTEND_DIR / "css"), name="css")
    app.mount("/js", StaticFiles(directory=FRONTEND_DIR / "js"), name="js")

    @app.get("/", include_in_schema=False)
    def serve_index() -> FileResponse:
        return FileResponse(FRONTEND_DIR / "index.html")
