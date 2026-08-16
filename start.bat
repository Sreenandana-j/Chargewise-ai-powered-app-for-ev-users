@echo off
echo ========================================================
echo        Starting EV Assistant (Backend and Frontend)
echo ========================================================
echo.

echo [1/2] Starting the Python FastAPI Backend...
cd backend
:: Set up python env, install dependencies, and run server
start cmd /k "python -m venv .venv && .\.venv\Scripts\activate.bat && pip install -r requirements.txt && uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload"
cd ..

timeout /t 8 /nobreak > nul

echo.
echo [2/2] Starting the Flutter Frontend...
cd frontend
:: Clear locked files just in case
rmdir /s /q build 2>nul
start cmd /k "flutter run -d edge"
cd ..
