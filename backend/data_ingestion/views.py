"""
Data Ingestion API Views.
Provides endpoints to trigger data ingestion and processing with real weather data.
"""

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from regions.models import Region
from alerts.models import Alert
from data_ingestion.services import fetch_weather_data


class TriggerIngestionView(APIView):
    """
    Trigger weather data ingestion and risk assessment for all regions.
    
    POST /api/ingest/trigger/
    
    Fetches real-time weather data from OpenWeatherMap and updates:
    - Region risk scores based on rainfall
    - Automatic alert creation for high-risk conditions
    """
    
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
            
            # Update risk score based on rainfall
            if rainfall_mm > 10:
                region.current_risk_score = 0.8  # High risk
            else:
                region.current_risk_score = 0.1  # Low risk
            
            region.save()
            updated_count += 1
            
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
                    
                    # Send push notification to all registered devices
                    from data_ingestion.services import send_push_notification
                    send_push_notification(region.name, region.current_risk_score)
            
            results.append({
                'region_id': region.id,
                'region_name': region.name,
                'rainfall_mm': round(rainfall_mm, 2),
                'temperature': round(temperature, 2),
                'risk_score': round(region.current_risk_score, 2),
                'alert_created': region.current_risk_score > 0.7 and not active_alert_exists
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
