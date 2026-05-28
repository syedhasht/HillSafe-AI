# HillSafe AI

HillSafe AI is a Flutter + Django landslide-risk warning system for mountainous regions of Pakistan. The mobile app gets the user's GPS location, the backend enriches that location with live weather and terrain data, then a trained Random Forest model returns a risk score.

The project is currently deployed as:

- Backend: Render web service
- Database: Neon PostgreSQL
- Mobile app: Flutter Android app
- Production API: `https://hillsafe-ai.onrender.com/api`

## Project Layout

```text
HillSafe-Ai/
  Backend/                 Django REST API, ML inference, database models
  Frontend App/            Flutter mobile app
  Datasets/                Training/source datasets and notebooks
  Weights/                 Backup/source copies of trained model files
  README.md                Developer handoff and project guide
```

Important backend model files are deployed from:

```text
Backend/ml_engine/models/
  landslide_rf_model.pkl
  weather_scaler.pkl
  rainfall_lstm.h5
```

The backend code loads models from `Backend/ml_engine/models`, not from `Weights`. `Weights` is only a backup/source folder.

## Main Runtime Flow

### User Location Prediction

This is the main community app flow.

```text
Flutter gets phone GPS
  -> POST /api/predict/location-risk/
  -> backend fetches OpenWeather for that exact lat/lon
  -> backend checks TerrainSample DB for rounded lat/lon
  -> if missing, backend calls OpenTopoData and SoilGrids once
  -> backend stores terrain in DB
  -> backend converts raw values to model feature codes
  -> Random Forest predicts risk_score
  -> Flutter displays risk_score as percentage
```

Example request:

```powershell
$body = @{
  latitude = 34.909
  longitude = 73.649
} | ConvertTo-Json

$response = Invoke-RestMethod `
  -Uri "https://hillsafe-ai.onrender.com/api/predict/location-risk/" `
  -Method Post `
  -Body $body `
  -ContentType "application/json"

$response | ConvertTo-Json -Depth 10
```

Example response shape:

```json
{
  "risk_score": 0.3,
  "risk_level": "LOW",
  "is_safe": true,
  "model_status": "ready",
  "source": "ml_model",
  "nearest_region": {
    "name": "Kohistan",
    "distance_km": 40.27,
    "current_temperature": 10.97,
    "current_rainfall": 0.0
  },
  "weather": {
    "temperature": 10.97,
    "rainfall_mm": 0.0,
    "humidity": 63.0,
    "source": "openweather"
  },
  "terrain": {
    "source": "database",
    "data_quality": "partial_api",
    "elevation_m": 2440.0,
    "slope_degrees": 6.576,
    "soil_type": "loamy"
  },
  "input_features": {
    "precipitation_code": 1,
    "slope": 2,
    "soil": 3,
    "lithology": 2,
    "elevation": 4,
    "ndvi": 2,
    "ndwi": 2
  }
}
```

`risk_score` is a decimal probability:

```text
0.1 = 10%
0.3 = 30%
0.85 = 85%
```

### Region Cards and Maps

The app also has region-based screens such as monitored regions, community map, authority map, regional summary, and analytics. Those screens read `Region.current_risk_score` from:

```text
GET /api/regions/
```

To avoid old dummy `10%` values, `GET /api/regions/` refreshes stale region risk scores automatically through the same ML pipeline. It refreshes only stale rows and limits the number of refreshes per request to avoid overloading free external APIs.

Current behavior:

```text
App opens / fetches regions
  -> GET /api/regions/
  -> backend refreshes stale Region rows through ML model
  -> response contains updated current_risk_score values
```

The manual ingestion endpoint still exists, but the app should not depend on manually calling it repeatedly.

## Prediction Data Sources

### OpenWeather

Used for live weather:

- rainfall
- snow treated as precipitation
- temperature
- humidity

Environment variables supported:

```text
OPENWEATHER_API_KEY
WEATHER_API_KEY
```

Render already stores these as environment variables. Do not commit `.env`.

### OpenTopoData

Used for real terrain elevation.

Endpoint used:

```text
https://api.opentopodata.org/v1/srtm30m
```

The backend queries five points:

- center
- north
- south
- east
- west

It stores:

- `elevation_m`
- `slope_degrees`
- `elevation_code`
- `slope_code`

Slope is calculated from elevation differences around the user or region coordinate.

### SoilGrids

Used for soil texture.

Endpoint used:

```text
https://rest.isric.org/soilgrids/v2.0/properties/query
```

