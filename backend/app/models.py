"""
SQLAlchemy ORM models for the EV Assistant database.

Tables:
  - users            – registered application users
  - vehicles         – EV vehicle catalogue
  - trips            – user trip records
  - charging_history – charging events linked to trips
"""
from datetime import datetime

from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
    func,
)
from sqlalchemy.orm import relationship

from app.database import Base


class User(Base):
    """Registered application user."""

    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    name = Column(String(100), nullable=False)
    email = Column(String(255), unique=True, index=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    # ── Relationships ──────────────────────────────────────────────────────────
    trips = relationship("Trip", back_populates="user", cascade="all, delete-orphan")

    def __repr__(self) -> str:
        return f"<User id={self.id} email={self.email!r}>"


class Vehicle(Base):
    """
    EV vehicle catalogue entry.
    Stores manufacturer specs used for battery prediction calculations.
    """

    __tablename__ = "vehicles"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    vehicle_name = Column(String(150), unique=True, nullable=False, index=True)
    battery_capacity = Column(Float, nullable=False, comment="Battery capacity in kWh")
    efficiency = Column(
        Float, nullable=False, comment="Energy consumption in kWh per km"
    )
    connector_type = Column(String(50), nullable=False)
    charging_speed = Column(Float, nullable=False, comment="Max charging speed in kW")
    range_km = Column(Float, nullable=True, comment="ARAI/WLTP certified range in km")
    manufacturer = Column(String(100), nullable=True)
    year = Column(Integer, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    # ── Relationships ──────────────────────────────────────────────────────────
    trips = relationship("Trip", back_populates="vehicle")

    def __repr__(self) -> str:
        return f"<Vehicle id={self.id} name={self.vehicle_name!r}>"


class Trip(Base):
    """User trip record with pre/post battery state."""

    __tablename__ = "trips"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    vehicle_id = Column(
        Integer, ForeignKey("vehicles.id", ondelete="SET NULL"), nullable=True, index=True
    )

    # ── Route ─────────────────────────────────────────────────────────────────
    source = Column(String(255), nullable=False)
    destination = Column(String(255), nullable=False)
    distance = Column(Float, nullable=False, comment="Distance in km")

    # ── Battery snapshot ──────────────────────────────────────────────────────
    battery_before = Column(Float, nullable=False, comment="Battery % before trip")
    battery_after = Column(Float, nullable=True, comment="Battery % after trip")
    energy_used = Column(Float, nullable=True, comment="Energy consumed in kWh")

    # ── Environmental / Driving factors (Level 2 & 3 Predictions) ─────────────
    elevation_gain_m = Column(Float, nullable=True, default=0.0, comment="Net elevation gain in meters")
    avg_speed_kmh = Column(Float, nullable=True, default=60.0, comment="Average speed of the trip in km/h")
    temperature_c = Column(Float, nullable=True, default=25.0, comment="Average ambient temperature in Celsius")
    traffic_level = Column(String(50), nullable=True, default="low", comment="Traffic level (low, medium, heavy)")
    ac_on = Column(Boolean, nullable=True, default=False, comment="Whether climate control was active")
    payload_weight_kg = Column(Float, nullable=True, default=0.0, comment="Additional weight from cargo/passengers in kg")
    road_type = Column(String(50), nullable=True, default="mixed", comment="Road type (city, highway, mixed)")
    battery_health = Column(Float, nullable=True, default=100.0, comment="State of health of the battery (0-100%)")

    # ── Meta ──────────────────────────────────────────────────────────────────
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    # ── Relationships ──────────────────────────────────────────────────────────
    user = relationship("User", back_populates="trips")
    vehicle = relationship("Vehicle", back_populates="trips")
    charging_history = relationship(
        "ChargingHistory", back_populates="trip", cascade="all, delete-orphan"
    )

    def __repr__(self) -> str:
        return f"<Trip id={self.id} user={self.user_id} {self.source!r}→{self.destination!r}>"


class ChargingHistory(Base):
    """Charging event associated with a trip or standalone session."""

    __tablename__ = "charging_history"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    trip_id = Column(
        Integer,
        ForeignKey("trips.id", ondelete="CASCADE"),
        nullable=True,
        index=True,
    )

    # ── Station ───────────────────────────────────────────────────────────────
    station_name = Column(String(200), nullable=False)
    station_location = Column(String(255), nullable=True)

    # ── Session details ───────────────────────────────────────────────────────
    charging_power = Column(Float, nullable=False, comment="Charging power in kW")
    charging_time = Column(Float, nullable=False, comment="Duration in minutes")
    energy_added = Column(Float, nullable=True, comment="Energy added in kWh")
    charging_cost = Column(Float, nullable=True, comment="Cost in INR")

    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    # ── Relationships ──────────────────────────────────────────────────────────
    trip = relationship("Trip", back_populates="charging_history")

    def __repr__(self) -> str:
        return f"<ChargingHistory id={self.id} station={self.station_name!r}>"
