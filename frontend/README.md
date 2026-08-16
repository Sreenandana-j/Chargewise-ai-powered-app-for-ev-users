# EV Assistant Application

A full-stack application designed to help Electric Vehicle (EV) owners plan their routes, find charging stations, and accurately predict battery consumption based on real-world factors.

## Project Structure

This repository contains both the frontend (Flutter) and backend (FastAPI) codebases, along with early prototype scripts.

- `lib/`, `android/`, `ios/`, etc.: The **Flutter Frontend** application.
- `backend/`: The **FastAPI Backend**, handling routing, database, battery prediction, and charging station data.
- `prototypes/`: Early standalone Python scripts (`Map` and `logic`) that served as proof-of-concepts before being integrated into the backend.

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (latest stable version)
- Python 3.10+ (for the backend)
- API Keys: The backend requires keys for OpenRouteService and OpenChargeMap (see backend config).

## Getting Started

### 1. Running the Backend (FastAPI)

Navigate to the `backend/` directory, set up your virtual environment, and run the server.

```bash
cd backend
python -m venv .venv

# On Windows:
.venv\Scripts\activate
# On macOS/Linux:
source .venv/bin/activate

# Install dependencies (assuming you have a requirements.txt or just install standard ones)
pip install fastapi uvicorn sqlalchemy requests pydantic

# Run the backend server
uvicorn app.main:app --reload
```
The backend will be available at `http://localhost:8000`. API documentation is automatically available at `http://localhost:8000/docs`.

### 2. Running the Frontend (Flutter)

The Flutter frontend connects to the backend API automatically.

```bash
# From the root of the repository
flutter pub get

# Run the app on an attached device, emulator, or Chrome
flutter run
```

*Note: The frontend is configured to point to `http://10.0.2.2:8000` when running on Android emulators and `http://127.0.0.1:8000` for Web/Desktop. See `lib/data/services/api_client.dart`.*

## Collaboration

For collaborators, please clone this repository and follow the setup instructions above. Ensure you have the backend running locally before attempting to log in or plan a route from the Flutter app.
