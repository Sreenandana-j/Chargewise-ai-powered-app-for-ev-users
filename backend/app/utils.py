"""
Shared utility functions used across multiple routers.
Includes the authenticated-user dependency and battery prediction logic.
"""
import logging
from datetime import datetime
from typing import Optional

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app import models
from app.auth import decode_access_token
from app.database import get_db

logger = logging.getLogger(__name__)

# ─── Bearer token extractor ───────────────────────────────────────────────────
security = HTTPBearer()


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db),
) -> models.User:
    """
    FastAPI dependency that validates the Bearer JWT and returns the active user.

    Raises:
        HTTP 401 – if the token is missing, malformed, or expired.
        HTTP 403 – if the account is inactive.
    """
    token = credentials.credentials
    token_data = decode_access_token(token)

    if token_data is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired authentication token.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    user: Optional[models.User] = (
        db.query(models.User).filter(models.User.id == token_data.user_id).first()
    )

    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User associated with this token no longer exists.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This account has been deactivated.",
        )

    return user


# ─── Battery Prediction Engine ────────────────────────────────────────────────

def predict_battery(
    distance_km: float,
    battery_percentage: float,
    vehicle: models.Vehicle,
    elevation_gain_m: float = 0.0,
    avg_speed_kmh: float = 60.0,
    temperature_c: float = 25.0,
    traffic_level: str = "low",
    ac_on: bool = False,
    payload_weight_kg: float = 0.0,
    road_type: str = "mixed",
    battery_health: float = 100.0,
    use_ai: bool = True,
) -> dict:
    """
    EV battery usage prediction engine.
    Supports:
      - Level 1: Simple distance-based calculation.
      - Level 2: Physics-based empirical adjustments (elevation, weight, speed, traffic, temperature, AC).
      - Level 3: AI regression model prediction (scikit-learn) with empirical fallback.
    """
    # 1. Attempt Level 3 AI Prediction if requested and model is available
    if use_ai:
        try:
            from app.ai_model import get_ai_prediction
            ai_result = get_ai_prediction(
                distance_km=distance_km,
                battery_percentage=battery_percentage,
                vehicle=vehicle,
                elevation_gain_m=elevation_gain_m,
                avg_speed_kmh=avg_speed_kmh,
                temperature_c=temperature_c,
                traffic_level=traffic_level,
                ac_on=ac_on,
                payload_weight_kg=payload_weight_kg,
                road_type=road_type,
                battery_health=battery_health,
            )
            if ai_result is not None:
                logger.info("Battery prediction using Level 3 AI model.")
                return ai_result
        except Exception as exc:
            logger.warning("AI model prediction failed, falling back to Level 2 physics: %s", exc)

    # 2. Level 2 Physics-based Empirical Model
    effective_capacity = vehicle.battery_capacity * (battery_health / 100.0)
    base_energy = distance_km * vehicle.efficiency

    # Payload weight penalty (curb weight assumed as 1600kg)
    curb_weight = 1600.0
    weight_factor = (curb_weight + payload_weight_kg) / curb_weight

    # Speed factor (optimised at 60 km/h; drag increases quadratically at high speeds)
    speed_factor = 1.0
    if avg_speed_kmh > 90:
        speed_factor = 1.0 + 0.004 * (avg_speed_kmh - 90) ** 1.8
    elif avg_speed_kmh < 35:
        speed_factor = 1.15  # Stop and go inefficiency

    # Traffic adjustment factor
    traffic_factor = 1.0
    if traffic_level.lower() == "medium":
        traffic_factor = 1.1
    elif traffic_level.lower() == "heavy":
        traffic_factor = 1.3

    # Temperature adjustment factor (battery chemistry efficiency)
    temp_factor = 1.0
    if temperature_c < 10.0:
        temp_factor = 1.15  # 15% drop in range for cold weather
    elif temperature_c > 35.0:
        temp_factor = 1.05  # 5% drop in range for extreme heat

    # AC / Climate control auxiliary energy
    # AC consumes ~1.5 kW constant power
    trip_duration_hours = distance_km / max(avg_speed_kmh, 1.0)
    ac_energy_kwh = (1.5 * trip_duration_hours) if ac_on else 0.0

    # Potential energy adjustment due to net elevation change (m * g * h)
    # Mass (kg) * gravity (9.81 m/s^2) * height (m)
    total_mass_kg = curb_weight + payload_weight_kg
    work_gravity_joules = total_mass_kg * 9.81 * elevation_gain_m
    work_gravity_kwh = work_gravity_joules / (3600.0 * 1000.0)

    if elevation_gain_m > 0:
        # Going uphill requires power (assume 85% motor efficiency)
        elevation_energy_kwh = work_gravity_kwh / 0.85
    else:
        # Going downhill recovers energy via regenerative braking (assume 50% recovery efficiency)
        elevation_energy_kwh = work_gravity_kwh * 0.5 * 0.85

    # Compute total estimated energy consumed
    energy_used_kwh = (base_energy * weight_factor * speed_factor * traffic_factor * temp_factor) + elevation_energy_kwh + ac_energy_kwh
    energy_used_kwh = max(energy_used_kwh, 0.0)

    # Battery percentage consumed
    battery_percentage_used = (energy_used_kwh / effective_capacity) * 100.0
    battery_percentage_used = round(min(battery_percentage_used, 100.0), 2)

    battery_after = max(battery_percentage - battery_percentage_used, 0.0)
    battery_after = round(battery_after, 2)

    # Estimated remaining range (km) after the trip
    full_range_km = effective_capacity / vehicle.efficiency
    estimated_range_km = round((battery_after / 100.0) * full_range_km, 2)

    is_feasible = battery_after >= 15.0  # 15% safety buffer

    # Time-based tariff and charging time logic (Person 3 features)
    current_hour = datetime.now().hour
    is_peak_hour = 16 <= current_hour < 22
    base_tariff = 24.0 if is_peak_hour else 17.0
    
    # Calculate charger limits and charging times
    # Target charge level to make trip safe: battery_pct_used + 15% buffer
    target_battery = min(battery_percentage_used + 15.0, 100.0)
    energy_needed_kwh = effective_capacity * ((target_battery - battery_percentage) / 100.0)
    energy_needed_kwh = max(energy_needed_kwh, 0.0)

    # Assume a standard 50 kW DC fast charger for en-route charging suggestions
    charging_power_kw = min(50.0, vehicle.charging_speed)
    charge_time_hours = energy_needed_kwh / charging_power_kw if charging_power_kw > 0 else 0.0
    charge_hours = int(charge_time_hours)
    charge_minutes = int((charge_time_hours - charge_hours) * 60)

    # Dynamic pricing including 10% taxes/fees
    total_cost = round(energy_needed_kwh * base_tariff * 1.1, 2)

    if battery_after >= 15.0:
        recommendation = (
            f"Trip is feasible. You will arrive with {battery_after:.1f}% battery (above safety limit). "
            f"No charging stops required."
        )
    else:
        recommendation = (
            f"Insufficient battery for a safe trip. You will arrive with {battery_after:.1f}% battery. "
            f"We recommend charging your battery to {target_battery:.1f}% before or during the trip. "
            f"Estimated charge time on a 50kW fast charger: {charge_hours}h {charge_minutes}m. "
            f"Estimated cost: {total_cost:.1f} INR."
        )

    return {
        "vehicle_name": vehicle.vehicle_name,
        "distance_km": distance_km,
        "energy_used_kwh": round(energy_used_kwh, 4),
        "battery_percentage_used": battery_percentage_used,
        "battery_before": battery_percentage,
        "battery_after": battery_after,
        "estimated_range_km": estimated_range_km,
        "is_trip_feasible": is_feasible,
        "recommendation": recommendation,
        "charging_time_hours": charge_hours,
        "charging_time_minutes": charge_minutes,
        "charging_cost_inr": total_cost,
    }
