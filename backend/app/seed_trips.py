"""
seed_trips.py – generates mock user and simulated historical EV trips
to provide training data for the Level 3 AI machine learning model.
"""
import random
import logging
from datetime import datetime, timedelta
from app.database import get_db_context, create_tables
from app.models import User, Vehicle, Trip
from app.auth import hash_password

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Mock list of route names in Kerala for realistic source/destinations
KERALA_PLACES = [
    "Kochi", "Tiruvalla", "Kottayam", "Trivandrum", "Alappuzha", 
    "Chengannur", "Kollam", "Thrissur", "Palakkad", "Kozhikode"
]


def run_seeder():
    logger.info("Initializing database and seeding vehicle/trip data...")
    create_tables()

    with get_db_context() as db:
        # 1. Create a test user if not exists
        test_email = "test@example.com"
        user = db.query(User).filter(User.email == test_email).first()
        if not user:
            user = User(
                name="Test Driver",
                email=test_email,
                password_hash=hash_password("Password123")  # Complies with password requirements
            )
            db.add(user)
            db.flush()  # Populates user.id
            logger.info("Seeded test user: %s", test_email)
        else:
            logger.info("Test user already exists.")

        # 2. Verify vehicles exist (otherwise seed them)
        vehicles = db.query(Vehicle).all()
        if not vehicles:
            logger.info("No vehicles found. Starting main app to seed vehicles first...")
            from app.main import SEED_VEHICLES
            for v_data in SEED_VEHICLES:
                db.add(Vehicle(**v_data))
            db.flush()
            vehicles = db.query(Vehicle).all()
            logger.info("Seeded %d vehicles.", len(vehicles))

        # 3. Generate simulated trips if database is empty of trips
        trip_count = db.query(Trip).filter(Trip.user_id == user.id).count()
        if trip_count >= 150:
            logger.info("Database already contains %d trips. Skipping trip seeding.", trip_count)
            return

        logger.info("Seeding 150 simulated trips for AI training...")
        
        # Start date for historical trips (e.g. 6 months ago)
        start_date = datetime.now() - timedelta(days=180)

        for i in range(150):
            # Select random vehicle and endpoints
            vehicle = random.choice(vehicles)
            source = random.choice(KERALA_PLACES)
            destination = random.choice(KERALA_PLACES)
            while destination == source:
                destination = random.choice(KERALA_PLACES)

            # Generate random trip characteristics
            distance = round(random.uniform(15.0, 280.0), 2)
            battery_before = round(random.uniform(50.0, 100.0), 1)
            
            # Level 2 / 3 Environmental factors
            elevation_gain_m = round(random.uniform(-100.0, 800.0), 1)
            avg_speed_kmh = round(random.uniform(30.0, 110.0), 1)
            temperature_c = round(random.uniform(18.0, 42.0), 1)
            traffic_level = random.choice(["low", "medium", "heavy"])
            ac_on = random.choice([True, False]) if 22.0 <= temperature_c <= 28.0 else True
            payload_weight_kg = round(random.uniform(0.0, 220.0), 1)
            road_type = random.choice(["city", "highway", "mixed"])
            battery_health = round(random.uniform(88.0, 100.0), 1)

            # --- Physical simulation model with added random noise ---
            effective_capacity = vehicle.battery_capacity * (battery_health / 100.0)
            base_efficiency = vehicle.efficiency
            
            # Speed penalty (quadratic drag increase)
            speed_factor = 1.0
            if avg_speed_kmh > 90:
                speed_factor = 1.0 + 0.004 * (avg_speed_kmh - 90) ** 1.8
            elif avg_speed_kmh < 35:
                speed_factor = 1.15

            # Traffic penalty
            traffic_factor = 1.0
            if traffic_level == "medium":
                traffic_factor = 1.1
            elif traffic_level == "heavy":
                traffic_factor = 1.3

            # Temperature penalty
            temp_factor = 1.0
            if temperature_c > 35.0:
                temp_factor = 1.05
            elif temperature_c < 20.0:
                temp_factor = 1.02

            # Payload weight factor
            curb_weight = 1600.0
            weight_factor = (curb_weight + payload_weight_kg) / curb_weight

            # AC power draw
            trip_hours = distance / avg_speed_kmh
            ac_energy = (1.5 * trip_hours) if ac_on else 0.0

            # Potential energy change
            work_gravity = (curb_weight + payload_weight_kg) * 9.81 * elevation_gain_m
            gravity_energy = work_gravity / (3600.0 * 1000.0)
            if elevation_gain_m > 0:
                elevation_energy = gravity_energy / 0.85
            else:
                elevation_energy = gravity_energy * 0.5 * 0.85

            # Total physics-calculated energy usage
            simulated_energy = (base_efficiency * distance * speed_factor * traffic_factor * temp_factor * weight_factor) \
                               + elevation_energy + ac_energy
            
            # Add random noise (e.g. +/- 6% variance due to wind, driving habits, etc.)
            noise_factor = random.uniform(0.94, 1.06)
            energy_used = max(simulated_energy * noise_factor, 0.5)

            # Calculate ending battery percentage
            battery_after = max(battery_before - (energy_used / effective_capacity) * 100.0, 0.0)
            battery_after = round(battery_after, 2)
            energy_used = round(energy_used, 4)

            # Random trip timestamps distributed over past 6 months
            trip_time = start_date + timedelta(
                days=random.randint(0, 179),
                hours=random.randint(0, 23),
                minutes=random.randint(0, 59)
            )

            # Insert Trip Record
            trip = Trip(
                user_id=user.id,
                vehicle_id=vehicle.id,
                source=source,
                destination=destination,
                distance=distance,
                battery_before=battery_before,
                battery_after=battery_after,
                energy_used=energy_used,
                elevation_gain_m=elevation_gain_m,
                avg_speed_kmh=avg_speed_kmh,
                temperature_c=temperature_c,
                traffic_level=traffic_level,
                ac_on=ac_on,
                payload_weight_kg=payload_weight_kg,
                road_type=road_type,
                battery_health=battery_health,
                notes=f"Simulated trip #{i+1}",
                created_at=trip_time
            )
            db.add(trip)

        logger.info("Successfully seeded 150 historical trips for user test@example.com.")


if __name__ == "__main__":
    run_seeder()
