# HillSafe AI

HillSafe AI is a Flutter and Django based early warning system for landslide and weather-related hazard risk. The mobile app gets the user's location, the backend enriches it with live weather and terrain data, and the ML pipeline returns a risk level with safety guidance.

Production API:

```text
https://hillsafe-ai.onrender.com/api
```

## Features

- Community mobile app with live GPS-based risk checking
- Authority dashboard for monitored regions, reports, SOS, and alerts
- Backend ML prediction pipeline using weather, terrain, and region data
- OpenWeather integration for live weather
- OpenTopoData integration for elevation and slope
- SoilGrids integration for soil texture
- Neon PostgreSQL database
- Render deployment
- Firebase Cloud Messaging for push alerts
- Gemini-powered safety assistant

## Tech Stack

- Frontend: Flutter, Dart
- Backend: Django, Django REST Framework
- Database: PostgreSQL on Neon
- ML: scikit-learn, TensorFlow/Keras, NumPy, pandas
- Deployment: Render, Gunicorn
- External APIs: OpenWeather, OpenTopoData, SoilGrids, Firebase, Gemini

## Repository Structure

```text
HillSafe-Ai/
  Backend/          Django API, ML pipeline, database models
  Frontend App/     Flutter Android app
  Datasets/         Training/source datasets
  Weights/          Backup model artifacts
  Document.txt      Full project documentation
  README.md         Basic GitHub overview
```

## Main Flow

```text
Flutter app gets user GPS
  -> POST /api/predict/location-risk/
  -> backend checks monitored hazard zone distance
  -> backend fetches weather and terrain data
  -> ML model predicts risk
  -> app shows risk level and safety message
```

If the user is outside the monitored hazard radius, the backend returns `NO RISK` directly. If the user is inside or near a monitored hazard zone, the ML prediction pipeline runs.

## Backend Setup

```powershell
cd Backend
python -m venv venv
.\venv\Scripts\activate
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
```

Local backend:

```text
http://127.0.0.1:8000
```

## Flutter Setup

```powershell
cd "Frontend App"
flutter pub get
flutter run
```

Build release APK:

```powershell
cd "Frontend App"
flutter build apk --release
```

APK output:

```text
Frontend App/build/app/outputs/flutter-apk/app-release.apk
```

## Important Endpoints

```text
GET  /api/regions/
POST /api/predict/location-risk/
GET  /api/predict/status/
POST /api/alerts/create/
GET  /api/alerts/
POST /api/reports/mark-safe/
POST /api/reports/sos/
POST /api/accounts/save-device-token/
POST /api/chatbot/
```

## Deployment

Render service settings:

```text
Root Directory: Backend
Build Command: pip install -r requirements.txt && python manage.py collectstatic --noinput && python manage.py migrate && python create_superuser.py && python seed_regions.py
Start Command: gunicorn hillsafe_core.wsgi:application
```

Required environment variables include:

```text
SECRET_KEY
DEBUG
ALLOWED_HOSTS
CORS_ALLOWED_ORIGINS
DB_HOST
DB_NAME
DB_USER
DB_PASSWORD
DB_PORT
OPENWEATHER_API_KEY
WEATHER_API_KEY
GEMINI_API_KEY
SKLEARN_MODEL_PATH
LSTM_MODEL_PATH
```

Do not commit `.env`, database credentials, API keys, or Firebase service account files.

## Documentation

For the full project explanation, evaluation notes, model pipeline, file map, endpoints, and feature details, read:

```text
Document.txt
```
