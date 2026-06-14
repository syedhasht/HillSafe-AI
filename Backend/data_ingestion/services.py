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


def _distance_km(lat1, lon1, lat2, lon2):
    import math

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


def send_push_notification(region, risk_score, alert_radius_km=10):
    """
    Send Firebase Cloud Messaging push notification to resident devices
    within the affected region radius when high-risk conditions are detected.
    """
    try:
        import firebase_admin
        from firebase_admin import messaging
        from accounts.models import DeviceToken
        from django.conf import settings
        
        # Ensure firebase_admin is initialized
        if not firebase_admin._apps:
            import os
            def _get_service_account_path():
                path1 = os.path.join(settings.BASE_DIR, 'serviceAccountKey.json')
                if os.path.exists(path1):
                    return path1
                path2 = os.path.join(os.path.dirname(settings.BASE_DIR), 'serviceAccountKey.json')
                if os.path.exists(path2):
                    return path2
                return path1
            cred_path = _get_service_account_path()
            cred = firebase_admin.credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)

        # Authority devices monitor alerts in the command center and should not
        # receive resident-facing push notifications.
        located_devices = (
            DeviceToken.objects
            .exclude(user__role__iexact='AUTHORITY')
            .exclude(latitude__isnull=True)
            .exclude(longitude__isnull=True)
        )
        tokens = []
        for device in located_devices:
            distance = _distance_km(
                float(device.latitude),
                float(device.longitude),
                float(region.latitude),
                float(region.longitude),
            )
            if distance <= alert_radius_km:
                tokens.append(device.token)
        
        if not tokens:
            print(f"⚠️ No device tokens found. Skipping push notification.")
            return
        
        title = '⚠️ High Risk Alert!'
        body_message = (
            f'Landslide risk detected in {region.name} ({int(risk_score * 100)}%).\n'
            'Move away from slopes, riverbanks, unstable roads, and follow official safety guidance.'
        )

        # Create high-priority notification message
        message = messaging.MulticastMessage(
            tokens=tokens,
            notification=messaging.Notification(
                title=title,
                body=body_message,
            ),
            data={
                'type': 'HIGH_RISK_ALERT',
                'region': region.name,
                'risk_score': str(risk_score),
                'alert_type': 'HIGH_RISK',
                'title': title,
                'message': body_message,
                'sound': 'default',
            },
            android=messaging.AndroidConfig(
                priority='high',
                notification=messaging.AndroidNotification(
                    title=title,
                    body=body_message,
                    sound='default',
                    channel_id='critical_alerts' if risk_score >= 0.8 else 'risk_alerts',
                ),
            ),
            apns=messaging.APNSConfig(
                headers={'apns-priority': '10'},
                payload=messaging.APNSPayload(
                    aps=messaging.Aps(
                        sound='default',
                        badge=1,
                        content_available=True,
                    )
                ),
            ),
        )
        
        # Send multicast message in chunks of 500
        total_sent = 0
        for i in range(0, len(tokens), 500):
            chunk = tokens[i:i + 500]
            message.tokens = chunk
            response = messaging.send_each_for_multicast(message)
            total_sent += response.success_count
            print(f"✓ Sent push notifications chunk: {response.success_count} success, {response.failure_count} failed")
            
    except ImportError:
        print("⚠️ Firebase Admin SDK not initialized. Cannot send notifications.")
    except Exception as e:
        print(f"⚠️ Error sending push notification: {e}")

