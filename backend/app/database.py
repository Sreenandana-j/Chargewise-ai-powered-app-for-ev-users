"""
Database engine and session management.
Supports both SQLite (development) and PostgreSQL (production) via DATABASE_URL.
"""
import logging
from contextlib import contextmanager
from typing import Generator

from sqlalchemy import create_engine, event, text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from app.config import settings

logger = logging.getLogger(__name__)

# ─── Engine Setup ─────────────────────────────────────────────────────────────
_is_sqlite = settings.DATABASE_URL.startswith("sqlite")

connect_args = {}
engine_kwargs: dict = {}

if _is_sqlite:
    # SQLite requires check_same_thread=False for FastAPI's async request handling.
    # StaticPool ensures the same in-memory DB is shared across threads in tests.
    connect_args = {"check_same_thread": False}
    engine_kwargs = {
        "connect_args": connect_args,
        "poolclass": StaticPool,
    }
else:
    # PostgreSQL connection pool settings for production.
    engine_kwargs = {
        "pool_size": 10,
        "max_overflow": 20,
        "pool_pre_ping": True,  # Verify connections before use.
        "echo": settings.DEBUG,
    }

engine = create_engine(settings.DATABASE_URL, **engine_kwargs)

# Enable WAL mode and foreign keys for SQLite (safe no-op on PostgreSQL).
if _is_sqlite:
    @event.listens_for(engine, "connect")
    def _set_sqlite_pragmas(dbapi_conn, _connection_record):
        cursor = dbapi_conn.cursor()
        cursor.execute("PRAGMA journal_mode=WAL;")
        cursor.execute("PRAGMA foreign_keys=ON;")
        cursor.close()

# ─── Session Factory ──────────────────────────────────────────────────────────
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine,
)

# ─── Declarative Base ─────────────────────────────────────────────────────────
Base = declarative_base()


# ─── Dependency ───────────────────────────────────────────────────────────────
def get_db() -> Generator[Session, None, None]:
    """
    FastAPI dependency that yields a database session and ensures cleanup.

    Usage:
        @router.get("/example")
        def example(db: Session = Depends(get_db)):
            ...
    """
    db = SessionLocal()
    try:
        yield db
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


@contextmanager
def get_db_context() -> Generator[Session, None, None]:
    """
    Context-manager version of get_db for use outside FastAPI dependency injection
    (e.g., scripts, seed functions).
    """
    db = SessionLocal()
    try:
        yield db
        db.commit()
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


def create_tables() -> None:
    """Create all database tables defined in models.py."""
    logger.info("Creating database tables…")
    Base.metadata.create_all(bind=engine)
    logger.info("Database tables created successfully.")


def verify_connection() -> bool:
    """Verify the database connection is healthy."""
    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        return True
    except Exception as exc:  # noqa: BLE001
        logger.error("Database connection failed: %s", exc)
        return False
