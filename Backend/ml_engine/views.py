"""
ML Engine API Views for HillSafe AI

Provides REST API endpoints for machine learning predictions.
"""

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
import math
import os
import requests
from regions.models import Region, TerrainSample
from .predictor import HillSafePredictor


def _risk_level(score):
    if score > 0.7:
        return 'HIGH', False
    if score > 0.3:
        return 'MODERATE', False
    return 'LOW', True


def _distance_km(lat1, lon1, lat2, lon2):
    radius = 6371
    d_lat = math.radians(lat2 - lat1)
    d_lon = math.radians(lon2 - lon1)
    a = (
        math.sin(d_lat / 2) ** 2
        + math.cos(math.radians(lat1))
        * math.cos(math.radians(lat2))
        * math.sin(d_lon / 2) ** 2
    )
    return radius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


def _find_nearest_region(latitude, longitude):
    nearest = None
    nearest_distance = None

    for region in Region.objects.all():
        distance = _distance_km(
            latitude,
            longitude,
            region.latitude,
            region.longitude,
        )
        if nearest_distance is None or distance < nearest_distance:
            nearest = region
            nearest_distance = distance

    return nearest, nearest_distance


def _fetch_openweather_weather(latitude, longitude):
    api_key = os.getenv('OPENWEATHER_API_KEY') or os.getenv('WEATHER_API_KEY')
    if not api_key:
        raise requests.RequestException('OPENWEATHER_API_KEY or WEATHER_API_KEY is not configured')

    url = 'https://api.openweathermap.org/data/2.5/weather'
    params = {
        'lat': latitude,
        'lon': longitude,
        'appid': api_key,
        'units': 'metric',
    }

    response = requests.get(url, params=params, timeout=8)
    response.raise_for_status()
    data = response.json()
    rain = float(data.get('rain', {}).get('1h') or data.get('rain', {}).get('3h') or 0)
    snow = float(data.get('snow', {}).get('1h') or data.get('snow', {}).get('3h') or 0)
    main = data.get('main', {})

    return {
        'temperature': float(main.get('temp') or 0),
        'rainfall_mm': rain + snow,
        'humidity': float(main.get('humidity') or 0),
        'source': 'openweather',
    }


def _precipitation_code(rainfall_mm):
    if rainfall_mm <= 0:
        return 1
    if rainfall_mm < 2.5:
        return 2
    if rainfall_mm < 10:
        return 3
    if rainfall_mm < 25:
        return 4
    return 5


def _location_key(latitude, longitude):
    return round(latitude, 4), round(longitude, 4)


def _elevation_code(elevation_m):
    if elevation_m is None:
        return 2
    if elevation_m < 500:
        return 1
    if elevation_m < 1000:
        return 2
    if elevation_m < 1500:
        return 3
    if elevation_m < 2500:
        return 4
    return 5


def _slope_code(slope_degrees):
    if slope_degrees is None:
        return 2
    if slope_degrees < 5:
        return 1
    if slope_degrees < 15:
        return 2
    if slope_degrees < 25:
        return 3
    if slope_degrees < 35:
        return 4
    return 5


def _soil_code_from_texture(clay, sand, silt):
    if clay is None or sand is None or silt is None:
        return 'unknown', 2
    if clay >= 35:
        return 'clay-rich', 4
    if sand >= 60:
        return 'sandy', 1
    if silt >= 50:
        return 'silty', 2
    return 'loamy', 3