The backend requests:

- clay
- sand
- silt
- depths `0-5cm` and `5-15cm`

It stores:

- `soil_type`
- `soil_code`
- `clay_percent`
- `sand_percent`
- `silt_percent`

### Still Defaulted

These fields exist in the DB/model input, but are still defaulted until better geospatial datasets are added:

- `lithology_type`
- `lithology_code`
- `ndvi_code`
- `ndwi_code`

Macrostrat was considered but left out because Pakistan coverage/quality needs verification. Future developers can add a geology dataset/API later and persist it in `TerrainSample`.

## Database Models

### Region

File:

```text
Backend/regions/models.py
```

Represents monitored regions such as Murree, Swat, Kohistan, Hunza, Skardu, etc.

Key fields:

- `name`
- `district`
- `latitude`
- `longitude`
- `current_risk_score`
- `last_updated`

`current_risk_score` is used by region cards, map screens, analytics, and authority views.

### TerrainSample

File:

```text
Backend/regions/models.py
```

Stores terrain lookup results for rounded lat/lon so the backend does not call free APIs every time.

Key fields:

- `latitude_key`
- `longitude_key`
- `requested_latitude`
- `requested_longitude`
- `elevation_m`
- `slope_degrees`
- `elevation_code`
- `slope_code`
- `soil_type`
- `soil_code`
- `clay_percent`
- `sand_percent`
- `silt_percent`
- `lithology_type`
- `lithology_code`
- `ndvi_code`
- `ndwi_code`
- `data_quality`
- `fetch_errors`

First request near a location:

```text
terrain.source = api_saved_to_database
```

Repeated request for same rounded coordinate:

```text
terrain.source = database
```

Migration:

```text
Backend/regions/migrations/0003_terrainsample.py
```

## ML Model

Main file:

```text
Backend/ml_engine/predictor.py
```

The active deployed prediction model is:

```text
Backend/ml_engine/models/landslide_rf_model.pkl
```

The model was saved with scikit-learn `1.6.1`, so `Backend/requirements.txt` pins:

```text
scikit-learn==1.6.1
```

This prevents model unpickle version warnings and reduces deployment risk.

### Feature Shape

The Random Forest expects 12 feature codes:

```text
aspect
curvature
earthquake
elevation
flow
lithology
ndvi
ndwi
plan
precipitation
profile
slope
```

Current real/derived values:

- `precipitation` from OpenWeather rainfall/snow
- `elevation` from OpenTopoData
- `slope` from OpenTopoData-derived slope
- `soil` is accepted for API compatibility and saved, but the RF feature array does not include soil directly

Current defaults:

- `aspect`
- `curvature`
- `earthquake`
- `flow`
- `plan`
- `profile`
- `lithology`
- `ndvi`
- `ndwi`

### LSTM

File:

```text
Backend/ml_engine/models/rainfall_lstm.h5
```

The LSTM is lazy-loaded only if `predict_rainfall_trend()` is called. This is intentional because Render free instances have limited memory. The main landslide risk endpoint only needs the Random Forest.

Expected status endpoint output:

```text
rf_model_loaded: true
lstm_model_loaded: false
scaler_loaded: true
status: ready
```

`lstm_model_loaded: false` is acceptable as long as `status` is `ready`.

## Shared Backend Pipeline Files

### `Backend/ml_engine/views.py`

Contains:

- `PredictRiskView`
- `PredictLocationRiskView`
- `ModelStatusView`
- OpenWeather helper
- OpenTopoData helper
- SoilGrids helper
- terrain DB lookup helper

Primary endpoint:

```text
POST /api/predict/location-risk/
```

### `Backend/ml_engine/risk_pipeline.py`

Shared helper used by region refresh and manual ingestion.

Main function:

```python
predict_region_risk(region)
```

It runs:

```text
region lat/lon
  -> OpenWeather
  -> TerrainSample DB/OpenTopoData/SoilGrids
  -> feature codes
  -> Random Forest
```

### `Backend/api/views.py`

Important views:

- `RegionListView`: returns regions and refreshes stale region risks
- `SensorDataView`: aggregated region data
- `AnalyticsView`: simple analytics/trend response
- `SafetyStatusView`: safety status per region
- `MarkSafeView`: mark user safe/unsafe
- `CustomLoginView`: passwordless login

### `Backend/data_ingestion/views.py`

Manual endpoint:

```text
POST /api/ingest/trigger/
```

This now uses the ML pipeline too. It no longer hardcodes:

