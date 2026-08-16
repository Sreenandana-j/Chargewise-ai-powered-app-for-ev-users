"""
Battery prediction router.

Endpoint:
  POST /battery-prediction – predict energy usage and remaining range for a planned trip.

Formula (prototype):
  Energy Used (kWh)      = distance × vehicle.efficiency
  Battery % Used         = (energy_used ÷ battery_capacity) × 100
  Remaining Battery %    = initial_battery % − battery % used
  Estimated Range (km)   = (remaining_battery % ÷ 100) × (battery_capacity ÷ efficiency)
"""
import logging

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app import models
from app.database import get_db
from app.schemas import BatteryPredictionRequest, BatteryPredictionResponse
from app.utils import get_current_user, predict_battery

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/battery-prediction", tags=["Battery Prediction"])


@router.post(
    "",
    response_model=BatteryPredictionResponse,
    summary="Predict battery usage for a planned trip",
)
def battery_prediction(
    payload: BatteryPredictionRequest,
    db: Session = Depends(get_db),
    _: models.User = Depends(get_current_user),
) -> dict:
    """
    Estimate energy consumption and remaining battery for a planned journey.

    ### Input
    - **distance**: Planned trip distance in km.
    - **battery_percentage**: Current state-of-charge (0–100 %).
    - **vehicle_id**: ID of the vehicle to use for efficiency calculations.

    ### Output
    - Energy used in kWh
    - Battery percentage consumed
    - Remaining battery percentage
    - Estimated remaining range in km
    - Trip feasibility flag and recommendation text

    > **Note**: This is a prototype formula. Future versions will incorporate
    > AI/ML models trained on real telemetry data for higher accuracy.
    """
    vehicle = db.query(models.Vehicle).filter(models.Vehicle.id == payload.vehicle_id).first()
    if not vehicle:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Vehicle with id={payload.vehicle_id} not found.",
        )

    result = predict_battery(
        distance_km=payload.distance,
        battery_percentage=payload.battery_percentage,
        vehicle=vehicle,
        elevation_gain_m=payload.elevation_gain_m,
        avg_speed_kmh=payload.avg_speed_kmh,
        temperature_c=payload.temperature_c,
        traffic_level=payload.traffic_level,
        ac_on=payload.ac_on,
        payload_weight_kg=payload.payload_weight_kg,
        road_type=payload.road_type,
        battery_health=payload.battery_health,
    )

    logger.info(
        "Battery prediction: vehicle=%s distance=%.1f km feasible=%s",
        vehicle.vehicle_name,
        payload.distance,
        result["is_trip_feasible"],
    )

    return result
