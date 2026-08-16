"""
Vehicles router – CRUD for EV vehicle catalogue.

Endpoints:
  GET    /vehicles          – list all vehicles (public)
  GET    /vehicles/{id}     – get one vehicle
  POST   /vehicles          – add a new vehicle (authenticated)
  PUT    /vehicles/{id}     – update a vehicle (authenticated)
  DELETE /vehicles/{id}     – remove a vehicle (authenticated)
"""
import logging
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app import models
from app.database import get_db
from app.schemas import MessageResponse, VehicleCreate, VehicleResponse, VehicleUpdate
from app.utils import get_current_user

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/vehicles", tags=["Vehicles"])


@router.get(
    "",
    response_model=list[VehicleResponse],
    summary="List all EV vehicles",
)
def list_vehicles(
    skip: int = Query(0, ge=0, description="Pagination offset"),
    limit: int = Query(50, ge=1, le=200, description="Max results to return"),
    search: Optional[str] = Query(None, description="Filter by vehicle name"),
    db: Session = Depends(get_db),
) -> list[models.Vehicle]:
    """
    Retrieve the complete vehicle catalogue.

    This endpoint is **public** – no authentication required.
    Supports optional name search and pagination.
    """
    query = db.query(models.Vehicle)
    if search:
        query = query.filter(models.Vehicle.vehicle_name.ilike(f"%{search}%"))
    return query.order_by(models.Vehicle.vehicle_name).offset(skip).limit(limit).all()


@router.get(
    "/{vehicle_id}",
    response_model=VehicleResponse,
    summary="Get a single vehicle by ID",
    responses={404: {"description": "Vehicle not found"}},
)
def get_vehicle(vehicle_id: int, db: Session = Depends(get_db)) -> models.Vehicle:
    """Retrieve specs for a specific EV vehicle."""
    vehicle = db.query(models.Vehicle).filter(models.Vehicle.id == vehicle_id).first()
    if not vehicle:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Vehicle with id={vehicle_id} not found.",
        )
    return vehicle


@router.post(
    "",
    response_model=VehicleResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Add a new vehicle",
    responses={
        409: {"description": "Vehicle name already exists"},
    },
)
def create_vehicle(
    payload: VehicleCreate,
    db: Session = Depends(get_db),
    _: models.User = Depends(get_current_user),
) -> models.Vehicle:
    """
    Add a new EV model to the catalogue.
    Requires a valid Bearer token.
    """
    existing = (
        db.query(models.Vehicle)
        .filter(models.Vehicle.vehicle_name == payload.vehicle_name)
        .first()
    )
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Vehicle '{payload.vehicle_name}' already exists.",
        )

    vehicle = models.Vehicle(**payload.model_dump())
    db.add(vehicle)
    db.commit()
    db.refresh(vehicle)

    logger.info("New vehicle created: id=%d name=%s", vehicle.id, vehicle.vehicle_name)
    return vehicle


@router.put(
    "/{vehicle_id}",
    response_model=VehicleResponse,
    summary="Update vehicle details",
    responses={404: {"description": "Vehicle not found"}},
)
def update_vehicle(
    vehicle_id: int,
    payload: VehicleUpdate,
    db: Session = Depends(get_db),
    _: models.User = Depends(get_current_user),
) -> models.Vehicle:
    """
    Partially update an EV vehicle record.
    Only the provided fields will be updated; omitted fields remain unchanged.
    """
    vehicle = db.query(models.Vehicle).filter(models.Vehicle.id == vehicle_id).first()
    if not vehicle:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Vehicle with id={vehicle_id} not found.",
        )

    update_data = payload.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(vehicle, field, value)

    db.commit()
    db.refresh(vehicle)

    logger.info("Vehicle updated: id=%d", vehicle_id)
    return vehicle


@router.delete(
    "/{vehicle_id}",
    response_model=MessageResponse,
    summary="Delete a vehicle",
    responses={404: {"description": "Vehicle not found"}},
)
def delete_vehicle(
    vehicle_id: int,
    db: Session = Depends(get_db),
    _: models.User = Depends(get_current_user),
) -> dict:
    """
    Remove an EV vehicle from the catalogue.
    Associated trip records will have their vehicle reference set to NULL.
    """
    vehicle = db.query(models.Vehicle).filter(models.Vehicle.id == vehicle_id).first()
    if not vehicle:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Vehicle with id={vehicle_id} not found.",
        )

    vehicle_name = vehicle.vehicle_name
    db.delete(vehicle)
    db.commit()

    logger.info("Vehicle deleted: id=%d name=%s", vehicle_id, vehicle_name)
    return {"message": f"Vehicle '{vehicle_name}' deleted successfully.", "success": True}
