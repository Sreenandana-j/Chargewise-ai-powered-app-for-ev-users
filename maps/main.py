import requests
import folium
from config import ORS_API_KEY, OCM_API_KEY

# -----------------------------
# USER INPUT
# -----------------------------

start = input("Enter Starting Point: ")
destination = input("Enter Destination: ")
battery_range = float(input("Enter EV Battery Range (km): "))


# -----------------------------
# GET COORDINATES
# -----------------------------

def get_coordinates(place):

    url = "https://api.openrouteservice.org/geocode/search"

    params = {
        "api_key": ORS_API_KEY,
        "text": place
    }

    print(f"\nFinding coordinates for {place}...")

    try:

        response = requests.get(
            url,
            params=params,
            timeout=30
        )

        response.raise_for_status()

        data = response.json()

        if "features" not in data or len(data["features"]) == 0:
            return None

        return data["features"][0]["geometry"]["coordinates"]

    except requests.exceptions.RequestException as e:

        print("Error:", e)
        return None


# -----------------------------
# GET ROUTE DISTANCE
# -----------------------------

def get_distance(start_coords, destination_coords):

    url = "https://api.openrouteservice.org/v2/directions/driving-car/geojson"

    headers = {
        "Authorization": ORS_API_KEY,
        "Content-Type": "application/json"
    }

    body = {
        "coordinates": [
            start_coords,
            destination_coords
        ]
    }

    print("\nCalculating route...")

    try:

        response = requests.post(
            url,
            json=body,
            headers=headers,
            timeout=30
        )

        response.raise_for_status()

        data = response.json()

        if "features" not in data:
            return None, None, None

        summary = data["features"][0]["properties"]["summary"]

        distance = summary["distance"]
        duration = summary["duration"]

        route = data["features"][0]["geometry"]["coordinates"]

        return distance, duration, route

    except requests.exceptions.RequestException as e:

        print("Error:", e)
        return None, None, None


# -----------------------------
# FIND CHARGING STATIONS
# -----------------------------

def find_charging_stations(latitude, longitude):

    url = "https://api.openchargemap.io/v3/poi/"

    params = {
        "key": OCM_API_KEY,
        "latitude": latitude,
        "longitude": longitude,
        "distance": 50,
        "distanceunit": "KM",
        "maxresults": 5
    }

    print("\nSearching charging stations...")

    try:

        response = requests.get(
            url,
            params=params,
            timeout=30
        )

        response.raise_for_status()

        return response.json()

    except requests.exceptions.RequestException as e:

        print("Error:", e)
        return []


# -----------------------------
# GET START & DESTINATION
# -----------------------------

start_coordinates = get_coordinates(start)
destination_coordinates = get_coordinates(destination)

if start_coordinates is None:
    print("\nStarting location not found.")
    exit()

if destination_coordinates is None:
    print("\nDestination not found.")
    exit()


# -----------------------------
# ROUTE DETAILS
# -----------------------------

distance, duration, route = get_distance(
    start_coordinates,
    destination_coordinates
)

if distance is None:
    print("\nUnable to calculate route.")
    exit()

trip_distance = distance / 1000

print("\n========== EV ROUTE REPORT ==========")
print("From :", start)
print("To   :", destination)
print("Distance :", round(trip_distance, 2), "km")
print("Travel Time :", round(duration / 60, 2), "minutes")

stations = []
# -----------------------------
# BATTERY CHECK
# -----------------------------

if battery_range >= trip_distance:

    print("\nBattery Status : Sufficient")
    print("No charging required.")

else:

    print("\nBattery Status : Charging Required")

    stations = find_charging_stations(
        destination_coordinates[1],
        destination_coordinates[0]
    )

    if len(stations) == 0:

        print("No charging stations found near destination.")

    else:

        stations = sorted(
            stations,
            key=lambda x: x["AddressInfo"].get("Distance", 999)
        )

        print("\nRecommended Charging Stations\n")

        for station in stations[:3]:

            address = station["AddressInfo"]

            print("Station :", address.get("Title"))

            print("Distance :",
                  round(address.get("Distance", 0), 2),
                  "KM")

            connections = station.get("Connections")

            if connections:

                charger = connections[0].get("ConnectionType")

                if charger:
                    print("Charger :", charger.get("Title"))

            print("-----------------------------")


