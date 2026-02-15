"""
Test OpenWeatherMap API integration.
Fetches real weather data for seeded regions.
"""

import os
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'hillsafe_core.settings')
django.setup()

from django.test import Client
import json

client = Client()

print("=" * 60)
print("Testing OpenWeatherMap API Integration")
print("=" * 60)

# Test the trigger endpoint
print("\n[TEST] POST /api/ingest/trigger/")
print("-" * 60)

response = client.post('/api/ingest/trigger/')

print(f"Status Code: {response.status_code}")

if response.status_code == 200:
    data = response.json()
    print("\nResponse:")
    print(json.dumps(data, indent=2))
    
    if data['status'] == 'success':
        print(f"\nSUCCESS: {data['message']}")
        print(f"Regions Updated: {data['updated']}")
        print(f"Alerts Created: {data['alerts_created']}")
        
        print("\nRegion Details:")
        for result in data['results']:
            if 'error' in result:
                print(f"\n  {result['region_name']}: ERROR - {result['error']}")
            else:
                print(f"\n  {result['region_name']}:")
                print(f"    Rainfall: {result['rainfall_mm']}mm")
                print(f"    Temperature: {result['temperature']}C")
                print(f"    Risk Score: {result['risk_score']}")
                print(f"    Alert Created: {'YES' if result.get('alert_created') else 'NO'}")
else:
    print(f"FAIL: Request failed with status {response.status_code}")
    print(response.content)

print("\n" + "=" * 60)
print("Test Completed!")
print("=" * 60)
