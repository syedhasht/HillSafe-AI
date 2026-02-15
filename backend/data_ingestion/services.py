"""
Data Ingestion Service for HillSafe AI.
Handles fetching live weather data from OpenWeatherMap API with fallback to mock data.
"""

import os
import random
import requests


def fetch_weather_data(region):
    """
    Fetch live weather data for a given region from OpenWeatherMap API.
    Falls back to mock data if API is unavailable or returns errors.
    
    Args:
        region: Region model instance with latitude and longitude
    
    Returns:
        dict: Weather data with rainfall_mm and temperature
    
    Example:
        {'rainfall_mm': 5.2, 'temperature': 18.5}
    """
    
    api_key = os.getenv('OPENWEATHER_API_KEY')
    
    if not api_key:
        print(f"API Error for {region.name}. No API key found. Switching to Mock Data.")
        return _generate_mock_data(region)
    
    # OpenWeatherMap API endpoint
    url = "https://api.openweathermap.org/data/2.5/weather"
    
    # API parameters
    params = {
        'lat': region.latitude,
        'lon': region.longitude,
        'appid': api_key,
        'units': 'metric'  # Get temperature in Celsius
    }
    
    try:
        # Make API request
        response = requests.get(url, params=params, timeout=10)
        
        # Check for successful response
        if response.status_code != 200:
            print(f"API Error for {region.name} (Status {response.status_code}). Switching to Mock Data.")
            return _generate_mock_data(region)
        
        data = response.json()
        
        # Extract rainfall (1-hour precipitation if available, else 0)
        rainfall = data.get('rain', {}).get('1h', 0)
        
        # Extract temperature
        temperature = data['main']['temp']
        
        # Log the fetched data
        print(f"Fetched for {region.name}: Rain={rainfall}mm, Temp={temperature}C")
        
        return {
            'rainfall_mm': rainfall,
            'temperature': temperature
        }
        
    except requests.exceptions.RequestException as e:
        print(f"API Error for {region.name}. Switching to Mock Data. Error: {str(e)}")
        return _generate_mock_data(region)
    except KeyError as e:
        print(f"API Error for {region.name}. Unexpected response format. Switching to Mock Data.")
        return _generate_mock_data(region)


def _generate_mock_data(region):
    """
    Generate mock weather data for testing when API is unavailable.
    
    Args:
        region: Region model instance
    
    Returns:
        dict: Mock weather data
    """
    mock_data = {
        'rainfall_mm': random.uniform(0, 60),
        'temperature': random.uniform(10, 25)
    }
    
    print(f"Generated Mock Data for {region.name}: Rain={mock_data['rainfall_mm']:.1f}mm, Temp={mock_data['temperature']:.1f}C")
    
    return mock_data


def send_push_notification(region_name, risk_score):
    """
    Send Firebase Cloud Messaging push notification to all registered devices
    when high-risk conditions are detected.
    
    Args:
        region_name: Name of the affected region
        risk_score: Risk score (0-1 scale)
    """
    try:
        from firebase_admin import messaging
        from accounts.models import DeviceToken
        
        # Get all registered device tokens
        tokens = list(DeviceToken.objects.values_list('token', flat=True))
        
        if not tokens:
            print(f"⚠️ No device tokens found. Skipping push notification.")
            return
        
        # Create notification message
        message = messaging.MulticastMessage(
            notification=messaging.Notification(
                title='⚠️ High Risk Alert!',
                body=f'Landslide risk detected in {region_name} ({int(risk_score * 100)}%)',
            ),
            data={
                'region': region_name,
                'risk_score': str(risk_score),
                'alert_type': 'HIGH_RISK',
            },
            tokens=tokens,
        )
        
        # Send multicast message
        response = messaging.send_multicast(message)
        
        print(f"✓ Sent push notifications to {response.success_count} device(s)")
        if response.failure_count > 0:
            print(f"⚠️ {response.failure_count} notification(s) failed to send")
            
    except ImportError:
        print("⚠️ Firebase Admin SDK not initialized. Cannot send notifications.")
    except Exception as e:
        print(f"⚠️ Error sending push notification: {e}")