# -----------------------------
# SEARCH CHARGING STATIONS
# AT ANY LOCATION
# -----------------------------

choice = input(
    "\nDo you want to search charging stations at another location? (yes/no): "
).lower()

if choice == "yes":

    current_location = input("Enter Location : ")

    current_coordinates = get_coordinates(current_location)

    if current_coordinates is None:

        print("Location not found.")

    else:

        current_map = folium.Map(
            location=[
                current_coordinates[1],
                current_coordinates[0]
            ],
            zoom_start=13
        )

        folium.Marker(
            [
                current_coordinates[1],
                current_coordinates[0]
            ],
            popup=current_location,
            icon=folium.Icon(color="red")
        ).add_to(current_map)

        nearby = find_charging_stations(
            current_coordinates[1],
            current_coordinates[0]
        )

        if len(nearby) == 0:

            print("No charging stations found.")

        else:

            nearby = sorted(
                nearby,
                key=lambda x: x["AddressInfo"].get("Distance", 999)
            )

            print("\nNearby Charging Stations\n")

            for station in nearby[:5]:

                address = station["AddressInfo"]

                latitude = address.get("Latitude")
                longitude = address.get("Longitude")

                if latitude and longitude:

                    folium.Marker(
                        [latitude, longitude],
                        popup=address.get("Title"),
                        icon=folium.Icon(color="green")
                    ).add_to(current_map)

                print("Station :", address.get("Title"))
                print("Distance :", address.get("Distance"), "KM")

                connections = station.get("Connections")

                if connections:

                    charger = connections[0].get("ConnectionType")

                    if charger:
                        print("Charger :", charger.get("Title"))

                print("-----------------------------")

            current_map.save("Charging_station_map.html")

            print("\nCharging_station_map.html created successfully.")
# -----------------------------
# CREATE EV ROUTE MAP
# -----------------------------

ev_map = folium.Map(
    location=[
        destination_coordinates[1],
        destination_coordinates[0]
    ],
    zoom_start=10
)

# -----------------------------
# START MARKER
# -----------------------------

folium.Marker(
    [
        start_coordinates[1],
        start_coordinates[0]
    ],
    popup="Starting Point",
    icon=folium.Icon(color="blue")
).add_to(ev_map)

# -----------------------------
# DESTINATION MARKER
# -----------------------------

folium.Marker(
    [
        destination_coordinates[1],
        destination_coordinates[0]
    ],
    popup="Destination",
    icon=folium.Icon(color="red")
).add_to(ev_map)

# -----------------------------
# ADD CHARGING STATIONS
# -----------------------------

if len(stations) > 0:

    for station in stations[:3]:

        address = station["AddressInfo"]

        latitude = address.get("Latitude")
        longitude = address.get("Longitude")
        name = address.get("Title", "Charging Station")

        if latitude is not None and longitude is not None:

            folium.Marker(
                [latitude, longitude],
                popup=name,
                icon=folium.Icon(color="green", icon="flash")
            ).add_to(ev_map)

# -----------------------------
# DRAW ROUTE
# -----------------------------

route_points = []

for point in route:
    route_points.append([point[1], point[0]])

folium.PolyLine(
    route_points,
    color="blue",
    weight=5,
    opacity=0.8
).add_to(ev_map)

# -----------------------------
# FIT MAP TO ROUTE
# -----------------------------

ev_map.fit_bounds(route_points)

# -----------------------------
# SAVE MAP
# -----------------------------

ev_map.save("EV_route_map.html")

print("\nEV_route_map.html created successfully!")
print("\n========== END OF REPORT ==========")