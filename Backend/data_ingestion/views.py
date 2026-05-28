"""
Data Ingestion API Views.
Provides endpoints to trigger data ingestion and processing with real weather data.
"""

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from regions.models import Region
from alerts.models import Alert
from data_ingestion.services import fetch_weather_data
from ml_engine.predictor import HillSafePredictor
from ml_engine.views import (
    _get_or_create_terrain_sample,
    _precipitation_code,
    _terrain_defaults_from_region,
)


class TriggerIngestionView(APIView):
    """
    Trigger weather data ingestion and risk assessment for all regions.
    
    POST /api/ingest/trigger/
    
    Fetches real-time weather data from OpenWeatherMap and updates:
    - Region risk scores based on rainfall
    - Automatic alert creation for high-risk conditions
    """
    
    permission_classes = [permissions.AllowAny]
    
    def post(self, request):
        regions = Region.objects.all()
        
        if not regions.exists():
            return Response(
                {
                    'status': 'warning',
                    'message': 'No regions found in the database',
                    'updated': 0
                },
                status=status.HTTP_200_OK
            )
        
        results = []
        updated_count = 0
        alerts_created = 0
        
        predictor = HillSafePredictor()
        if not predictor.is_model_ready():
            return Response(
                {
                    'status': 'error',
                    'message': 'ML model is not ready. Region risks were not updated.',
                },
                status=status.HTTP_503_SERVICE_UNAVAILABLE
            )

        for region in regions:
            # Fetch live weather data
            weather_data = fetch_weather_data(region)
            
            if weather_data is None:
                results.append({
                    'region_id': region.id,
                    'region_name': region.name,
                    'error': 'Failed to fetch weather data'
                })
                continue
            
            rainfall_mm = weather_data['rainfall_mm']
            temperature = weather_data['temperature']

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

            risk_score = predictor.predict_risk(
                _precipitation_code(rainfall_mm),
                terrain['slope'],
                terrain['soil'],
                terrain['lithology'],
                terrain_features={
                    'Elevation': terrain['elevation'],
                    'NDVI': terrain['ndvi'],
                    'NDWI': terrain['ndwi'],
                },
            )

            region.current_risk_score = risk_score
            
            region.save()
            updated_count += 1
            alert_created = False
            
            # Auto-create alert for high risk
            if region.current_risk_score > 0.7:
                # Check if an active alert already exists
                active_alert_exists = Alert.objects.filter(
                    region=region,
                    is_active=True
                ).exists()
                
                if not active_alert_exists:
                    Alert.objects.create(
                        region=region,
                        severity='CRITICAL',
                        message=f"Heavy rain ({rainfall_mm}mm) detected in {region.name}. "
                               f"Landslide risk is high. Please take necessary precautions.",
                        is_active=True
                    )
                    alerts_created += 1
                    alert_created = True
                    
                    # Send push notification to all registered devices
                    from data_ingestion.services import send_push_notification
                    send_push_notification(region.name, region.current_risk_score)
            
            results.append({
                'region_id': region.id,
                'region_name': region.name,
                'rainfall_mm': round(rainfall_mm, 2),
                'temperature': round(temperature, 2),
                'risk_score': round(region.current_risk_score, 2),
                'terrain_source': terrain_source,
                'alert_created': alert_created
            })
        
        return Response(
            {
                'status': 'success',
                'message': f'Weather updated for {updated_count} region(s)',
                'updated': updated_count,
                'alerts_created': alerts_created,
                'results': results
            },
            status=status.HTTP_200_OK
        )