def _fetch_opentopodata_terrain(latitude, longitude):
    offset = 0.001
    locations = [
        f'{latitude},{longitude}',
        f'{latitude + offset},{longitude}',
        f'{latitude - offset},{longitude}',
        f'{latitude},{longitude + offset}',
        f'{latitude},{longitude - offset}',
    ]
    response = requests.get(
        'https://api.opentopodata.org/v1/srtm30m',
        params={'locations': '|'.join(locations)},
        timeout=10,
    )
    response.raise_for_status()
    data = response.json()
    if data.get('status') != 'OK':
        raise requests.RequestException(data.get('error') or 'OpenTopoData returned a non-OK status')

    results = data.get('results') or []
    elevations = [item.get('elevation') for item in results]
    if len(elevations) < 5 or elevations[0] is None:
        raise requests.RequestException('OpenTopoData did not return enough elevation points')

    center, north, south, east, west = [float(value) if value is not None else None for value in elevations[:5]]
    if None in [north, south, east, west]:
        slope_degrees = None
    else:
        lat_distance_m = 111_320 * offset * 2
        lon_distance_m = 111_320 * math.cos(math.radians(latitude)) * offset * 2
        north_south_gradient = (north - south) / lat_distance_m
        east_west_gradient = (east - west) / lon_distance_m
        slope_degrees = math.degrees(math.atan(math.hypot(north_south_gradient, east_west_gradient)))

    return {
        'elevation_m': center,
        'slope_degrees': slope_degrees,
        'elevation_code': _elevation_code(center),
        'slope_code': _slope_code(slope_degrees),
        'source': 'opentopodata_srtm30m',
    }


def _fetch_soilgrids_soil(latitude, longitude):
    response = requests.get(
        'https://rest.isric.org/soilgrids/v2.0/properties/query',
        params=[
            ('lon', longitude),
            ('lat', latitude),
            ('property', 'clay'),
            ('property', 'sand'),
            ('property', 'silt'),
            ('depth', '0-5cm'),
            ('depth', '5-15cm'),
            ('value', 'mean'),
        ],
        timeout=12,
    )
    response.raise_for_status()
    data = response.json()

    values = {'clay': [], 'sand': [], 'silt': []}
    for layer in data.get('properties', {}).get('layers', []):
        name = layer.get('name')
        if name not in values:
            continue
        for depth in layer.get('depths', []):
            mean = depth.get('values', {}).get('mean')
            if mean is not None:
                values[name].append(float(mean) / 10)

    clay = sum(values['clay']) / len(values['clay']) if values['clay'] else None
    sand = sum(values['sand']) / len(values['sand']) if values['sand'] else None
    silt = sum(values['silt']) / len(values['silt']) if values['silt'] else None
    soil_type, soil_code = _soil_code_from_texture(clay, sand, silt)

    return {
        'soil_type': soil_type,
        'soil_code': soil_code,
        'clay_percent': clay,
        'sand_percent': sand,
        'silt_percent': silt,
        'source': 'soilgrids_v2',
    }


def _get_or_create_terrain_sample(latitude, longitude):
    latitude_key, longitude_key = _location_key(latitude, longitude)
    sample = TerrainSample.objects.filter(
        latitude_key=latitude_key,
        longitude_key=longitude_key,
    ).first()
    if sample:
        return sample, 'database'

    sample = TerrainSample(
        latitude_key=latitude_key,
        longitude_key=longitude_key,
        requested_latitude=latitude,
        requested_longitude=longitude,
    )
    errors = {}

    try:
        elevation = _fetch_opentopodata_terrain(latitude, longitude)
        sample.elevation_m = elevation['elevation_m']
        sample.slope_degrees = elevation['slope_degrees']
        sample.elevation_code = elevation['elevation_code']
        sample.slope_code = elevation['slope_code']
        sample.elevation_source = elevation['source']
    except requests.RequestException as exc:
        errors['elevation'] = str(exc)

    try:
        soil = _fetch_soilgrids_soil(latitude, longitude)
        sample.soil_type = soil['soil_type']
        sample.soil_code = soil['soil_code']
        sample.clay_percent = soil['clay_percent']
        sample.sand_percent = soil['sand_percent']
        sample.silt_percent = soil['silt_percent']
        sample.soil_source = soil['source']
    except requests.RequestException as exc:
        errors['soil'] = str(exc)

    has_elevation = sample.elevation_m is not None and sample.slope_degrees is not None
    has_soil = bool(sample.soil_type and sample.soil_type != 'unknown')
    sample.data_quality = 'partial_api' if has_elevation or has_soil else 'defaults'
    sample.fetch_errors = errors
    sample.save()
    return sample, 'api_saved_to_database'


def _terrain_defaults_from_region(region):
    stored_risk = float(region.current_risk_score or 0)

    if stored_risk >= 0.7:
        slope = 4
        lithology = 4
    elif stored_risk >= 0.3:
        slope = 3
        lithology = 3
    else:
        slope = 2
        lithology = 2

    return {
        'slope': slope,
        'soil': 2,
        'lithology': lithology,
        'elevation': 2,
        'ndvi': 2,
        'ndwi': 2,
        'feature_source': 'nearest_region_defaults',
    }


