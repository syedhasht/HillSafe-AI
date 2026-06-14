"""
Data Ingestion API Views.
Provides endpoints to trigger data ingestion and processing with real weather data.
"""

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from django.utils import timezone
from regions.models import Region
from alerts.models import Alert
from data_ingestion.services import fetch_weather_data
from ml_engine.predictor import HillSafePredictor
from ml_engine.risk_pipeline import predict_region_risk


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
        Alert.objects.filter(timestamp__lt=timezone.now() - timezone.timedelta(hours=24)).delete()
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
            try:
                prediction = predict_region_risk(region)
            except Exception as exc:
                results.append({
                    'region_id': region.id,
                    'region_name': region.name,
                    'error': str(exc),
                })
                continue

            rainfall_mm = prediction['weather']['rainfall_mm']
            temperature = prediction['weather']['temperature']
            region.current_risk_score = prediction['risk_score']
            region.save(update_fields=['current_risk_score', 'updated_at', 'last_updated'])
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
                    
                    # Send push notification only to resident devices inside the region radius.
                    from data_ingestion.services import send_push_notification
                    send_push_notification(region, region.current_risk_score)
            
            results.append({
                'region_id': region.id,
                'region_name': region.name,
                'rainfall_mm': round(rainfall_mm, 2),
                'temperature': round(temperature, 2),
                'risk_score': round(region.current_risk_score, 2),
                'terrain_source': prediction['terrain_source'],
                'alert_created': alert_created
            })

        if updated_count:
            from data_ingestion.map_updates import send_authority_map_update
            send_authority_map_update('predictions_refreshed')
        
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
