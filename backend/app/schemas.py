"""
Pydantic schemas for request validation and response serialization.

Each domain has three schema variants:
  - Base     – shared fields
  - Create   – input fields for create operations (excludes server-set fields)
  - Response – output shape returned to clients (includes computed/server fields)
"""
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, EmailStr, Field, field_validator


# ─────────────────────────────────────────────────────────────────────────────
# Auth Schemas
# ─────────────────────────────────────────────────────────────────────────────


class UserSignupRequest(BaseModel):
    name: str = Field(..., min_length=2, max_length=100, example="Jane Doe")
    email: EmailStr = Field(..., example="jane@example.com")
    password: str = Field(..., min_length=8, max_length=128, example="SecurePass@123")

    @field_validator("password")
    @classmethod
    def password_strength(cls, v: str) -> str:
        if not any(c.isupper() for c in v):
            raise ValueError("Password must contain at least one uppercase letter.")
        if not any(c.isdigit() for c in v):
            raise ValueError("Password must contain at least one digit.")
        return v


class UserLoginRequest(BaseModel):
    email: EmailStr = Field(..., example="jane@example.com")
    password: str = Field(..., example="SecurePass@123")


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int = Field(..., description="Token validity in seconds")

    class Config:
        json_schema_extra = {
            "example": {
                "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9…",
                "token_type": "bearer",
                "expires_in": 86400,
            }
        }


class TokenData(BaseModel):
    """Decoded JWT payload."""
    user_id: Optional[int] = None
    email: Optional[str] = None


# ─────────────────────────────────────────────────────────────────────────────
# User Schemas
# ─────────────────────────────────────────────────────────────────────────────


