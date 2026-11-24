from pathlib import Path
from urllib.parse import quote_plus

from pydantic_settings import BaseSettings, SettingsConfigDict

PROJECT_ROOT = Path(__file__).resolve().parents[2]
ENV_FILE = PROJECT_ROOT / ".env"


class Settings(BaseSettings):
    db_host: str = "127.0.0.1"
    db_port: int = 3306
    db_name: str = "sachonline"
    db_user: str = "sachonline_app"
    db_password: str = ""
    database_url_override: str | None = None

    jwt_secret_key: str = "dev-only-change-me-in-env"
    jwt_algorithm: str = "HS256"
    jwt_expire_minutes: int = 120
    cookie_secure: bool = False
    session_cookie_name: str = "sachonline_session"

    app_title: str = "SachOnline - Quản Lý Sách Online (vps-2324802010261)"
    app_host: str = "127.0.0.1"
    app_port: int = 8000

    model_config = SettingsConfigDict(
        env_file=str(ENV_FILE),
        env_file_encoding="utf-8",
        extra="ignore",
    )

    @property
    def database_url(self) -> str:
        if self.database_url_override:
            return self.database_url_override
        user = quote_plus(self.db_user)
        password = quote_plus(self.db_password)
        return (
            f"mysql+pymysql://{user}:{password}"
            f"@{self.db_host}:{self.db_port}/{self.db_name}?charset=utf8mb4"
        )


settings = Settings()
