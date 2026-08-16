"""
Application configuration using environment variables.
Loads settings from .env file for clean separation of config from code.
"""
import os
from functools import lru_cache
from typing import Optional

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """
    Application settings loaded from environment variables.
    All values have sensible defaults for development; override in .env for production.
    """

    # ─── Application ──────────────────────────────────────────────────────────
    APP_NAME: str = "EV Assistant API"
    APP_VERSION: str = "1.0.0"
    APP_DESCRIPTION: str = (
        "Production-ready FastAPI backend for the EV Assistant Application. "
        "Provides endpoints for authentication, vehicle management, "
        "battery prediction, charging history, and trip tracking."
    )
    DEBUG: bool = False
    ENVIRONMENT: str = "development"  # development | staging | production

    # ─── Database ─────────────────────────────────────────────────────────────
    # Use SQLite by default for development; switch to PostgreSQL in production.
    DATABASE_URL: str = "sqlite:///./ev_assistant.db"
    # Example PostgreSQL URL:
    # DATABASE_URL=postgresql://user:password@localhost:5432/ev_assistant

    # ─── Security / JWT ───────────────────────────────────────────────────────
    SECRET_KEY: str = "CHANGE_ME_IN_PRODUCTION_USE_A_LONG_RANDOM_STRING"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24  # 24 hours

    # ─── CORS ─────────────────────────────────────────────────────────────────
    # Comma-separated list of allowed origins for Flutter/web clients.
    ALLOWED_ORIGINS: str = "*"

    # ─── Logging ──────────────────────────────────────────────────────────────
    LOG_LEVEL: str = "INFO"  # DEBUG | INFO | WARNING | ERROR | CRITICAL

    # ─── External APIs ────────────────────────────────────────────────────────
    ORS_API_KEY: str = "eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6ImYzOGYyNWM1YzA5ZDQxY2U5MjRiODY4YjQzMTViMDM1IiwiaCI6Im11cm11cjY0In0="
    OCM_API_KEY: str = "f31b982d-cc1e-4336-b5ad-cd7a87514f8d"
    GOOGLE_MAPS_API_KEY: Optional[str] = None
    CHARGING_NETWORK_API_KEY: Optional[str] = None

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = True

    @property
    def allowed_origins_list(self) -> list[str]:
        """Parse the comma-separated ALLOWED_ORIGINS string into a list."""
        return [origin.strip() for origin in self.ALLOWED_ORIGINS.split(",")]


@lru_cache()
def get_settings() -> Settings:
    """Return a cached Settings instance (singleton pattern)."""
    return Settings()


# Module-level settings instance for convenience imports.
settings = get_settings()
