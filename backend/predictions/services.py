"""
Prediction Service for HillSafe AI.
Handles risk calculation and alert generation based on weather data.
"""

from predictions.models import PredictionLog
from regions.models import Region
from alerts.models import Alert


def calculate_risk(weather_data, region_id):
    """
    Calculate landslide risk score based on weather data.
    
    Args:
        weather_data (dict): Weather data containing rainfall_mm and soil_moisture
        region_id (int): ID of the region to calculate risk for
    
    Returns:
        float: Calculated risk score (0.0 to 1.0)
    
    Side Effects:
        - Creates a PredictionLog entry in the database
        - Creates a CRITICAL Alert if risk > 0.7
    
    TODO: Replace mock model with actual trained ML model (.pkl file)
    Currently using simple threshold-based logic for testing.
    """
    
    # Mock Model Logic - replace with actual ML model
    rainfall = weather_data.get('rainfall_mm', 0)
    soil_moisture = weather_data.get('soil_moisture', 0)
    
    # Simple threshold-based risk calculation
    if rainfall > 30:
        risk = 0.8
    else:
        risk = 0.2
    
    # Get region object
    try:
        region = Region.objects.get(id=region_id)
    except Region.DoesNotExist:
        raise ValueError(f"Region with ID {region_id} does not exist")
    
    # Save prediction result to database
    prediction_log = PredictionLog.objects.create(
        region=region,
        risk_score=risk,
        rainfall_mm=rainfall,
        soil_moisture=soil_moisture
    )
    
    # Update region's current risk score
    region.current_risk_score = risk
    region.save()
    
    # Trigger alert if risk is high
    if risk > 0.7:
        # Deactivate old alerts for this region
        Alert.objects.filter(region=region, is_active=True).update(is_active=False)
        
        # Create new CRITICAL alert
        Alert.objects.create(
            region=region,
            severity='CRITICAL',
            message=f"HIGH RISK ALERT: Landslide risk is critically high ({risk:.1%}). "
                   f"Rainfall: {rainfall:.1f}mm, Soil Moisture: {soil_moisture:.1f}%. "
                   f"Please take necessary precautions and avoid vulnerable areas.",
            is_active=True
        )
    
    return risk
