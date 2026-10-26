"""Owner: TV4 - LB / TV1 - Phuoc.

Application configuration loaded from environment and backend/.env.
"""

from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

BASE_DIR = Path(__file__).resolve().parents[3]
ENV_FILE = BASE_DIR / "backend" / ".env"
FALLBACK_ENV = BASE_DIR / ".env"


class Settings(BaseSettings):
    """Application settings and environment configuration."""

    PROJECT_NAME: str = "StockMate API"
    ENVIRONMENT: str = "development"
    DEBUG: bool = True
    API_V1_PREFIX: str = "/api"

    # Database
    POSTGRES_HOST: str = "localhost"
    POSTGRES_PORT: int = 5432
    POSTGRES_DB: str = "stock_exchange"
    POSTGRES_USER: str = "postgres"
    POSTGRES_PASSWORD: str = "postgres"
    DATABASE_URL: str = "postgresql+psycopg://postgres:postgres@localhost:5432/stock_exchange"

    # Security
    SECRET_KEY: str = "change-this-secret-key-in-production-for-jwt-signing"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24
    REFRESH_TOKEN_EXPIRE_DAYS: int = 14

    # CORS
    BACKEND_CORS_ORIGINS: str = "http://localhost:8080,http://127.0.0.1:8080"

    # Trading Rules
    TRANSACTION_FEE_RATE: float = 0.0015
    SELL_TAX_RATE: float = 0.001
    SETTLEMENT_DAYS: int = 2

    model_config = SettingsConfigDict(
        env_file=str(ENV_FILE) if ENV_FILE.exists() else str(FALLBACK_ENV),
        env_file_encoding="utf-8",
        extra="ignore",
    )

    @property
    def cors_origins_list(self) -> list[str]:
        if not self.BACKEND_CORS_ORIGINS:
            return ["*"]
        return [origin.strip() for origin in self.BACKEND_CORS_ORIGINS.split(",") if origin.strip()]


settings = Settings()
