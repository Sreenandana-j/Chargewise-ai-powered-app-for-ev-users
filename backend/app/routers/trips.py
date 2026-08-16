"""
Trips router – trip creation and history.

Endpoints:
  POST /trip          – log a new trip
  GET  /trip-history  – fetch current user's trip history
  GET  /trip/{id}     – get a specific trip
"""
import logging
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session, joinedload

from app import models
from app.database import get_db
from app.schemas import TripCreate, TripResponse
from app.utils import get_current_user, predict_battery

logger = logging.getLogger(__name__)

router = APIRouter(tags=["Trips"])


@router.post(
    "/trip",
    response_model=TripResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Log a new trip",
)
def create_trip(
    payload: TripCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
) -> models.Trip:
    """
    Record a completed or planned trip.

    If **battery_after** and **energy_used** are not provided but a valid **vehicle_id**
    is supplied, the API will auto-calculate them using the battery prediction formula.
    """
    # Validate vehicle exists.
    vehicle: Optional[models.Vehicle] = None
    if payload.vehicle_id is not None:
        vehicle = (
            db.query(models.Vehicle)
            .filter(models.Vehicle.id == payload.vehicle_id)
            .first()
        )
        if not vehicle:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Vehicle with id={payload.vehicle_id} not found.",
            )

    trip_data = payload.model_dump()

    # Auto-calculate battery_after and energy_used if not provided.
    if vehicle and payload.battery_after is None:
        prediction = predict_battery(
            distance_km=payload.distance,
            battery_percentage=payload.battery_before,
            vehicle=vehicle,
            elevation_gain_m=payload.elevation_gain_m or 0.0,
            avg_speed_kmh=payload.avg_speed_kmh or 60.0,
            temperature_c=payload.temperature_c or 25.0,
            traffic_level=payload.traffic_level or "low",
            ac_on=payload.ac_on or False,
            payload_weight_kg=payload.payload_weight_kg or 0.0,
            road_type=payload.road_type or "mixed",
            battery_health=payload.battery_health or 100.0,
        )
        trip_data["battery_after"] = prediction["battery_after"]
        trip_data["energy_used"] = prediction["energy_used_kwh"]

    trip = models.Trip(user_id=current_user.id, **trip_data)
    db.add(trip)
    db.commit()
    db.refresh(trip)

    logger.info(
        "Trip created: id=%d user=%d %s→%s %.1f km",
        trip.id,
        current_user.id,
        trip.source,
        trip.destination,
        trip.distance,
    )

    # Reload with relationships for response serialisation.
    return (
        db.query(models.Trip)
        .options(
            joinedload(models.Trip.vehicle),
            joinedload(models.Trip.charging_history),
        )
        .filter(models.Trip.id == trip.id)
        .first()
    )


@router.get(
    "/trip-history",
    response_model=list[TripResponse],
    summary="Get current user's trip history",
)
def trip_history(
    skip: int = Query(0, ge=0, description="Pagination offset"),
    limit: int = Query(20, ge=1, le=100, description="Max results to return"),
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
) -> list[models.Trip]:
    """
    Retrieve all trips logged by the authenticated user, newest first.

    Each trip includes vehicle details and any associated charging sessions.
    """
    trips = (
        db.query(models.Trip)
        .options(
            joinedload(models.Trip.vehicle),
            joinedload(models.Trip.charging_history),
        )
        .filter(models.Trip.user_id == current_user.id)
        .order_by(models.Trip.created_at.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )
    return trips


@router.get(
    "/trip/{trip_id}",
    response_model=TripResponse,
    summary="Get a specific trip by ID",
    responses={
        403: {"description": "Not your trip"},
        404: {"description": "Trip not found"},
    },
)
def get_trip(
    trip_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
) -> models.Trip:
    """Retrieve details for a single trip. Users can only view their own trips."""
    trip = (
        db.query(models.Trip)
        .options(
            joinedload(models.Trip.vehicle),
            joinedload(models.Trip.charging_history),
        )
        .filter(models.Trip.id == trip_id)
        .first()
    )

    if not trip:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Trip with id={trip_id} not found.",
        )

    if trip.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You do not have permission to view this trip.",
        )

    return trip