```text
0.1 for low rain
0.8 for high rain
```

## Backend Endpoints

Base URL:

```text
https://hillsafe-ai.onrender.com/api
```

Core endpoints:

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/` | API index |
| POST | `/login/` | Passwordless login |
| GET | `/regions/` | List monitored regions, refresh stale risks |
| GET | `/alerts/` | List alerts |
| GET | `/analytics/?period=7days` | Analytics data |
| GET | `/sensor-data/` | Aggregated sensor/risk values |
| GET | `/districts/` | District list |
| GET | `/safety-status/` | Safe-user counts |
| POST | `/mark-safe/` | Basic mark-safe endpoint |
| POST | `/predict/risk/` | Direct ML prediction with manual feature inputs |
| POST | `/predict/location-risk/` | Main GPS-based prediction endpoint |
| GET | `/predict/status/` | Model status |
| POST | `/ingest/trigger/` | Manual region refresh/alert generation |
| POST | `/reports/submit/` | Submit incident report |
| POST | `/reports/mark-safe/` | Mark current user safe in report flow |
| GET | `/reports/stats/<region_id>/` | Region safety/report stats |
| GET | `/reports/my-reports/` | Current user's reports |
| GET | `/reports/list/` | All reports for authority views |
| POST | `/accounts/save-device-token/` | Save Firebase device token |

Important root URL file:

```text
Backend/hillsafe_core/urls.py
```

App URL files:

```text
Backend/api/urls.py
Backend/ml_engine/urls.py
Backend/data_ingestion/urls.py
Backend/reports/urls.py
Backend/accounts/urls.py
```

## Flutter App Flow

Main API config:

```text
Frontend App/lib/services/api_service.dart
```

Production backend URL:

```dart
static const String baseUrl = 'https://hillsafe-ai.onrender.com/api';
```

Main live risk call:

```dart
predictLocationRisk(latitude: ..., longitude: ...)
```

Important Flutter files:

```text
Frontend App/lib/services/api_service.dart
Frontend App/lib/providers/safety_controller.dart
Frontend App/lib/widgets/weather_risk_widget.dart
Frontend App/lib/screens/community/community_dashboard.dart
Frontend App/lib/screens/community/risk_map_screen.dart
Frontend App/lib/screens/maps/authority_map_screen.dart
Frontend App/lib/screens/dashboard_authority/regional_summary_screen.dart
```

### Top Live Card

File:

```text
Frontend App/lib/widgets/weather_risk_widget.dart
```

Uses:

```text
POST /api/predict/location-risk/
```

This is the most accurate user-specific prediction.

### Background Safety Controller

File:

```text
Frontend App/lib/providers/safety_controller.dart
```

Runs app-level refresh logic and notifications. It also calls:

```text
POST /api/predict/location-risk/
```

### Monitored Region Cards

File:

```text
Frontend App/lib/screens/community/community_dashboard.dart
```

Uses:

```text
GET /api/regions/
```

The backend refreshes stale region scores before returning them.

### Map Screens

Files:

```text
Frontend App/lib/screens/community/risk_map_screen.dart
Frontend App/lib/screens/maps/authority_map_screen.dart
```

These use region scores from:

```text
GET /api/regions/
```

## Deployment Notes

### Render

Render service:

```text
https://hillsafe-ai.onrender.com
```

Render root directory:

```text
Backend
```

Build command currently runs:

```bash
pip install -r requirements.txt && python manage.py collectstatic --noinput && python manage.py migrate && python create_superuser.py && python seed_regions.py
```

Start command:

```bash
gunicorn hillsafe_core.wsgi:application
```

Because migrations are in the build command, new Django migrations are applied automatically on deploy.

### Neon

Render connects to Neon using environment variables:

```text
DB_HOST
DB_NAME
DB_USER
DB_PASSWORD
DB_PORT
```

### Environment Variables

Render should have:

```text
ALLOWED_HOSTS
CORS_ALLOWED_ORIGINS
DB_HOST
DB_NAME
DB_PASSWORD
DB_PORT
DB_USER
DEBUG
OPENWEATHER_API_KEY
WEATHER_API_KEY
SECRET_KEY
PYTHON_VERSION
SKLEARN_MODEL_PATH
LSTM_MODEL_PATH
SATELLITE_API_KEY
```

`OPENWEATHER_API_KEY` or `WEATHER_API_KEY` is required for live weather.

Do not push `.env` to GitHub. Keep secrets in Render Environment Variables.

### Secret Files

Render has:

```text
serviceAccountKey.json
```

Used by Firebase Admin SDK for push notifications.

## Git Ignore and Model Files

`Backend/.gitignore` ignores generic `.pkl` and `.h5` files, but explicitly allows the three deployment model artifacts:

```gitignore
!ml_engine/models/
!ml_engine/models/landslide_rf_model.pkl
!ml_engine/models/weather_scaler.pkl
!ml_engine/models/rainfall_lstm.h5
```

If production model status says not ready, check whether these files are committed and present in GitHub:

```bash
git ls-files Backend/ml_engine/models
```

Expected files:

```text
Backend/ml_engine/models/landslide_rf_model.pkl
Backend/ml_engine/models/weather_scaler.pkl
Backend/ml_engine/models/rainfall_lstm.h5
```

## Local Backend Setup

From repository root:

```powershell
cd Backend
.\venv\Scripts\activate
python manage.py migrate
python manage.py check
python manage.py runserver
```

If venv does not exist:

```powershell
cd Backend
python -m venv venv
.\venv\Scripts\activate
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
```

Local API root:

```text
http://127.0.0.1:8000/
```

## Local Flutter Setup

From repository root:

```powershell
cd "Frontend App"
flutter pub get
flutter run -d <device-id>
```

Build APK:

```powershell
cd "Frontend App"
flutter build apk --release
```

APK output:

```text
Frontend App/build/app/outputs/flutter-apk/app-release.apk
```

## Production Health Checks

Check model status:

```powershell
Invoke-RestMethod "https://hillsafe-ai.onrender.com/api/predict/status/"
```

Expected:

```text
rf_model_loaded: True
lstm_model_loaded: False
scaler_loaded: True
status: ready
```

Test location prediction:

```powershell
$body = @{
  latitude = 34.909
  longitude = 73.649
} | ConvertTo-Json

