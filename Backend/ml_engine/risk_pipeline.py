"""
Shared backend risk pipeline helpers.

These functions keep location risk and region risk refreshes on the same
weather, terrain, and ML path.
"""

from ml_engine.predictor import HillSafePredictor
from ml_engine.views import (
    _fetch_openweather_weather,
    _get_or_create_terrain_sample,
    _precipitation_code,
    _terrain_defaults_from_region,
)


def predict_region_risk(region):
    weather = _fetch_openweather_weather(region.latitude, region.longitude)
    terrain_defaults = _terrain_defaults_from_region(region)
    terrain_sample, terrain_source = _get_or_create_terrain_sample(
        region.latitude,
        region.longitude,
    )
    terrain = {
        'slope': terrain_sample.slope_code or terrain_defaults['slope'],
        'soil': terrain_sample.soil_code or terrain_defaults['soil'],
        'lithology': terrain_sample.lithology_code or terrain_defaults['lithology'],
        'elevation': terrain_sample.elevation_code or terrain_defaults['elevation'],
        'ndvi': terrain_sample.ndvi_code or terrain_defaults['ndvi'],
        'ndwi': terrain_sample.ndwi_code or terrain_defaults['ndwi'],
    }

    predictor = HillSafePredictor()
    if not predictor.is_model_ready():
        raise RuntimeError('ML model is not ready')

    risk_score = predictor.predict_risk(
        _precipitation_code(weather['rainfall_mm']),
        terrain['slope'],
        terrain['soil'],
        terrain['lithology'],
        terrain_features={
            'Elevation': terrain['elevation'],
            'NDVI': terrain['ndvi'],
            'NDWI': terrain['ndwi'],
        },
    )

    return {
        'risk_score': risk_score,
        'weather': weather,
        'terrain_source': terrain_source,
        'terrain_sample': terrain_sample,
        'input_features': {
            'precipitation_code': _precipitation_code(weather['rainfall_mm']),
            'rainfall_mm': weather['rainfall_mm'],
            'slope': terrain['slope'],
            'soil': terrain['soil'],
            'lithology': terrain['lithology'],
            'elevation': terrain['elevation'],
            'ndvi': terrain['ndvi'],
            'ndwi': terrain['ndwi'],
        },
    }
