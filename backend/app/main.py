"""
EV Assistant FastAPI Application – entry point.

Bootstraps the FastAPI app, registers middleware, mounts all routers,
seeds initial vehicle data, and exposes /health and /docs endpoints.
"""
import logging
import logging.config
from contextlib import asynccontextmanager
from typing import AsyncGenerator

from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.config import settings
from app.database import create_tables, get_db_context, verify_connection
from app.models import Vehicle
from app.routers import auth, battery, charging, routes, trips, users, vehicles

# ─── Logging Setup ────────────────────────────────────────────────────────────
logging.basicConfig(
    level=getattr(logging, settings.LOG_LEVEL.upper(), logging.INFO),
    format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger(__name__)

# ─── Seed Data ────────────────────────────────────────────────────────────────
# 5 popular Indian EV models with real-world specifications.
SEED_VEHICLES = [
    {
        "vehicle_name": "Tata Nexon EV",
        "battery_capacity": 40.5,       # kWh (Long Range)
        "efficiency": 0.154,            # kWh/km (approx. 6.5 km/kWh)
        "connector_type": "CCS2",
        "charging_speed": 50.0,         # kW DC
        "range_km": 312,                # ARAI certified
        "manufacturer": "Tata Motors",
        "year": 2024,
    },
    {
        "vehicle_name": "MG ZS EV",
        "battery_capacity": 50.3,       # kWh
        "efficiency": 0.178,            # kWh/km (approx. 5.6 km/kWh)
        "connector_type": "CCS2",
        "charging_speed": 76.0,         # kW DC
        "range_km": 461,                # WLTP
        "manufacturer": "MG Motor India",
        "year": 2024,
    },
    {
        "vehicle_name": "Mahindra BE 6",
        "battery_capacity": 79.0,       # kWh (larger pack)
        "efficiency": 0.168,            # kWh/km
        "connector_type": "CCS2",
        "charging_speed": 175.0,        # kW DC fast charge
        "range_km": 535,                # ARAI certified
        "manufacturer": "Mahindra & Mahindra",
        "year": 2025,
    },
    {
        "vehicle_name": "Tata Curvv EV",
        "battery_capacity": 55.0,       # kWh
        "efficiency": 0.162,            # kWh/km
        "connector_type": "CCS2",
        "charging_speed": 70.0,         # kW DC
        "range_km": 502,                # ARAI certified
        "manufacturer": "Tata Motors",
        "year": 2024,
    },
    {
        "vehicle_name": "BYD Atto 3",
        "battery_capacity": 60.48,      # kWh (Standard Range)
        "efficiency": 0.171,            # kWh/km
        "connector_type": "CCS2",
        "charging_speed": 88.0,         # kW DC
        "range_km": 468,                # ARAI certified
        "manufacturer": "BYD India",
        "year": 2024,
    },
]


def seed_vehicles() -> None:
    """Insert the 5 sample EV models if they don't already exist."""
    with get_db_context() as db:
        for vehicle_data in SEED_VEHICLES:
            existing = (
                db.query(Vehicle)
                .filter(Vehicle.vehicle_name == vehicle_data["vehicle_name"])
                .first()
            )
            if not existing:
                db.add(Vehicle(**vehicle_data))
                logger.info("Seeded vehicle: %s", vehicle_data["vehicle_name"])
        logger.info("Vehicle seed complete.")


# ─── Lifespan ─────────────────────────────────────────────────────────────────

@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    """Application lifespan: startup and shutdown hooks."""
    # ── Startup ───────────────────────────────────────────────────────────────
    logger.info("Starting %s v%s …", settings.APP_NAME, settings.APP_VERSION)

    if not verify_connection():
        logger.critical("Cannot connect to the database. Aborting startup.")
        raise RuntimeError("Database connection failed.")

    create_tables()
    seed_vehicles()

    logger.info("%s is ready.", settings.APP_NAME)
    yield

    # ── Shutdown ──────────────────────────────────────────────────────────────
    logger.info("%s shutting down.", settings.APP_NAME)


# ─── FastAPI Application ──────────────────────────────────────────────────────

app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description=settings.APP_DESCRIPTION,
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
    lifespan=lifespan,
)

# ─── CORS Middleware ──────────────────────────────────────────────────────────
# Flutter web / mobile clients require permissive CORS during development.
# Restrict origins in production via the ALLOWED_ORIGINS env variable.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"] if "*" in settings.allowed_origins_list else settings.allowed_origins_list,
    allow_credentials=False if "*" in settings.allowed_origins_list else True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─── Global Exception Handler ─────────────────────────────────────────────────

@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    """Catch-all handler to prevent stack traces leaking to clients."""
    logger.exception("Unhandled exception on %s %s", request.method, request.url)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": "An unexpected error occurred. Please try again later.", "success": False},
    )

# ─── Routers ──────────────────────────────────────────────────────────────────
app.include_router(auth.router)
app.include_router(users.router)
app.include_router(vehicles.router)
app.include_router(battery.router)
app.include_router(charging.router)
app.include_router(routes.router)
app.include_router(trips.router)

# ─── Health / Root ────────────────────────────────────────────────────────────

@app.get("/", tags=["Health"], summary="API root")
def root() -> dict:
    """Welcome message and API info."""
    return {
        "app": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "docs": "/docs",
        "health": "/health",
    }


@app.get("/health", tags=["Health"], summary="Health check")
def health_check() -> dict:
    """
    Health check endpoint for load balancers and uptime monitors.

    Returns 200 OK when the application is running and the database is reachable.
    """
    db_ok = verify_connection()
    payload = {
        "status": "healthy" if db_ok else "degraded",
        "database": "connected" if db_ok else "unreachable",
        "version": settings.APP_VERSION,
        "environment": settings.ENVIRONMENT,
    }
    status_code = status.HTTP_200_OK if db_ok else status.HTTP_503_SERVICE_UNAVAILABLE
    return JSONResponse(content=payload, status_code=status_code)