class PredictRiskView(APIView):
    """
    POST endpoint for landslide risk prediction using ML models.
    
    Endpoint: POST /api/predict/risk/
    
    Request Body:
    {
        "rainfall": 45.5,
        "slope": 35.0,
        "soil": 2.0,
        "lithology": 3
    }
    
    Response:
    {
        "risk_score": 0.85,
        "risk_level": "HIGH",
        "is_safe": false,
        "model_status": "ready"
    }
    """
    
    permission_classes = [permissions.AllowAny]
    
    def post(self, request):
        # Extract parameters from request
        rainfall = request.data.get('rainfall')
        slope = request.data.get('slope')
        soil = request.data.get('soil')
        lithology = request.data.get('lithology')
        
        # Validate required fields
        if any(param is None for param in [rainfall, slope, soil, lithology]):
            return Response(
                {
                    'error': 'Missing required fields',
                    'required': ['rainfall', 'slope', 'soil', 'lithology']
                },
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Validate data types
        try:
            rainfall = float(rainfall)
            slope = float(slope)
            soil = float(soil)
            lithology = int(lithology)
        except (ValueError, TypeError):
            return Response(
                {'error': 'Invalid data types. rainfall, slope, soil must be numbers; lithology must be an integer'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Get predictor instance (singleton)
        predictor = HillSafePredictor()
        
        # Check if model is loaded
        if not predictor.is_model_ready():
            return Response(
                {
                    'error': 'ML model not loaded',
                    'message': 'The prediction model is currently unavailable. Please check server logs.',
                    'model_status': 'not_ready'
                },
                status=status.HTTP_503_SERVICE_UNAVAILABLE
            )
        
        # Perform prediction
        risk_score = predictor.predict_risk(rainfall, slope, soil, lithology)
        
        # Determine risk level
        if risk_score > 0.7:
            risk_level = 'HIGH'
            is_safe = False
        elif risk_score > 0.3:
            risk_level = 'MODERATE'
            is_safe = False
        else:
            risk_level = 'LOW'
            is_safe = True
        
        # Return prediction result
        return Response(
            {
                'risk_score': round(risk_score, 3),
                'risk_level': risk_level,
                'is_safe': is_safe,
                'model_status': 'ready',
                'input_params': {
                    'rainfall': rainfall,
                    'slope': slope,
                    'soil': soil,
                    'lithology': lithology
                }
            },
            status=status.HTTP_200_OK
        )


class PredictLocationRiskView(APIView):
    """
    POST endpoint for location-based landslide risk prediction.

    Frontend should send only:
    {
        "latitude": 31.4086,
        "longitude": 74.1732
    }

    Backend finds nearest region, fetches live weather, prepares numeric model
    inputs, runs the ML model, and returns debug fields for verification.
    """

    permission_classes = [permissions.AllowAny]

    def post(self, request):
        latitude = request.data.get('latitude')
        longitude = request.data.get('longitude')

        try:
            latitude = float(latitude)
            longitude = float(longitude)
        except (ValueError, TypeError):
            return Response(
                {'error': 'latitude and longitude must be valid numbers'},
                status=status.HTTP_400_BAD_REQUEST
            )

        if not (-90 <= latitude <= 90 and -180 <= longitude <= 180):
            return Response(
                {'error': 'latitude or longitude out of range'},
                status=status.HTTP_400_BAD_REQUEST
            )

        nearest_region, distance_km = _find_nearest_region(latitude, longitude)
        if nearest_region is None:
            return Response(
                {'error': 'No regions available for nearest-location lookup'},
                status=status.HTTP_404_NOT_FOUND
            )

        try:
            weather = _fetch_openweather_weather(latitude, longitude)
        except requests.RequestException as exc:
            weather = {
                'temperature': None,
                'rainfall_mm': 0.0,
                'humidity': None,
                'source': 'weather_fallback',
                'error': str(exc),
            }

        terrain_defaults = _terrain_defaults_from_region(nearest_region)
        terrain_sample, terrain_source = _get_or_create_terrain_sample(latitude, longitude)
        terrain = {
            'slope': terrain_sample.slope_code or terrain_defaults['slope'],
            'soil': terrain_sample.soil_code or terrain_defaults['soil'],
            'lithology': terrain_sample.lithology_code or terrain_defaults['lithology'],
            'elevation': terrain_sample.elevation_code or terrain_defaults['elevation'],
            'ndvi': terrain_sample.ndvi_code or terrain_defaults['ndvi'],
            'ndwi': terrain_sample.ndwi_code or terrain_defaults['ndwi'],
            'feature_source': terrain_source,
        }
        rainfall_code = _precipitation_code(weather['rainfall_mm'])

        predictor = HillSafePredictor()
        if not predictor.is_model_ready():
            return Response(
                {
                    'error': 'ML model not loaded',
                    'model_status': 'not_ready',
                    'source': 'model_unavailable',
                },
                status=status.HTTP_503_SERVICE_UNAVAILABLE
            )

        risk_score = predictor.predict_risk(
            rainfall_code,
            terrain['slope'],
            terrain['soil'],
            terrain['lithology'],
            terrain_features={
                'Elevation': terrain['elevation'],
                'NDVI': terrain['ndvi'],
                'NDWI': terrain['ndwi'],
            },
        )
        risk_level, is_safe = _risk_level(risk_score)

        return Response(
            {
                'risk_score': round(risk_score, 3),
                'risk_level': risk_level,
                'is_safe': is_safe,
                'model_status': 'ready',
                'source': 'ml_model',
                'nearest_region': {
                    'id': nearest_region.id,
                    'name': nearest_region.name,
                    'district': nearest_region.district,
                    'latitude': nearest_region.latitude,
                    'longitude': nearest_region.longitude,
                    'distance_km': round(distance_km, 2),
                    'current_risk_score': nearest_region.current_risk_score,
                    'current_temperature': weather['temperature'],
                    'current_rainfall': weather['rainfall_mm'],
                    'current_humidity': weather['humidity'],
                },
                'weather': weather,
                'terrain': {
                    'source': terrain_source,
                    'data_quality': terrain_sample.data_quality,
                    'latitude_key': float(terrain_sample.latitude_key),
                    'longitude_key': float(terrain_sample.longitude_key),
                    'elevation_m': terrain_sample.elevation_m,
                    'slope_degrees': terrain_sample.slope_degrees,
                    'soil_type': terrain_sample.soil_type,
                    'soil_code': terrain_sample.soil_code,
                    'clay_percent': terrain_sample.clay_percent,
                    'sand_percent': terrain_sample.sand_percent,
                    'silt_percent': terrain_sample.silt_percent,
                    'lithology_type': terrain_sample.lithology_type,
                    'lithology_code': terrain_sample.lithology_code,
                    'ndvi_code': terrain_sample.ndvi_code,
                    'ndwi_code': terrain_sample.ndwi_code,
                    'fetch_errors': terrain_sample.fetch_errors,
                },
                'input_features': {
                    'precipitation_code': rainfall_code,
                    'rainfall_mm': weather['rainfall_mm'],
                    'slope': terrain['slope'],
                    'soil': terrain['soil'],
                    'lithology': terrain['lithology'],
                    'elevation': terrain['elevation'],
                    'ndvi': terrain['ndvi'],
                    'ndwi': terrain['ndwi'],
                    'feature_source': terrain['feature_source'],
                },
            },
            status=status.HTTP_200_OK
        )


class ModelStatusView(APIView):
    """
    GET endpoint to check ML model loading status.
    
    Endpoint: GET /api/predict/status/
    
    Response:
    {
        "rf_model_loaded": true,
        "lstm_model_loaded": true,
        "scaler_loaded": true,
        "status": "ready"
    }
    """
    
    permission_classes = [permissions.AllowAny]
    
    def get(self, request):
        predictor = HillSafePredictor()
        
        return Response(
            {
                'rf_model_loaded': predictor.rf_model is not None,
                'lstm_model_loaded': predictor.lstm_model is not None,
                'scaler_loaded': predictor.scaler is not None,
                'status': 'ready' if predictor.is_model_ready() else 'not_ready'
            },
            status=status.HTTP_200_OK
        )
