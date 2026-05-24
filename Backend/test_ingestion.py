"""
Test script for Data Ingestion and Prediction Services.
Tests the trigger endpoint that processes all regions.
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
print("HillSafe AI - Data Ingestion & Prediction Test")
print("=" * 60)

# Test: Trigger Data Ingestion
print("\n[TEST] Testing Data Ingestion Trigger (POST /api/ingest/trigger/)")
print("-" * 60)

response = client.post('/api/ingest/trigger/')

print(f"Status Code: {response.status_code}")

if response.status_code == 200:
    data = response.json()
    print(json.dumps(data, indent=2))
    
    if data['status'] == 'success':
        print(f"\nSUCCESS: {data['message']}")
        print(f"Alerts Created: {data['alerts_created']}")
        
        for result in data['results']:
            if 'error' in result:
                print(f"\nERROR in {result['region_name']}: {result['error']}")
            else:
                print(f"\n{result['region_name']}:")
                print(f"  Risk Score: {result['risk_score']}")
                print(f"  Rainfall: {result['rainfall_mm']}mm")
                print(f"  Soil Moisture: {result['soil_moisture']}%")
                print(f"  Alert Created: {'YES' if result['alert_created'] else 'NO'}")
    else:
        print(f"\nWARNING: {data['message']}")
else:
    print(f"FAIL: Request failed with status {response.status_code}")
    print(response.content)

print("\n" + "=" * 60)
print("Test Completed!")
print("=" * 60)

# Show updated regions
from regions.models import Region
from alerts.models import Alert
from predictions.models import PredictionLog

print("\nDatabase Summary:")
print(f"  Total Regions: {Region.objects.count()}")
print(f"  Active Alerts: {Alert.objects.filter(is_active=True).count()}")
print(f"  Prediction Logs: {PredictionLog.objects.count()}")

if Region.objects.exists():
    print("\nRegions with Risk Scores:")
    for region in Region.objects.all():
        print(f"  - {region.name}: {region.current_risk_score:.2f}")

if Alert.objects.filter(is_active=True).exists():
    print("\nActive Alerts:")
    for alert in Alert.objects.filter(is_active=True):
        print(f"  - [{alert.severity}] {alert.region.name}: {alert.message[:50]}...")