class UserBase(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    email: EmailStr


class UserResponse(UserBase):
    id: int
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True


class UserProfileResponse(UserResponse):
    trip_count: Optional[int] = 0


# ─────────────────────────────────────────────────────────────────────────────
# Vehicle Schemas
# ─────────────────────────────────────────────────────────────────────────────


class VehicleBase(BaseModel):
    vehicle_name: str = Field(..., min_length=2, max_length=150, example="Tata Nexon EV")
    battery_capacity: float = Field(..., gt=0, description="Battery capacity in kWh", example=40.5)
    efficiency: float = Field(
        ..., gt=0, description="Energy consumption in kWh/km", example=0.154
    )
    connector_type: str = Field(..., max_length=50, example="CCS2")
    charging_speed: float = Field(
        ..., gt=0, description="Max charging speed in kW", example=50.0
    )
    range_km: Optional[float] = Field(None, gt=0, description="ARAI/WLTP range in km", example=312)
    manufacturer: Optional[str] = Field(None, max_length=100, example="Tata Motors")
    year: Optional[int] = Field(None, ge=2010, le=2100, example=2024)


class VehicleCreate(VehicleBase):
    pass


class VehicleUpdate(BaseModel):
    """All fields optional for partial updates."""
    vehicle_name: Optional[str] = Field(None, min_length=2, max_length=150)
    battery_capacity: Optional[float] = Field(None, gt=0)
    efficiency: Optional[float] = Field(None, gt=0)
    connector_type: Optional[str] = Field(None, max_length=50)
    charging_speed: Optional[float] = Field(None, gt=0)
    range_km: Optional[float] = Field(None, gt=0)
    manufacturer: Optional[str] = Field(None, max_length=100)
    year: Optional[int] = Field(None, ge=2010, le=2100)


class VehicleResponse(VehicleBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True


# ─────────────────────────────────────────────────────────────────────────────
# Battery Prediction Schemas
# ─────────────────────────────────────────────────────────────────────────────


class BatteryPredictionRequest(BaseModel):
    distance: float = Field(..., gt=0, description="Trip distance in km", example=80.0)
    battery_percentage: float = Field(
        ..., ge=0, le=100, description="Current battery percentage", example=85.0
    )
    vehicle_id: int = Field(..., description="ID of the vehicle", example=1)
    
    # Optional parameters for Level 2 & 3 Predictions
    elevation_gain_m: Optional[float] = Field(0.0, description="Net elevation gain in meters", example=50.0)
    avg_speed_kmh: Optional[float] = Field(60.0, description="Average speed in km/h", example=55.0)
    temperature_c: Optional[float] = Field(25.0, description="Ambient temperature in Celsius", example=28.0)
    traffic_level: Optional[str] = Field("low", description="Traffic level: low, medium, heavy", example="low")
    ac_on: Optional[bool] = Field(False, description="Whether climate control is on", example=True)
    payload_weight_kg: Optional[float] = Field(0.0, description="Weight of passenger and cargo in kg", example=75.0)
    road_type: Optional[str] = Field("mixed", description="Road type: city, highway, mixed", example="mixed")
    battery_health: Optional[float] = Field(100.0, description="Battery state of health percentage", example=95.0)

    class Config:
        json_schema_extra = {
            "example": {
                "distance": 80.0,
                "battery_percentage": 85.0,
                "vehicle_id": 1,
                "elevation_gain_m": 50.0,
                "avg_speed_kmh": 55.0,
                "temperature_c": 28.0,
                "traffic_level": "low",
                "ac_on": True,
                "payload_weight_kg": 75.0,
                "road_type": "mixed",
                "battery_health": 95.0,
            }
        }


class BatteryPredictionResponse(BaseModel):
    vehicle_name: str
    distance_km: float
    energy_used_kwh: float = Field(..., description="Estimated energy consumed in kWh")
    battery_percentage_used: float = Field(..., description="Battery % consumed")
    battery_before: float = Field(..., description="Initial battery %")
    battery_after: float = Field(..., description="Estimated remaining battery %")
    estimated_range_km: float = Field(
        ..., description="Estimated remaining range after trip in km"
    )
    is_trip_feasible: bool = Field(
        ..., description="Whether the trip can be completed without charging"
    )
    recommendation: str = Field(..., description="Human-readable advice")
    charging_time_hours: Optional[int] = Field(None, description="Estimated charging time hours")
    charging_time_minutes: Optional[int] = Field(None, description="Estimated charging time minutes")
    charging_cost_inr: Optional[float] = Field(None, description="Estimated charging cost in INR")


# ─────────────────────────────────────────────────────────────────────────────
# Charging Station Schemas
# ─────────────────────────────────────────────────────────────────────────────


class ChargingStationResponse(BaseModel):
    id: int
    name: str
    location: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    connector_types: list[str]
    max_power_kw: float
    is_available: bool
    price_per_kwh: float
    operator: str


# ─────────────────────────────────────────────────────────────────────────────
# Charging History Schemas
# ─────────────────────────────────────────────────────────────────────────────


class ChargingHistoryBase(BaseModel):
    trip_id: Optional[int] = Field(None, description="Associated trip ID (optional)")
    station_name: str = Field(..., min_length=2, max_length=200, example="Tata Power EZ Charge")
    station_location: Optional[str] = Field(None, max_length=255)
    charging_power: float = Field(..., gt=0, description="Charging power in kW", example=50.0)
    charging_time: float = Field(
        ..., gt=0, description="Charging duration in minutes", example=45.0
    )
    energy_added: Optional[float] = Field(None, gt=0, description="Energy added in kWh")
    charging_cost: Optional[float] = Field(None, ge=0, description="Cost in INR", example=250.0)


class ChargingHistoryCreate(ChargingHistoryBase):
    pass


class ChargingHistoryResponse(ChargingHistoryBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True


# ─────────────────────────────────────────────────────────────────────────────
# Trip Schemas
# ─────────────────────────────────────────────────────────────────────────────


class TripBase(BaseModel):
    vehicle_id: Optional[int] = Field(None, description="Associated vehicle ID")
    source: str = Field(..., min_length=2, max_length=255, example="Chennai")
    destination: str = Field(..., min_length=2, max_length=255, example="Bangalore")
    distance: float = Field(..., gt=0, description="Distance in km", example=350.0)
    battery_before: float = Field(
        ..., ge=0, le=100, description="Battery % before trip", example=90.0
    )
    battery_after: Optional[float] = Field(
        None, ge=0, le=100, description="Battery % after trip"
    )
    energy_used: Optional[float] = Field(None, ge=0, description="Energy consumed in kWh")
    
    # Optional parameters for Level 2 & 3 Predictions
    elevation_gain_m: Optional[float] = Field(0.0, description="Net elevation gain in meters")
    avg_speed_kmh: Optional[float] = Field(60.0, description="Average speed of the trip in km/h")
    temperature_c: Optional[float] = Field(25.0, description="Average ambient temperature in Celsius")
    traffic_level: Optional[str] = Field("low", description="Traffic level (low, medium, heavy)")
    ac_on: Optional[bool] = Field(False, description="Whether climate control was active")
    payload_weight_kg: Optional[float] = Field(0.0, description="Additional weight from cargo/passengers in kg")
    road_type: Optional[str] = Field("mixed", description="Road type (city, highway, mixed)")
    battery_health: Optional[float] = Field(100.0, description="State of health of the battery (0-100%)")
    
    notes: Optional[str] = Field(None, max_length=500)


class TripCreate(TripBase):
    pass


class TripResponse(TripBase):
    id: int
    user_id: int
    created_at: datetime
    vehicle: Optional[VehicleResponse] = None
    charging_sessions: Optional[list[ChargingHistoryResponse]] = None

    class Config:
        from_attributes = True


# ─────────────────────────────────────────────────────────────────────────────
# Generic Response Wrappers
# ─────────────────────────────────────────────────────────────────────────────


class MessageResponse(BaseModel):
    """Generic success message envelope."""
    message: str
    success: bool = True


class ErrorResponse(BaseModel):
    """Structured error response returned on exceptions."""
    detail: str
    error_code: Optional[str] = None
    success: bool = False


# ─────────────────────────────────────────────────────────────────────────────
# Route Planning Schemas
# ─────────────────────────────────────────────────────────────────────────────


class RoutePlanRequest(BaseModel):
    origin: str = Field(..., min_length=2, example="Kochi")
    destination: str = Field(..., min_length=2, example="Tiruvalla")
    vehicle_id: int = Field(..., example=1)
    battery_percentage: float = Field(..., ge=0, le=100, example=80.0)
    
    # Optional parameters for Level 2 & 3 Predictions
    elevation_gain_m: Optional[float] = Field(0.0, description="Net elevation gain in meters")
    avg_speed_kmh: Optional[float] = Field(60.0, description="Average speed in km/h")
    temperature_c: Optional[float] = Field(25.0, description="Ambient temperature in Celsius")
    traffic_level: Optional[str] = Field("low", description="Traffic level (low, medium, heavy)")
    ac_on: Optional[bool] = Field(False, description="Whether climate control was active")
    payload_weight_kg: Optional[float] = Field(0.0, description="Additional weight in kg")
    road_type: Optional[str] = Field("mixed", description="Road type (city, highway, mixed)")
    battery_health: Optional[float] = Field(100.0, description="State of health of the battery")


class RoutePlanResponse(BaseModel):
    origin_coords: list[float] = Field(..., description="[longitude, latitude] of start")
    destination_coords: list[float] = Field(..., description="[longitude, latitude] of destination")
    distance_km: float
    duration_mins: float
    route_points: list[list[float]] = Field(..., description="List of [latitude, longitude] route coordinates")
    battery_prediction: BatteryPredictionResponse
    charging_stops_suggested: list[dict] = Field(default=[], description="Suggested charging stations along or near route")