$response = Invoke-RestMethod `
  -Uri "https://hillsafe-ai.onrender.com/api/predict/location-risk/" `
  -Method Post `
  -Body $body `
  -ContentType "application/json"

$response | ConvertTo-Json -Depth 10
```

Test region list:

```powershell
Invoke-RestMethod "https://hillsafe-ai.onrender.com/api/regions/"
```

Manual ingestion, only when needed:

```powershell
Invoke-RestMethod `
  -Uri "https://hillsafe-ai.onrender.com/api/ingest/trigger/" `
  -Method Post
```

Manual ingestion should not be required every time the app opens because `/api/regions/` refreshes stale region risks.

## Known Limitations

- Lithology, NDVI, and NDWI are still defaults.
- Soil is saved and returned, but the current RF feature array does not include soil directly.
- Region risk refresh is throttled to protect free external APIs.
- Render free instances may sleep, so first request after inactivity can be slow.
- LSTM rainfall trend is present but not used in the main deployed risk path.
- Some analytics endpoints still generate simple simulated trend data based on current region risk. They are useful for UI but not yet a fully historical analytics system.

## Common Troubleshooting

### Browser Says "Not Found" for `/api/predict/location-risk/`

That endpoint is POST-only. Opening it in a browser sends GET. Use PowerShell/Postman/curl with POST JSON.

### Prediction Returns 503

Check:

```powershell
Invoke-RestMethod "https://hillsafe-ai.onrender.com/api/predict/status/"
```

If `rf_model_loaded` is false, Render probably does not have the model files. Confirm they are committed under:

```text
Backend/ml_engine/models/
```

### App Shows 10%

Older code hardcoded `0.1` in ingestion when rain was low. The backend now uses the ML pipeline for both live location prediction and stale region refreshes. If 10% appears again:

1. Check that the latest backend code is deployed.
2. Check `/api/predict/status/`.
3. Check `/api/regions/` output.
4. Confirm Flutter `baseUrl` points to Render.

### Render Build Works But Runtime Fails

Check Render runtime logs, not only build logs. Build success only means packages installed, migrations ran, and static files collected. Runtime model loading errors appear after Gunicorn starts.

## Developer Rule Of Thumb

- User-specific live risk: use `POST /api/predict/location-risk/`.
- Region cards/maps: use `GET /api/regions/`.
- Do not put prediction logic in Flutter.
- Do not use dummy frontend slope/soil/lithology values.
- Do not commit `.env`.
- Store repeated terrain API results in the database through `TerrainSample`.
- Keep model files under `Backend/ml_engine/models` for deployment.
