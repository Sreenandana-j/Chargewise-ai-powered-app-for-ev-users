"""
Charging router – charging stations and charging history.

Endpoints:
  GET  /charging-stations   – list mock/static EV charging stations
  POST /charging-history     – log a charging session
  GET  /charging-history     – retrieve current user's charging history
"""
import logging
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app import models
from app.database import get_db
from app.schemas import (
    ChargingHistoryCreate,
    ChargingHistoryResponse,
    ChargingStationResponse,
)
from app.utils import get_current_user

logger = logging.getLogger(__name__)

router = APIRouter(tags=["Charging"])

# ─── Static charging station data ─────────────────────────────────────────────
# In production, replace with a live charging-network API call.
MOCK_CHARGING_STATIONS: list[dict] = [
    {
        "id": 1,
        "name": "Tata Power EZ Charge – Chennai Central",
        "location": "Chennai Central Railway Station, Chennai, Tamil Nadu",
        "latitude": 13.0827,
        "longitude": 80.2707,
        "connector_types": ["CCS2", "CHAdeMO", "Type 2"],
        "max_power_kw": 50.0,
        "is_available": True,
        "price_per_kwh": 12.5,
        "operator": "Tata Power",
    },
    {
        "id": 2,
        "name": "EESL Charging Station – Bangalore MG Road",
        "location": "MG Road Metro Station, Bangalore, Karnataka",
        "latitude": 12.9716,
        "longitude": 77.6099,
        "connector_types": ["CCS2", "Type 2"],
        "max_power_kw": 30.0,
        "is_available": True,
        "price_per_kwh": 10.0,
        "operator": "EESL",
    },
    {
        "id": 3,
        "name": "Ather Grid – Koramangala",
        "location": "Koramangala 5th Block, Bangalore, Karnataka",
        "latitude": 12.9352,
        "longitude": 77.6244,
        "connector_types": ["Ather Proprietary", "Type 2"],
        "max_power_kw": 22.0,
        "is_available": False,
        "price_per_kwh": 9.0,
        "operator": "Ather Energy",
    },
    {
        "id": 4,
        "name": "MG ZS EV – Rapid Charger Hub Mumbai",
        "location": "BKC Complex, Bandra Kurla, Mumbai, Maharashtra",
        "latitude": 19.0596,
        "longitude": 72.8656,
        "connector_types": ["CCS2", "CHAdeMO"],
        "max_power_kw": 100.0,
        "is_available": True,
        "price_per_kwh": 14.0,
        "operator": "MG Motors",
    },
    {
        "id": 5,
        "name": "BYD DC Fast Charger – Delhi Aerocity",
        "location": "Aerocity, New Delhi",
        "latitude": 28.5562,
        "longitude": 77.0999,
        "connector_types": ["CCS2", "Type 2"],
        "max_power_kw": 120.0,
        "is_available": True,
        "price_per_kwh": 13.0,
        "operator": "BYD India",
    },
    {
        "id": 6,
        "name": "Mahindra REIL – Hyderabad HITEC City",
        "location": "HITEC City, Hyderabad, Telangana",
        "latitude": 17.4400,
        "longitude": 78.3489,
        "connector_types": ["CCS2", "Type 2"],
        "max_power_kw": 50.0,
        "is_available": True,
        "price_per_kwh": 11.5,
        "operator": "Mahindra Electric",
    },
    {
        "id": 7,
        "name": "Charge Zone – Pune Hinjewadi IT Park",
        "location": "Hinjewadi Phase 1, Pune, Maharashtra",
        "latitude": 18.5912,
        "longitude": 73.7389,
        "connector_types": ["CCS2", "Type 2", "CHAdeMO"],
        "max_power_kw": 60.0,
        "is_available": True,
        "price_per_kwh": 12.0,
        "operator": "Charge Zone",
    },
    {
        "id": 8,
        "name": "Nexcharge – Kochi InfoPark",
        "location": "Infopark Campus, Kakkanad, Kochi, Kerala",
        "latitude": 10.0167,
        "longitude": 76.3567,
        "connector_types": ["CCS2", "Type 2"],
        "max_power_kw": 30.0,
        "is_available": True,
        "price_per_kwh": 10.5,
        "operator": "Nexcharge",
    },
]


@router.get(
    "/charging-stations",
    response_model=list[ChargingStationResponse],
    summary="List available EV charging stations",
)
def list_charging_stations(
    available_only: bool = Query(False, description="Return only currently available stations"),
    connector: Optional[str] = Query(None, description="Filter by connector type (e.g. CCS2)"),
    _: models.User = Depends(get_current_user),
) -> list[dict]:
    """
    Return a list of EV charging stations.

    Currently returns a curated static dataset of Indian charging stations.
    In production this will proxy a live charging-network API.

    Optional filters:
    - **available_only**: Show only stations currently in service.
    - **connector**: Filter by connector type (case-insensitive).
    """
    stations = MOCK_CHARGING_STATIONS

    if available_only:
        stations = [s for s in stations if s["is_available"]]

    if connector:
        stations = [
            s
            for s in stations
            if any(connector.lower() in ct.lower() for ct in s["connector_types"])
        ]

    return stations


@router.post(
    "/charging-history",
    response_model=ChargingHistoryResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Log a charging session",
)
def create_charging_history(
    payload: ChargingHistoryCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
) -> models.ChargingHistory:
    """
    Record a charging session.

    Optionally link the session to an existing trip via **trip_id**.
    If linked, the trip must belong to the authenticated user.
    """
    # Validate trip ownership if trip_id is provided.
    if payload.trip_id is not None:
        trip = db.query(models.Trip).filter(models.Trip.id == payload.trip_id).first()
        if not trip:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Trip with id={payload.trip_id} not found.",
            )
        if trip.user_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You do not have permission to link a charging session to this trip.",
            )

    history = models.ChargingHistory(**payload.model_dump())
    db.add(history)
    db.commit()
    db.refresh(history)

    logger.info(
        "Charging session logged: id=%d station=%s user=%d",
        history.id,
        history.station_name,
        current_user.id,
    )
    return history


@router.get(
    "/charging-history",
    response_model=list[ChargingHistoryResponse],
    summary="Get charging history for current user",
)
def get_charging_history(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
) -> list[models.ChargingHistory]:
    """
    Retrieve charging sessions linked to the authenticated user's trips.
    Sessions not linked to any trip are excluded from this view.
    """
    # Fetch charging history via user's trips.
    user_trip_ids = (
        db.query(models.Trip.id)
        .filter(models.Trip.user_id == current_user.id)
        .subquery()
    )

    history = (
        db.query(models.ChargingHistory)
        .filter(models.ChargingHistory.trip_id.in_(user_trip_ids))
        .order_by(models.ChargingHistory.created_at.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )

    return history
